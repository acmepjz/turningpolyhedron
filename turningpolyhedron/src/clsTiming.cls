VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsTiming"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'////////////////////////////////
'This file is public domain.
'////////////////////////////////

Private Declare Function QueryPerformanceCounter Lib "kernel32.dll" (ByRef lpPerformanceCount As Currency) As Long
Private Declare Function QueryPerformanceFrequency Lib "kernel32.dll" (ByRef lpFrequency As Currency) As Long
Private Declare Function GetTickCount Lib "kernel32.dll" () As Long
Private Declare Sub Sleep Lib "kernel32.dll" (ByVal dwMilliseconds As Long)

Private t1 As Currency, t2 As Currency
Private t1_1 As Long, t2_1 As Long
Private nFreq As Currency
Private bRun As Boolean

Private m_nMinPeriod As Double
Private m_nFPS As Double

Friend Property Get FPS() As Double
FPS = m_nFPS
End Property

Friend Sub WaitForNextFrame()
Dim a As Currency, a_1 As Long
Dim f As Double
Dim i As Long
If m_nMinPeriod <= 0 Then Exit Sub
If bRun Then
 Do
  QueryPerformanceCounter a
'  a_1 = GetTickCount
  f = (a - t2) / nFreq * 1000
  i = (m_nMinPeriod - f) / 2
  If i <= 1 Then Exit Do
  Sleep i
 Loop
' '///bad code:spinlock
' If i > 0 Then
'  Do Until f > m_nMinPeriod
'   QueryPerformanceCounter a
'   f = (a - t2) / nFreq * 1000
'  Loop
' End If
' '///
 m_nFPS = (1000 / f + m_nFPS * 7) / 8
' m_nFPS = (1000 / (a_1 - t2_1 + 1) + m_nFPS * 7) / 8
 t2 = a
' t2_1 = a_1
Else
 QueryPerformanceCounter t2
 bRun = True
End If
End Sub

Friend Property Get MinPeriod() As Double
MinPeriod = m_nMinPeriod
End Property

Friend Property Let MinPeriod(ByVal n As Double)
m_nMinPeriod = n
End Property

Private Sub Class_Initialize()
QueryPerformanceFrequency nFreq
End Sub

Friend Sub Clear()
t1 = 0
t2 = 0
m_nFPS = 0
bRun = False
End Sub

Friend Sub StartTiming()
If Not bRun Then
 QueryPerformanceCounter t2
 bRun = True
End If
End Sub

Friend Sub StopTiming()
On Error Resume Next
Dim a As Currency
If bRun Then
 QueryPerformanceCounter a
 t1 = t1 + a - t2
 bRun = False
End If
End Sub

Friend Function GetMs() As Double
On Error Resume Next
Dim a As Currency
If bRun Then
 QueryPerformanceCounter a
 GetMs = (t1 + a - t2) / nFreq * 1000
Else
 GetMs = t1 / nFreq * 1000
End If
End Function
