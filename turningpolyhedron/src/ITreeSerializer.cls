VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "ITreeSerializer"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'////////////////////////////////
'This file is public domain.
'////////////////////////////////

Public Function ReadNode(ByVal lp As Long, ByVal nLength As Long, ByVal objOut As ITreeStorageBuilder, Optional ByVal bLoadSubNodeOnly As Boolean) As Boolean
'
End Function

Public Sub WriteNode(ByVal obj As ITreeStorageReader, ByVal objOut As clsTreeStorageNode, Optional ByVal bWriteHeader As Boolean = True, Optional ByVal bSaveSubNodeOnly As Boolean)
'
End Sub

Public Function LoadNodeFromFile(ByVal FileName As String, ByVal objOut As ITreeStorageBuilder, Optional ByVal bLoadSubNodeOnly As Boolean) As Boolean
'
End Function

Public Function SaveNodeToFile(ByVal FileName As String, ByVal obj As ITreeStorageReader, Optional ByVal bWriteHeader As Boolean = True, Optional ByVal bSaveSubNodeOnly As Boolean) As Boolean
'
End Function

