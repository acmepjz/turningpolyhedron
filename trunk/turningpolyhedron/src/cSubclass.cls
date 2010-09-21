VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "cSubclass"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'////////////////////////////////
'This file is public domain.
'////////////////////////////////

'--------------------------------------------------------------------------------------------------
'cSubclass - module-less, IDE safe, machine code window subclasser
'
'v1.00 20030107 First cut..........................................................................
'

Option Explicit

Private Declare Function CallWindowProc Lib "user32.dll" Alias "CallWindowProcA" (ByVal lpPrevWndFunc As Long, ByVal hwnd As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Private Declare Function IsWindow Lib "user32.dll" (ByVal hwnd As Long) As Long
Private Declare Function SetWindowLong Lib "user32.dll" Alias "SetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long
Private Const GWL_WNDPROC As Long = -4
Private Declare Function GetModuleHandle Lib "kernel32.dll" Alias "GetModuleHandleA" (ByVal lpModuleName As String) As Long
Private Declare Function GetProcAddress Lib "kernel32.dll" (ByVal hModule As Long, ByVal lpProcName As String) As Long
Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

Private Const OFFSET_P1   As Long = 9                     'Callback gate address
Private Const OFFSET_P2   As Long = 22                    'Before table entry count
Private Const OFFSET_P3   As Long = 37                    'Before table address
Private Const OFFSET_P4   As Long = 51                    'In IDE ?
Private Const OFFSET_P5   As Long = 69                    'Owner object address for iSubclass_Before
Private Const OFFSET_P6   As Long = 141                   'Original WndProc address
Private Const OFFSET_P7   As Long = 146                   'CallWindowProc address
Private Const OFFSET_P8   As Long = 154                   'After table entry count
Private Const OFFSET_P9   As Long = 169                   'After table address
Private Const OFFSET_PA   As Long = 183                   'In IDE?
Private Const OFFSET_PB   As Long = 201                   'Owner object address for iSubclass_After
Private Const OFFSET_PC   As Long = 250                   'Original WndProc address
Private Const OFFSET_PD   As Long = 260                   'SetWindowLong address
Private Const ARRAY_LB    As Long = 1                     'Low bound of arrays

Private Type tCode
  buf(ARRAY_LB To 272)    As Byte                         'Code buffer
End Type

Private Type tCodeBuf
  code                    As tCode                        'Subclass WndProc code
End Type

Private CodeBuf           As tCodeBuf                     'Subclass WndProc code instance
Private nBreakGate        As Long                         'Callback breakpoint gate
Private nMsgCntB          As Long                         'Before msg table entry count
Private nMsgCntA          As Long                         'After msg table entry count
Private aMsgTblB()        As Long                         'Before msg table array
Private aMsgTblA()        As Long                         'After msg table array
Private hWndSubclass      As Long                         'Handle of the window being subclassed
Private nWndProcSubclass  As Long                         'The address of our WndProc
Private nWndProcOriginal  As Long                         'The address of the existing WndProc

Public Enum eMsgWhen
        MSG_AFTER = 0
        MSG_BEFORE = 1
End Enum


'-----------------------------
'Class creation/destruction

'Called automatically when the class instance is created.
Private Sub Class_Initialize()
Const OPS As String = "558BEC83C4F85756BE_patch1_33C08945FC8945F8B90000000083F900746183F9FF740CBF000000008B450CF2AF755033C03D_patch4_740B833E007542C70601000000BA_patch5_8B0283F8000F84A50000008D4514508D4510508D450C508D4508508D45FC508D45F8508B0252FF5020C706000000008B45F883F8007570FF7514FF7510FF750CFF750868_patch6_E8_patch7_8945FCB90000000083F900744D83F9FF740CBF000000008B450CF2AF753C33C03D_patchA_740B833E00752EC70601000000BA_patchB_8B0283F8007425FF7514FF7510FF750CFF75088D45FC508B0252FF501CC706000000005E5F8B45FCC9C2100068_patchC_6AFCFF7508E8_patchD_33C08945FCEBE190"
Dim i     As Long, _
    j     As Long, _
    nIDE  As Long

'Convert the string from hexadecimal pairs to bytes and store in the opcode buffer
  With CodeBuf.code
    j = 1                                                 'Set the character index to the start of the opcode string
    For i = ARRAY_LB To UBound(.buf)                      'For each byte of the code buffer
      .buf(i) = Val("&H" & Mid$(OPS, j, 2))               'Pull a pair of hex characters and convert to a byte
      j = j + 2                                           'Bump to the next pair of characters
    Next i                                                'Next byte of the code buffer
    nWndProcSubclass = VarPtr(.buf(ARRAY_LB))             'Address of the cSubclass WndProc entry point
  End With
  nIDE = InIDE                                            'Determine whether we're running in the IDE or not

'Patch the WndProc code with runtime values
  Call PatchVal(OFFSET_P1, VarPtr(nBreakGate))            'Breakpoint gate address
  Call PatchVal(OFFSET_P4, nIDE)                          'Wether we need check the breakpoint gate and the vtable
  Call PatchRel(OFFSET_P7, AddrFunc("CallWindowProcA"))   'Address of the CallWindowProc api function
  Call PatchVal(OFFSET_PA, nIDE)                          'Whether we need check the breakpoint gate and the vtable
  Call PatchRel(OFFSET_PD, AddrFunc("SetWindowLongA"))    'Address of the SetWindowLong api function
End Sub

'Called automatically when the class instance is destroyed.
Private Sub Class_Terminate()
  If hWndSubclass <> 0 Then                               'If the Subclass thunk is active
    Call UnSubclass                                       'UnSubclass
  End If
End Sub

'-----------------------------
'Public interface

'Call this method to add a message to the msg callback table. NB This method can be called at any time
Public Sub AddMsg(uMsg As Long, When As eMsgWhen)
  If When = MSG_BEFORE Then                    'If before
    Call AddMsgSub(uMsg, aMsgTblB, nMsgCntB, When)        'Add the message, pass the before table and before table message count variables
  Else                                                    'Else after
    Call AddMsgSub(uMsg, aMsgTblA, nMsgCntA, When)        'Add the message, pass the after table and after table message count variables
  End If
End Sub

'Allow the user to arbitarily call the original WndProc
Public Function CallOrigWndProc(ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
  If hWndSubclass <> 0 Then
    CallOrigWndProc = CallWindowProc( _
    nWndProcOriginal, hWndSubclass, uMsg, wParam, lParam) 'Call the original WndProc
  Else
    Debug.Assert False                                    'LOGIC ERROR: The subclasser isn't active!
  End If
End Function

'Call this method to delete a message from the msg table. NB This method can be called at any time
Public Sub DelMsg(uMsg As Long, When As eMsgWhen)
  If When = MSG_BEFORE Then                    'If before
    Call DelMsgSub(uMsg, aMsgTblB, nMsgCntB, When)        'Delete the message, pass the before table and before message count variables
  Else                                                    'Else after
    Call DelMsgSub(uMsg, aMsgTblA, nMsgCntA, When)        'Delete the message, pass the after table and after message count variables
  End If
End Sub

'Call this method to subclass the passed window handle
Public Sub Subclass(hwnd As Long, Owner As iSubclass)
  Debug.Assert (hWndSubclass = 0)                         'LOGIC ERROR: The subclasser is already active!
  Debug.Assert hwnd                                       'LOGIC ERROR: Invalid window handle
  Debug.Assert IsWindow(hwnd)                             'LOGIC ERROR: Invalid window handle
  
  hWndSubclass = hwnd                                     'Store the window handle
  nWndProcOriginal = SetWindowLong( _
                                  hwnd, _
                                  GWL_WNDPROC, _
                                  nWndProcSubclass)       'Set our WndProc in place of the original
  Debug.Assert nWndProcOriginal                           '??? You can't subclass a window outside of the current process
  
  Call PatchVal(OFFSET_P5, ObjPtr(Owner))                 'Owner object address for iSubclass_Before
  Call PatchVal(OFFSET_P6, nWndProcOriginal)              'Original WndProc address for CallWindowProc
  Call PatchVal(OFFSET_PB, ObjPtr(Owner))                 'Owner object address for iSubclass_After
  Call PatchVal(OFFSET_PC, nWndProcOriginal)              'Original WndProc address for SetWindowLong
End Sub

'Call this method to stop subclassing the window
Public Sub UnSubclass()
  If hWndSubclass <> 0 Then
    Call PatchVal(OFFSET_P2, 0)                           'Patch the code to ensure no further iSubclass_Before callbacks
    Call PatchVal(OFFSET_P8, 0)                           'Patch the code to ensure no further iSubclass_After callbacks
    Call SetWindowLong(hWndSubclass, _
                                  GWL_WNDPROC, _
                                  nWndProcOriginal)       'Restore the original WndProc
    hWndSubclass = 0                                      'Indicate the subclasser is inactive
    nMsgCntB = 0                                          'Message before count equals zero
    nMsgCntA = 0                                          'Message after count equals zero
  End If
End Sub

'-----------------------------
' Private subroutines

'Worker sub for AddMsg
Private Sub AddMsgSub(uMsg As Long, aMsgTbl() As Long, nMsgCnt As Long, When As eMsgWhen)
Dim nEntry  As Long, _
    nOff1   As Long, _
    nOff2   As Long
  
  If uMsg = -1 Then                  'If ALL_MESSAGES
    nMsgCnt = -1                                          'Indicates that all messages are to callback
  Else                                                    'Else a specific message number
    For nEntry = ARRAY_LB To nMsgCnt                      'For each existing entry. NB will skip if nMsgCnt = 0
      Select Case aMsgTbl(nEntry)                         'Select on the message number stored in this table entry
      Case -1                                             'This msg table slot is a deleted entry
        aMsgTbl(nEntry) = uMsg                            'Re-use this entry
        Exit Sub                                          'Bail
      Case uMsg                                           'The msg is already in the table!
        Exit Sub                                          'Bail
      End Select
    Next nEntry                                           'Next entry

'Make space for the new entry
    ReDim Preserve aMsgTbl(ARRAY_LB To nEntry)            'Increase the size of the table. NB nEntry = nMsgCnt + 1
    nMsgCnt = nEntry                                      'Bump the entry count
    aMsgTbl(nEntry) = uMsg                                'Store the message number in the table
  End If
  
  If When = MSG_BEFORE Then                    'If before
    nOff1 = OFFSET_P2                                     'Patch the Before table entry count
    nOff2 = OFFSET_P3                                     'Patch the Before table address
  Else                                                    'Else after
    nOff1 = OFFSET_P8                                     'Patch the After table entry count
    nOff2 = OFFSET_P9                                     'Patch the After table address
  End If

'Patch the appropriate table entries
  Call PatchVal(nOff1, nMsgCnt)                           'Patch the appropriate table entry count
  Call PatchVal(nOff2, AddrMsgTbl(aMsgTbl))               'Patch the appropriate table address. We need do this because there's no guarantee that the table existed at SubClass time, the table only gets created if a specific message number is added.
End Sub

'Worker sub for DelMsg
Private Sub DelMsgSub(uMsg As Long, aMsgTbl() As Long, nMsgCnt As Long, When As eMsgWhen)
Dim nEntry As Long
  
  If uMsg = -1 Then                  'If deleting all messages (specific or ALL_MESSAGES)
    nMsgCnt = 0                                           'Message count is now zero
    If When = MSG_BEFORE Then                  'If before
      nEntry = OFFSET_P2                                  'Patch the before table message count location
    Else                                                  'Else after
      nEntry = OFFSET_P8                                  'Patch the after table message count location
    End If
    Call PatchVal(nEntry, 0)                              'Patch the after table message count
  Else                                                    'Else deleteting a specific message
    For nEntry = ARRAY_LB To nMsgCnt                      'For each table entry
      If aMsgTbl(nEntry) = uMsg Then                      'If this entry is the message we wish to delete
        aMsgTbl(nEntry) = -1                              'Mark the table slot as available
        Exit For                                          'Bail
      End If
    Next nEntry                                           'Next entry
  End If
End Sub

'Return the address of the passed user32.dll api function
Private Function AddrFunc(sProc As String) As Long
  AddrFunc = GetProcAddress(GetModuleHandle("user32"), sProc)
End Function

'Return the address of the low bound of the passed table array
Private Function AddrMsgTbl(aMsgTbl() As Long) As Long
  On Error Resume Next                                    'The table may not be dimensioned yet so we need protection
    AddrMsgTbl = VarPtr(aMsgTbl(ARRAY_LB))                'Get the address of the first element of the passed message table
  On Error GoTo 0                                         'Switch off error protection
End Function

'Patch the code offset with the passed value
Private Sub PatchVal(nOffset As Long, nValue As Long)
  Call CopyMemory(ByVal (nWndProcSubclass + nOffset), nValue, 4)
End Sub

'Patch the code offset with the relative address to the target address
Private Sub PatchRel(nOffset As Long, nTargetAddr As Long)
  Call CopyMemory(ByVal (nWndProcSubclass + nOffset), nTargetAddr - nWndProcSubclass - nOffset - 4, 4)
End Sub

'Return -1 if we're running in the IDE or 0 if were running compiled.
Private Function InIDE() As Long
Static Value As Long
  
  If Value = 0 Then
    Value = 1
    Debug.Assert True Or InIDE()                          'This line won't exist in the compiled app
    InIDE = Value - 1
  End If
  
  Value = 0
End Function
