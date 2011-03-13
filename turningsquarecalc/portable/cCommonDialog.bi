#pragma once

type cCommonDialog
Declare Function VBGetOpenFileName(FileName As String, _
                           FileTitle As String = "", _
                           FileMustExist As Short = -1, _
                           MultiSelect As Short = 0, _
                           ReadOnly As Short = 0, _
                           HideReadOnly As Short = -1, _
                           filter As String = "All (*.*)| *.*", _
                           FilterIndex As Long = 1, _
                           InitDir As String = "", _
                           DlgTitle As String = "", _
                           DefaultExt As String = "", _
                           Owner As Long = -1, _
                           Flags As Long = 0) As Short
Declare Function VBGetSaveFileName(FileName As String, _
                           FileTitle As String = "", _
                           OverWritePrompt As Short = -1, _
                           Filter As String = "All (*.*)| *.*", _
                           FilterIndex As Long = 1, _
                           InitDir As String = "", _
                           DlgTitle As String = "", _
                           DefaultExt As String = "", _
                           Owner As Long = -1, _
                           Flags As Long = 0) As Short
_dummy_ as long
end type
