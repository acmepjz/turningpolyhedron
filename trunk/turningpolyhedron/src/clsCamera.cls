VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsCamera"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private m_tViewPos As D3DVECTOR
Private m_tViewAt As D3DVECTOR
Private m_tViewUp As D3DVECTOR

Private m_fDist As Single, m_fAngle As Single

Private m_bLockCamera As Boolean

Private nOldX As Long, nOldY As Long

Friend Sub Move(ByVal dx As Single, ByVal dy As Single, ByVal dz As Single)
m_tViewPos.x = m_tViewPos.x + dx
m_tViewPos.y = m_tViewPos.y + dy
m_tViewPos.z = m_tViewPos.z + dz
m_tViewAt.x = m_tViewAt.x + dx
m_tViewAt.y = m_tViewAt.y + dy
m_tViewAt.z = m_tViewAt.z + dz
End Sub

Friend Sub MoveByLocalCoordinatesLH(ByVal dx As Single, ByVal dy As Single, ByVal dz As Single)
Dim xx As D3DVECTOR, yy As D3DVECTOR, zz As D3DVECTOR
Dim x1 As Single, y1 As Single, z1 As Single
'///
zz.x = m_tViewAt.x - m_tViewPos.x
zz.y = m_tViewAt.y - m_tViewPos.y
zz.z = m_tViewAt.z - m_tViewPos.z
D3DXVec3Normalize zz, zz
D3DXVec3Normalize xx, D3DXVec3Cross(m_tViewUp, zz)
yy = D3DXVec3Cross(zz, xx)
'///
x1 = dx * xx.x + dy * yy.x + dz * zz.x
y1 = dx * xx.y + dy * yy.y + dz * zz.y
z1 = dx * xx.z + dy * yy.z + dz * zz.z
'///
m_tViewPos.x = m_tViewPos.x + x1
m_tViewPos.y = m_tViewPos.y + y1
m_tViewPos.z = m_tViewPos.z + z1
m_tViewAt.x = m_tViewAt.x + x1
m_tViewAt.y = m_tViewAt.y + y1
m_tViewAt.z = m_tViewAt.z + z1
End Sub

Friend Property Get Distance() As Single
Distance = m_fDist
End Property

Friend Property Let Distance(ByVal f As Single)
On Error Resume Next
Dim t As D3DVECTOR
Dim f1 As Single
t.x = m_tViewPos.x - m_tViewAt.x
t.y = m_tViewPos.y - m_tViewAt.y
t.z = m_tViewPos.z - m_tViewAt.z
f1 = f / m_fDist 'D3DXVec3Length(t)
If f < 0 Then
 m_fDist = -f
 m_fAngle = 3.141593! - m_fAngle
Else
 m_fDist = f
End If
If m_bLockCamera Then
 m_tViewAt.x = m_tViewPos.x - t.x * f1
 m_tViewAt.y = m_tViewPos.y - t.y * f1
 m_tViewAt.z = m_tViewPos.z - t.z * f1
Else
 m_tViewPos.x = m_tViewAt.x + t.x * f1
 m_tViewPos.y = m_tViewAt.y + t.y * f1
 m_tViewPos.z = m_tViewAt.z + t.z * f1
End If
End Property

Friend Sub Zoom(ByVal nAmount As Single)
On Error Resume Next
Dim t As D3DVECTOR
t.x = m_tViewPos.x - m_tViewAt.x
t.y = m_tViewPos.y - m_tViewAt.y
t.z = m_tViewPos.z - m_tViewAt.z
If nAmount < 0 Then
 m_fDist = -m_fDist * nAmount
 m_fAngle = 3.141593! - m_fAngle
Else
 m_fDist = m_fDist * nAmount
End If
If m_bLockCamera Then
 m_tViewAt.x = m_tViewPos.x - t.x * nAmount
 m_tViewAt.y = m_tViewPos.y - t.y * nAmount
 m_tViewAt.z = m_tViewPos.z - t.z * nAmount
Else
 m_tViewPos.x = m_tViewAt.x + t.x * nAmount
 m_tViewPos.y = m_tViewAt.y + t.y * nAmount
 m_tViewPos.z = m_tViewAt.z + t.z * nAmount
End If
End Sub

Friend Property Get LockCamera() As Boolean
LockCamera = m_bLockCamera
End Property

Friend Property Let LockCamera(ByVal b As Boolean)
m_bLockCamera = b
End Property

Friend Property Get CameraPosition() As D3DVECTOR
CameraPosition = m_tViewPos
End Property

Friend Property Let CameraPosition(ByRef v As D3DVECTOR)
m_tViewPos = v
pCalcAngle
End Property

Friend Property Get ViewTarget() As D3DVECTOR
ViewTarget = m_tViewAt
End Property

Friend Property Let ViewTarget(ByRef v As D3DVECTOR)
m_tViewAt = v
pCalcAngle
End Property

Friend Property Get ViewUp() As D3DVECTOR
ViewUp = m_tViewUp
End Property

Friend Property Let ViewUp(ByRef v As D3DVECTOR)
m_tViewUp = v
pCalcAngle
End Property

Private Sub pCalcAngle()
On Error Resume Next
Dim t As D3DVECTOR
Dim f As Single
t.x = m_tViewPos.x - m_tViewAt.x
t.y = m_tViewPos.y - m_tViewAt.y
t.z = m_tViewPos.z - m_tViewAt.z
m_fDist = D3DXVec3Length(t)
f = D3DXVec3Dot(t, m_tViewUp) / (m_fDist * D3DXVec3Length(m_tViewUp)) 'cos
m_fAngle = Atn((1 - f) / Sqr(1 - f * f)) * 2
End Sub

Friend Sub SetCamrea(pEye As D3DVECTOR, pAt As D3DVECTOR, pUp As D3DVECTOR)
m_tViewPos = pEye
m_tViewAt = pAt
m_tViewUp = pUp
pCalcAngle
End Sub

Friend Sub Rotate(ByVal dx As Single, ByVal dy As Single)
On Error Resume Next
Dim mat As D3DMATRIX
Dim t As D3DVECTOR
Dim f As Single
t.x = m_tViewPos.x - m_tViewAt.x
t.y = m_tViewPos.y - m_tViewAt.y
t.z = m_tViewPos.z - m_tViewAt.z
f = m_fAngle + dy
If f < 0.0016 Then f = 0.0016 Else If f > 3.14 Then f = 3.14
dy = f - m_fAngle
m_fAngle = f
D3DXMatrixRotationAxis mat, D3DXVec3Cross(t, m_tViewUp), -dy
D3DXVec3TransformCoord t, t, mat
D3DXMatrixRotationAxis mat, m_tViewUp, dx
D3DXVec3TransformCoord t, t, mat
If m_bLockCamera Then
 m_tViewAt.x = m_tViewPos.x - t.x
 m_tViewAt.y = m_tViewPos.y - t.y
 m_tViewAt.z = m_tViewPos.z - t.z
Else
 m_tViewPos.x = m_tViewAt.x + t.x
 m_tViewPos.y = m_tViewAt.y + t.y
 m_tViewPos.z = m_tViewAt.z + t.z
End If
End Sub

Friend Sub BeginDrag(ByVal x As Long, ByVal y As Long)
nOldX = x
nOldY = y
End Sub

Friend Sub Drag(ByVal x As Long, ByVal y As Long, ByVal nAmount As Single)
Rotate (x - nOldX) * nAmount, (nOldY - y) * nAmount
nOldX = x
nOldY = y
End Sub

Friend Sub Apply(ByVal objRender As clsRenderPipeline)
Dim mat As D3DMATRIX
D3DXMatrixLookAtLH mat, m_tViewPos, m_tViewAt, m_tViewUp
d3dd9.SetTransform D3DTS_VIEW, mat
objRender.SetViewPosition Vec4(m_tViewPos.x, m_tViewPos.y, m_tViewPos.z, 0)
End Sub
