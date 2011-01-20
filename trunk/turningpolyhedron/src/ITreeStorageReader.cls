VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "ITreeStorageReader"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'////////////////////////////////
'This file is public domain.
'////////////////////////////////

'return value: size
Public Function GetName(ByRef lpName As Long) As Long
'
End Function

'return value: size
Public Function GetValue(ByRef lpValue As Long) As Long
'
End Function

'nUserData: =0 first <>0 next
'return value: =0 no more data <>0 next data
Public Function GetNextAttribute(ByVal nUserData As Long, ByRef lpName As Long, ByRef nNameSize As Long, ByRef lpValue As Long, ByRef nValueSize As Long) As Long
'
End Function

'nUserData: =0 first <>0 next
'return value: =0 no more data <>0 next data
Public Function GetNextNode(ByVal nUserData As Long, ByRef obj As ITreeStorageReader) As Long
'
End Function

