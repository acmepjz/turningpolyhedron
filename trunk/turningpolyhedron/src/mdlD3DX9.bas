Attribute VB_Name = "mdlD3DX9"
'//////////////////////////////////////////
'
' some D3D9 and D3DX9 ***STUPID*** macros
' --- test only ---
'
'//////////////////////////////////////////

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

Option Explicit

Public Function MAKEFOURCC(ByVal ch0 As Byte, ByVal ch1 As Byte, ByVal ch2 As Byte, ByVal ch3 As Byte) As Long
If ch3 < &H80& Then
 MAKEFOURCC = ch0 Or (ch1 * &H100&) Or (ch2 * &H10000) Or (ch3 * &H1000000)
Else
 MAKEFOURCC = &H80000000 Or ch0 Or (ch1 * &H100&) Or (ch2 * &H10000) Or ((ch3 Xor &H80&) * &H1000000)
End If
End Function

Public Function MAKEFOURCC_STR(ch0 As String, ch1 As String, ch2 As String, ch3 As String) As Long
MAKEFOURCC_STR = MAKEFOURCC(AscB(ch0), AscB(ch1), AscB(ch2), AscB(ch3))
End Function

Public Function D3DCOLOR_ARGB(ByVal a As Byte, ByVal r As Byte, ByVal g As Byte, ByVal b As Byte) As Long
D3DCOLOR_ARGB = MAKEFOURCC(b, g, r, a)
End Function

'#define D3DCOLOR_COLORVALUE(r,g,b,a) D3DCOLOR_RGBA(cuint((r)*255),cuint((g)*255),cuint((b)*255),cuint((a)*255))
'#define D3DCOLOR_RGBA(r,g,b,a) D3DCOLOR_ARGB(a,r,g,b)

Public Function D3DCOLOR_XRGB(ByVal r As Byte, ByVal g As Byte, ByVal b As Byte) As Long
D3DCOLOR_XRGB = &HFF000000 Or b Or (g * &H100&) Or (r * &H10000)
End Function

'#define D3DCOLOR_XYUV(y,u,v) D3DCOLOR_ARGB(0xff,y,u,v)
'#define D3DCOLOR_AYUV(a,y,u,v) D3DCOLOR_ARGB(a,y,u,v)

'#define D3DPS_VERSION(major,minor) (0xffff0000 or ((major) << 8) or (minor))
'#define D3DVS_VERSION(major,minor) (0xfffe0000 or ((major) << 8) or (minor))
'#define D3DSHADER_VERSION_MAJOR(version) (((version) shr 8) & 0xff)
'#define D3DSHADER_VERSION_MINOR(version) (((version) shr 0) & 0xff)
'#define D3DSHADER_COMMENT(s) ((((s) << D3DSI_COMMENTSIZE_SHIFT) & D3DSI_COMMENTSIZE_MASK) or D3DSIO_COMMENT)
'#define D3DPS_END() 0xffff
'#define D3DVS_END() 0xffff

Public Function D3DDECL_END() As D3DVERTEXELEMENT9
D3DDECL_END.Stream = &HFF&
D3DDECL_END.Type = D3DDECLTYPE_UNUSED
End Function

'//===========================================================================
'//
'// Custom functions
'//
'//===========================================================================

Public Function Vec2(Optional ByVal x As Single, Optional ByVal y As Single) As D3DXVECTOR2
With Vec2
 .x = x
 .y = y
End With
End Function

Public Function Vec3(Optional ByVal x As Single, Optional ByVal y As Single, Optional ByVal z As Single) As D3DVECTOR
With Vec3
 .x = x
 .y = y
 .z = z
End With
End Function

Public Function Vec4(Optional ByVal x As Single, Optional ByVal y As Single, Optional ByVal z As Single, Optional ByVal w As Single) As D3DXVECTOR4
With Vec4
 .x = x
 .y = y
 .z = z
 .w = w
End With
End Function

Public Function D3DVertexElementCreate(Optional ByVal nStream As Long, Optional ByVal nOffset As Long, _
Optional ByVal nType As D3DDECLTYPE, Optional ByVal nMethod As D3DDECLMETHOD, _
Optional ByVal nUsage As D3DDECLUSAGE, Optional ByVal nUsageIndex As Long) As D3DVERTEXELEMENT9
With D3DVertexElementCreate
 .Stream = nStream
 .Offset = nOffset
 .Type = nType
 .Method = nMethod
 .Usage = nUsage
 .UsageIndex = nUsageIndex
End With
End Function

Public Function SingleToLong(ByVal n As Single) As Long
Dim i As Long
CopyMemory i, n, 4&
SingleToLong = i
End Function

Public Function LongToSingle(ByVal n As Long) As Single
Dim i As Single
CopyMemory i, n, 4&
LongToSingle = i
End Function

'//===========================================================================
'//
'// Inline functions
'//
'//===========================================================================

'//--------------------------
'// 2D Vector
'//--------------------------

Public Function D3DXVec2Length(pV As D3DXVECTOR2) As Single
D3DXVec2Length = Sqr(pV.x * pV.x + pV.y * pV.y)
End Function

Public Function D3DXVec2LengthSq(pV As D3DXVECTOR2) As Single
D3DXVec2LengthSq = pV.x * pV.x + pV.y * pV.y
End Function

Public Function D3DXVec2Dot(pV1 As D3DXVECTOR2, pV2 As D3DXVECTOR2) As Single
D3DXVec2Dot = pV1.x * pV2.x + pV1.y * pV2.y
End Function

Public Function D3DXVec2CCW(pV1 As D3DXVECTOR2, pV2 As D3DXVECTOR2) As Single
D3DXVec2CCW = pV1.x * pV2.y - pV1.y * pV2.x
End Function

Public Function D3DXVec2Add(pV1 As D3DXVECTOR2, pV2 As D3DXVECTOR2) As D3DXVECTOR2
With D3DXVec2Add
 .x = pV1.x + pV2.x
 .y = pV1.y + pV2.y
End With
End Function

Public Function D3DXVec2Subtract(pV1 As D3DXVECTOR2, pV2 As D3DXVECTOR2) As D3DXVECTOR2
With D3DXVec2Subtract
 .x = pV1.x - pV2.x
 .y = pV1.y - pV2.y
End With
End Function

Public Function D3DXVec2Minimize(pV1 As D3DXVECTOR2, pV2 As D3DXVECTOR2) As D3DXVECTOR2
With D3DXVec2Minimize
 If pV1.x < pV2.x Then .x = pV1.x Else .x = pV2.x
 If pV1.y < pV2.y Then .y = pV1.y Else .y = pV2.y
End With
End Function

Public Function D3DXVec2Maximize(pV1 As D3DXVECTOR2, pV2 As D3DXVECTOR2) As D3DXVECTOR2
With D3DXVec2Maximize
 If pV1.x > pV2.x Then .x = pV1.x Else .x = pV2.x
 If pV1.y > pV2.y Then .y = pV1.y Else .y = pV2.y
End With
End Function

Public Function D3DXVec2Scale(pV As D3DXVECTOR2, ByVal s As Single) As D3DXVECTOR2
With D3DXVec2Scale
 .x = pV.x * s
 .y = pV.y * s
End With
End Function

Public Function D3DXVec2Lerp(pV1 As D3DXVECTOR2, pV2 As D3DXVECTOR2, ByVal s As Single) As D3DXVECTOR2
With D3DXVec2Lerp
 .x = pV1.x + s * (pV2.x - pV1.x)
 .y = pV1.y + s * (pV2.y - pV1.y)
End With
End Function

'//--------------------------
'// 3D Vector
'//--------------------------

Public Function D3DXVec3Length(pV As D3DVECTOR) As Single
D3DXVec3Length = Sqr(pV.x * pV.x + pV.y * pV.y + pV.z * pV.z)
End Function

Public Function D3DXVec3LengthSq(pV As D3DVECTOR) As Single
D3DXVec3LengthSq = pV.x * pV.x + pV.y * pV.y + pV.z * pV.z
End Function

Public Function D3DXVec3Dot(pV1 As D3DVECTOR, pV2 As D3DVECTOR) As Single
D3DXVec3Dot = pV1.x * pV2.x + pV1.y * pV2.y + pV1.z * pV2.z
End Function

Public Function D3DXVec3Cross(pV1 As D3DVECTOR, pV2 As D3DVECTOR) As D3DVECTOR
With D3DXVec3Cross
 .x = pV1.y * pV2.z - pV1.z * pV2.y
 .y = pV1.z * pV2.x - pV1.x * pV2.z
 .z = pV1.x * pV2.y - pV1.y * pV2.x
End With
End Function

Public Function D3DXVec3Add(pV1 As D3DVECTOR, pV2 As D3DVECTOR) As D3DVECTOR
With D3DXVec3Add
 .x = pV1.x + pV2.x
 .y = pV1.y + pV2.y
 .z = pV1.z + pV2.z
End With
End Function

Public Function D3DXVec3Subtract(pV1 As D3DVECTOR, pV2 As D3DVECTOR) As D3DVECTOR
With D3DXVec3Subtract
 .x = pV1.x - pV2.x
 .y = pV1.y - pV2.y
 .z = pV1.z - pV2.z
End With
End Function

Public Function D3DXVec3Minimize(pV1 As D3DVECTOR, pV2 As D3DVECTOR) As D3DVECTOR
With D3DXVec3Minimize
 If pV1.x < pV2.x Then .x = pV1.x Else .x = pV2.x
 If pV1.y < pV2.y Then .y = pV1.y Else .y = pV2.y
 If pV1.z < pV2.z Then .z = pV1.z Else .z = pV2.z
End With
End Function

Public Function D3DXVec3Maximize(pV1 As D3DVECTOR, pV2 As D3DVECTOR) As D3DVECTOR
With D3DXVec3Maximize
 If pV1.x > pV2.x Then .x = pV1.x Else .x = pV2.x
 If pV1.y > pV2.y Then .y = pV1.y Else .y = pV2.y
 If pV1.z > pV2.z Then .z = pV1.z Else .z = pV2.z
End With
End Function

Public Function D3DXVec3Scale(pV As D3DVECTOR, ByVal s As Single) As D3DVECTOR
With D3DXVec3Scale
 .x = pV.x * s
 .y = pV.y * s
 .z = pV.z * s
End With
End Function

Public Function D3DXVec3Lerp(pV1 As D3DVECTOR, pV2 As D3DVECTOR, ByVal s As Single) As D3DVECTOR
With D3DXVec3Lerp
 .x = pV1.x + s * (pV2.x - pV1.x)
 .y = pV1.y + s * (pV2.y - pV1.y)
 .z = pV1.z + s * (pV2.z - pV1.z)
End With
End Function

'//--------------------------
'// 4D Vector
'//--------------------------

Public Function D3DXVec4Length(pV As D3DXVECTOR4) As Single
D3DXVec4Length = Sqr(pV.x * pV.x + pV.y * pV.y + pV.z * pV.z + pV.w * pV.w)
End Function

Public Function D3DXVec4LengthSq(pV As D3DXVECTOR4) As Single
D3DXVec4LengthSq = pV.x * pV.x + pV.y * pV.y + pV.z * pV.z + pV.w * pV.w
End Function

Public Function D3DXVec4Dot(pV1 As D3DXVECTOR4, pV2 As D3DXVECTOR4) As Single
D3DXVec4Dot = pV1.x * pV2.x + pV1.y * pV2.y + pV1.z * pV2.z + pV1.w * pV2.w
End Function

Public Function D3DXVec4Add(pV1 As D3DXVECTOR4, pV2 As D3DXVECTOR4) As D3DXVECTOR4
With D3DXVec4Add
 .x = pV1.x + pV2.x
 .y = pV1.y + pV2.y
 .z = pV1.z + pV2.z
 .w = pV1.w + pV2.w
End With
End Function

Public Function D3DXVec4Subtract(pV1 As D3DXVECTOR4, pV2 As D3DXVECTOR4) As D3DXVECTOR4
With D3DXVec4Subtract
 .x = pV1.x - pV2.x
 .y = pV1.y - pV2.y
 .z = pV1.z - pV2.z
 .w = pV1.w - pV2.w
End With
End Function

Public Function D3DXVec4Add3(pV1 As D3DXVECTOR4, pV2 As D3DXVECTOR4, pV3 As D3DXVECTOR4) As D3DXVECTOR4
With D3DXVec4Add3
 .x = pV1.x + pV2.x + pV3.x
 .y = pV1.y + pV2.y + pV3.y
 .z = pV1.z + pV2.z + pV3.z
 .w = pV1.w + pV2.w + pV3.w
End With
End Function

Public Function D3DXVec4Subtract3(pV1 As D3DXVECTOR4, pV2 As D3DXVECTOR4, pV3 As D3DXVECTOR4) As D3DXVECTOR4
With D3DXVec4Subtract3
 .x = pV1.x - pV2.x - pV3.x
 .y = pV1.y - pV2.y - pV3.y
 .z = pV1.z - pV2.z - pV3.z
 .w = pV1.w - pV2.w - pV3.w
End With
End Function

Public Function D3DXVec4AddSubtract(pV1 As D3DXVECTOR4, pV2 As D3DXVECTOR4, pV3 As D3DXVECTOR4) As D3DXVECTOR4
With D3DXVec4AddSubtract
 .x = pV1.x + pV2.x - pV3.x
 .y = pV1.y + pV2.y - pV3.y
 .z = pV1.z + pV2.z - pV3.z
 .w = pV1.w + pV2.w - pV3.w
End With
End Function

Public Function D3DXVec4Minimize(pV1 As D3DXVECTOR4, pV2 As D3DXVECTOR4) As D3DXVECTOR4
With D3DXVec4Minimize
 If pV1.x < pV2.x Then .x = pV1.x Else .x = pV2.x
 If pV1.y < pV2.y Then .y = pV1.y Else .y = pV2.y
 If pV1.z < pV2.z Then .z = pV1.z Else .z = pV2.z
 If pV1.w < pV2.w Then .w = pV1.w Else .w = pV2.w
End With
End Function

Public Function D3DXVec4Maximize(pV1 As D3DXVECTOR4, pV2 As D3DXVECTOR4) As D3DXVECTOR4
With D3DXVec4Maximize
 If pV1.x > pV2.x Then .x = pV1.x Else .x = pV2.x
 If pV1.y > pV2.y Then .y = pV1.y Else .y = pV2.y
 If pV1.z > pV2.z Then .z = pV1.z Else .z = pV2.z
 If pV1.w > pV2.w Then .w = pV1.w Else .w = pV2.w
End With
End Function

Public Function D3DXVec4Scale(pV As D3DXVECTOR4, ByVal s As Single) As D3DXVECTOR4
With D3DXVec4Scale
 .x = pV.x * s
 .y = pV.y * s
 .z = pV.z * s
 .w = pV.w * s
End With
End Function

Public Function D3DXVec4AddScale(pV1 As D3DXVECTOR4, pV2 As D3DXVECTOR4, ByVal s As Single) As D3DXVECTOR4
With D3DXVec4AddScale
 .x = pV1.x + pV2.x * s
 .y = pV1.y + pV2.y * s
 .z = pV1.z + pV2.z * s
 .w = pV1.w + pV2.w * s
End With
End Function

Public Function D3DXVec4Lerp(pV1 As D3DXVECTOR4, pV2 As D3DXVECTOR4, ByVal s As Single) As D3DXVECTOR4
With D3DXVec4Lerp
 .x = pV1.x + s * (pV2.x - pV1.x)
 .y = pV1.y + s * (pV2.y - pV1.y)
 .z = pV1.z + s * (pV2.z - pV1.z)
 .w = pV1.w + s * (pV2.w - pV1.w)
End With
End Function

'//--------------------------
'// 4D Matrix
'//--------------------------

Public Function D3DXMatrixIdentity() As D3DMATRIX
With D3DXMatrixIdentity
 .m11 = 1
 .m22 = 1
 .m33 = 1
 .m44 = 1
End With
End Function

'//--------------------------
'// Quaternion
'//--------------------------

Public Function D3DXQuaternionIdentity() As D3DXVECTOR4
D3DXQuaternionIdentity.w = 1
End Function

Public Function D3DXQuaternionConjugate(pQ As D3DXVECTOR4) As D3DXVECTOR4
With D3DXQuaternionConjugate
 .x = -pQ.x
 .y = -pQ.y
 .z = -pQ.z
 .w = pQ.w
End With
End Function

'//--------------------------
'// Plane
'//--------------------------

Public Function D3DXPlaneDot(pP As D3DPLANE, pV As D3DXVECTOR4) As Single
D3DXPlaneDot = pP.a * pV.x + pP.b * pV.y + pP.c * pV.z + pP.d * pV.w
End Function

Public Function D3DXPlaneDotCoord(pP As D3DPLANE, pV As D3DXVECTOR4) As Single
D3DXPlaneDotCoord = pP.a * pV.x + pP.b * pV.y + pP.c * pV.z + pP.d
End Function

Public Function D3DXPlaneDotNormal(pP As D3DPLANE, pV As D3DXVECTOR4) As Single
D3DXPlaneDotNormal = pP.a * pV.x + pP.b * pV.y + pP.c * pV.z
End Function

Public Function D3DXPlaneScale(pP As D3DPLANE, ByVal s As Single) As D3DPLANE
With D3DXPlaneScale
 .a = pP.a * s
 .b = pP.b * s
 .c = pP.c * s
 .d = pP.d * s
End With
End Function

'//--------------------------
'// Color
'//--------------------------

Public Function D3DXColorNegative(pC As D3DCOLORVALUE) As D3DCOLORVALUE
With D3DXColorNegative
 .r = 1 - pC.r
 .g = 1 - pC.g
 .b = 1 - pC.b
 .a = pC.a
End With
End Function

Public Function D3DXColorAdd(pC1 As D3DCOLORVALUE, pC2 As D3DCOLORVALUE) As D3DCOLORVALUE
With D3DXColorAdd
 .r = pC1.r + pC2.r
 .g = pC1.g + pC2.g
 .b = pC1.b + pC2.b
 .a = pC1.a + pC2.a
End With
End Function

Public Function D3DXColorSubtract(pC1 As D3DCOLORVALUE, pC2 As D3DCOLORVALUE) As D3DCOLORVALUE
With D3DXColorSubtract
 .r = pC1.r - pC2.r
 .g = pC1.g - pC2.g
 .b = pC1.b - pC2.b
 .a = pC1.a - pC2.a
End With
End Function

Public Function D3DXColorScale(pC As D3DCOLORVALUE, ByVal s As Single) As D3DCOLORVALUE
With D3DXColorScale
 .r = pC.r * s
 .g = pC.g * s
 .b = pC.b * s
 .a = pC.a * s
End With
End Function

Public Function D3DXColorModulate(pC1 As D3DCOLORVALUE, pC2 As D3DCOLORVALUE) As D3DCOLORVALUE
With D3DXColorModulate
 .r = pC1.r * pC2.r
 .g = pC1.g * pC2.g
 .b = pC1.b * pC2.b
 .a = pC1.a * pC2.a
End With
End Function

Public Function D3DXColorLerp(pC1 As D3DCOLORVALUE, pC2 As D3DCOLORVALUE, ByVal s As Single) As D3DCOLORVALUE
With D3DXColorLerp
 .r = pC1.r + s * (pC2.r - pC1.r)
 .g = pC1.g + s * (pC2.g - pC1.g)
 .b = pC1.b + s * (pC2.b - pC1.b)
 .a = pC1.a + s * (pC2.a - pC1.a)
End With
End Function

