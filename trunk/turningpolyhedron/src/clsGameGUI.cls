VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsGameGUI"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Implements IFakeDXAppEvent
Implements IRenderableObject

Private Function IFakeDXAppEvent_OnEvent(ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
Dim v1 As D3DVECTOR, v2 As D3DVECTOR, v3 As D3DVECTOR
Dim f As Single
Dim i As Long
Dim Button As Long
'///
Static nOldX As Long, nOldY As Long
Static vx As D3DVECTOR, vy As D3DVECTOR
'///TEST ONLY
Select Case nType
Case FakeDXAppEvent_KeyDown
 i = -1
 Select Case nParam1
 Case vbKeyUp
  i = 0
 Case vbKeyLeft
  i = 1
 Case vbKeyDown
  i = 2
 Case vbKeyRight
  i = 3
 Case vbKeySpace
  'TODO:when a polyhedron is falling then can't change polyhedron index
  'TODO:skip invalid polyhedron
  i = objGameMgr.CurrentPolyhedron + 1
  If i > objGameMgr.PolyhedronCount Then i = 1
  objGameMgr.CurrentPolyhedron = i
  objGameMgr.FollowCurrentPolyhedron = True
  Exit Function
 Case vbKeyR
  objGameMgr.ResetOnNextUpdate = True
  Exit Function
 End Select
 If i >= 0 Then
  If Not objGameMgr.CurrentPolyhedronObject Is Nothing Then
   '///TODO:get z direction
   objCamera.GetRealCamera v1, v2, v3
   v1.x = v1.x - v2.x
   v1.y = v1.y - v2.y
   v2.x = v1.x - v1.y
   v2.y = v1.x + v1.y
   If v2.x > 0 Then
    If v2.y > 0 Then i = i + 1 _
    Else i = i + 2
   Else
    If v2.y < 0 Then i = i - 1
   End If
   i = i And 3&
   '///
   If objGameMgr.CanPlayerMovePolyhedron Then
    If objGameMgr.MoveCurrentPolyhedron(i) Then
     objGameMgr.FollowCurrentPolyhedron = True
    End If
   End If
  End If
 End If
Case FakeDXAppEvent_MouseDown
 Button = nParam3 And &HFFFF&
 Select Case Button
 Case 1 'rotate
  objCamera.LockCamera = False
  objCamera.BeginDrag nParam1, nParam2
 Case 2 'drag
  nOldX = nParam1
  nOldY = nParam2
  '///TODO:
  objCamera.GetRealCamera v1, v2, v3
  D3DXVec3Normalize v3, v3
  v1.x = v1.x - v2.x
  v1.y = v1.y - v2.y
  v1.z = v1.z - v2.z
  objRenderTest.GetProjection_PerspectiveFovLH f, 0, 0, 0
  f = Tan(f / 2) * 2 / d3dpp.BackBufferHeight
  '---
  v2.x = D3DXVec3LengthSq(v1)
  v2.y = -D3DXVec3Dot(v1, v3)
  vy = Vec3
  If v2.y > 0.000001! Or v2.y < -0.000001! Then
   v2.z = v2.x / v2.y * f
   If v2.z < 1000! And v2.z > -1000! Then
    D3DXVec3Normalize vy, D3DXVec3AddScale(v1, v3, v2.y)
    vy.x = vy.x * v2.z
    vy.y = vy.y * v2.z
    vy.z = vy.z * v2.z
   End If
  End If
  '---
  f = f * Sqr(v2.x)
  v2 = D3DXVec3Cross(v3, v1)
  D3DXVec3Normalize v2, v2
  vx.x = v2.x * f
  vx.y = v2.y * f
  vx.z = v2.z * f
  '///
 End Select
Case FakeDXAppEvent_MouseMove
 Button = nParam3 And &HFFFF&
 Select Case Button
 Case 1
  objCamera.Drag nParam1, nParam2, 0.01
 Case 2
  objGameMgr.FollowCurrentPolyhedron = False
  objCamera.Move vx.x * (nParam1 - nOldX) + vy.x * (nParam2 - nOldY), _
  vx.y * (nParam1 - nOldX) + vy.y * (nParam2 - nOldY), _
  vx.z * (nParam1 - nOldX) + vy.z * (nParam2 - nOldY)
  nOldX = nParam1
  nOldY = nParam2
 End Select
Case FakeDXAppEvent_MouseWheel
 If nParam1 > 0 Then
  objCamera.Zoom 0.8
 Else
  objCamera.Zoom 1.25
 End If
End Select
End Function

Private Sub IRenderableObject_Render(ByVal nType As enumRenderPassType, ByVal objRender As clsRenderPipeline, ByVal objCamera As clsCamera, ByVal IsEffectBegin As Boolean, ByVal IsSceneBegin As Boolean)
Select Case nType
Case RenderPass_Main
 If Not IsEffectBegin Then
  objRenderTest.SetTexture objTexture
  objRenderTest.SetNormalTexture objNormalTexture
  If Not objRender.BeginRender(nType, False) Then Exit Sub
 End If
 '---
 objGameMgr.UpdateLevelRuntimeData objTiming.GetDelta
 '---
 If Not IsSceneBegin Then d3dd9.BeginScene
 objRenderTest.EndEffect
 '///draw level
 objGameMgr.DrawLevel
 '////////draw landscape test (new and buggy) without advanced shading effects
 d3dd9.SetTexture 0, objLandTexture
 objLand.Render objRender, objCamera
 '////////
 '///
 If Not IsSceneBegin Then d3dd9.EndScene
 If Not IsEffectBegin Then objRender.EndRender
Case RenderPass_FogVolume
 'TODO:
Case RenderPass_Overlay
 'TODO:
End Select
End Sub
