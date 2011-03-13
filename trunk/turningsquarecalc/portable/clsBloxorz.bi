#pragma once

#include once "main.bi"
#include once "clsTheFile.bi"

#define SolveItRecordMovedArea 1

Enum enumBloxorzStateValid
 BState_Fall = 0
 BState_Valid = 1
 BState_Thin = 2
 BState_UnknownError = 99
End Enum

type LPtypeSolveItSwitchIdPos as typeSolveItSwitchIdPos ptr
type LPtypeSolveItNode as typeSolveItNode ptr
type LPtypeSwitch as typeSwitch ptr
type LPtypeNextPos as typeNextPos ptr
type LPtypeSwitch as typeSwitch ptr

type IBloxorzCallBack
  SolveItCallBack as sub(ByVal nNodeNow As Long, ByVal nNodeCount As Long, bAbort As Boolean)
end type

type clsBloxorz
public:

StartX As Long
StartY As Long

Declare Sub AddSwitch()
Declare Sub AddSwitchBridge(ByVal Index As Long, ByVal x As Long=0, ByVal y As Long=0, ByVal Behavior As Long=0)
Declare Function BloxorzCheckBlockSlip(d() As Byte, ByVal x As Long, ByVal y As Long, ByVal GameS As Long, ByVal FS As Long, ByVal x2 As Long=0, ByVal y2 As Long=0) As Long
Declare Function BloxorzCheckIsMovable(d() As Byte, ByVal x As Long, ByVal y As Long, ByVal GameS As Long, ByVal FS As Long, ByRef QIE As Long=0) As Boolean
Declare Function BloxorzCheckIsValidState(d() As Byte, ByVal x As Long, ByVal y As Long, ByVal GameS As Long, ByVal x2 As Long=0, ByVal y2 As Long=0) As enumBloxorzStateValid
Declare Function BloxorzCheckPressButton(d() As Byte, ByVal x As Long, ByVal y As Long, ByVal GameS As Long, ByVal lpBridgeChangeArray As any ptr=NULL, ByVal BridgeOff As Long=0, ByVal BridgeOn As Long=0) As Long
Declare Sub Clear()
Declare Sub ClearSwitch()
Declare Sub ClearSwitchBridge(ByVal Index As Long)
Declare Sub Clone(byval objSrc As clsBloxorz ptr)

Declare Sub Create(ByVal w As Long, ByVal h As Long)
Declare Function Data(ByVal x As Long, ByVal y As Long) As Long
Declare Sub SetData(ByVal x As Long, ByVal y As Long, ByVal n As Long)
Declare Function Data2(ByVal x As Long, ByVal y As Long) As Long
Declare Sub SetData2(ByVal x As Long, ByVal y As Long, ByVal n As Long)
Declare Sub Destroy()

Declare Function GetSpecifiedObjectCount(ByVal i1 As Long, ByVal i2 As Long=0, ByVal x1 As Long=0, ByVal y1 As Long=0, ByVal x2 As Long=0, ByVal y2 As Long=0) As Long
Declare Sub GetTransportPosition(ByVal x As Long, ByVal y As Long, ByRef x1 As Long, ByRef y1 As Long, ByRef x2 As Long, ByRef y2 As Long)
Declare Function Height() As Long
Declare Sub LoadLevel(ByVal lv As Long,byval d As clsTheFile ptr)
Declare Sub RemoveSwitch(ByVal Index As Long)
Declare Sub RemoveSwitchBridge(ByVal Index As Long, ByVal i As Long)
Declare Sub SaveLevel(ByVal lv As Long,byval d As clsTheFile ptr)
Declare Sub SetTransportPosition(ByVal x As Long, ByVal y As Long, ByVal x1 As Long, ByVal y1 As Long, ByVal x2 As Long, ByVal y2 As Long)
Declare Function SolveIt(byval objProgress As IBloxorzCallBack ptr=NULL) As Boolean
Declare Sub SolveItClear()
Declare Sub SolveItGetCanMoveArea(d() As Byte)
Declare Function SolveItGetDistance(ByVal Index As Long) As Long
Declare Function SolveItGetNodeIndex(ByVal m As Long, ByVal State As Long, ByVal x As Long, ByVal y As Long, ByVal x2 As Long=0, ByVal y2 As Long=0) As Long
Declare Function SolveItGetNodeMax() As Long
Declare Function SolveItGetNodeUsed() As Long
Declare Function SolveItGetSolution(ByVal Index As Long, ByVal lpMovedArea As any ptr=0) As String
Declare Function SolveItGetSolutionNodeIndex(byref SolX As Long=0, byref SolY As Long=0, byref SolSwitchStatus As Long=0) As Long
Declare Sub SolveItGetSwitchStatus(ByVal Index As Long, d() As Byte)
Declare Function SolveItGetSwitchStatusCount() As Long
Declare Function SolveItGetTimeUsed() As Long
Declare Function SolveItIsTrans() As Boolean
Declare Function SwitchBridgeBehavior(ByVal Index As Long, ByVal i As Long) As Long
Declare Sub SetSwitchBridgeBehavior(ByVal Index As Long, ByVal i As Long, ByVal n As Long)
Declare Function SwitchBridgeCount(ByVal Index As Long) As Long
Declare Sub SetSwitchBridgeCount(ByVal Index As Long, ByVal n As Long)
Declare Function SwitchBridgeX(ByVal Index As Long, ByVal i As Long) As Long
Declare Sub SetSwitchBridgeX(ByVal Index As Long, ByVal i As Long, ByVal n As Long)
Declare Function SwitchBridgeY(ByVal Index As Long, ByVal i As Long) As Long
Declare Sub SetSwitchBridgeY(ByVal Index As Long, ByVal i As Long, ByVal n As Long)
Declare Function SwitchCount() As Long
Declare Sub TransformLevel(ByVal nOperateIndex As Long)
Declare Function Width() As Long

Declare Function FromString(ByRef sString As String) As Boolean
Declare Function ToString() As String
Declare Function PasteFromClipboard() As Boolean
Declare Sub CopyToClipboard()


Declare Destructor

protected:

Declare Sub fOptimizeSwitch()

private:

Declare Function pSolveItBinarySearchTreeFindNode(ByVal Index As Long, ByVal Count As Long=0) As Long
Declare Sub pSolveItCalcMovedArea(d() As Byte, ByVal xo As Long, ByVal yo As Long, ByVal x As Long, ByVal y As Long, ByVal FS As Long)
Declare Function pSolveItCalcNext( SwitchTransTable() As Long , ByVal m As Long, ByVal k As Long, ByVal State As Long, ByVal FS As Long,byval ret As LPtypeNextPos) As Long
Declare Function pSolveItCalcNextSingle( SwitchTransTable() As Long , ByVal m As Long, ByVal k As Long, ByVal k2 As Long, ByVal FS As Long,byval ret As LPtypeNextPos) As Long
Declare Sub pSolveItCalcPos(ByVal n As Long)
Declare Function pSolveItCheckNodeState(ByVal m As Long, ByVal k As Long, ByVal State As Long, ByVal k2 As Long=0) As Long
Declare Function pSolveItPosToInt(ByVal p1 As Long, ByVal p2 As Long) As Long
Declare Sub pSolveItResizeNodeArray()

_xx_dat As UByte ptr
'0=empty        =space
'1=block        =b
'2=soft         =s
'3=heavy        =h
'4=transport    =v
'5=thin         =f
'6=bridge off   =lr
'7=bridge on    =kq
'8=end          =e
'======new!!!======
'9=ice
'10=pyramid
'11=stone

_xx_dat2 As Long ptr

sws As LPtypeSwitch
swc As Long

datw As Long
dath As Long '<=255 :-/

_xx_SwitchMap As UByte ptr
_xx_SwitchMapPosId As Long ptr

SwitchMapIdPos As LPtypeSolveItSwitchIdPos
SwitchStatusCount As Long
IsTrans As Boolean
GTheoryNode As LPtypeSolveItNode
GTheoryNodeMax As Long
GTheoryNodeUsed As Long
SolveItTime As Long
#If SolveItRecordMovedArea
_xx_SolveItMovedArea As UByte ptr
#EndIf

end type
