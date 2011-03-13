#pragma once

Type _class_Clipboard
Declare Sub Clear()
Declare Function GetText() As String
Declare Sub SetText(ByRef s As String)
_dummy_ as long
End Type

Extern Clipboard Alias "Clipboard" as _class_Clipboard
