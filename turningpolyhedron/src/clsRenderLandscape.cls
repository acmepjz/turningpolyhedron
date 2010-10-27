VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsRenderLandscape"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Type SAFEARRAYBOUND
    cElements As Long
    lLbound As Long
End Type
Private Type SAFEARRAY2D
    cDims As Integer
    fFeatures As Integer
    cbElements As Long
    cLocks As Long
    pvData As Long
    Bounds(0 To 1) As SAFEARRAYBOUND
End Type
Private Declare Function VarPtrArray Lib "msvbvm60.dll" Alias "VarPtr" (Ptr() As Any) As Long

Private m_hStub As Long

Private m_nSize As Long, m_fDim As Single, m_fScale As Single
Private m_tCenter As D3DVECTOR

Private m_nFogSize As Long, m_fFogScale As Single, m_fFogDisplace As Single

Friend Sub Render(ByVal objRender As clsRenderPipeline, ByVal objCamera As clsCamera, Optional ByVal fResolution As Single = 1000)
Dim tEye As D3DVECTOR
Dim tAt As D3DVECTOR
Dim tUp As D3DVECTOR
Dim fovy As Single, Aspect As Single, zn As Single, zf As Single
'///
If m_hStub = 0 Then Exit Sub
MyMini_VertexCount = 0
MyMini_IndexCount = 0
MyMini_FanCount = 0
'///
MyMini_Scale.x = m_fDim
MyMini_Scale.y = m_fDim
MyMini_Scale.z = m_fScale
MyMini_Offset.x = m_fDim * (1 - m_nSize) / 2 + m_tCenter.x
MyMini_Offset.y = m_fDim * (1 - m_nSize) / 2 - m_tCenter.z
MyMini_Offset.z = m_tCenter.y
'///
objRender.GetProjection_PerspectiveFovLH fovy, Aspect, zn, zf
objCamera.GetRealCamera tEye, tAt, tUp
'///
MiniStub_Draw m_hStub, fResolution, tEye.x, tEye.z, -tEye.y, tAt.x - tEye.x, tAt.z - tEye.z, tEye.y - tAt.y, tUp.x, tUp.z, -tUp.y, fovy * 57.29578!, Aspect, zn, zf
'///
'TODO:
If MyMini_IndexCount > 0 Then
 MyMini_IndexCount = MyMini_IndexCount \ 3
 d3dd9.SetVertexDeclaration d3dd9.CreateVertexDeclaration(m_tDefVertexDecl(0)) '??? slow!!!
' d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_SELECTARG2
' d3dd9.SetTextureStageState 0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG2
' d3dd9.SetRenderState D3DRS_FILLMODE, D3DFILL_WIREFRAME
 d3dd9.DrawIndexedPrimitiveUP D3DPT_TRIANGLELIST, 0, MyMini_VertexCount, MyMini_IndexCount, MyMini_Indices(0), D3DFMT_INDEX32, MyMini_Vertices(0), 64&
' d3dd9.SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_MODULATE
' d3dd9.SetTextureStageState 0, D3DTSS_ALPHAOP, D3DTOP_MODULATE
' d3dd9.SetRenderState D3DRS_FILLMODE, D3DFILL_SOLID
End If
End Sub

Friend Property Get Handle() As Long
Handle = m_hStub
End Property

Friend Function GetDataFromTexture(ByVal objTex As Direct3DTexture9, ByRef d() As Integer) As Long
Dim tDesc As D3DSURFACE_DESC, t1 As D3DLOCKED_RECT
Dim d0() As Byte, t0 As SAFEARRAY2D
Dim m2 As Long
Dim i As Long, j As Long, lp As Long, lp0 As Long, lp1 As Long
'///
If objTex Is Nothing Then Exit Function
'///
objTex.GetLevelDesc 0, tDesc
If tDesc.Pool = D3DPOOL_DEFAULT Then
 'TODO:
 Debug.Assert False
 Exit Function
End If
'///
Select Case tDesc.Format
Case D3DFMT_L8
 m2 = 1
Case D3DFMT_R8G8B8
 m2 = 3
Case D3DFMT_X8R8G8B8, D3DFMT_X8B8G8R8, D3DFMT_A8R8G8B8, D3DFMT_A8B8G8R8
 m2 = 4
Case Else
 'unknown format TODO:
 Debug.Assert False
 Exit Function
End Select
If tDesc.Width <> tDesc.Height Or tDesc.Width <= 1 Then Exit Function 'wrong size!
'///
objTex.LockRect 0, t1, ByVal 0, D3DLOCK_READONLY
t0.cDims = 1
t0.cbElements = 1
t0.Bounds(0).cElements = t1.Pitch * tDesc.Height
t0.pvData = t1.pBits
CopyMemory ByVal VarPtrArray(d0), VarPtr(t0), 4
ReDim d(tDesc.Width * tDesc.Height - 1)
For i = 1 To tDesc.Height
 lp = lp0
 For j = 1 To tDesc.Width
  d(lp1) = d0(lp)
  lp = lp + m2
  lp1 = lp1 + 1
 Next j
 lp0 = lp0 + t1.Pitch
Next i
CopyMemory ByVal VarPtrArray(d0), 0&, 4
objTex.UnlockRect 0
'///
GetDataFromTexture = tDesc.Width
End Function

Friend Function GetDataFromFile(ByVal fn As String, ByRef d() As Integer, Optional ByVal nSize As Long) As Long
Dim objTex As Direct3DTexture9
Dim ret As Long
Dim tInfo As D3DXIMAGE_INFO
'///
If fn = "" Then Exit Function
If nSize = 0 Then nSize = D3DX_DEFAULT_NONPOW2
ret = D3DXCreateTextureFromFileExW(d3dd9, fn, nSize, nSize, 1, 0, D3DFMT_L8, _
D3DPOOL_SCRATCH, D3DX_DEFAULT, D3DX_DEFAULT, 0, tInfo, ByVal 0, objTex) 'D3DFMT_L8 works!!! (D3DFMT_L16 will be buggy?)
If ret < 0 Then Exit Function
'///
GetDataFromFile = GetDataFromTexture(objTex, d)
End Function

Friend Function Create(ByVal lpImage As Long, ByVal nSize As Long, Optional ByVal fDim As Single = 1, Optional ByVal fScale As Single = 1, Optional ByVal nCenterX As Single, Optional ByVal nCenterY As Single, Optional ByVal nCenterZ As Single, Optional ByVal lpFogImage As Long, Optional ByVal nFogSize As Long, Optional ByVal fFogScale As Single, Optional ByVal fFogDisplace As Single) As Boolean
If nSize > 1 Then
 Destroy
 m_nSize = nSize
 m_fDim = fDim
 m_fScale = fScale
 m_tCenter.x = nCenterX
 m_tCenter.y = nCenterY
 m_tCenter.z = nCenterZ
 m_nFogSize = nFogSize
 m_fFogScale = fFogScale
 m_fFogDisplace = fFogDisplace
 '///
 m_hStub = MiniStub_Create(ByVal lpImage, m_nSize, m_fDim, m_fScale, 1, m_tCenter.x, m_tCenter.y, m_tCenter.z, _
 AddressOf MyMiniCallback_BeginFan, AddressOf MyMiniCallback_FanVertex, 0, 0, 0, ByVal lpFogImage, m_nFogSize, m_fFogScale, m_fFogDisplace, 1, _
 AddressOf MyMiniCallback_PrismEdge, ByVal 0, ByVal 0, 0, 0, 0, 0, 0, 0, 0)
 '///
 Create = m_hStub <> 0
End If
End Function

Friend Function CreateFromFile(ByVal fnImage As String, Optional ByVal nSize As Long, Optional ByVal fDim As Single = 1, Optional ByVal fScale As Single = 1, Optional ByVal nCenterX As Single, Optional ByVal nCenterY As Single, Optional ByVal nCenterZ As Single, Optional ByVal fnFogImage As String, Optional ByVal nFogSize As Long, Optional ByVal fFogScale As Single, Optional ByVal fFogDisplace As Single) As Boolean
Dim d() As Integer
Dim dFog() As Integer
Dim lpFogImage As Long
'///
nSize = GetDataFromFile(fnImage, d, nSize)
If nSize <= 0 Then Exit Function
'///
nFogSize = GetDataFromFile(fnFogImage, dFog, nFogSize)
If nFogSize > 0 Then lpFogImage = VarPtr(dFog(0))
'///
Destroy
m_nSize = nSize
m_fDim = fDim
m_fScale = fScale
m_tCenter.x = nCenterX
m_tCenter.y = nCenterZ
m_tCenter.z = -nCenterY
m_nFogSize = nFogSize
m_fFogScale = fFogScale
m_fFogDisplace = fFogDisplace
'///
m_hStub = MiniStub_Create(d(0), m_nSize, m_fDim, m_fScale, 1, m_tCenter.x, m_tCenter.y, m_tCenter.z, _
AddressOf MyMiniCallback_BeginFan, AddressOf MyMiniCallback_FanVertex, 0, 0, 0, ByVal lpFogImage, m_nFogSize, m_fFogScale, m_fFogDisplace, 1, _
AddressOf MyMiniCallback_PrismEdge, ByVal 0, ByVal 0, 0, 0, 0, 0, 0, 0, 0)
'///
CreateFromFile = m_hStub <> 0
End Function

Friend Sub Destroy()
If m_hStub Then MiniStub_Destroy m_hStub
m_hStub = 0
End Sub

Private Sub Class_Initialize()
SetMiniErrorHandler AddressOf MyMiniCallback_ErrorHandler
End Sub

Private Sub Class_Terminate()
Destroy
End Sub
