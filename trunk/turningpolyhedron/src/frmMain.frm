VERSION 5.00
Begin VB.Form frmMain 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Form1"
   ClientHeight    =   7200
   ClientLeft      =   45
   ClientTop       =   435
   ClientWidth     =   9600
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   480
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   640
   StartUpPosition =   3  '´°¿ÚÈ±Ê¡
   Begin VB.CommandButton Command2 
      Caption         =   "Windowed"
      Height          =   375
      Left            =   120
      TabIndex        =   1
      Top             =   600
      Visible         =   0   'False
      Width           =   1095
   End
   Begin VB.Timer Timer1 
      Interval        =   50
      Left            =   3480
      Top             =   1440
   End
   Begin VB.CommandButton Command1 
      Caption         =   "Exit"
      Height          =   375
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Visible         =   0   'False
      Width           =   1095
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private objTest As D3DXMesh
Private objDrawTest As New clsSimplex

Private Sub Command1_Click()
Unload Me
End Sub

Private Sub Command2_Click()
On Error Resume Next
d3dpp.Windowed = 1
'd3dpp.BackBufferWidth = 800
'd3dpp.BackBufferHeight = 600 'then change the window's size manually
d3dd9.Reset d3dpp
Me.Refresh
End Sub

Private Sub Form_Load()
On Error Resume Next
Set d3d9 = Direct3DCreate9(D3D_SDK_VERSION)
If d3d9 Is Nothing Then
 MsgBox "Can't create D3D9!!!", vbExclamation, "Fatal Error"
 Form_Unload 0
 End
End If
With d3dpp
 .hDeviceWindow = Me.hWnd
 .SwapEffect = D3DSWAPEFFECT_DISCARD
 .BackBufferCount = 1
 .BackBufferFormat = D3DFMT_X8R8G8B8
 .BackBufferWidth = 640
 .BackBufferHeight = 480
 .Windowed = 1
 .hDeviceWindow = Me.hWnd
 .EnableAutoDepthStencil = 1
 .AutoDepthStencilFormat = D3DFMT_D24S8
 '.PresentationInterval = D3DPRESENT_INTERVAL_IMMEDIATE
 '.MultiSampleType = D3DMULTISAMPLE_4_SAMPLES
End With
'create device
Set d3dd9 = d3d9.CreateDevice(0, D3DDEVTYPE_HAL, Me.hWnd, D3DCREATE_HARDWARE_VERTEXPROCESSING, d3dpp)
If d3dd9 Is Nothing Then
 MsgBox "Can't create device!!!", vbExclamation, "Fatal Error"
 Form_Unload 0
 End
End If
pSetRenderState
End Sub

Private Sub pSetRenderState()
'test only
Dim mat As D3DMATRIX
Dim v0 As D3DVECTOR, v1 As D3DVECTOR, v2 As D3DVECTOR
With d3dd9
 .SetRenderState D3DRS_LIGHTING, 0
 .SetSamplerState 0, D3DSAMP_MIPFILTER, D3DTEXF_LINEAR
 .SetSamplerState 0, D3DSAMP_MINFILTER, D3DTEXF_LINEAR
 .SetSamplerState 0, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR
 D3DXMatrixPerspectiveFovLH mat, Atn(1), Me.ScaleWidth / Me.ScaleHeight, 0.1, 100
 .SetTransform D3DTS_PROJECTION, mat
 v0.X = 2
 v0.Y = 6
 v0.z = 3
 v2.z = 10
 D3DXMatrixLookAtLH mat, v0, v1, v2
 .SetTransform D3DTS_VIEW, mat
 '///
 .SetTextureStageState 0, D3DTSS_COLOROP, D3DTOP_SELECTARG1
 .SetTextureStageState 0, D3DTSS_COLORARG1, D3DTA_DIFFUSE
 '///
 .SetRenderState D3DRS_CULLMODE, D3DCULL_CCW
 '.SetRenderState D3DRS_NORMALIZENORMALS, 1
End With
D3DXCreateBox d3dd9, 2, 2, 4, objTest, Nothing
'D3DXCreateTeapot d3dd9, objTest, Nothing
objDrawTest.Create
End Sub

Private Sub Form_Unload(Cancel As Integer)
Set objDrawTest = Nothing
Set objTest = Nothing
Set d3dd9 = Nothing
Set d3d9 = Nothing
End Sub

Private Sub Timer1_Timer()
On Error Resume Next
Dim i As Long
Dim mat As D3DMATRIX, mat1 As D3DMATRIX
'Static j As Long
With d3dd9
 i = .TestCooperativeLevel
 If i = D3DERR_DEVICENOTRESET Then
  .Reset d3dpp
'  j = 0
  i = .TestCooperativeLevel
  Debug.Print "Reset"
 End If
 If i = 0 Then
'  If j = 0 Then
   D3DXMatrixRotationZ mat1, 0.02
   .GetTransform D3DTS_WORLD, mat
   D3DXMatrixMultiply mat, mat1, mat
   .SetTransform D3DTS_WORLD, mat
   '///
   .Clear 0, ByVal 0, D3DCLEAR_TARGET Or D3DCLEAR_ZBUFFER, 0, 1, 0
   .BeginScene
   objDrawTest.BeginRender
   objTest.DrawSubset 0
   objDrawTest.EndRender
   .EndScene
'   j = 1
'  End If
  .Present ByVal 0, ByVal 0, 0, ByVal 0
 End If
End With
'Command1.Refresh
'Command2.Refresh
End Sub
