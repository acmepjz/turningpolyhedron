VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsEffectManager"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

'Private Type typeFakeDXEffectArgumentPos
' nOffset As Byte
' nSize As Byte
'End Type

Private Type typeFakeDXEffectArgument
 nType As Long '[3]
 '0=undefined
 '1=hard-coded constant[1]
 '2=shader argument constant[2]
 '---read vertex shader input = &H10000-&H1FFFFF
 '&H10000,&H20000=color0-1
 '&H100000-&H1F0000=texcoord0-15
 'bit0-3,4-7,8-11,12-15=components1,2,3,4 if all 0 then default order = &H4321
 '0=undefined/zero
 '1,2,3,4=components1,2,3,4
 '5=hard-coded constant[1]
 '6=shader argument constant[2]
 '7=one
 '---(2D)texture[1][2][a] = &H1000000-&H1FFFFFF
 '&H1xyzzww
 'x=texture sampler index (0-15)
 'y=texcoord index (0-15)
 'zz=output components (default=&HE4)
 'ww=input components (default=&HE4)
 '---
 'TODO:other (eg. expression, volune texture, etc.)
 '--------
 '[1] uses sData
 '[2] uses sOptionalData
 '[a] sData format = sampler properties ['\x01' ...]
 '    sOptionalData = file name (???) currently unsupported
 '////////following strings are BINARY data !!!
 sData As String '[3]
 sOptionalData As String '[4]
 '////////if use shader argument
 nParamOffset As Byte
 nParamSize As Byte
 '////////
 nReserved1 As Byte
 nReserved2 As Byte
End Type

'TODO:light type
Private Type typeFakeDXEffect
 nTemplateIndex As Long
 '-1=this is a template
 '0=no template
 '>0=template index
 sTemplateName As String 'if this is a template
 '////////
 sShaderProgram As String '[3]
 '""         = don't use shader (alias "default" "none")
 '"standard" = standard shader
 nDiffuseAlgorithm As Long '[3]
 '0=default=Lambertian
 '1=Oren-Nayar
 nSpecularAlgorithm As Long '[3]
 '0=default=Blinn-Phong
 '1=Phong
 nFlags As Long '[3]
 '1=advanecd fog enabled (currently unsupported)
 '2=shadow map enabled (currently unsupported)
 '////////
 tArguments(63) As typeFakeDXEffectArgument
 '////////
 sShaderSourceCode As String
 nParamUsed As Long 'used float4
 '////////
 objEffect As D3DXEffect
End Type
'--------
'[3] compare (pCompareFakeDXEffect value=1)
'[4] optional compare (pCompareFakeDXEffect value=2)
'--------

Private Enum enumFakeDXEffectArgumentType
 IDA_Ambient
 IDA_Diffuse
 IDA_Specular
 IDA_SpecularHardness
 IDA_OrenNayarRoughness
 IDA_Emissive
 'TODO:normal mapping and parallax mapping
 IDA_NormalMap
 IDA_NormalScale
 IDA_ParallaxMap
 IDA_ParallaxOffset
 IDA_ParallaxScale
End Enum

Private m_tEffect() As typeFakeDXEffect
Private m_nEffectCount As Long, m_nEffectMax As Long

Private m_sParamName(63) As String
Private m_nParamSize(63) As Long
Private m_sOutputName(31) As String
Private m_sOutputSemantics(31) As String

Friend Sub Destroy()
Erase m_tEffect
m_nEffectCount = 0
m_nEffectMax = 0
End Sub

Private Sub Class_Initialize()
Dim i As Long
'///
m_sParamName(IDA_Ambient) = "ambient"
m_sParamName(IDA_Diffuse) = "diffuse"
m_sParamName(IDA_Specular) = "specular"
m_sParamName(IDA_SpecularHardness) = "specularHardness"
m_sParamName(IDA_OrenNayarRoughness) = "OrenNayarRoughness"
m_sParamName(IDA_Emissive) = "emissive"
m_sParamName(IDA_NormalMap) = "normalMap"
m_sParamName(IDA_NormalScale) = "normalScale"
m_sParamName(IDA_ParallaxMap) = "parallaxMap"
m_sParamName(IDA_ParallaxOffset) = "parallaxOffset"
m_sParamName(IDA_ParallaxScale) = "parallaxScale"
'///
m_nParamSize(IDA_Ambient) = 4
m_nParamSize(IDA_Diffuse) = 4
m_nParamSize(IDA_Specular) = 4
m_nParamSize(IDA_SpecularHardness) = 1
m_nParamSize(IDA_OrenNayarRoughness) = 1
m_nParamSize(IDA_Emissive) = 4
'///following are currently unsupported TODO:
m_nParamSize(IDA_NormalMap) = 4 '????????
m_nParamSize(IDA_NormalScale) = 1
m_nParamSize(IDA_ParallaxMap) = 1 '???????? TODO:combined to normal map
m_nParamSize(IDA_ParallaxOffset) = 1
m_nParamSize(IDA_ParallaxScale) = 1
'///
For i = 0 To 1
 m_sOutputSemantics(i + 1) = "COLOR" + CStr(i)
 m_sOutputName(i + 1) = "c" + CStr(i)
Next i
For i = 0 To 15
 m_sOutputSemantics(i + 16) = "TEXCOORD" + CStr(i)
 m_sOutputName(i + 16) = "t" + CStr(i)
Next i
End Sub

'0=not match
'1=shader program match
'2=shader argument match
Friend Function pCompareFakeDXEffect(ByRef t1 As typeFakeDXEffect, ByRef t2 As typeFakeDXEffect) As Long
Dim i As Long
'///
If t1.sShaderProgram <> t2.sShaderProgram Then Exit Function
If t1.nDiffuseAlgorithm <> t2.nDiffuseAlgorithm Then Exit Function
If t1.nSpecularAlgorithm <> t2.nSpecularAlgorithm Then Exit Function
If t1.nFlags <> t2.nFlags Then Exit Function
For i = 0 To 63
 If t1.tArguments(i).nType <> t2.tArguments(i).nType Then Exit Function
 If t1.tArguments(i).sData <> t2.tArguments(i).sData Then Exit Function
Next i
'///
pCompareFakeDXEffect = 1
For i = 0 To 63
 If t1.tArguments(i).sOptionalData <> t2.tArguments(i).sOptionalData Then Exit Function
Next i
'///
pCompareFakeDXEffect = 2
End Function

Friend Function pFindExistingFakeDXEffect(ByRef t As typeFakeDXEffect, ByRef nIndex As Long) As Long
Dim i As Long
Dim j As Long, jj As Long
Dim idx As Long
'///
If t.nTemplateIndex > 0 Then
 nIndex = t.nTemplateIndex
 jj = 1
Else
 nIndex = 0
 jj = 0
End If
'///
For i = 1 To m_nEffectCount
 j = pCompareFakeDXEffect(m_tEffect(i), t)
 If j > jj Then
  jj = j
  nIndex = i
  If j >= 2 Then Exit For
 End If
Next i
'///
pFindExistingFakeDXEffect = jj
End Function

Friend Function pCombineFakeDXEffectFromTemplate(ByRef t As typeFakeDXEffect) As Boolean
Dim i As Long
Dim m1 As Long, m2 As Long
Dim s As String
If t.nTemplateIndex > 0 Then
 With m_tEffect(t.nTemplateIndex)
  t.sShaderProgram = .sShaderProgram
  t.nDiffuseAlgorithm = .nDiffuseAlgorithm
  t.nSpecularAlgorithm = .nSpecularAlgorithm
  t.nFlags = .nFlags
  '///TODO:check argument type
  For i = 0 To 63
   s = t.tArguments(i).sData
   If s = vbNullString Then s = t.tArguments(i).sOptionalData
   t.tArguments(i) = .tArguments(i)
   m1 = LenB(s)
   m2 = LenB(t.tArguments(i).sOptionalData)
   If m1 >= m2 Then t.tArguments(i).sOptionalData = s _
   Else MidB(t.tArguments(i).sOptionalData, 1, m1) = s
  Next i
  '///
  t.nParamUsed = .nParamUsed
  Set t.objEffect = .objEffect
 End With
End If
'///
pCombineFakeDXEffectFromTemplate = True
End Function

Friend Function pFindUnusedInput(bInputUsed() As Byte, ByVal nStart As Long, ByVal nEnd As Long) As Long
Dim i As Long
For i = nStart To nEnd
 If bInputUsed(i) = 0 Then
  bInputUsed(i) = 1
  pFindUnusedInput = i
  Exit Function
 End If
Next i
pFindUnusedInput = -1
End Function

Friend Function pParseArgumentFromString(ByRef t As typeFakeDXEffect, ByVal s As String, ByVal nIndex As Long) As Boolean
Dim nDesiredSize As Long
Dim lps As Long
Dim s1 As String
Dim v As Variant, m As Long
Dim i As Long, ii As Long
Dim j As Long
Dim k As Long, kk As Long
Dim ret As typeFakeDXEffectArgument
Dim f As Single
'///
nDesiredSize = m_nParamSize(nIndex)
If nDesiredSize <= 0 Then
 Debug.Assert False
 Exit Function
End If
'///
v = Split(Trim(s), ":")
m = UBound(v) + 1
If m > 0 Then
 s = Trim(v(0))
 If Left(s, 5) = "color" Then
  i = Val(Mid(s, 6))
  If i = 0 Or i = 1 Then ret.nType = (i + 1) * &H10000 _
  Else Exit Function
 ElseIf Left(s, 8) = "texcoord" Then
  i = Val(Mid(s, 9))
  If i >= 0 And i < 16 Then ret.nType = (i + 16) * &H10000 _
  Else Exit Function
 ElseIf Left(s, 15) = "textureArgument" Then
  i = Val(Mid(s, 9))
  If i >= 0 And i < 16 Then ret.nType = (i + 16) * &H100000 _
  Else Exit Function
 ElseIf Left(s, 11) = "textureFile" Then
  'TODO:
  Debug.Assert False
  Exit Function
 End If
 If ret.nType >= &H10000 And ret.nType < &H200000 Then
  '////////////////shader input
  If m > 1 Then
   s1 = Left(Trim(v(1)), 4)
   If m > 2 Then
    v = Split(Trim(v(2)), ",")
    m = UBound(v) + 1
   Else
    m = 0
   End If
   k = 1
   For i = 1 To Len(s1)
    '///
    Select Case Mid(s1, i, 1)
    Case "x", "r"
     kk = 1
    Case "y", "g"
     kk = 2
    Case "z", "b"
     kk = 3
    Case "w", "a"
     kk = 4
    Case "C"
     kk = 5
     If ii < m Then f = Val(v(ii)) Else f = 0
     s = Space(2)
     CopyMemory ByVal StrPtr(s), f, 4&
     ret.sData = ret.sData + s
     ii = ii + 1
    Case "A"
     kk = 6
     If ii < m Then f = Val(v(ii)) Else f = 0
     s = Space(2)
     CopyMemory ByVal StrPtr(s), f, 4&
     ret.sOptionalData = ret.sOptionalData + s
     ii = ii + 1
    Case "1"
     kk = 7
    Case Else
     kk = 0
    End Select
    ret.nType = ret.nType Or (k * kk)
    '///
    k = k * &H10&
   Next i
  End If
 ElseIf s = "shaderArgument" Then
  '////////////////shader argument (constant)
  ret.nType = 2
  If m > 1 Then
   v = Split(Trim(v(1)), ",")
   m = UBound(v) + 1
   If m > 0 Then
    ret.sOptionalData = Space(m * 2&)
    For i = 0 To m - 1
     f = Val(v(i))
     CopyMemory ByVal StrPtr(ret.sOptionalData) + i * 4&, f, 4&
    Next i
   End If
  End If
  ret.sOptionalData = Left(ret.sOptionalData + String(nDesiredSize * 2&, vbNullChar), nDesiredSize * 2&)
 ElseIf ret.nType >= &H1000000 And ret.nType < &H2000000 Then
  '////////////////texture
  ret.nType = ret.nType Or &HE4E4&
  'read output components
  i = InStr(1, s, ".")
  If i > 0 Then
   k = &H100&
   For i = i + 1 To i + 4
    Select Case Mid(s, i, 1)
    Case "x", "r": kk = 0
    Case "y", "g": kk = 1
    Case "z", "b": kk = 2
    Case "w", "a": kk = 3
    Case Else: Exit For
    End Select
    ret.nType = (ret.nType And Not (k * 3&)) Or (k * kk)
    k = k * 4&
   Next i
  End If
  'read input index and components
  If m > 1 Then
   s = Trim(v(1))
   If Left(s, 8) = "texcoord" Then
    i = Val(Mid(s, 9))
    If i >= 0 And i < 16 Then ret.nType = ret.nType Or (i * &H10000) _
    Else Exit Function
   Else
    Debug.Assert False
    Exit Function
   End If
   '///
   i = InStr(1, s, ".")
   If i > 0 Then
    k = &H1&
    For i = i + 1 To i + 4
     Select Case Mid(s, i, 1)
     Case "x", "r": kk = 0
     Case "y", "g": kk = 1
     Case "z", "b": kk = 2
     Case "w", "a": kk = 3
     Case Else: Exit For
     End Select
     ret.nType = (ret.nType And Not (k * 3&)) Or (k * kk)
     k = k * 4&
    Next i
   End If
   '///
  End If
  'read sampler parameters
  If m > 2 Then
   ret.sData = Trim(v(m - 1))
   If Right(ret.sData, 1) <> ";" Then ret.sData = ret.sData + ";"
  End If
 Else
  '////////////////fixed constant
  ret.nType = 1
  v = Split(s, ",")
  m = UBound(v) + 1
  If m > 0 Then
   ret.sData = Space(m * 2&)
   For i = 0 To m - 1
    f = Val(v(i))
    CopyMemory ByVal StrPtr(ret.sData) + i * 4&, f, 4&
   Next i
  End If
  ret.sData = Left(ret.sData + String(nDesiredSize * 2&, vbNullChar), nDesiredSize * 2&)
 End If
End If
'///
If nIndex = IDA_OrenNayarRoughness Then
 Select Case ret.nType
 Case 1
  m = LenB(ret.sData)
  If m >= 4 Then
   CopyMemory f, ByVal StrPtr(ret.sData), 4&
   ret.sData = Space(4)
   f = f * f
   CopyMemory ByVal StrPtr(ret.sData), CSng(1 - 0.5 * f / (f + 0.33)), 4&
   CopyMemory ByVal StrPtr(ret.sData) + 4&, CSng(0.45 * f / (f + 0.09)), 4&
  End If
 Case 2
  m = LenB(ret.sOptionalData)
  If m >= 4 Then
   CopyMemory f, ByVal StrPtr(ret.sOptionalData), 4&
   ret.sOptionalData = Space(4)
   f = f * f
   CopyMemory ByVal StrPtr(ret.sOptionalData), CSng(1 - 0.5 * f / (f + 0.33)), 4&
   CopyMemory ByVal StrPtr(ret.sOptionalData) + 4&, CSng(0.45 * f / (f + 0.09)), 4&
  End If
 End Select
End If
'///
t.tArguments(nIndex) = ret
pParseArgumentFromString = True
End Function

Friend Function pGenerateArgumentCode(ByRef t As typeFakeDXEffect, ByVal nIndex As Long, ByVal nDesiredSize As Long, Optional ByVal sAdditional As String = vbNullString) As String
Dim nType As Long
Dim i As Long, j As Long, jj As Long
Dim nLast As Long
Dim m As Long, lp As Long
Dim f As Single
Dim b As Boolean
Dim d(3) As Byte
'///
pGenerateArgumentCode = "0"
With t.tArguments(nIndex)
 nType = .nType
 If nType = 0 Then
 ElseIf nType = 1 Then
  m = LenB(.sData) \ 4&
  lp = StrPtr(.sData)
  If m = 1 Then
   CopyMemory f, ByVal lp, 4&
   pGenerateArgumentCode = CStr(f)
  ElseIf m > 1 Then
   pGenerateArgumentCode = "float" + CStr(nDesiredSize) + "("
   For i = 0 To nDesiredSize - 1
    If i > 0 Then pGenerateArgumentCode = pGenerateArgumentCode + ","
    If i >= m Then
     pGenerateArgumentCode = pGenerateArgumentCode + "0"
    Else
     CopyMemory f, ByVal lp + i * 4&, 4&
     pGenerateArgumentCode = pGenerateArgumentCode + CStr(f)
    End If
   Next i
   pGenerateArgumentCode = pGenerateArgumentCode + ")"
  End If
 ElseIf nType = 2 Then
  m = .nParamSize
  If m = 1 Or m >= nDesiredSize Then
   If nDesiredSize > m Then nDesiredSize = m
   pGenerateArgumentCode = "_fParam[" + CStr(.nParamOffset \ 4&) + "]"
   If nDesiredSize < 4 Then
    pGenerateArgumentCode = pGenerateArgumentCode + "." + Mid("xyzw", (.nParamOffset And 3&) + 1, nDesiredSize)
   End If
  ElseIf m > 1 Then
   pGenerateArgumentCode = "float" + CStr(nDesiredSize) + "(" + "_fParam[" + CStr(.nParamOffset \ 4&) + "]." _
   + Mid("xyzw", (.nParamOffset And 3&) + 1, m) + Replace(Space(nDesiredSize - m), " ", ",0") + ")"
  End If
 ElseIf nType >= &H10000 And nType < &H200000 Then
  If (nType And &HFFFF&) = 0 Then
   d(0) = 1
   d(1) = 2
   d(2) = 3
   d(3) = 4
  Else
   d(0) = nType And &HF&
   d(1) = (nType And &HF0&) \ &H10&
   d(2) = (nType And &HF00&) \ &H100&
   d(3) = (nType And &HF000&) \ &H1000&
  End If
  '///
  b = True
  For i = 0 To nDesiredSize - 1
   If d(i) < 1 Or d(i) > 4 Then
    b = False
    Exit For
   End If
  Next i
  If b Then
   pGenerateArgumentCode = "cin." + m_sOutputName(nType \ &H10000) + "."
   For i = 0 To nDesiredSize - 1
    pGenerateArgumentCode = pGenerateArgumentCode + Mid("xyzw", d(i), 1)
   Next i
  Else
   nLast = 0
   m = LenB(.sData) \ 4&
   lp = StrPtr(.sData)
   j = 0
   jj = 0
   '///
   If nDesiredSize > 1 Then pGenerateArgumentCode = "float" + CStr(nDesiredSize) + "(" _
   Else pGenerateArgumentCode = "("
   For i = 0 To nDesiredSize - 1
    If d(i) >= 1 And d(i) <= 4 Then
     If nLast <> 1 Then
      If i > 0 Then pGenerateArgumentCode = pGenerateArgumentCode + ","
      pGenerateArgumentCode = pGenerateArgumentCode + "cin." + m_sOutputName(nType \ &H10000) + "."
     End If
     nLast = 1
     pGenerateArgumentCode = pGenerateArgumentCode + Mid("xyzw", d(i), 1)
    Else
     Select Case d(i)
     Case 0
      nLast = 0
      If i > 0 Then pGenerateArgumentCode = pGenerateArgumentCode + ","
      pGenerateArgumentCode = pGenerateArgumentCode + "0"
     Case 5
      nLast = 0
      If i > 0 Then pGenerateArgumentCode = pGenerateArgumentCode + ","
      If j >= m Then
       pGenerateArgumentCode = pGenerateArgumentCode + "0"
      Else
       CopyMemory f, ByVal lp + j * 4&, 4&
       pGenerateArgumentCode = pGenerateArgumentCode + CStr(f)
      End If
      j = j + 1
     Case 6
      If nLast <> 2 Then
       If i > 0 Then pGenerateArgumentCode = pGenerateArgumentCode + ","
       pGenerateArgumentCode = pGenerateArgumentCode + "_fParam[" + CStr(.nParamOffset \ 4&) + "]."
      End If
      nLast = 2
      pGenerateArgumentCode = pGenerateArgumentCode + Mid("xyzw", ((.nParamOffset + jj) And 3&) + 1, 1)
      jj = jj + 1
     Case 7
      nLast = 0
      If i > 0 Then pGenerateArgumentCode = pGenerateArgumentCode + ","
      pGenerateArgumentCode = pGenerateArgumentCode + "1"
     Case Else
      Debug.Assert False
     End Select
    End If
   Next i
   pGenerateArgumentCode = pGenerateArgumentCode + ")"
  End If
  '///
 ElseIf nType >= &H1000000 And nType < &H2000000 Then
  'texture
  pGenerateArgumentCode = "tex2D(samp" + CStr((nType And &HF00000) \ &H100000) + ",cin.t" + CStr((nType And &HF0000) \ &H10000) + "."
  j = nType And &HFF&
  For i = 1 To 2
   pGenerateArgumentCode = pGenerateArgumentCode + Mid("xyzw", 1 + (j And 3&), 1)
   j = j \ 4&
  Next i
  pGenerateArgumentCode = pGenerateArgumentCode + ")."
  j = (nType And &HFF00&) \ &H100&
  For i = 1 To nDesiredSize
   pGenerateArgumentCode = pGenerateArgumentCode + Mid("xyzw", 1 + (j And 3&), 1)
   j = j \ 4&
  Next i
 Else
  'TODO:etc.
  Debug.Assert False
 End If
End With
End Function

Friend Function pGenerateHLSLCodeFromFakeDXEffect(ByRef t As typeFakeDXEffect, Optional ByVal bComment As Boolean) As Boolean
Dim sParam As String, sTexture As String
Dim sInput As String, sOutput As String
'///
Dim bParamUsed(255) As Byte
Dim bInputUsed(31) As Byte
Dim bTextureUsed(15) As Byte
Dim sTextureArgument(15) As String
Dim nExtraInputCount As Long
Dim i As Long
Dim j As Long
Dim k As Long, kk As Long
Dim m As Long, mm As Long
Dim nType As Long
'///
Dim bMoreNormals As Boolean
Dim bFogEnabled As Boolean 'currently unsupported
Dim bShadowMap As Boolean 'currently unsupported
'///
t.sShaderSourceCode = vbNullString
t.nParamUsed = 0
'///
'TODO:
'TODO:normal mapping and parallax mapping
Select Case t.sShaderProgram
Case vbNullString
 'TODO:no HLSL shader
Case "standard"
 '////////////////////////////////generate declarations
 '///assign parameters space
 For i = 0 To 63
  With t.tArguments(i)
   .nParamOffset = 0
   .nParamSize = 0
   kk = 1
   '///
   nType = .nType
   If nType = 2 Or (nType >= &H10000 And nType < &H200000) Then
    m = LenB(.sOptionalData) \ 4&
    Debug.Assert m <= 4
    If m > 0 And m <= 4 Then
     '///assign space
     For j = 0 To 252 Step 4
      kk = 0
      For k = j To j + 3
       If bParamUsed(k) Then
        kk = 0
       Else
        kk = kk + 1
        If kk >= m Then Exit For
       End If
      Next k
      If kk >= m Then
       .nParamOffset = k - m + 1
       .nParamSize = m
       '///set used flag
       For kk = k - m + 1 To k
        bParamUsed(kk) = 1
       Next kk
       '///output comment
       If bComment Then _
       sParam = sParam + "// " + CStr(i) + " " + m_sParamName(i) + " in _fParam[" + CStr(k \ 4&) + "]." + Mid("xyzw", ((k - m + 1) And 3&) + 1, m) + vbCrLf
       '///
       k = k \ 4& + 1
       If mm < k Then mm = k
       kk = 1
       Exit For
      End If
     Next j
     '///
    End If
   Else
    'TODO:etc.
   End If
  End With
  If kk = 0 Then Exit Function 'failed to assign space
 Next i
 '///generate parameters
 t.nParamUsed = mm
 If bComment Then _
 sParam = sParam + "// parameters used:" + CStr(mm) + vbCrLf
 If mm > 0 Then sParam = sParam + "float4 _fParam[" + CStr(mm) + "];" + vbCrLf
 sParam = sParam + vbCrLf
 '///assign input space
 For i = 0 To 63
  With t.tArguments(i)
   nType = .nType
   If nType >= &H10000 And nType < &H200000 Then
    j = nType \ &H10000
    bInputUsed(j) = 45
    '///output comment
    If bComment Then _
    sOutput = sOutput + "// " + CStr(i) + " " + m_sParamName(i) + " in " + m_sOutputSemantics(j) + vbCrLf
    '///
   ElseIf nType >= &H1000000 And nType < &H2000000 Then
    'texture
    j = ((nType And &HF0000) \ &H10000) + 16&
    bInputUsed(j) = 45
    '///output comment
    If bComment Then
     sOutput = sOutput + "// " + CStr(i) + " " + m_sParamName(i) + " in " + m_sOutputSemantics(j) + vbCrLf
     sTexture = sTexture + "// " + CStr(i) + " " + m_sParamName(i) + " in texture #" + _
     CStr((nType And &HF00000) \ &H100000) + " using " + m_sOutputSemantics(j) + vbCrLf
    End If
    '///
    j = (nType And &HF00000) \ &H100000
    bTextureUsed(j) = 1
    If .sData <> vbNullString Then sTextureArgument(j) = .sData
   Else
    'TODO:etc.
   End If
  End With
 Next i
 '///generate input
 sInput = sInput + "struct VS_INPUT{" + vbCrLf
 sOutput = sOutput + "struct VS_OUTPUT{" + vbCrLf
 For i = 0 To 31
  If bInputUsed(i) Then
   sInput = sInput + vbTab + "float4 " + m_sOutputName(i) + ":" + m_sOutputSemantics(i) + ";" + vbCrLf
   sOutput = sOutput + vbTab + "float4 " + m_sOutputName(i) + ":" + m_sOutputSemantics(i) + ";" + vbCrLf
  End If
 Next i
 '///assign extra input
 bMoreNormals = t.tArguments(IDA_NormalMap).nType <> 0 Or t.tArguments(IDA_ParallaxMap).nType <> 0
 bFogEnabled = t.nFlags And 1&
 bShadowMap = t.nFlags And 2&
 '///generate extra input
 If bComment Then
  sInput = sInput + vbTab + "//---" + vbCrLf
  sOutput = sOutput + vbTab + "//---" + vbCrLf
 End If
 i = pFindUnusedInput(bInputUsed, 16, 31)
 If i < 0 Then Exit Function
 sInput = sInput + vbTab + "float4 vPos:POSITION;" + vbCrLf
 sOutput = sOutput + vbTab + "float4 vPos:" + m_sOutputSemantics(i) + ";" + vbCrLf
 i = pFindUnusedInput(bInputUsed, 16, 31)
 If i < 0 Then Exit Function
 sInput = sInput + vbTab + "float4 vNormal:NORMAL;" + vbCrLf
 sOutput = sOutput + vbTab + "float4 vNormal:" + m_sOutputSemantics(i) + ";" + vbCrLf
 If bMoreNormals Then
  i = pFindUnusedInput(bInputUsed, 16, 31)
  If i < 0 Then Exit Function
  sInput = sInput + vbTab + "float4 vBinormal:BINORMAL;" + vbCrLf
  sOutput = sOutput + vbTab + "float4 vBinormal:" + m_sOutputSemantics(i) + ";" + vbCrLf
  i = pFindUnusedInput(bInputUsed, 16, 31)
  If i < 0 Then Exit Function
  sInput = sInput + vbTab + "float4 vTangent:TANGENT;" + vbCrLf
  sOutput = sOutput + vbTab + "float4 vTangent:" + m_sOutputSemantics(i) + ";" + vbCrLf
 End If
 If bShadowMap Then
  i = pFindUnusedInput(bInputUsed, 16, 31)
  If i < 0 Then Exit Function
  sOutput = sOutput + vbTab + "float4 vShadow:" + m_sOutputSemantics(i) + ";" + vbCrLf
 End If
 '///
 sInput = sInput + "};" + vbCrLf + vbCrLf
 sOutput = sOutput + "};" + vbCrLf + vbCrLf
 '///other parameters
 sParam = sParam + "float4x4 matWorld,matWorldInv,matTransform;" + vbCrLf + vbCrLf
 If bShadowMap Then _
 sParam = sParam + "float4x4 matShadow;" + vbCrLf + vbCrLf
 If bFogEnabled Then _
 sParam = sParam + "float4 zData; //for pixel fog. (c1,c2,0,0) such that z=1/(c1+c2*z')" + vbCrLf + vbCrLf
 '///TODO:custom light
 'test only
 sParam = sParam + "float4 lightDir,lightPos,viewPos;" + vbCrLf + "int lightType;" + vbCrLf + vbCrLf
 '///texture
 mm = 0
 sTexture = sTexture + vbCrLf
 For i = 0 To 15
  If bTextureUsed(i) Then
   sTexture = sTexture + "texture tex" + CStr(i) + ";" + vbCrLf + "sampler samp" + CStr(i) + "=sampler_state{" _
   + vbCrLf + vbTab + "Texture=<tex" + CStr(i) + ">;" + vbCrLf + vbTab + sTextureArgument(i) + vbCrLf + "};" + vbCrLf + vbCrLf
   mm = mm + 1
  End If
 Next i
 sParam = sParam + "// texture used:" + CStr(mm) + vbCrLf + vbCrLf + sTexture
 '///
 '////////////////////////////////generate vertex shader
 sParam = sParam + "void vs_func(VS_INPUT cin,out VS_OUTPUT cout,out float4 vPos:POSITION){" + vbCrLf
 For i = 0 To 31
  If bInputUsed(i) = 45 Then
   sParam = sParam + vbTab + "cout." + m_sOutputName(i) + "=cin." + m_sOutputName(i) + ";" + vbCrLf
  End If
 Next i
 sParam = sParam + vbCrLf
 sParam = sParam + vbTab + "vPos=mul(cin.vPos,matTransform);" + vbCrLf
 If bFogEnabled Then
  sParam = sParam + vbTab + "cout.vPos=float4(mul(cin.vPos,matWorld).xyz,vPos.z);" + vbCrLf
  sParam = sParam + vbTab + "cout.vNormal=float4(mul(cin.vNormal,matWorldInv).xyz,vPos.w);" + vbCrLf
 Else
  sParam = sParam + vbTab + "cout.vPos=mul(cin.vPos,matWorld);" + vbCrLf
  sParam = sParam + vbTab + "cout.vNormal=mul(cin.vNormal,matWorldInv);" + vbCrLf
 End If
 If bMoreNormals Then
  sParam = sParam + vbTab + "cout.vBinormal=mul(cin.vBinormal,matWorldInv);" + vbCrLf
  sParam = sParam + vbTab + "cout.vTangent=mul(cin.vTangent,matWorldInv);" + vbCrLf
 End If
 If bShadowMap Then
  sParam = sParam + vbTab + "cout.vShadow=mul(cin.vPos,matShadow);" + vbCrLf
 End If
 sParam = sParam + "}" + vbCrLf + vbCrLf
 '////////////////////////////////generate pixel shader
 sParam = sParam + "float4 ps_func(VS_OUTPUT cin):COLOR0{" + vbCrLf
 sParam = sParam + vbTab + "float3 vView=normalize(viewPos.xyz-cin.vPos.xyz);" + vbCrLf + vbCrLf
 If t.tArguments(IDA_ParallaxMap).nType Then
  'TODO:parallax mapping
 End If
 sParam = sParam + vbTab + "float lightAmount=1.0f;" + vbCrLf + vbCrLf
 If bShadowMap Then
  'TODO:shadow map
 End If
 If t.tArguments(IDA_NormalMap).nType Then
  'TODO:normal mapping
 Else
  sParam = sParam + vbTab + "float3 vNormal=cin.vNormal.xyz;" + vbCrLf + vbCrLf
 End If
 '///TODO:custom light
 sParam = sParam + vbTab + "float3 vLight;" + vbCrLf + vbTab + "if(lightType==1) vLight=normalize(lightPos.xyz-cin.vPos.xyz);" + vbCrLf + vbTab + _
 "else vLight=lightDir.xyz;" + vbCrLf + vbCrLf
 '///diffuse
 Select Case t.nDiffuseAlgorithm
 Case 0
  sParam = sParam + vbTab + "float n_dot_l=dot(vNormal,vLight);" + vbCrLf + vbCrLf
 Case 1 'Oren-Nayar
  sParam = sParam + vbTab + "float n_dot_l=saturate(dot(vNormal,vLight));" + vbCrLf
  sParam = sParam + vbTab + "float n_dot_v=saturate(dot(vNormal,vView));" + vbCrLf
  '///
  nType = t.tArguments(IDA_OrenNayarRoughness).nType
  Select Case nType
  Case 0, 1, 2
   sParam = sParam + vbTab + "n_dot_l*=dot(" + pGenerateArgumentCode(t, IDA_OrenNayarRoughness, 2)
  Case Else
   sParam = sParam + vbTab + "float OrenNayarRoughness=" + pGenerateArgumentCode(t, IDA_OrenNayarRoughness, 1) + ";" + vbCrLf
   sParam = sParam + vbTab + "OrenNayarRoughness*=OrenNayarRoughness;" + vbCrLf
   sParam = sParam + vbTab + "n_dot_l*=dot(float2(1-0.5*OrenNayarRoughness/(OrenNayarRoughness+0.33),0.45*OrenNayarRoughness/(OrenNayarRoughness+0.09))"
  End Select
  sParam = sParam + ",float2(1," + _
  "saturate(dot(normalize(vLight-n_dot_l*vNormal),normalize(vView-n_dot_l*vNormal)))" + _
  "*sqrt(1.0f-n_dot_l*n_dot_l)*sqrt(1.0f-n_dot_v*n_dot_v)/max(n_dot_l,n_dot_v)));" + vbCrLf + vbCrLf
 Case Else
  Exit Function
 End Select
 '///specular
 Select Case t.nSpecularAlgorithm
 Case 0
  sParam = sParam + vbTab + "float fSpecular=dot(vNormal,normalize(vLight+vView));" + vbCrLf + vbCrLf
 Case 1
  sParam = sParam + vbTab + "float fSpecular=dot(vView,-reflect(vLight,vNormal));" + vbCrLf + vbCrLf '-reflect ???
 Case Else
  Exit Function
 End Select
 '///
 sParam = sParam + vbTab + "float4 lightResult=lit(n_dot_l,fSpecular," + pGenerateArgumentCode(t, IDA_SpecularHardness, 1) + ");" + vbCrLf
 sParam = sParam + vbTab + "lightResult=" + pGenerateArgumentCode(t, IDA_Ambient, 4) + "+" + pGenerateArgumentCode(t, IDA_Emissive, 4) + _
 "+lightAmount*(lightResult.y*" + pGenerateArgumentCode(t, IDA_Diffuse, 4) + "+lightResult.z*" + pGenerateArgumentCode(t, IDA_Specular, 4) + _
 ");" + vbCrLf + vbCrLf
 '///
 If bFogEnabled Then
  sParam = sParam + vbTab + "return float4(lightResult.xyz,1.0f/(zData.x+zData.y*cin.vPos.w/cin.vNormal.w));" + vbCrLf + "}" + vbCrLf + vbCrLf
 Else
  sParam = sParam + vbTab + "return float4(lightResult.xyz,1.0f);" + vbCrLf + "}" + vbCrLf + vbCrLf
 End If
 '////////////////////////////////generate effect
 sParam = sParam + "technique test{" + vbCrLf + vbTab + "pass{" + vbCrLf + vbTab + vbTab + "VertexShader=compile vs_3_0 vs_func();" + _
 vbCrLf + vbTab + vbTab + "PixelShader=compile ps_3_0 ps_func();" + vbCrLf + vbTab + "}" + vbCrLf + "}" + vbCrLf
 '////////////////////////////////over
 t.sShaderSourceCode = sInput + sOutput + sParam
 pGenerateHLSLCodeFromFakeDXEffect = True
 '///
Case Else
 'TODO:unsupported
End Select
End Function

Friend Function AddEffectFromNode(ByVal objNode As clsTreeStorageNode) As Long
Dim t As typeFakeDXEffect
Dim i As Long, j As Long, m As Long
Dim s As String
'///
s = objNode.GetNameAsString
Select Case s
Case "shaderTemplate"
 t.nTemplateIndex = -1
Case "shader"
Case Else
 Exit Function
End Select
'///
For i = 1 To objNode.SubNodeCount
 If objNode.SubNodeType(i) = 0 Then
  s = objNode.GetSubNodeNameAsString(i)
  Select Case s
  Case vbNullString
  Case "templateName"
   s = objNode.GetSubNodeValueAsString(i)
   If t.nTemplateIndex = -1 Then
    t.sTemplateName = s
   Else
    For j = 1 To m_nEffectCount
     If m_tEffect(j).nTemplateIndex = -1 Then
      If m_tEffect(j).sTemplateName = s Then
       t.nTemplateIndex = j
       Exit For
      End If
     End If
    Next j
    If j > m_nEffectCount Then
     Debug.Assert False
     Exit Function
    End If
   End If
  Case "shaderProgram"
   s = objNode.GetSubNodeValueAsString(i)
   Select Case s
   Case vbNullString, "none", "default"
    t.sShaderProgram = vbNullString
   Case "standard"
    t.sShaderProgram = s
   Case Else
    Debug.Assert False
    Exit Function
   End Select
  Case "diffuseAlgorithm"
   s = objNode.GetSubNodeValueAsString(i)
   Select Case s
   Case vbNullString, "default", "Lambertian"
    t.nDiffuseAlgorithm = 0
   Case "Oren-Nayar"
    t.nDiffuseAlgorithm = 1
   Case Else
    Debug.Assert False
    Exit Function
   End Select
  Case "specularAlgorithm"
   s = objNode.GetSubNodeValueAsString(i)
   Select Case s
   Case vbNullString, "default", "Blinn-Phong"
    t.nSpecularAlgorithm = 0
   Case "Phong"
    t.nSpecularAlgorithm = 1
   Case Else
    Debug.Assert False
    Exit Function
   End Select
  Case Else
   For j = 0 To 63
    If s = m_sParamName(j) Then
     If Not pParseArgumentFromString(t, objNode.GetSubNodeValueAsString(i), j) Then Exit Function
     Exit For
    End If
   Next j
   If j > 63 Then
    Debug.Assert False
    Exit Function
   End If
  End Select
 End If
Next i
'///
If Not pCombineFakeDXEffectFromTemplate(t) Then Exit Function
'///check if already exists
j = pFindExistingFakeDXEffect(t, i)
If j >= 2 And t.nTemplateIndex >= 0 Then
 AddEffectFromNode = i
 Exit Function
End If
'///compile effect
If j = 1 Then
 Set t.objEffect = m_tEffect(i).objEffect
ElseIf t.sShaderProgram <> vbNullString Then
 If Not pGenerateHLSLCodeFromFakeDXEffect(t, True) Then
  Debug.Assert False
  Exit Function
 End If
 'Debug.Print t.sShaderSourceCode
 If Not CreateEffect(t.sShaderSourceCode, t.objEffect) Then
  Debug.Assert False
  Exit Function
 End If
End If
'///add new effect
m = m_nEffectCount + 1
If m > m_nEffectMax Then
 m_nEffectMax = m_nEffectMax + 16&
 ReDim Preserve m_tEffect(1 To m_nEffectMax)
End If
m_tEffect(m) = t
m_nEffectCount = m
'///over
AddEffectFromNode = m
End Function

Friend Function LoadEffectsFromFile(ByVal FileName As String, ByVal objSerializer As ITreeSerializer) As Long
Dim objNode As New clsTreeStorageNode
If Not objSerializer.LoadNodeFromFile(FileName, objNode) Then Exit Function
LoadEffectsFromFile = LoadEffectsFromSubNodes(objNode)
End Function

Friend Function LoadEffectsFromSubNodes(ByVal objNode As clsTreeStorageNode) As Long
Dim i As Long, m As Long
Dim obj As clsTreeStorageNode
For i = 1 To objNode.SubNodeCount
 Set obj = objNode.SubNodeObject(i)
 If Not obj Is Nothing Then
  If AddEffectFromNode(obj) > 0 Then m = m + 1
 End If
Next i
LoadEffectsFromSubNodes = m
End Function

Friend Property Get EffectCount() As Long
EffectCount = m_nEffectCount
End Property

Friend Property Get EffectObject(ByVal nIndex As Long) As D3DXEffect
If nIndex > 0 And nIndex <= m_nEffectCount Then Set EffectObject = m_tEffect(nIndex).objEffect
End Property

Private Sub Class_Terminate()
Destroy
End Sub
