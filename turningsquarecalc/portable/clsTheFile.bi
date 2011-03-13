#pragma once

#include once "main.bi"

Type LPtypeFileNodeArray as typeFileNodeArray ptr

public type clsTheFile
public:
    declare destructor
    declare Sub AddNode(ByVal Index As Long)
    declare Sub AddNodeArray(ByVal n As any ptr=NULL)
    declare Sub Clear()

    declare Sub ClearNode(ByVal Index As Long)
    declare Sub ClearNodeData(ByVal Index As Long, ByVal Index2 As Long)
    declare Sub EraseNodeData(ByVal Index As Long, ByVal Index2 As Long)
    declare function FileName() As String
    declare Function FindNodeArray(ByVal lp As any ptr, ByVal Start As Long=1) As Long
    declare Sub GetNodeData(ByVal Index As Long, ByVal Index2 As Long, b() As Byte)
    declare Sub GetNodeDataEx(ByVal Index As Long, ByVal Index2 As Long, ByVal lp As any ptr)
    declare Function LoadData( d() As Byte, ByVal _Signature As any ptr=NULL) As Boolean
    declare Function LoadFile( fn As String, ByVal _Signature As any ptr=NULL, ByVal bSkipSignature As Boolean=False) As Boolean
    declare Sub LoadNodeDataFromFile(ByVal Index As Long, ByVal Index2 As Long, fn As String)
    declare Function NodeArrayCount() As Long
    declare Property NodeArrayName(ByVal Index As Long) As String
    declare Property NodeArrayName(ByVal Index As Long, s As String)
    declare Property NodeArrayNameValue(ByVal Index As Long) As Long
    declare Property NodeArrayNameValue(ByVal Index As Long, ByVal n As Long)
    declare Function NodeCount(ByVal Index As Long) As Long
    declare Function NodeSize(ByVal Index As Long, ByVal Index2 As Long) As Long
    declare sub SetNodeSize(ByVal Index As Long, ByVal Index2 As Long, ByVal m As Long)
    declare Sub RemoveNode(ByVal Index As Long, ByVal Index2 As Long)

    declare Sub RemoveNodeArray(ByVal Index As Long)
    'declare Function SaveData(d() As Byte, ByVal IsCompress As Boolean = True) As Long
    declare Function SaveFile( fn As String = "", ByVal IsCompress As Boolean = True) As Boolean
    declare Sub SaveNodeDataToFile(ByVal Index As Long, ByVal Index2 As Long, fn As String)
    declare Sub SetNodeArrayName(ByVal Index As Long, ByVal lp As any ptr)
    declare Sub SetNodeData(ByVal Index As Long, ByVal Index2 As Long, b() As Byte)
    declare Sub SetNodeDataEx(ByVal Index As Long, ByVal Index2 As Long, ByVal m As Long, ByVal lp As any ptr)
    declare Property Signature() As String
    declare Property Signature( s As String)

private:
    
    declare Sub pLoadData(b() As Byte)
    declare Function pSaveData(b() As Byte) As Long

    nds As LPtypeFileNodeArray
    ndc As Long
    sig(7) As byte

    m_sFileName As String

end type
