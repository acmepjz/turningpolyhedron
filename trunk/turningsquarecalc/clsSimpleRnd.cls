VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsSimpleRnd"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'a stupid logistic random

Private x(1 To 10) As Double

Public Sub Randomize(ByVal s As String)
Dim i As Long, j As Long, k As Long
For i = 1 To 10
 x(i) = Abs(Sin(i))
Next i
i = 0
s = UCase(s)
For j = 1 To Len(s)
 k = Asc(Mid(s, j, 1)) - 65
 If k >= 0 And k < 26 Then
  i = i + 1
  If i > 10 Then Exit For
  x(i) = x(i) + 0.03846 * k + 0.01234
  If x(i) > 1 Then x(i) = x(i) - 1
 End If
Next j
End Sub

Public Function ValidateRndSeed(ByVal s As String) As String
Dim s2 As String
Dim i As Long, j As Long, k As Long
s = UCase(s)
For j = 1 To Len(s)
 k = Asc(Mid(s, j, 1)) - 65
 If k >= 0 And k < 26 Then
  i = i + 1
  If i > 10 Then Exit For
  s2 = s2 + Chr(65 + k)
 End If
Next j
ValidateRndSeed = s2
End Function

Public Function RndSeed() As String
Dim i As Long, s As String
For i = 1 To 10
 s = s + Chr(65 + Int(26 * VBA.Rnd))
Next i
RndSeed = s
End Function

Public Function Rnd() As Single
Dim i As Long, f As Single
Dim f2 As Single
f2 = 0.5
For i = 1 To 10
 x(i) = 4 * x(i) * (1 - x(i))
 If x(i) > 0.5 Then f = f + f2
 f2 = f2 * 0.5
Next i
Rnd = f
End Function
