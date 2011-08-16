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

#Const UsePerformanceCounter = True
#Const UseSpinLock = False

#If UsePerformanceCounter Then
Private Declare Function QueryPerformanceCounter Lib "kernel32.dll" (ByRef lpPerformanceCount As Currency) As Long
Private Declare Function QueryPerformanceFrequency Lib "kernel32.dll" (ByRef lpFrequency As Currency) As Long
#Else
Private Declare Function GetTickCount Lib "kernel32.dll" () As Long
#End If
Private Declare Sub Sleep Lib "kernel32.dll" (ByVal dwMilliseconds As Long)

#If UsePerformanceCounter Then
Private t1 As Currency, t2 As Currency
Private nFreq As Currency
#Else
Private t1_1 As Long, t2_1 As Long
#End If
Private bRun As Boolean

Private m_fDelta As Double

Private m_nMinPeriod As Double
Private m_nFPS As Double

Private m_bAverageFPS As Boolean, m_nFPS_1 As Long, m_nFPS_T As Double

Friend Property Get AverageFPSEnabled() As Boolean
AverageFPSEnabled = m_bAverageFPS
End Property

Friend Property Let AverageFPSEnabled(ByVal b As Boolean)
m_bAverageFPS = b
End Property

Friend Property Get FPS() As Double
FPS = m_nFPS
End Property

Friend Sub WaitForNextFrame()
#If UsePerformanceCounter Then
Dim a As Currency
#Else
Dim a_1 As Long
#End If
Dim f As Double
Dim i As Long
If bRun Then
 If m_nMinPeriod > 0 Then
  Do
   #If UsePerformanceCounter Then
   QueryPerformanceCounter a
   f = (a - t2) / nFreq * 1000
   #Else
   a_1 = GetTickCount
   f = a_1 - t2_1
   #End If
   i = (m_nMinPeriod - f) / 2
   If i <= 1 Then Exit Do
   Sleep i 'TODO:background calculation instead of sleep
  Loop
  '///bad code:spinlock
  #If UseSpinLock Then
  #If UsePerformanceCounter Then
  If i > 0 Then
   Do Until f > m_nMinPeriod
    QueryPerformanceCounter a
    f = (a - t2) / nFreq * 1000
   Loop
  End If
  #End If
  #End If
  '///
 Else
  #If UsePerformanceCounter Then
  QueryPerformanceCounter a
  f = (a - t2) / nFreq * 1000
  #Else
  a_1 = GetTickCount
  f = a_1 - t2_1
  #End If
 End If
 '///
 m_fDelta = f
 '///
 If m_bAverageFPS Then
  m_nFPS_T = m_nFPS_T + f
  m_nFPS_1 = m_nFPS_1 + 1
  If m_nFPS_T > 500 Then
   m_nFPS = 1000 / m_nFPS_T * m_nFPS_1
   m_nFPS_T = 0
   m_nFPS_1 = 0
  End If
 Else
  If f < 0.001 Then f = 0.001
  m_nFPS = (1000 / f + m_nFPS * 7) / 8
 End If
 #If UsePerformanceCounter Then
 t2 = a
 #Else
 t2_1 = a_1
 #End If
Else
 #If UsePerformanceCounter Then
 QueryPerformanceCounter t2
 #Else
 t2_1 = GetTickCount
 #End If
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
#If UsePerformanceCounter Then
QueryPerformanceFrequency nFreq
#End If
End Sub

Friend Sub Clear()
#If UsePerformanceCounter Then
t1 = 0
t2 = 0
#Else
t1_1 = 0
t2_1 = 0
#End If
m_nFPS = 0
bRun = False
End Sub

Friend Sub StartTiming()
If Not bRun Then
 #If UsePerformanceCounter Then
 QueryPerformanceCounter t2
 #Else
 t2_1 = GetTickCount
 #End If
 bRun = True
End If
End Sub

Friend Sub StopTiming()
On Error Resume Next
#If UsePerformanceCounter Then
Dim a As Currency
#End If
If bRun Then
 #If UsePerformanceCounter Then
 QueryPerformanceCounter a
 t1 = t1 + a - t2
 #Else
 t1_1 = t1_1 + GetTickCount - t2_1
 #End If
 bRun = False
End If
End Sub

Friend Function GetMs() As Double
On Error Resume Next
#If UsePerformanceCounter Then
Dim a As Currency
#End If
If bRun Then
 #If UsePerformanceCounter Then
 QueryPerformanceCounter a
 GetMs = (t1 + a - t2) / nFreq * 1000
 #Else
 GetMs = t1_1 + GetTickCount - t2_1
 #End If
Else
 #If UsePerformanceCounter Then
 GetMs = t1 / nFreq * 1000
 #Else
 GetMs = t1_1
 #End If
End If
End Function

Friend Function GetDelta() As Double
GetDelta = m_fDelta
End Function
