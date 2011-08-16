VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "ITreeStorageBuilder"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'////////////////////////////////
'This file is public domain.
'////////////////////////////////

Public Sub SetName(ByVal lp As Long, ByVal nLength As Long, ByRef Cancel As Boolean)
'
End Sub

Public Sub SetValue(ByVal lp As Long, ByVal nLength As Long, ByRef Cancel As Boolean)
'
End Sub

'return value: newly created node
'if it's Nothing then cancelled
Public Function NewNode() As ITreeStorageBuilder
'
End Function

Public Sub EndNode(ByRef Cancel As Boolean)
'
End Sub

Public Sub NewAttribute(ByVal lpName As Long, ByVal nNameLength As Long, ByVal lpValue As Long, ByVal nValueLength As Long, ByRef Cancel As Boolean)
'
End Sub
