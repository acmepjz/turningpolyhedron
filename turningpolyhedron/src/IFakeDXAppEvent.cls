VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "IFakeDXAppEvent"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'nType: see mdlMain
'---
'mouse event: nParam1=x, nParam2=y, nParam3=xxxxyyyy, xxxx=shift, yyyy=button
'mouse wheel: nParam1=delta, nParam2=shift
'key event: nParam1=keycode, nParam2=shift
'---
Public Function OnEvent(ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
'
End Function
