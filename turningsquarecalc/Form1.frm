VERSION 5.00
Begin VB.Form Form1 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "摇方块"
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
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   480
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   640
   StartUpPosition =   2  '屏幕中心
   Begin VB.PictureBox p0 
      Height          =   2535
      Index           =   6
      Left            =   3960
      ScaleHeight     =   165
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   181
      TabIndex        =   68
      Top             =   4560
      Width           =   2775
      Begin VB.TextBox txtGame 
         Enabled         =   0   'False
         Height          =   285
         Index           =   2
         Left            =   960
         TabIndex        =   79
         Text            =   "30"
         Top             =   960
         Width           =   1455
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "…"
         Height          =   270
         Index           =   19
         Left            =   2190
         TabIndex        =   77
         Top             =   600
         Width           =   270
      End
      Begin VB.TextBox txtGame 
         Height          =   285
         Index           =   1
         Left            =   600
         TabIndex        =   76
         Top             =   600
         Width           =   1575
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "关闭(&C)"
         Height          =   285
         Index           =   17
         Left            =   1560
         TabIndex        =   72
         Top             =   1680
         Width           =   900
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "生成(&G)"
         Height          =   285
         Index           =   16
         Left            =   600
         TabIndex        =   71
         Top             =   1680
         Width           =   900
      End
      Begin VB.CheckBox chk1 
         Caption         =   "使用当前关卡作为模板"
         Height          =   255
         Left            =   180
         TabIndex        =   70
         Top             =   1320
         Width           =   2415
      End
      Begin VB.ComboBox cmbMode 
         Height          =   315
         Left            =   600
         Style           =   2  'Dropdown List
         TabIndex        =   69
         Top             =   240
         Width           =   1815
      End
      Begin VB.Frame Frame1 
         Caption         =   "随机地图"
         Height          =   2055
         Index           =   2
         Left            =   120
         TabIndex        =   73
         Top             =   0
         Width           =   2535
         Begin VB.Label Label1 
            Caption         =   "迭代次数"
            Height          =   255
            Index           =   18
            Left            =   60
            TabIndex        =   78
            Top             =   960
            Width           =   855
         End
         Begin VB.Label Label1 
            Caption         =   "模式"
            Height          =   255
            Index           =   16
            Left            =   60
            TabIndex        =   75
            Top             =   240
            Width           =   495
         End
         Begin VB.Label Label1 
            Caption         =   "种子"
            Height          =   255
            Index           =   17
            Left            =   60
            TabIndex        =   74
            Top             =   600
            Width           =   495
         End
      End
      Begin VB.Label Label1 
         BackColor       =   &H00800000&
         Height          =   255
         Index           =   20
         Left            =   120
         TabIndex        =   81
         Top             =   2160
         Width           =   15
      End
      Begin VB.Label Label1 
         Appearance      =   0  'Flat
         BorderStyle     =   1  'Fixed Single
         ForeColor       =   &H80000008&
         Height          =   255
         Index           =   19
         Left            =   120
         TabIndex        =   80
         Top             =   2160
         Width           =   2535
      End
   End
   Begin VB.PictureBox p0 
      BorderStyle     =   0  'None
      Height          =   3495
      Index           =   0
      Left            =   6840
      ScaleHeight     =   233
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   345
      TabIndex        =   0
      Top             =   4320
      Visible         =   0   'False
      Width           =   5175
      Begin VB.CommandButton cmd0 
         Caption         =   "游戏说明"
         BeginProperty Font 
            Name            =   "Tahoma"
            Size            =   24
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   1065
         Index           =   2
         Left            =   0
         TabIndex        =   65
         Tag             =   "1"
         Top             =   2400
         Width           =   5175
      End
      Begin VB.CommandButton cmd0 
         Caption         =   "地图编辑/求解"
         BeginProperty Font 
            Name            =   "Tahoma"
            Size            =   24
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   1065
         Index           =   1
         Left            =   0
         TabIndex        =   2
         Tag             =   "2"
         Top             =   1200
         Width           =   5175
      End
      Begin VB.CommandButton cmd0 
         Caption         =   "进入游戏"
         BeginProperty Font 
            Name            =   "Tahoma"
            Size            =   24
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   1065
         Index           =   0
         Left            =   0
         TabIndex        =   1
         Tag             =   "1"
         Top             =   0
         Width           =   5175
      End
   End
   Begin VB.PictureBox p0 
      Height          =   2535
      Index           =   1
      Left            =   240
      ScaleHeight     =   165
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   213
      TabIndex        =   3
      Top             =   3720
      Visible         =   0   'False
      Width           =   3255
      Begin VB.TextBox txtGame 
         BackColor       =   &H00000000&
         BorderStyle     =   0  'None
         ForeColor       =   &H00FFFFFF&
         Height          =   285
         Index           =   4
         Left            =   120
         TabIndex        =   82
         Top             =   1560
         Visible         =   0   'False
         Width           =   1575
      End
      Begin VB.TextBox txtGame 
         BackColor       =   &H00000000&
         BorderStyle     =   0  'None
         ForeColor       =   &H00FFFFFF&
         Height          =   1335
         Index           =   0
         Left            =   120
         MultiLine       =   -1  'True
         TabIndex        =   64
         Top             =   120
         Visible         =   0   'False
         Width           =   1935
      End
   End
   Begin VB.PictureBox p0 
      Height          =   6135
      Index           =   3
      Left            =   360
      ScaleHeight     =   405
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   629
      TabIndex        =   5
      Top             =   840
      Visible         =   0   'False
      Width           =   9495
      Begin VB.CommandButton cmdEdit 
         Caption         =   "&Solution"
         Height          =   285
         Index           =   14
         Left            =   7560
         TabIndex        =   55
         Top             =   0
         Width           =   900
      End
      Begin VB.TextBox txtGame 
         Height          =   5655
         Index           =   3
         Left            =   7560
         Locked          =   -1  'True
         MultiLine       =   -1  'True
         TabIndex        =   54
         Top             =   360
         Width           =   1935
      End
      Begin VB.OptionButton optSt 
         Caption         =   "Single"
         Height          =   255
         Index           =   3
         Left            =   4440
         Style           =   1  'Graphical
         TabIndex        =   53
         Top             =   0
         Width           =   900
      End
      Begin VB.OptionButton optSt 
         Caption         =   "Vertical"
         Height          =   255
         Index           =   2
         Left            =   3480
         Style           =   1  'Graphical
         TabIndex        =   52
         Top             =   0
         Width           =   900
      End
      Begin VB.OptionButton optSt 
         Caption         =   "Horizontal"
         Height          =   255
         Index           =   1
         Left            =   2520
         Style           =   1  'Graphical
         TabIndex        =   51
         Top             =   0
         Width           =   900
      End
      Begin VB.OptionButton optSt 
         Caption         =   "Up"
         Height          =   255
         Index           =   0
         Left            =   1560
         Style           =   1  'Graphical
         TabIndex        =   50
         Top             =   0
         Width           =   900
      End
      Begin VB.ComboBox cmbSt 
         Height          =   315
         Left            =   120
         Style           =   2  'Dropdown List
         TabIndex        =   49
         Top             =   0
         Width           =   1335
      End
      Begin VB.PictureBox pSolution 
         Height          =   1215
         Left            =   0
         ScaleHeight     =   77
         ScaleMode       =   3  'Pixel
         ScaleWidth      =   197
         TabIndex        =   48
         Top             =   360
         Width           =   3015
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "&Close"
         Height          =   285
         Index           =   13
         Left            =   8520
         TabIndex        =   47
         Top             =   0
         Width           =   900
      End
      Begin VB.Label Label1 
         Alignment       =   1  'Right Justify
         Height          =   615
         Index           =   14
         Left            =   5280
         TabIndex        =   63
         Top             =   0
         Width           =   2175
      End
   End
   Begin VB.PictureBox p0 
      Height          =   6375
      Index           =   2
      Left            =   0
      ScaleHeight     =   421
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   629
      TabIndex        =   4
      Top             =   240
      Visible         =   0   'False
      Width           =   9495
      Begin VB.CommandButton cmdEdit 
         Caption         =   "随机地图(Beta)"
         Height          =   255
         Index           =   18
         Left            =   6360
         TabIndex        =   67
         Top             =   360
         Width           =   1815
      End
      Begin VB.OptionButton optMode 
         Caption         =   "????"
         Height          =   255
         Index           =   2
         Left            =   7560
         Style           =   1  'Graphical
         TabIndex        =   62
         Top             =   720
         Visible         =   0   'False
         Width           =   570
      End
      Begin VB.CheckBox chkPos 
         Caption         =   "设置"
         Height          =   255
         Index           =   3
         Left            =   7200
         Style           =   1  'Graphical
         TabIndex        =   60
         Top             =   6000
         Width           =   615
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "清除(&C)"
         Height          =   285
         Index           =   15
         Left            =   6360
         TabIndex        =   58
         Top             =   0
         Width           =   900
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "求解..."
         Height          =   285
         Index           =   12
         Left            =   8520
         TabIndex        =   46
         Top             =   720
         Width           =   900
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "清除"
         Height          =   255
         Index           =   11
         Left            =   8760
         TabIndex        =   43
         Top             =   5040
         Width           =   555
      End
      Begin VB.ComboBox cmbBehavior 
         Height          =   315
         Left            =   7440
         Style           =   2  'Dropdown List
         TabIndex        =   42
         Top             =   5400
         Width           =   1815
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "X"
         Height          =   255
         Index           =   10
         Left            =   8490
         TabIndex        =   40
         Top             =   5040
         Width           =   255
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "+"
         Height          =   255
         Index           =   9
         Left            =   8220
         TabIndex        =   39
         Top             =   5040
         Width           =   255
      End
      Begin VB.CheckBox chkPos 
         Caption         =   "设置"
         Height          =   255
         Index           =   2
         Left            =   6960
         Style           =   1  'Graphical
         TabIndex        =   37
         Top             =   5040
         Width           =   615
      End
      Begin VB.ListBox lstSwitch 
         Height          =   2205
         Left            =   6480
         TabIndex        =   35
         Top             =   2760
         Width           =   2775
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "X"
         Height          =   255
         Index           =   8
         Left            =   9030
         TabIndex        =   34
         Top             =   2400
         Width           =   255
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "+"
         Height          =   255
         Index           =   7
         Left            =   8760
         TabIndex        =   33
         Top             =   2400
         Width           =   255
      End
      Begin VB.ComboBox cmbS 
         Height          =   315
         Left            =   6960
         Style           =   2  'Dropdown List
         TabIndex        =   32
         Top             =   2400
         Width           =   1695
      End
      Begin VB.OptionButton optMode 
         Caption         =   "选择"
         Height          =   255
         Index           =   1
         Left            =   6960
         Style           =   1  'Graphical
         TabIndex        =   20
         Top             =   720
         Width           =   570
      End
      Begin VB.OptionButton optMode 
         Caption         =   "编辑"
         Height          =   255
         Index           =   0
         Left            =   6360
         Style           =   1  'Graphical
         TabIndex        =   19
         Top             =   720
         Value           =   -1  'True
         Width           =   570
      End
      Begin VB.PictureBox p2 
         BorderStyle     =   0  'None
         Height          =   615
         Index           =   1
         Left            =   6480
         ScaleHeight     =   41
         ScaleMode       =   3  'Pixel
         ScaleWidth      =   129
         TabIndex        =   18
         Top             =   1320
         Visible         =   0   'False
         Width           =   1935
         Begin VB.CheckBox chkPos 
            Caption         =   "设置"
            Height          =   255
            Index           =   1
            Left            =   480
            Style           =   1  'Graphical
            TabIndex        =   25
            Top             =   360
            Width           =   615
         End
         Begin VB.CheckBox chkPos 
            Caption         =   "设置"
            Height          =   255
            Index           =   0
            Left            =   480
            Style           =   1  'Graphical
            TabIndex        =   24
            Top             =   0
            Width           =   615
         End
         Begin VB.Label Label1 
            Caption         =   "99,99"
            Height          =   255
            Index           =   4
            Left            =   1200
            TabIndex        =   27
            Top             =   360
            Width           =   735
         End
         Begin VB.Label Label1 
            Caption         =   "99,99"
            Height          =   255
            Index           =   3
            Left            =   1200
            TabIndex        =   26
            Top             =   0
            Width           =   735
         End
         Begin VB.Label Label1 
            Caption         =   "位置2"
            Height          =   255
            Index           =   2
            Left            =   0
            TabIndex        =   23
            Top             =   360
            Width           =   615
         End
         Begin VB.Label Label1 
            Caption         =   "位置1"
            Height          =   255
            Index           =   1
            Left            =   0
            TabIndex        =   22
            Top             =   0
            Width           =   615
         End
      End
      Begin VB.PictureBox p2 
         BorderStyle     =   0  'None
         Height          =   495
         Index           =   0
         Left            =   6480
         ScaleHeight     =   33
         ScaleMode       =   3  'Pixel
         ScaleWidth      =   177
         TabIndex        =   16
         Top             =   1320
         Visible         =   0   'False
         Width           =   2655
         Begin VB.ComboBox cmbSwitch 
            Height          =   315
            Left            =   1320
            Style           =   2  'Dropdown List
            TabIndex        =   28
            Top             =   0
            Width           =   1335
         End
         Begin VB.Label Label1 
            Alignment       =   1  'Right Justify
            Caption         =   "按钮编号"
            Height          =   255
            Index           =   0
            Left            =   0
            TabIndex        =   21
            Top             =   0
            Width           =   1215
         End
      End
      Begin VB.Frame Frame1 
         Caption         =   "属性"
         Height          =   975
         Index           =   0
         Left            =   6360
         TabIndex        =   17
         Top             =   1080
         Width           =   3015
         Begin VB.Label Label1 
            Caption         =   "没有属性。"
            Height          =   255
            Index           =   5
            Left            =   120
            TabIndex        =   29
            Top             =   240
            Width           =   1935
         End
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "&Resize"
         Height          =   285
         Index           =   6
         Left            =   7320
         TabIndex        =   15
         Top             =   0
         Width           =   900
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "删除(&D)"
         Height          =   285
         Index           =   5
         Left            =   5280
         TabIndex        =   14
         Top             =   0
         Width           =   900
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "添加(&A)"
         Height          =   285
         Index           =   4
         Left            =   4320
         TabIndex        =   13
         Top             =   0
         Width           =   900
      End
      Begin VB.ComboBox cmbLv 
         Height          =   315
         Left            =   2880
         Style           =   2  'Dropdown List
         TabIndex        =   12
         Top             =   0
         Width           =   1335
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "退出(&Q)"
         Height          =   285
         Index           =   3
         Left            =   8520
         TabIndex        =   11
         Top             =   0
         Width           =   900
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "保存(&S)"
         Height          =   285
         Index           =   2
         Left            =   1920
         TabIndex        =   10
         Top             =   0
         Width           =   900
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "打开(&O)"
         Height          =   285
         Index           =   1
         Left            =   960
         TabIndex        =   9
         Top             =   0
         Width           =   900
      End
      Begin VB.CommandButton cmdEdit 
         Caption         =   "新建(&N)"
         Height          =   285
         Index           =   0
         Left            =   0
         TabIndex        =   8
         Top             =   0
         Width           =   900
      End
      Begin VB.CommandButton Command1 
         Caption         =   "Load Flash"
         Height          =   255
         Left            =   8280
         TabIndex        =   7
         Top             =   360
         Visible         =   0   'False
         Width           =   1095
      End
      Begin VB.PictureBox pEdit 
         Height          =   5535
         Left            =   0
         ScaleHeight     =   365
         ScaleMode       =   3  'Pixel
         ScaleWidth      =   413
         TabIndex        =   6
         Top             =   720
         Width           =   6255
      End
      Begin VB.Frame Frame1 
         Caption         =   "按钮"
         Height          =   3735
         Index           =   1
         Left            =   6360
         TabIndex        =   30
         Top             =   2160
         Width           =   3015
         Begin VB.Label Label1 
            Caption         =   "行为"
            Height          =   255
            Index           =   9
            Left            =   120
            TabIndex        =   41
            Top             =   3240
            Width           =   855
         End
         Begin VB.Label Label1 
            Caption         =   "99,99"
            Height          =   255
            Index           =   8
            Left            =   1320
            TabIndex        =   38
            Top             =   2880
            Width           =   735
         End
         Begin VB.Label Label1 
            Caption         =   "位置"
            Height          =   255
            Index           =   7
            Left            =   120
            TabIndex        =   36
            Top             =   2880
            Width           =   615
         End
         Begin VB.Label Label1 
            Caption         =   "编号"
            Height          =   255
            Index           =   6
            Left            =   120
            TabIndex        =   31
            Top             =   240
            Width           =   495
         End
      End
      Begin VB.Label Label1 
         Caption         =   "99,99"
         Height          =   255
         Index           =   13
         Left            =   7920
         TabIndex        =   61
         Top             =   6000
         Width           =   735
      End
      Begin VB.Label Label1 
         Caption         =   "起点位置"
         Height          =   255
         Index           =   12
         Left            =   6360
         TabIndex        =   59
         Top             =   6000
         Width           =   855
      End
      Begin VB.Shape shpSelect 
         BorderColor     =   &H000000FF&
         BorderWidth     =   2
         Height          =   255
         Left            =   7680
         Top             =   720
         Width           =   255
      End
      Begin VB.Image i0 
         Height          =   360
         Index           =   4
         Left            =   120
         Picture         =   "Form1.frx":0000
         Top             =   330
         Width           =   7200
      End
   End
   Begin VB.PictureBox p0 
      Height          =   855
      Index           =   4
      Left            =   1680
      ScaleHeight     =   53
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   317
      TabIndex        =   44
      Top             =   -600
      Visible         =   0   'False
      Width           =   4815
      Begin VB.PictureBox p0 
         Height          =   735
         Index           =   5
         Left            =   0
         ScaleHeight     =   45
         ScaleMode       =   3  'Pixel
         ScaleWidth      =   197
         TabIndex        =   56
         Top             =   0
         Visible         =   0   'False
         Width           =   3015
         Begin VB.Label Label1 
            Alignment       =   2  'Center
            BackColor       =   &H00800000&
            BorderStyle     =   1  'Fixed Single
            Caption         =   "正在求解……"
            BeginProperty Font 
               Name            =   "Tahoma"
               Size            =   26.25
               Charset         =   0
               Weight          =   400
               Underline       =   0   'False
               Italic          =   0   'False
               Strikethrough   =   0   'False
            EndProperty
            ForeColor       =   &H00FFFFFF&
            Height          =   735
            Index           =   11
            Left            =   0
            TabIndex        =   57
            Top             =   0
            Width           =   4800
         End
      End
      Begin VB.Label Label1 
         Alignment       =   2  'Center
         BorderStyle     =   1  'Fixed Single
         Caption         =   "正在求解……"
         BeginProperty Font 
            Name            =   "Tahoma"
            Size            =   26.25
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   735
         Index           =   10
         Left            =   0
         TabIndex        =   45
         Top             =   0
         Width           =   4800
      End
   End
   Begin VB.Label Label1 
      Caption         =   "http://www.miniclip.com/games/bloxorz/en/"
      BeginProperty Font 
         Name            =   "Tahoma"
         Size            =   8.25
         Charset         =   0
         Weight          =   400
         Underline       =   -1  'True
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   255
      Index           =   15
      Left            =   7560
      TabIndex        =   66
      Top             =   0
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Image i0 
      Height          =   375
      Index           =   8
      Left            =   120
      Top             =   6480
      Visible         =   0   'False
      Width           =   615
   End
   Begin VB.Image i0 
      BorderStyle     =   1  'Fixed Single
      Height          =   900
      Index           =   6
      Left            =   7800
      Picture         =   "Form1.frx":12FE
      Top             =   6360
      Visible         =   0   'False
      Width           =   4140
   End
   Begin VB.Image i0 
      BorderStyle     =   1  'Fixed Single
      Height          =   900
      Index           =   5
      Left            =   7680
      Picture         =   "Form1.frx":1B11
      Top             =   6240
      Visible         =   0   'False
      Width           =   4140
   End
   Begin VB.Image i0 
      BorderStyle     =   1  'Fixed Single
      Height          =   24645
      Index           =   3
      Left            =   5400
      Picture         =   "Form1.frx":31E4
      Top             =   6960
      Visible         =   0   'False
      Width           =   5985
   End
   Begin VB.Image i0 
      BorderStyle     =   1  'Fixed Single
      Height          =   24645
      Index           =   2
      Left            =   5160
      Picture         =   "Form1.frx":12A84
      Top             =   6840
      Visible         =   0   'False
      Width           =   5985
   End
   Begin VB.Image i0 
      BorderStyle     =   1  'Fixed Single
      Height          =   54255
      Index           =   1
      Left            =   360
      Picture         =   "Form1.frx":1EC41
      Top             =   6960
      Visible         =   0   'False
      Width           =   4830
   End
   Begin VB.Image i0 
      BorderStyle     =   1  'Fixed Single
      Height          =   54255
      Index           =   0
      Left            =   120
      Picture         =   "Form1.frx":32F2E
      Top             =   6840
      Visible         =   0   'False
      Width           =   4830
   End
   Begin VB.Image i0 
      BorderStyle     =   1  'Fixed Single
      Height          =   7260
      Index           =   7
      Left            =   6000
      Picture         =   "Form1.frx":66091
      Top             =   6480
      Visible         =   0   'False
      Width           =   9660
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Const TheSignature = "摇方块XP"

Private Declare Sub ZeroMemory Lib "kernel32.dll" Alias "RtlZeroMemory" (ByRef Destination As Any, ByVal Length As Long)
Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Declare Sub Sleep Lib "kernel32.dll" (ByVal dwMilliseconds As Long)
Private Declare Function GetAsyncKeyState Lib "user32.dll" (ByVal vKey As Long) As Integer
Private Declare Function GetActiveWindow Lib "user32.dll" () As Long
Private Declare Sub InitCommonControls Lib "comctl32.dll" ()

Private Declare Function CreateSolidBrush Lib "gdi32.dll" (ByVal crColor As Long) As Long
Private Declare Function FillRect Lib "user32.dll" (ByVal hdc As Long, ByRef lpRect As RECT, ByVal hBrush As Long) As Long
Private Declare Function FrameRect Lib "user32.dll" (ByVal hdc As Long, ByRef lpRect As RECT, ByVal hBrush As Long) As Long
Private Declare Function DeleteObject Lib "gdi32.dll" (ByVal hObject As Long) As Long
Private Declare Function GetCursorPos Lib "user32.dll" (ByRef lpPoint As POINTAPI) As Long
Private Declare Function ScreenToClient Lib "user32.dll" (ByVal hwnd As Long, ByRef lpPoint As POINTAPI) As Long
Private Type POINTAPI
    x As Long
    y As Long
End Type

Private Type RECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type
Private Declare Function PtInRect Lib "user32.dll" (ByRef lpRect As RECT, ByVal x As Long, ByVal y As Long) As Long
Private Declare Function GetTickCount Lib "kernel32.dll" () As Long
Private Declare Function ShellExecute Lib "shell32.dll" Alias "ShellExecuteA" (ByVal hwnd As Long, ByVal lpOperation As String, ByVal lpFile As String, ByVal lpParameters As String, ByVal lpDirectory As String, ByVal nShowCmd As Long) As Long

Private bmG As New cDIBSection, bmG_Back As New cDIBSection
Private bmG_Lv As New cDIBSection
Private GameLayer0SX As Long, GameLayer0SY As Long

Private bmEdit As New cDIBSection

Private WithEvents sEdit As cScrollBar
Attribute sEdit.VB_VarHelpID = -1

Private bmImg(3) As New cAlphaDibSection

Private cd As New cCommonDialog

Private f As New clsTheFile, Lev() As clsBloxorz, LevCount As Long

Private eSelect As Long, eSX As Long, eSY As Long
Private sSX As Long, sSY As Long, sSX2 As Long, sSY2 As Long

Private Type typeTheBitmap2
 ImgIndex As Long
 x As Long
 y As Long
 w As Long
 h As Long
 dX As Long
 dy As Long
 ow As Long
 oh As Long
End Type

Private Type typeTheBitmap3
 ImgIndex As Long
 x As Long
 y As Long
 w As Long
 h As Long
 dX As Long
 dy As Long
End Type

Private Type typeTheBitmapArray
 Count As Long
 bm() As typeTheBitmap3
End Type

Private bmps(9 To 524) As typeTheBitmap2

Private Anis() As typeTheBitmapArray
'1-4=up move
'5-8=h move
'9-12=v move
'13-16=single move
'29=start
'30=end
'31-60=shadow
Private Const Ani_Layer0 = 61
Private Const Ani_Misc = 99

'/////'         *          '/////
'/////' *        x=10,y=16 '/////
'/////'          *         '/////
'/////'  *x=32,y=-5        '/////

Private GameD() As Byte, GameStatus As Long, GameLev As Long
'-2=exit game
'-1=return to menu
'0=load current level
'1=show level
'2=block fall
'3=block fall 2 (thin block)
'4=complete
'
'9 =play-check the pos is valid
'10=play-wait for key press
'11=play-moving animation
'12=play-move over,check state
'13=play-sliping animation
Private GameW As Long, GameH As Long
Private GameX As Long, GameY As Long, GameS As Long, GameX2 As Long, GameY2 As Long
Private GameFS As Long
'Private GameClick As Boolean
Private GameLvStartTime As Long, GameLvStep As Long, GameLvRetry As Long
Private GameDemoS As String, GameDemoPos As Long, GameDemoBegin As Boolean

Private GameMenuCaption() As String, GameMenuItemCount As Long

Implements IBloxorzCallBack

'////////random map
Implements ISort

Private GameIsRndMap As Boolean
Private LevTemp As New clsBloxorz 'extremely stupid!!!
Private objRnd As New clsSimpleRnd
Private nFitness() As Long

'////////new!!! international support
Private objText As New clsGNUGetText

Private Sub Instruction_Init()
Dim i As Long, j As Long, k As Long, m As Long
txtGame(0).Visible = False
'///init bitmap
bmG.Create 640, 480
'///init data
GameStatus = 0
'GameClick = False
'///enter loop
Game_Instruction_Loop
'///clear up
bmG.ClearUp
bmG_Lv.ClearUp
bmG_Back.ClearUp
If GameStatus <> -2 Then pShowPanel 0
End Sub

Private Sub Game_Init()
Dim i As Long, j As Long, k As Long, m As Long
txtGame(0).Visible = False
'///init bitmap
bmG.Create 640, 480
bmG_Lv.Create 640, 480
'...
'///load level
GameIsRndMap = False
Game_LoadLevel CStr(App.Path) + "\Default.box"
'///init data
GameStatus = 0
'GameClick = False
Game_InitMenu objText.GetText("Return to game"), objText.GetText("Restart"), objText.GetText("Pick a level"), _
objText.GetText("Open level file"), objText.GetText("Random level"), objText.GetText("Input solution"), _
objText.GetText("Auto solver"), objText.GetText("Game instructions"), objText.GetText("Main menu"), objText.GetText("Exit game")
'///enter loop
Game_Loop
'///clear up
bmG.ClearUp
bmG_Lv.ClearUp
bmG_Back.ClearUp
Erase Lev
LevCount = 0
f.Clear
'MsgBox "Exit!"
If GameStatus = -1 Then pShowPanel 0
End Sub

Private Sub Game_Loop()
Dim i As Long, j As Long, k As Long, m As Long
Dim w As Long, h As Long
Dim x As Long, y As Long, x2 As Long, y2 As Long
Dim d() As Byte, dL() As Long, dSng() As Single
Dim bEnsureReDraw As Boolean, nBridgeChangeCount As Long
Dim idx As Long, idx2 As Long, nAnimationIndex As Long
Dim kx As Long, ky As Long, kt As Long
'Dim bmTemp As New cDIBSection
Dim p As POINTAPI, r As RECT, IsMouseIn As Boolean, IsMouseIn2 As Boolean, IsSliping As Boolean
Dim s As String, sSolution As String, t As Long ' time!
':-/
Dim QIE As Long, QIE_O As Long
Do
 Select Case GameStatus
 Case 0 '///////////////////////////////////////////////////////load level
  'init layer0 size
  With Lev(GameLev)
   GameW = .Width
   GameH = .Height
  End With
  w = GameW * 32 + GameH * 10
  h = GameW * 5 + GameH * 16 + 16
  GameLayer0SX = (640 - w) \ 2
  GameLayer0SY = (480 - h) \ 2 + GameW * 5 + 8
  'init
  GameLvRetry = -1
  GameLvStartTime = 0
  GameDemoPos = 0
  GameDemoBegin = False
  'level name animation
  bmG_Lv.Cls
  If GameIsRndMap Then
   DrawTextB bmG_Lv.hdc, objText.GetText("Random Level"), Label1(10).Font, 0, 0, 640, 480, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
  Else
   DrawTextB bmG_Lv.hdc, Replace(objText.GetText("Level %d"), "%d", CStr(GameLev)), Label1(10).Font, 0, 0, 640, 480, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
  End If
  For i = 0 To 255 Step 17
   bmG.Cls
   AlphaBlendA bmG.hdc, 0, 200, 640, 80, bmG_Lv.hdc, 0, 200, , , i, False
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  For i = 1 To 50
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  For i = 255 To 0 Step -17
   bmG.Cls
   AlphaBlendA bmG.hdc, 0, 200, 640, 80, bmG_Lv.hdc, 0, 200, , , i, False
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  GameStatus = 1
 Case 1 '///////////////////////////////////////////////////////start level
  'init level
  With Lev(GameLev)
   ReDim GameD(1 To GameW, 1 To GameH)
   For i = 1 To GameW
    For j = 1 To GameH
     GameD(i, j) = .Data(i, j)
    Next j
   Next i
   GameX = .StartX
   GameY = .StartY
   GameS = 0
   GameFS = 0
   IsSliping = False
  End With
  'init
  nBridgeChangeCount = 0
  kt = 0
  If Not GameDemoBegin Then GameLvRetry = GameLvRetry + 1
  GameLvStep = 0
  sSolution = ""
  GameDemoPos = IIf(GameDemoBegin, 1, 0)
  GameDemoBegin = False
  QIE = 0
  QIE_O = 0
  'init back
  Game_InitBack
  'animate
  ReDim dL(1 To GameW, 1 To GameH * 2)
  For i = 1 To GameW
   For j = 1 To GameH
    dL(i, j) = Int(16 * Rnd)
    dL(i, j + GameH) = -1
   Next j
  Next i
  For i = 0 To 255 Step 51
   bmG.Cls
   AlphaBlendA bmG.hdc, 0, 0, 640, 480, bmG_Back.hdc, 0, 0, , , i, False
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  For k = 0 To 36
   bmG_Back.PaintPicture bmG.hdc
   x = GameLayer0SX + GameW * 32
   y = GameLayer0SY - GameW * 5
   For i = GameW To 1 Step -1
    x = x - 32
    y = y + 5
    x2 = x
    y2 = y
    For j = 1 To GameH
     If dL(i, j) >= 0 And k >= dL(i, j) Then
      dL(i, j) = -32
      dL(i, j + GameH) = 400
     End If
     If dL(i, j + GameH) >= 0 Then
      pTheBitmapDraw3 bmG.hdc, Ani_Layer0, GameD(i, j), x2, y2 + dL(i, j + GameH), -dL(i, j)
      If GameD(i, j) = 11 Then
       pTheBitmapDraw3 bmG.hdc, Ani_Misc, 6, x2, y2 + dL(i, j + GameH), -dL(i, j)
      End If
      dL(i, j + GameH) = (dL(i, j + GameH) * 3) \ 4
      dL(i, j) = dL(i, j) - 16
      If dL(i, j) < -255 Then dL(i, j) = -255
     End If
     x2 = x2 + 10
     y2 = y2 + 16
    Next j
   Next i
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next k
  'init array
  ReDim dL(1 To GameW, 1 To GameH)
  'draw layer0
  bmG_Back.PaintPicture bmG_Lv.hdc
  pGameDrawLayer0 bmG_Lv.hdc, GameD, GameW, GameH, GameLayer0SX, GameLayer0SY
  'box falls
  For j = -600 To 0 Step 50
   bmG_Lv.PaintPicture bmG.hdc
   Game_DrawLayer1 bmG.hdc, , , Ani_Misc, 5, j
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next j
  For i = 1 To Anis(29).Count
   bmG_Lv.PaintPicture bmG.hdc
   Game_DrawLayer1 bmG.hdc, , True, 29, i
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  'init time
  t = 0
  If GameLvStartTime = 0 Then GameLvStartTime = GetTickCount
  'end
  GameStatus = 9
 Case 2 '///////////////////////////////////////////////////////block fall
  'TODO:block fall
  Select Case GameFS
  Case 1: x2 = -2: y2 = -4 'up
  Case 2: x2 = 2: y2 = 4 'down
  Case 3: x2 = -5: y2 = 1 'left
  Case 4: x2 = 5: y2 = -1 'right
  Case Else 'may be block 2 fall
   x2 = 0
   y2 = 0
   GameFS = 1
  End Select
  idx = 70 + 4 * GameS + GameFS
  idx2 = 1
  w = 0
  h = 1
  x = 0
  For i = 1 To 30
   w = w + h + y2
   h = h + 1
   x = x + x2
   idx2 = 1 + idx2 Mod 9
   bmG_Back.PaintPicture bmG.hdc
   Game_DrawLayer1 bmG.hdc, , False, idx, idx2, w, , True, x
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  'fall animation
  ReDim dL(1 To GameW, 1 To GameH * 2)
  For i = 1 To GameW
   For j = 1 To GameH
    dL(i, j) = Int(15 * Rnd)
   Next j
  Next i
  For k = 0 To 30
   bmG_Back.PaintPicture bmG.hdc
   x = GameLayer0SX + GameW * 32
   y = GameLayer0SY - GameW * 5
   For i = GameW To 1 Step -1
    x = x - 32
    y = y + 5
    x2 = x
    y2 = y
    For j = 1 To GameH
     If dL(i, j) >= 0 And k >= dL(i, j) Then
      dL(i, j) = -2
     End If
     If dL(i, j + GameH) < 510 Then
      pTheBitmapDraw3 bmG.hdc, Ani_Layer0, GameD(i, j), x2, y2 + dL(i, j + GameH), 255 - dL(i, j + GameH) \ 2
      If GameD(i, j) = 11 Then
       pTheBitmapDraw3 bmG.hdc, Ani_Misc, 6, x2, y2 + dL(i, j + GameH), 255 - dL(i, j + GameH) \ 2
      End If
      If dL(i, j) < 0 Then
       dL(i, j + GameH) = dL(i, j + GameH) - dL(i, j)
       dL(i, j) = dL(i, j) - 2
      End If
     End If
     x2 = x2 + 10
     y2 = y2 + 16
    Next j
   Next i
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next k
  For i = 255 To 0 Step -51
   bmG.Cls
   AlphaBlendA bmG.hdc, 0, 0, 640, 480, bmG_Back.hdc, 0, 0, , , i, False
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  'end
  GameStatus = 1 'restart
 Case 3 '///////////////////////////////////////////////////////block fall 2
  ReDim dL(1 To GameW, 1 To GameH * 2)
  For i = 1 To GameW
   For j = 1 To GameH
    dL(i, j) = 20 + Int(15 * Rnd)
   Next j
  Next i
  dL(GameX, GameY) = -2
  w = 0
  h = 0
  For k = 0 To 50
   bmG_Back.PaintPicture bmG.hdc
   x = GameLayer0SX + GameW * 32
   y = GameLayer0SY - GameW * 5
   For i = GameW To 1 Step -1
    x = x - 32
    y = y + 5
    x2 = x
    y2 = y
    For j = 1 To GameH
     If dL(i, j) >= 0 And k >= dL(i, j) Then
      dL(i, j) = -2
     End If
     If dL(i, j + GameH) < 510 Then
      pTheBitmapDraw3 bmG.hdc, Ani_Layer0, GameD(i, j), x2, y2 + dL(i, j + GameH), 255 - dL(i, j + GameH) \ 2
      If GameD(i, j) = 11 Then
       pTheBitmapDraw3 bmG.hdc, Ani_Misc, 6, x2, y2 + dL(i, j + GameH), 255 - dL(i, j + GameH) \ 2
      End If
      If dL(i, j) < 0 Then
       dL(i, j + GameH) = dL(i, j + GameH) - dL(i, j)
       dL(i, j) = dL(i, j) - 2
      End If
     End If
     If w < 510 And i = GameX And j = GameY Then
      w = w + h
      h = h + 1
      pTheBitmapDraw3 bmG.hdc, 1, 1, x2, y2 + w
     End If
     x2 = x2 + 10
     y2 = y2 + 16
    Next j
   Next i
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next k
  For i = 255 To 0 Step -51
   bmG.Cls
   AlphaBlendA bmG.hdc, 0, 0, 640, 480, bmG_Back.hdc, 0, 0, , , i, False
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  'end
  GameStatus = 1 'restart
 Case 4 '///////////////////////////////////////////////////////win
  'block animation
  For i = 1 To Anis(30).Count
   bmG_Lv.PaintPicture bmG.hdc
   Game_DrawLayer1 bmG.hdc, , , 30, i
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  'animation
  ReDim dSng(1 To GameW, 1 To GameH * 3)
  ReDim dL(1 To GameW, 1 To GameH)
  w = GameLayer0SX + (GameX - 1) * 32 + (GameY - 1) * 10
  h = GameLayer0SY - (GameX - 1) * 5 + (GameY - 1) * 16
  x = GameLayer0SX + GameW * 32
  y = GameLayer0SY - GameW * 5
  For i = GameW To 1 Step -1
   x = x - 32
   y = y + 5
   x2 = x
   y2 = y
   For j = 1 To GameH
    dSng(i, j) = x2
    dSng(i, j + GameH) = y2
    dL(i, j) = Int(4 * Rnd)
    dSng(i, j + GameH * 2) = 5 / (10 + dL(i, j)) / (10 + Sqr((x2 - w) * (x2 - w) + (y2 - h) * (y2 - h)))
    x2 = x2 + 10
    y2 = y2 + 16
   Next j
  Next i
  For k = 0 To 51
   bmG_Back.PaintPicture bmG.hdc
   For i = GameW To 1 Step -1
    For j = 1 To GameH
     kx = dL(i, j)
     m = 255 - (5 + kx) * k
     If m > 0 Then
      x = dSng(i, j)
      y = dSng(i, j + GameH)
      dSng(i, j) = dSng(i, j) - (y - h) * dSng(i, j + GameH * 2) * k
      dSng(i, j + GameH) = dSng(i, j + GameH) + (x - w) * dSng(i, j + GameH * 2) * k
      x2 = dSng(i, j)
      y2 = dSng(i, j + GameH)
      pTheBitmapDraw3 bmG.hdc, Ani_Layer0, GameD(i, j), x2, y2, m
      If GameD(i, j) = 11 Then
       pTheBitmapDraw3 bmG.hdc, Ani_Misc, 6, x2, y2, m
      End If
     End If
    Next j
   Next i
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next k
  'clear up
  Erase dSng, dL
  For i = 255 To 0 Step -51
   bmG.Cls
   AlphaBlendA bmG.hdc, 0, 0, 640, 480, bmG_Back.hdc, 0, 0, , , i, False
   Game_Paint
   Sleep 10
   DoEvents
   If GameStatus < 0 Then Exit Sub
  Next i
  'end
  If GameDemoPos = 0 Then
   If GameIsRndMap Then
    txtGame(4).Text = objRnd.RndSeed
    bmG_Back.Cls '??
    Game_RndMap_Run
   Else
    GameLev = GameLev + 1
    If GameLev > LevCount Then GameLev = LevCount
   End If
   GameStatus = 0 'next level
  Else 'just demo only
   GameLvRetry = GameLvRetry - 1
   GameStatus = 1
  End If
 Case 9, 10, 11, 12, 13, 14, 15 '///////////////////////////////////////////////////////.....
  'calc index
  idx = GameS * 4 + 1
  idx2 = 1
  Select Case GameStatus
  Case 9 'check state valid
   Select Case Lev(GameLev).BloxorzCheckIsValidState(GameD, GameX, GameY, GameS, GameX2, GameY2)
   Case 0 'fall
    GameStatus = 2 'TODO:animation?
    'block2 fall?
    m = 0
    If GameS = 3 Then
     If GameX2 > 0 And GameY2 > 0 And GameX2 <= GameW And GameY2 <= GameW Then
      i = GameD(GameX2, GameY2)
      If i = 0 Or i = 6 Then m = 1
     Else
      m = 1
     End If
    End If
    If m Then
     x = GameX
     y = GameY
     GameX = GameX2
     GameY = GameY2
     GameX2 = x
     GameY2 = y
     GameFS = 0
    End If
   Case 1 'valid
    If GameD(GameX, GameY) = 8 And GameS = 0 Then GameStatus = 4 Else GameStatus = 10
   Case 2 'thin
    GameStatus = 3
   Case Else 'unknown
    MsgBox objText.GetText("Unknown error!")
    GameStatus = -1
   End Select
   bEnsureReDraw = True
  Case 10 'press key?
   y = 0
   If GameDemoPos > 0 And kt < 32 Then 'don't press space too frequently
    If GameDemoPos > Len(GameDemoS) Then
     y = 99
    Else
     Select Case Mid(GameDemoS, GameDemoPos, 1)
     Case "u", "↑"
      y = 1
     Case "d", "↓"
      y = 2
     Case "l", "←"
      y = 3
     Case "r", "→"
      y = 4
     Case " ", "s", "◇", "□", "_"
      y = 5
     Case vbCr, vbLf, ",", ";"
      y = 99
     End Select
     GameDemoPos = GameDemoPos + 1
    End If
    If y = 99 Then 'end
     GameDemoPos = 0
     y = 0
    End If
   End If
   If GetActiveWindow = Me.hwnd Or y > 0 Then
    If GetAsyncKeyState(vbKeyR) = &H8001 Then 'restart?
     GameStatus = 1
    ElseIf GetAsyncKeyState(vbKeyPageUp) = &H8001 And GameLev < LevCount Then 'next level (prev?)
     GameIsRndMap = False
     GameLev = GameLev + 1
     GameStatus = 0
    ElseIf GetAsyncKeyState(vbKeyPageDown) = &H8001 And GameLev > 1 Then 'prev level (next?)
     GameIsRndMap = False
     GameLev = GameLev - 1
     GameStatus = 0
    End If
    If GameStatus <= 1 Then
     'animation
     For i = 255 To 0 Step -51
      bmG.Cls
      AlphaBlendA bmG.hdc, 0, 0, 640, 480, bmG_Back.hdc, 0, 0, , , i, False
      Game_Paint
      Sleep 10
      DoEvents
      If GameStatus < 0 Then Exit Sub
     Next i
    ElseIf (GetAsyncKeyState(vbKeySpace) = &H8001 And GameDemoPos = 0) Or y = 5 Then
     If GameS = 3 Then
      'record step
      sSolution = sSolution + "◇"
      'swap block
      x = GameX
      y = GameY
      GameX = GameX2
      GameY = GameY2
      GameX2 = x
      GameY2 = y
      'animation
      kx = GameLayer0SX + (GameX - 1) * 32 + (GameY - 1) * 10 + 21
      ky = GameLayer0SY - (GameX - 1) * 5 + (GameY - 1) * 16 - 10
      kt = 40
     End If
    Else
     If (GetAsyncKeyState(vbKeyUp) And &H8000) And GameDemoPos = 0 Then
      y = 1
     ElseIf (GetAsyncKeyState(vbKeyDown) And &H8000) And GameDemoPos = 0 Then
      y = 2
     ElseIf (GetAsyncKeyState(vbKeyLeft) And &H8000) And GameDemoPos = 0 Then
      y = 3
     ElseIf (GetAsyncKeyState(vbKeyRight) And &H8000) And GameDemoPos = 0 Then
      y = 4
     End If
     If y > 0 Then
      If Lev(GameLev).BloxorzCheckIsMovable(GameD, GameX, GameY, GameS, y, QIE) Then
       GameFS = y
       GameStatus = 11
       'init animation
       If QIE_O Then
        nAnimationIndex = IIf(QIE > 0, 1, 1) '6?
       Else
        nAnimationIndex = 2
       End If
       'calc step
       GameLvStep = GameLvStep + 1
       'record step
       Select Case y
       Case 1:      s = "↑"
       Case 2:      s = "↓"
       Case 3:      s = "←"
       Case 4:      s = "→"
       End Select
       sSolution = sSolution + s
      End If
     End If
    End If
   End If
  Case 11 'moving animation
   'TODO:block???
   idx = GameS * 4 + GameFS
   idx2 = nAnimationIndex
   nAnimationIndex = nAnimationIndex + 1
   i = Anis(idx).Count
   If QIE Then i = 7 ':-/
   If nAnimationIndex >= i Then GameStatus = 12
   bEnsureReDraw = True
  Case 13 'sliping animation
   'TODO:block???
   idx = GameS * 4 + GameFS
   idx2 = 1
   nAnimationIndex = nAnimationIndex + 1
   If nAnimationIndex >= 7 Then GameStatus = 12
   'calc delta
   Select Case GameFS
   Case 1: x2 = -10: y2 = -16 'up
   Case 2: x2 = 10: y2 = 16   'down
   Case 3: x2 = -32: y2 = 5   'left
   Case 4: x2 = 32: y2 = -5   'right
   End Select
   x2 = (x2 * nAnimationIndex) \ 8
   y2 = (y2 * nAnimationIndex) \ 8
   bEnsureReDraw = True
  Case 12 'check moved state
   QIE_O = QIE ':-/
   Select Case QIE
   Case 1: x2 = 20: y2 = 32 'up
   Case 2: x2 = -10: y2 = -16    'down
   Case 3: x2 = 64: y2 = -10   'left
   Case 4: x2 = -32: y2 = 5    'right
   Case Else: x2 = 0: y2 = 0
   End Select
   'calc new pos
   If IsSliping Then
    Select Case GameFS
    Case 1: GameY = GameY - 1 'up
    Case 2: GameY = GameY + 1 'down
    Case 3: GameX = GameX - 1 'left
    Case 4: GameX = GameX + 1 'right
    End Select
   Else
    Select Case GameFS
    Case 1 'up
     If GameS = 0 Then GameY = GameY - 2 Else GameY = GameY - 1
     If GameS = 0 Or GameS = 2 Then GameS = 2 - GameS
    Case 2 'down
     If GameS = 2 Then GameY = GameY + 2 Else GameY = GameY + 1
     If GameS = 0 Or GameS = 2 Then GameS = 2 - GameS
    Case 3 'left
     If GameS = 0 Then GameX = GameX - 2 Else GameX = GameX - 1
     If GameS < 2 Then GameS = 1 - GameS
    Case 4 'right
     If GameS = 1 Then GameX = GameX + 2 Else GameX = GameX + 1
     If GameS < 2 Then GameS = 1 - GameS
    End Select
   End If
   'update index
   idx = GameS * 4 + 1
   'check
   Select Case Lev(GameLev).BloxorzCheckIsValidState(GameD, GameX, GameY, GameS, GameX2, GameY2)
   Case 0 'fall
    GameStatus = 2 'TODO:animation?
   Case 1 'valid
    GameStatus = 9
    'press button
    nBridgeChangeCount = Lev(GameLev).BloxorzCheckPressButton(GameD, GameX, GameY, GameS, VarPtr(dL(1, 1)), 115, 215)
    If nBridgeChangeCount > 0 Then
     bmG_Back.PaintPicture bmG_Lv.hdc
     pGameDrawLayer0 bmG_Lv.hdc, GameD, GameW, GameH, GameLayer0SX, GameLayer0SY
    End If
    'trans (teleport)
    If GameS = 0 And GameD(GameX, GameY) = 4 Then
     'TODO:more animation
     'animation
     For i = 255 To 0 Step -17
      bmG_Lv.PaintPicture bmG.hdc
      Game_DrawLayer1 bmG.hdc, , True, 1, 1, , i
      Game_Paint
      Sleep 10
      DoEvents
      If GameStatus < 0 Then Exit Sub
     Next i
     x = GameX
     y = GameY
     Lev(GameLev).GetTransportPosition x, y, GameX, GameY, GameX2, GameY2
     '///add check code
     If GameX < 1 Or GameX2 < 1 Or GameY < 1 Or GameY2 < 1 _
     Or GameX > GameW Or GameX2 > GameW Or GameY > GameH Or GameY2 > GameH Then
      MsgBox objText.GetText("Map error!")
      GameStatus = -1
      Exit Sub
     End If
     '///new mode:check two box get together?
     GameS = 3
     If GameX = GameX2 Then
      If GameY + 1 = GameY2 Then
       GameS = 2
      ElseIf GameY - 1 = GameY2 Then
       GameY = GameY2
       GameS = 2
      ElseIf GameY = GameY2 Then 'new mode
       GameS = 0 '???
      End If
     ElseIf GameY = GameY2 Then
      If GameX + 1 = GameX2 Then
       GameS = 1
      ElseIf GameX - 1 = GameX2 Then
       GameX = GameX2
       GameS = 1
      End If
     End If
     '///
     idx = 13 'update index '???
     GameFS = 0 'clear last move to prevent ice
     'animation
     kx = GameLayer0SX + (GameX - 1) * 32 + (GameY - 1) * 10 + 21
     ky = GameLayer0SY - (GameX - 1) * 5 + (GameY - 1) * 16 - 10
     kt = 24
     If GameS = 1 Then 'h
      kx = kx + 16
      ky = ky - 2
     ElseIf GameS = 2 Then 'v
      kx = kx + 5
      ky = ky + 8
     End If
     For i = 0 To 15
      bmG_Lv.PaintPicture bmG.hdc
      Game_DrawLayer1 bmG.hdc, , True, GameS * 4& + 1, 1, , i * 17
      pTheBitmapDraw3 bmG.hdc, Ani_Misc, 3, kx - 40 + i, ky, i * 17
      pTheBitmapDraw3 bmG.hdc, Ani_Misc, 4, kx + 40 - i, ky, i * 17
      Game_Paint
      Sleep 10
      DoEvents
      If GameStatus < 0 Then Exit Sub
     Next i
    End If
    IsSliping = False
    i = Lev(GameLev).BloxorzCheckBlockSlip(GameD, GameX, GameY, GameS, GameFS, GameX2, GameY2)
    If i > 0 Then 'ice
     GameFS = i
     GameStatus = 13
     IsSliping = True
     nAnimationIndex = 0
    ElseIf GameS = 0 And GameD(GameX, GameY) = 10 And GameFS > 0 Then    'pyramid
     'check movable
     If Lev(GameLev).BloxorzCheckIsMovable(GameD, GameX, GameY, GameS, GameFS) Then
      GameStatus = 11
      nAnimationIndex = 1
     End If
    Else
     'erase direction
     GameFS = 0
     'two box get together?
     If GameS = 3 Then
      If GameX = GameX2 Then
       If GameY + 1 = GameY2 Then
        GameS = 2
       ElseIf GameY - 1 = GameY2 Then
        GameY = GameY2
        GameS = 2
       ElseIf GameY = GameY2 Then 'err!!
        MsgBox objText.GetText("Map error!")
        GameStatus = -1
       End If
      ElseIf GameY = GameY2 Then
       If GameX + 1 = GameX2 Then
        GameS = 1
       ElseIf GameX - 1 = GameX2 Then
        GameX = GameX2
        GameS = 1
       End If
      End If
     End If
    End If
    'update index
    idx = GameS * 4 + 1
    'If True Then
    ' GameStatus = 9
    'End If
   Case 2 'thin
    GameStatus = 3
   Case Else 'unknown
    MsgBox objText.GetText("Unknown error!")
    GameStatus = -1
   End Select
   bEnsureReDraw = True
  End Select
  If nBridgeChangeCount > 0 Then bEnsureReDraw = True
  If kt > 0 Then bEnsureReDraw = True
  'draw menu?
  GetCursorPos p
  ScreenToClient Me.hwnd, p
  r.Left = 600
  r.Top = 8
  r.Right = 632
  r.Bottom = 24
  If CBool(PtInRect(r, p.x, p.y)) Xor IsMouseIn Then
   IsMouseIn = Not IsMouseIn
   bEnsureReDraw = True
  End If
  'copyBtn?
  If GameIsRndMap Then
   r.Left = 252
   r.Right = 300
   If CBool(PtInRect(r, p.x, p.y)) Xor IsMouseIn2 Then
    IsMouseIn2 = Not IsMouseIn2
    bEnsureReDraw = True
   End If
  End If
  'check time
  i = GetTickCount - GameLvStartTime
  If i >= t * 1000 Then
   t = i \ 1000
   bEnsureReDraw = True
  End If
  'redraw?
  If bEnsureReDraw And GameStatus > 1 Then '???
   bmG_Lv.PaintPicture bmG.hdc
   'draw text (ZDepth????)
   s = Format(t Mod 60, "00")
   i = t \ 60
   s = Format(i \ 60, "00:") + Format(i Mod 60, "00:") + s
   DrawTextB bmG.hdc, CStr(GameLvStep), Me.Font, 64, 24, 72, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
   DrawTextB bmG.hdc, s, Me.Font, 64, 40, 72, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
   DrawTextB bmG.hdc, CStr(GameLvRetry), Me.Font, 64, 56, 72, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
   'draw bridge status change
   nBridgeChangeCount = 0
   For i = 1 To GameW
    For j = 1 To GameH
     m = dL(i, j)
     Select Case m
     Case 100 To 115 'off
      pTheBitmapDraw3 bmG.hdc, Ani_Misc, 1, _
      GameLayer0SX + (i - 1) * 32 + (j - 1) * 10, _
      GameLayer0SY - (i - 1) * 5 + (j - 1) * 16, (m - 100) * 17
      dL(i, j) = m - 1
      nBridgeChangeCount = nBridgeChangeCount + 1
     Case 200 To 215 'on
      pTheBitmapDraw3 bmG.hdc, Ani_Misc, 2, _
      GameLayer0SX + (i - 1) * 32 + (j - 1) * 10, _
      GameLayer0SY - (i - 1) * 5 + (j - 1) * 16, (m - 200) * 17
      dL(i, j) = m - 1
      nBridgeChangeCount = nBridgeChangeCount + 1
     Case Else
      dL(i, j) = 0
     End Select
    Next j
   Next i
   'layer 1
   If IsSliping Then 'slip?
    Game_DrawLayer1 bmG.hdc, , True, idx, idx2, y2, , , x2, True
   ElseIf QIE_O > 0 And GameFS = 0 Then ':-/
    Game_DrawLayer1 bmG.hdc, , True, QIE_O, 8, y2, , , x2, True
   ElseIf QIE_O > 0 And (QIE_O > 2 Xor GameFS > 2) Then ':-/
    Select Case GameFS
    Case 1 'up
     Game_DrawLayer1 bmG.hdc, , True, QIE_O, 8, y2 - (16 * nAnimationIndex) \ 8, _
     , , x2 - (10 * nAnimationIndex) \ 8, True
    Case 2 'down
     Game_DrawLayer1 bmG.hdc, , True, QIE_O, 8, y2 + (16 * nAnimationIndex) \ 8, _
     , , x2 + (10 * nAnimationIndex) \ 8, True
    Case 3 'left
     Game_DrawLayer1 bmG.hdc, , True, QIE_O, 8, y2 + (5 * nAnimationIndex) \ 8, _
     , , x2 - (32 * nAnimationIndex) \ 8, True
    Case 4 'right
     Game_DrawLayer1 bmG.hdc, , True, QIE_O, 8, y2 - (5 * nAnimationIndex) \ 8, _
     , , x2 + (32 * nAnimationIndex) \ 8, True
    End Select
   Else
    Game_DrawLayer1 bmG.hdc, , True, idx, idx2
   End If
   'draw []
   Select Case kt
   Case 1 To 16
    pTheBitmapDraw3 bmG.hdc, Ani_Misc, 3, kx - 24, ky, 17 * (kt - 1)
    pTheBitmapDraw3 bmG.hdc, Ani_Misc, 4, kx + 24, ky, 17 * (kt - 1)
    kt = kt - 1
   Case 17 To 24
    pTheBitmapDraw3 bmG.hdc, Ani_Misc, 3, kx - 24, ky
    pTheBitmapDraw3 bmG.hdc, Ani_Misc, 4, kx + 24, ky
    kt = kt - 1
   Case 25 To 40
    pTheBitmapDraw3 bmG.hdc, Ani_Misc, 3, kx - kt, ky, 17 * (40 - kt)
    pTheBitmapDraw3 bmG.hdc, Ani_Misc, 4, kx + kt, ky, 17 * (40 - kt)
    kt = kt - 1
   End Select
   'draw menu
   If IsMouseIn Or IsMouseIn2 Then
    x = CreateSolidBrush(vbBlack)
    If IsMouseIn Then
     r.Left = 600
     r.Right = 632
    Else
     r.Left = 252
     r.Right = 300
    End If
    FrameRect bmG.hdc, r, x
    DeleteObject x
   End If
   Game_Paint
   bEnsureReDraw = False
  End If
  Sleep 10
  DoEvents
  'copy seed?
  If IsMouseIn2 And GameIsRndMap Then
   If GetAsyncKeyState(1) And &H8000 Then
    With Clipboard
     .Clear
     .SetText txtGame(0).Tag
    End With
   End If
  End If
  'menu
  If (IsMouseIn And (GetAsyncKeyState(1) And &H8000&) <> 0) Or GetAsyncKeyState(vbKeyEscape) = &H8001 Then
   j = GetTickCount
   'GameClick = False
   bmG.PaintPicture bmG_Back.hdc
   i = Game_Menu_Loop
   Select Case i
   Case 1 'return
    Game_InitBack
   Case 2 'restart
    'animation
    For i = 255 To 0 Step -51
     bmG.Cls
     AlphaBlendA bmG.hdc, 0, 0, 640, 480, bmG_Back.hdc, 0, 0, , , i, False
     Game_Paint
     Sleep 10
     DoEvents
     If GameStatus < 0 Then Exit Sub
    Next i
    'over
    GameStatus = 1
   Case 3 'select level
    s = InputBox(Replace(objText.GetText("Level: (Max=%d)"), "%d", CStr(LevCount)), , GameLev)
    On Error Resume Next
    Err.Clear
    i = Val(s)
    If Err.Number Then i = 0
    On Error GoTo 0
    If i > 0 And i <= LevCount And (i <> GameLev Or GameIsRndMap) Then 'valid
     'exit random mode
     If GameIsRndMap Then
      Lev(GameLev).Clone LevTemp
      GameIsRndMap = False
     End If
     GameLev = i
     'animation
     For i = 255 To 0 Step -51
      bmG.Cls
      AlphaBlendA bmG.hdc, 0, 0, 640, 480, bmG_Back.hdc, 0, 0, , , i, False
      Game_Paint
      Sleep 10
      DoEvents
      If GameStatus < 0 Then Exit Sub
     Next i
     'over
     GameStatus = 0
    Else
     Game_InitBack
    End If
   Case 4 'open file
    s = ""
    If cd.VBGetOpenFileName(s, , , , , True, objText.GetText("Turning Square level pack|*.box"), , CStr(App.Path), , , Me.hwnd) Then
     'exit random mode
     GameIsRndMap = False
     Game_LoadLevel s
     'animation
     For i = 255 To 0 Step -51
      bmG.Cls
      AlphaBlendA bmG.hdc, 0, 0, 640, 480, bmG_Back.hdc, 0, 0, , , i, False
      Game_Paint
      Sleep 10
      DoEvents
      If GameStatus < 0 Then Exit Sub
     Next i
     'over
     GameStatus = 0
    Else
     Game_InitBack
    End If
   Case 5 'new!!! random map
    'TODO:
    i = Game_RndMap_Loop
    Select Case i
    Case 1
     'animation
     For i = 255 To 0 Step -51
      bmG.Cls
      AlphaBlendA bmG.hdc, 0, 0, 640, 480, bmG_Back.hdc, 0, 0, , , i, False
      Game_Paint
      Sleep 10
      DoEvents
      If GameStatus < 0 Then Exit Sub
     Next i
     'over
     GameStatus = 0
    End Select
    Game_InitBack
   Case 6 'input solution
    txtGame(0).Text = sSolution
    txtGame(0).Locked = False
    i = Game_TextBox_Loop
    Select Case i
    Case 1
     'animation
     For i = 255 To 0 Step -51
      bmG.Cls
      AlphaBlendA bmG.hdc, 0, 0, 640, 480, bmG_Back.hdc, 0, 0, , , i, False
      Game_Paint
      Sleep 10
      DoEvents
      If GameStatus < 0 Then Exit Sub
     Next i
     'over
     GameStatus = 1
     GameDemoS = LCase(txtGame(0).Text)
     GameDemoBegin = True
    End Select
    Game_InitBack
   Case 7 'solve it
    If Lev(GameLev).SolveIt(Me) Then
     m = Lev(GameLev).SolveItGetSolutionNodeIndex
     If m > 0 Then
      GameDemoS = Lev(GameLev).SolveItGetSolution(m)
      s = Replace(GameDemoS, "u", "↑")
      s = Replace(s, "d", "↓")
      s = Replace(s, "l", "←")
      s = Replace(s, "r", "→")
      s = Replace(s, "s", "◇")
      txtGame(0).Text = s + vbCrLf + objText.GetText("Moves:") + CStr(Lev(GameLev).SolveItGetDistance(m))
      txtGame(0).Locked = True
      i = Game_TextBox_Loop
      Select Case i
      Case 1
       'animation
       For i = 255 To 0 Step -51
        bmG.Cls
        AlphaBlendA bmG.hdc, 0, 0, 640, 480, bmG_Back.hdc, 0, 0, , , i, False
        Game_Paint
        Sleep 10
        DoEvents
        If GameStatus < 0 Then Exit Sub
       Next i
       'over
       GameStatus = 1
       GameDemoBegin = True
      End Select
      Game_InitBack
     Else
      MsgBox objText.GetText("No solution!"), vbExclamation
     End If
    Else
     MsgBox objText.GetText("Error!"), vbCritical
    End If
    Lev(GameLev).SolveItClear 'the missing code!
    Game_InitBack
   Case 8 'instruction
    'animation
    For i = 255 To 0 Step -51
     bmG.Cls
     AlphaBlendA bmG.hdc, 0, 0, 640, 480, bmG_Back.hdc, 0, 0, , , i, False
     Game_Paint
     Sleep 10
     DoEvents
     If GameStatus < 0 Then Exit Sub
    Next i
    Game_Instruction_Loop
    'animation
    For i = 0 To 255 Step 51
     bmG.Cls
     AlphaBlendA bmG.hdc, 0, 0, 640, 480, bmG_Lv.hdc, 0, 0, , , i, False
     Game_Paint
     Sleep 10
     DoEvents
     If GameStatus < 0 Then Exit Sub
    Next i
    'over
    Game_InitBack
   Case GameMenuItemCount - 1
    GameStatus = -1
   Case GameMenuItemCount
    GameStatus = -2
   End Select
   GameLvStartTime = GameLvStartTime + (GetTickCount - j)
   'GameClick = False
   bEnsureReDraw = True
  End If
  'exit??
  If GameStatus < 0 Then Exit Sub
 Case Else 'err?
  Sleep 10
  DoEvents
  If GameStatus < 0 Then Exit Sub
 End Select
Loop
End Sub

Private Function Game_Menu_Loop() As Long
Dim i As Long, j As Long
Dim x As Long, y As Long
Dim w As Long, h As Long
Dim r As RECT, hbr As Long, hbr2 As Long
Dim p As POINTAPI
'init
w = 128
h = GameMenuItemCount * 20 + 12
r.Left = 320 - w \ 2
r.Right = r.Left + w
hbr = CreateSolidBrush(vbBlack)
hbr2 = CreateSolidBrush(&H80FF&)
'show menu
x = h \ 2
y = 5
For i = 1 To 16
 r.Top = 240 - y
 r.Bottom = 240 + y
 bmG_Back.PaintPicture bmG.hdc
 FillRect bmG.hdc, r, hbr
 FrameRect bmG.hdc, r, hbr2
 Game_Paint
 Sleep 10
 DoEvents
 If GameStatus < 0 Then
  DeleteObject hbr
  DeleteObject hbr2
  Exit Function
 End If
 y = x - ((x - y) * 3) \ 4
Next i
'show text
r.Top = 240 - h \ 2
r.Bottom = r.Top + h
For i = 1 To 17 + (GameMenuItemCount - 1)
 y = r.Top + 8
 bmG_Back.PaintPicture bmG.hdc
 FillRect bmG.hdc, r, hbr
 FrameRect bmG.hdc, r, hbr2
 For j = 1 To GameMenuItemCount
  x = &HF0F0F * (i - (j - 1))
  If x > 0 Then
   If x > &HFFFFFF Then x = &HFFFFFF
   DrawTextB bmG.hdc, GameMenuCaption(j), Me.Font, r.Left, y, w, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, x, , True
  End If
  y = y + 20
 Next j
 Game_Paint
 Sleep 10
 DoEvents
 If GameStatus < 0 Then
  DeleteObject hbr
  DeleteObject hbr2
  Exit Function
 End If
Next i
'menu loop
i = 0
r.Left = r.Left + 8
r.Right = r.Right - 8
y = 240 - h \ 2 + 8
Do
 GetCursorPos p
 ScreenToClient Me.hwnd, p
 'hit test
 If p.x >= r.Left And p.x < r.Right Then
  If p.y >= y And p.y < 240 + h \ 2 - 8 Then
   j = p.y - y
   If j Mod 20 < 16 Then
    j = 1 + j \ 20
   Else
    j = 0
   End If
  Else
   j = 0
  End If
 Else
  j = 0
 End If
 If i <> j Then
  'erase old
  If i > 0 Then
   r.Top = y + (i - 1) * 20
   r.Bottom = r.Top + 16
   FrameRect bmG.hdc, r, hbr
  End If
  i = j
  'draw new
  If i > 0 Then
   r.Top = y + (i - 1) * 20
   r.Bottom = r.Top + 16
   FrameRect bmG.hdc, r, hbr2
  End If
  Game_Paint
 End If
 Sleep 20
 DoEvents
 If GameStatus < 0 Then
  DeleteObject hbr
  DeleteObject hbr2
  Exit Function
 End If
 If (GetAsyncKeyState(1) And &H8000) And i > 0 Then
  Game_Menu_Loop = i
  Select Case i 'animation?
  Case 1
   r.Left = r.Left - 8
   r.Right = r.Right + 8
   'hide text
   r.Top = 240 - h \ 2
   r.Bottom = r.Top + h
   For i = 1 To 17 + (GameMenuItemCount - 1)
    y = r.Top + 8
    bmG_Back.PaintPicture bmG.hdc
    FillRect bmG.hdc, r, hbr
    FrameRect bmG.hdc, r, hbr2
    For j = 1 To GameMenuItemCount
     x = &HF0F0F * (j - i + 16)
     If x > 0 Then
      If x > &HFFFFFF Then x = &HFFFFFF
      DrawTextB bmG.hdc, GameMenuCaption(j), Me.Font, r.Left, y, w, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, x, , True
     End If
     y = y + 20
    Next j
    Game_Paint
    Sleep 10
    DoEvents
    If GameStatus < 0 Then
     DeleteObject hbr
     DeleteObject hbr2
     Game_Menu_Loop = 0
     Exit Function
    End If
   Next i
   'hide menu
   y = h \ 2
   For i = 1 To 16
    r.Top = 240 - y
    r.Bottom = 240 + y
    bmG_Back.PaintPicture bmG.hdc
    FillRect bmG.hdc, r, hbr
    FrameRect bmG.hdc, r, hbr2
    Game_Paint
    Sleep 10
    DoEvents
    If GameStatus < 0 Then
     DeleteObject hbr
     DeleteObject hbr2
     Game_Menu_Loop = 0
     Exit Function
    End If
    y = (y * 3) \ 4
   Next i
  End Select
  Exit Do
 End If
Loop
'clear up
DeleteObject hbr
DeleteObject hbr2
End Function

Private Function Game_TextBox_Loop() As Long
Dim i As Long, j As Long, p As POINTAPI
Dim w As Long, h As Long
Dim r As RECT, hbr As Long, hbr2 As Long
Dim b1 As Boolean, b2 As Boolean
Dim bo1 As Boolean, bo2 As Boolean
'init
w = 320
h = 256
r.Left = 320 - w \ 2
r.Right = r.Left + w
r.Top = 240 - h \ 2
r.Bottom = r.Top + h
hbr = CreateSolidBrush(vbBlack)
hbr2 = CreateSolidBrush(&H80FF&)
'show
bmG_Back.PaintPicture bmG.hdc
FillRect bmG.hdc, r, hbr
FrameRect bmG.hdc, r, hbr2
DrawTextB bmG.hdc, objText.GetText("Demo"), Me.Font, r.Left + 8, r.Bottom - 24, 64, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
DrawTextB bmG.hdc, objText.GetText("Cancel"), Me.Font, r.Right - 72, r.Bottom - 24, 64, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
Game_Paint
txtGame(0).Move r.Left + 8, r.Top + 8, w - 16, h - 40
txtGame(0).Visible = True
txtGame(0).SetFocus
'init button
r.Bottom = r.Bottom - 8
r.Top = r.Bottom - 16
Do
 'get cursor pos
 GetCursorPos p
 ScreenToClient Me.hwnd, p
 'mouse in button1?
 r.Left = 320 - w \ 2 + 8
 r.Right = r.Left + 64
 b1 = PtInRect(r, p.x, p.y)
 If b1 Xor bo1 Then
  bo1 = b1
  FrameRect bmG.hdc, r, IIf(b1, hbr2, hbr)
  Game_Paint
 End If
 'mouse in button2?
 r.Left = r.Left + w - 80
 r.Right = r.Left + 64
 b2 = PtInRect(r, p.x, p.y)
 If b2 Xor bo2 Then
  bo2 = b2
  FrameRect bmG.hdc, r, IIf(b2, hbr2, hbr)
  Game_Paint
 End If
 Sleep 20
 DoEvents
 'click button1?
 If b1 Then
  If GetAsyncKeyState(1) And &H8000 Then
   Game_TextBox_Loop = 1
   Exit Do
  End If
 End If
 'click button2?
 If b2 Then
  If GetAsyncKeyState(1) And &H8000 Then
   Game_TextBox_Loop = 0
   Exit Do
  End If
 End If
 If GameStatus < 0 Then Exit Do
Loop
'clear up
txtGame(0).Visible = False
DeleteObject hbr
DeleteObject hbr2
End Function

'new!!!
Private Function Game_RndMap_Loop() As Long
Dim i As Long, j As Long, k As Long, p As POINTAPI
Dim w As Long, h As Long
Dim r As RECT, r2 As RECT, r3 As RECT
Dim hbr As Long, hbr2 As Long, hbr3 As Long
Dim b1 As Boolean, b2 As Boolean
'calc width and height
w = 256
h = 80
j = cmbMode.ListCount
i = 32 + j * 16&
If i > h Then h = i
'init
r.Left = 320 - w \ 2
r.Right = r.Left + w
r.Top = 240 - h \ 2
r.Bottom = r.Top + h
hbr = CreateSolidBrush(vbBlack)
hbr2 = CreateSolidBrush(&H80FF&)
hbr3 = CreateSolidBrush(&H4080&)
'show
bmG_Back.PaintPicture bmG.hdc
FillRect bmG.hdc, r, hbr
FrameRect bmG.hdc, r, hbr2
r2.Left = r.Left + 144
r2.Top = r.Top + 32
r2.Right = r.Left + 240
r2.Bottom = r.Top + 48
FrameRect bmG.hdc, r2, hbr2
DrawTextB bmG.hdc, objText.GetText("Generate"), Me.Font, r.Left + 144, r.Bottom - 24, 48, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
DrawTextB bmG.hdc, objText.GetText("Cancel"), Me.Font, r.Left + 200, r.Bottom - 24, 48, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
DrawTextB bmG.hdc, objText.GetText("Random map mode:"), Me.Font, r.Left + 8, r.Top + 8, 128, 16, DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
DrawTextB bmG.hdc, objText.GetText("Seed:"), Me.Font, r.Left + 144, r.Top + 8, 128, 16, DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
Game_Paint
With txtGame(4)
 .Move r.Left + 145, r.Top + 33, 94, 14
 .Text = objRnd.RndSeed
 .Visible = True
End With
Do 'refresh continously :-3
 'get cursor pos
 GetCursorPos p
 ScreenToClient Me.hwnd, p
 r2.Top = r.Bottom - 24
 r2.Bottom = r2.Top + 16
 'mouse in button1?
 r2.Left = r.Left + 144
 r2.Right = r2.Left + 48
 b1 = PtInRect(r2, p.x, p.y)
 FrameRect bmG.hdc, r2, IIf(b1, hbr2, hbr)
 'mouse in button2?
 r2.Left = r.Left + 200
 r2.Right = r2.Left + 48
 b2 = PtInRect(r2, p.x, p.y)
 FrameRect bmG.hdc, r2, IIf(b2, hbr2, hbr)
 'listbox control :-3
 r2.Left = r.Left + 8
 r2.Top = r.Top + 24
 r2.Right = r2.Left + 128
 r2.Bottom = r2.Top + j * 16&
 FillRect bmG.hdc, r2, hbr
 k = -1
 For i = 0 To j - 1
  r3.Left = r2.Left
  r3.Top = r2.Top + i * 16&
  r3.Right = r2.Right
  r3.Bottom = r3.Top + 16&
  If i = cmbMode.ListIndex Then FillRect bmG.hdc, r3, hbr3
  DrawTextB bmG.hdc, cmbMode.List(i), Me.Font, r2.Left, r3.Top, 128, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
  If PtInRect(r3, p.x, p.y) Then
   r3.Left = r3.Left + 2
   r3.Top = r3.Top + 1
   r3.Right = r3.Right - 2
   r3.Bottom = r3.Bottom - 1
   FrameRect bmG.hdc, r3, hbr2
   If GetAsyncKeyState(1) And &H8000 Then k = i
  End If
 Next i
 FrameRect bmG.hdc, r2, hbr2
 If k >= 0 Then cmbMode.ListIndex = k
 'over
 Game_Paint
 Sleep 50
 DoEvents
 'click button1?
 If b1 Then
  If GetAsyncKeyState(1) And &H8000 Then
   txtGame(4).Visible = False
   'get arguments
   i = Val(txtGame(4).Text)
   If i > 0 And i <= cmbMode.ListCount Then cmbMode.ListIndex = i - 1
   'enter random mode
   If Not GameIsRndMap Then
    LevTemp.Clone Lev(GameLev)
    GameIsRndMap = True
   End If
   'start random
   Game_RndMap_Run
   Game_RndMap_Loop = 1
   Exit Do
  End If
 End If
 'click button2?
 If b2 Then
  If GetAsyncKeyState(1) And &H8000 Then
   Game_RndMap_Loop = 0
   Exit Do
  End If
 End If
 If GameStatus < 0 Then Exit Do
Loop
'clear up
txtGame(4).Visible = False
DeleteObject hbr
DeleteObject hbr2
DeleteObject hbr3
End Function

Private Sub Game_Instruction_Loop()
Const sSource1 As String = "http://code.google.com/p/turningpolyhedron/"
Const sSource2 As String = "http://www.vbgood.com/thread-69691-1-1.html"
Dim i As Long, j As Long, p As POINTAPI, r As RECT
Dim x As Long, y As Long, x2 As Long, y2 As Long
Dim hbr As Long
Dim b1 As Boolean, bc1 As Boolean, b2 As Boolean
Dim b1a As Boolean, bc1a As Boolean
Dim b1b As Boolean, bc1b As Boolean
Dim s As String, s1 As String
'init
hbr = CreateSolidBrush(&H80FF&)
'
bmG.Cls
Game_Paint
'draw
bmG_Back.CreateFromPicture i0(7).Picture
'////////////////////////////////////////////'map 1
x = 572
y = 32
For j = 1 To 3
 x2 = x
 y2 = y
 For i = 6 To 1 Step -1
  If i = 5 And j = 2 Then
   pTheBitmapDraw3 bmG_Back.hdc, Ani_Layer0, 8, x2, y2
  Else
   pTheBitmapDraw3 bmG_Back.hdc, Ani_Layer0, 1, x2, y2
  End If
  x2 = x2 - 32
  y2 = y2 + 5
 Next i
 x = x + 10
 y = y + 16
Next j
pGameDrawBox bmG_Back.hdc, 1, 1, 454, 68
'////////////////////////////////////////////'map 2
x = 572
y = 128
For j = 1 To 3
 x2 = x
 y2 = y
 For i = 6 To 1 Step -1
  If i = 3 Or i = 4 Then
   If j = 2 Then pTheBitmapDraw3 bmG_Back.hdc, Ani_Layer0, 7, x2, y2
  ElseIf i = 1 And j = 1 Then
   pTheBitmapDraw3 bmG_Back.hdc, Ani_Layer0, 2, x2, y2
  ElseIf i = 6 And j = 1 Then
   pTheBitmapDraw3 bmG_Back.hdc, Ani_Layer0, 3, x2, y2
  Else
   pTheBitmapDraw3 bmG_Back.hdc, Ani_Layer0, 1, x2, y2
  End If
  x2 = x2 - 32
  y2 = y2 + 5
 Next i
 x = x + 10
 y = y + 16
Next j
'////////////////////////////////////////////'map 3
x = 572
y = 224
For j = 1 To 3
 x2 = x
 y2 = y
 For i = 6 To 1 Step -1
  If i = 3 Or i = 4 Then
   pTheBitmapDraw3 bmG_Back.hdc, Ani_Layer0, 5, x2, y2
  ElseIf i = 5 And j = 2 Then
   pTheBitmapDraw3 bmG_Back.hdc, Ani_Layer0, 4, x2, y2
  Else
   pTheBitmapDraw3 bmG_Back.hdc, Ani_Layer0, 1, x2, y2
  End If
  x2 = x2 - 32
  y2 = y2 + 5
 Next i
 x = x + 10
 y = y + 16
Next j
pGameDrawBox bmG_Back.hdc, 13, 1, 444, 244
pGameDrawBox bmG_Back.hdc, 13, 1, 432, 281
'////////////////////////////////////////////'map 4
x = 572
y = 320
For j = 1 To 3
 x2 = x
 y2 = y
 For i = 6 To 1 Step -1
  If i = 4 And j = 3 Then
   pTheBitmapDraw3 bmG_Back.hdc, Ani_Layer0, 10, x2, y2
  ElseIf (i < 3 And j < 3) Or i > 4 Then
   pTheBitmapDraw3 bmG_Back.hdc, Ani_Layer0, 1, x2, y2
  Else
   pTheBitmapDraw3 bmG_Back.hdc, Ani_Layer0, 9, x2, y2
  End If
  If (i < 3 And j < 3) Or (i = 6 And j = 2) Then
   pTheBitmapDraw3 bmG_Back.hdc, Ani_Misc, 6, x2, y2
  End If
  x2 = x2 - 32
  y2 = y2 + 5
 Next i
 x = x + 10
 y = y + 16
Next j
pTheBitmapDraw3 bmG_Back.hdc, 4, 7, 523, 345
'////////////////////////////////////////////
s1 = String(2, Chr(&HA1A1&))
's = s1 + "“摇方块”是一款益智游戏，游戏的目标是控制方块落入每关最后的小洞。在默认关卡中共有33关。"
's = s + "要移动方块，只需按下方向键。小心不要掉到边界以外——如果掉出去了，当前关卡就会重新开始。"
's = s + vbCr + vbCr + s1 + "桥梁和开关在很多关卡中出现。当开关被方块按下时就会被激活；你并不需要一直呆在开关上面以保持开关被按下。"
's = s + vbCr + vbCr + s1 + "有两种类型的开关：“硬”的X型的开关和“软”的圆形的开关。当方块的任何部分按下“软”的开关时开关都会被激活；"
's = s + "激活“硬”的开关需要更大的压力，所以方块必须“站”在上面。"
's = s + vbCr + vbCr + s1 + "当开关被激活后，每个开关的行为可能不一样。有些开关每次按下时会切换特定桥梁的状态，另一些开关按下后会打开特定的桥梁，再次按下后不会关闭桥梁。"
's = s + "当桥梁状态改变时，红色或绿色的方块会在桥梁上闪动，以提示桥梁的打开或关闭。"
's = s + vbCr + vbCr + s1 + "橙色的砖块比其他的更易碎，不能承受太大的压力。如果方块“站”在上面，那么方块就会掉落。"
's = s + vbCr + vbCr + s1 + "还有一种砖块上面有一个圆形的符号。当方块“站”在上面时方块将会被分成两小块，并被传送到不同的位置。"
's = s + "两个小块可以独立控制，用空格键来切换。当两个小块靠到一起后就可以还原成原来的方块。"
's = s + "小方块仍然可以按下“软”的开关，但是不能按下“硬”的开关。另外，小方块也不能落入终点，只有完整的方块才能落入终点。"
's = s + vbCr + vbCr + s1 + "新版本中增加了几种砖块：突起的砖块、冰以及墙。方块“站”在突起的砖块上不太稳定，所以它会马上“摇”下来，除非有墙挡着。"
's = s + "当方块完全处在冰上时就会滑动，一直到有部分离开冰或者撞墙。而墙作为一种障碍物，方块不能通过，但是可以斜着靠在上面，靠上去后仍可移动。"
'////////
's = Replace(Replace(objText.GetText("#INSTRUCTIONS#"), "\n", vbLf), "\t", s1)
s = Replace(objText.GetText("#INSTRUCTIONS#"), vbTab, s1)
's = s + vbCr + vbCr + s1 + ""
's = s + vbCr + vbCr + s1 + ""
DrawTextB bmG_Back.hdc, s, Me.Font, 8, 8, 400, 400, DT_EXPANDTABS Or DT_WORDBREAK, vbWhite, , True
'////////////////////////////////////////////
s = objText.GetText("VB6 version, author: acme_pjz")
DrawTextB bmG_Back.hdc, s, Me.Font, 8, 408, 320, 16, DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
s = objText.GetText("Source code:")
DrawTextB bmG_Back.hdc, s, Me.Font, 8, 424, 256, 16, DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
DrawTextB bmG_Back.hdc, sSource1, Label1(15).Font, 100, 424, 230, 16, DT_VCENTER Or DT_SINGLELINE, &HFF8000, , True, False
DrawTextB bmG_Back.hdc, sSource2, Label1(15).Font, 100, 440, 240, 16, DT_VCENTER Or DT_SINGLELINE, &HFF8000, , True, False
s = objText.GetText("Original version:")
DrawTextB bmG_Back.hdc, s, Me.Font, 8, 456, 96, 16, DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
DrawTextB bmG_Back.hdc, Label1(15).Caption, Label1(15).Font, 100, 456, 220, 16, DT_VCENTER Or DT_SINGLELINE, &HFF8000, , True, False
DrawTextB bmG_Back.hdc, objText.GetText("OK"), Me.Font, 568, 456, 64, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
'animation
For i = 0 To 255 Step 51
 bmG.Cls
 AlphaBlendA bmG.hdc, 0, 0, 640, 480, bmG_Back.hdc, 0, 0, , , i, False
 Game_Paint
 Sleep 10
 DoEvents
 If GameStatus < 0 Then Exit Sub
Next i
'loop
Do
 bmG_Back.PaintPicture bmG.hdc
 'get cursor pos
 GetCursorPos p
 ScreenToClient Me.hwnd, p
 'init button
 r.Left = 100
 r.Right = 340
 'mouse in button1a?
 r.Top = 424
 r.Bottom = 440
 b1a = PtInRect(r, p.x, p.y)
 If b1a Then
  DrawTextB bmG.hdc, sSource1, Label1(15).Font, 100, 424, 256, 16, DT_VCENTER Or DT_SINGLELINE, &H80FF&, , True, False
 Else
  bc1a = False
 End If
 'mouse in button1b?
 r.Top = 440
 r.Bottom = 456
 b1b = PtInRect(r, p.x, p.y)
 If b1b Then
  DrawTextB bmG.hdc, sSource2, Label1(15).Font, 100, 440, 256, 16, DT_VCENTER Or DT_SINGLELINE, &H80FF&, , True, False
 Else
  bc1b = False
 End If
 'mouse in button1?
 r.Top = 456
 r.Bottom = 472
 b1 = PtInRect(r, p.x, p.y)
 If b1 Then
  DrawTextB bmG.hdc, Label1(15).Caption, Label1(15).Font, 100, 456, 256, 16, DT_VCENTER Or DT_SINGLELINE, &H80FF&, , True, False
 Else
  bc1 = False
 End If
 'mouse in button2?
 r.Left = 568
 r.Right = 632
 b2 = PtInRect(r, p.x, p.y)
 If b2 Then FrameRect bmG.hdc, r, hbr
 Game_Paint
 Sleep 20
 DoEvents
 'click button1?
 If b1 And Not bc1 Then
  If GetAsyncKeyState(1) And &H8000 Then
   bc1 = True
   ShellExecute Me.hwnd, "open", Label1(15).Caption, vbNullString, vbNullString, 5
  End If
 End If
 If b1a And Not bc1a Then
  If GetAsyncKeyState(1) And &H8000 Then
   bc1a = True
   ShellExecute Me.hwnd, "open", sSource1, vbNullString, vbNullString, 5
  End If
 End If
 If b1b And Not bc1b Then
  If GetAsyncKeyState(1) And &H8000 Then
   bc1b = True
   ShellExecute Me.hwnd, "open", sSource2, vbNullString, vbNullString, 5
  End If
 End If
 'click exit button?
 If b2 Then
  If GetAsyncKeyState(1) And &H8000 Then Exit Do
 End If
 If GameStatus < 0 Then
  DeleteObject hbr
  Exit Sub
 End If
Loop
'animation
For i = 255 To 0 Step -51
 bmG.Cls
 AlphaBlendA bmG.hdc, 0, 0, 640, 480, bmG_Back.hdc, 0, 0, , , i, False
 Game_Paint
 Sleep 10
 DoEvents
 If GameStatus < 0 Then Exit Sub
Next i
'clear up
DeleteObject hbr
End Sub

Private Sub Game_InitBack()
  bmG_Back.CreateFromPicture i0(7).Picture
  'draw text
  If GameIsRndMap Then
   DrawTextB bmG_Back.hdc, objText.GetText("Random Level") + txtGame(4).Tag, Me.Font, 8, 8, 480, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
   DrawTextB bmG_Back.hdc, objText.GetText("Seed:") + txtGame(0).Tag, Me.Font, 128, 8, 480, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
   'button
   bmImg(3).AlphaPaintPicture bmG_Back.hdc, 256, 9, 16, 16, 96, 32, , True
   DrawTextB bmG_Back.hdc, objText.GetText("Copy"), Me.Font, 272, 8, 48, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
  Else
   DrawTextB bmG_Back.hdc, Replace(objText.GetText("Level %d"), "%d", CStr(GameLev)) + Me.Tag, Me.Font, 8, 8, 480, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
  End If
  DrawTextB bmG_Back.hdc, objText.GetText("Moves"), Me.Font, 8, 24, 72, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
  DrawTextB bmG_Back.hdc, objText.GetText("Time used"), Me.Font, 8, 40, 72, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
  DrawTextB bmG_Back.hdc, objText.GetText("Retries"), Me.Font, 8, 56, 72, 16, DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
  DrawTextB bmG_Back.hdc, objText.GetText("Menu"), Me.Font, 600, 8, 32, 16, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbBlack, , True
End Sub

Private Sub Game_Paint()
bmG.PaintPicture p0(1).hdc
End Sub

Private Sub Game_InitMenu(ParamArray s())
Dim i As Long, lps As Long, lpe As Long
lps = LBound(s)
lpe = UBound(s)
GameMenuItemCount = lpe - lps + 1
ReDim GameMenuCaption(1 To GameMenuItemCount)
For i = lps To lpe
 GameMenuCaption(i - lps + 1) = s(i)
Next i
End Sub

Private Sub Game_LoadLevel(ByVal fn As String)
Dim i As Long, j As Long, k As Long, m As Long
Dim b As Boolean
fn = Replace(fn, vbNullChar, "")
fn = Replace(fn, "/", "\")
If f.LoadFile(fn, TheSignature) Then
 k = f.FindNodeArray("LEV")
 If k <> 0 Then
  Erase Lev
  LevCount = 0
  m = f.NodeCount(k)
  If m > 0 Then
   LevCount = m
   ReDim Lev(1 To m)
   For i = 1 To m
    Set Lev(i) = New clsBloxorz
    Lev(i).LoadLevel i, f
   Next i
   b = True
  End If
 End If
End If
If b Then
 Me.Tag = Replace(objText.GetText(" of %d ("), "%d", CStr(LevCount)) + Mid(fn, InStrRev(fn, "\") + 1) + ")"
Else
 Me.Tag = ""
 MsgBox objText.GetText("Wrong level!"), vbCritical
 ReDim Lev(1 To 1)
 LevCount = 1
 Set Lev(1) = New clsBloxorz
 With Lev(1)
  .Create 15, 10
  For i = 1 To 15
   For j = 1 To 10
    .Data(i, j) = 1
   Next j
  Next i
 End With
End If
GameLev = 1
End Sub

Private Sub Game_DrawLayer1(ByVal hdc As Long, Optional ByVal DrawBox As Boolean = True, Optional ByVal DrawBoxShadow As Boolean, Optional ByVal Index As Long, Optional ByVal Index2 As Long, Optional ByVal BoxDeltaY As Long, Optional ByVal BoxAlpha As Long = 255, Optional ByVal WithLayer0 As Boolean, Optional ByVal BoxDeltaX As Long, Optional ByVal NoZDepth As Boolean)
Dim i As Long, j As Long
Dim x As Long, y As Long, x2 As Long, y2 As Long, dy As Long
Dim FS As Long '1=for j,i 2=for i,j
Dim bx As Boolean
dy = BoxDeltaY
If NoZDepth Then BoxDeltaY = 0
'determine draw direction
Select Case GameFS
Case 0, 1, 2, 3, 4 '???
 Select Case GameS
 Case 0, 1, 3
  FS = 1
 Case 2
  FS = 2
 End Select
Case 1, 2 ', 5, 6 'up
 FS = 2
Case 3, 4 ', 7, 8
 FS = 1
End Select
bx = BoxDeltaY >= 0 And BoxDeltaY <= 32
'draw box first?
If DrawBox And (BoxDeltaY > 32 Or GameX > GameW Or GameY < 1) Then
 x = GameLayer0SX + (GameX - 1) * 32 + (GameY - 1) * 10 + BoxDeltaX
 y = GameLayer0SY - (GameX - 1) * 5 + (GameY - 1) * 16 + dy
 If DrawBoxShadow Then
  pGameDrawBox hdc, Index, Index2, x, y, BoxAlpha
 Else
  pTheBitmapDraw3 hdc, Index, Index2, x, y, BoxAlpha
 End If
End If
'draw
Select Case FS
Case 1
 x = GameLayer0SX + GameW * 32
 y = GameLayer0SY - GameW * 5
 For j = 1 To GameH
  x2 = x
  y2 = y
  For i = GameW To 1 Step -1
   x2 = x2 - 32
   y2 = y2 + 5
   If WithLayer0 Then pTheBitmapDraw3 hdc, Ani_Layer0, GameD(i, j), x2, y2
   Select Case GameD(i, j)
   Case 11
    pTheBitmapDraw3 hdc, Ani_Misc, 6, x2, y2
   End Select
   'draw box?
   If DrawBox And GameX = i And GameY = j And bx Then
    If DrawBoxShadow Then
     pGameDrawBox hdc, Index, Index2, x2 + BoxDeltaX, y2 + dy, BoxAlpha
    Else
     pTheBitmapDraw3 hdc, Index, Index2, x2 + BoxDeltaX, y2 + dy, BoxAlpha
    End If
   End If
   'draw box 2?
   If DrawBox And GameX2 = i And GameY2 = j And GameS = 3 Then
    If DrawBoxShadow Then
     pGameDrawBox hdc, 13, 1, x2, y2, BoxAlpha
    Else
     pTheBitmapDraw3 hdc, 13, 1, x2, y2, BoxAlpha
    End If
   End If
  Next i
  x = x + 10
  y = y + 16
 Next j
Case 2
 x = GameLayer0SX + GameW * 32
 y = GameLayer0SY - GameW * 5
 For i = GameW To 1 Step -1
  x = x - 32
  y = y + 5
  x2 = x
  y2 = y
  For j = 1 To GameH
   If WithLayer0 Then pTheBitmapDraw3 hdc, Ani_Layer0, GameD(i, j), x2, y2
   Select Case GameD(i, j)
   Case 11
    pTheBitmapDraw3 hdc, Ani_Misc, 6, x2, y2
   End Select
   'draw box?
   If DrawBox And GameX = i And GameY = j And bx Then
    If DrawBoxShadow Then
     pGameDrawBox hdc, Index, Index2, x2 + BoxDeltaX, y2 + dy, BoxAlpha
    Else
     pTheBitmapDraw3 hdc, Index, Index2, x2 + BoxDeltaX, y2 + dy, BoxAlpha
    End If
   End If
   'draw box 2?
   If DrawBox And GameX2 = i And GameY2 = j And GameS = 3 Then
    If DrawBoxShadow Then
     pGameDrawBox hdc, 13, 1, x2, y2, BoxAlpha
    Else
     pTheBitmapDraw3 hdc, 13, 1, x2, y2, BoxAlpha
    End If
   End If
   x2 = x2 + 10
   y2 = y2 + 16
  Next j
 Next i
End Select
'draw box last?
If DrawBox And (BoxDeltaY < 0 Or GameX < 1 Or GameY > GameH) Then
 x = GameLayer0SX + (GameX - 1) * 32 + (GameY - 1) * 10 + BoxDeltaX
 y = GameLayer0SY - (GameX - 1) * 5 + (GameY - 1) * 16 + dy
 If DrawBoxShadow Then
  pGameDrawBox hdc, Index, Index2, x, y, BoxAlpha
 Else
  pTheBitmapDraw3 hdc, Index, Index2, x, y, BoxAlpha
 End If
End If
End Sub

Private Sub pTheBitmapDraw2(ByVal hdc As Long, ByVal Index As Long, ByVal x As Long, ByVal y As Long, Optional ByVal Alpha As Byte = 255)
With bmps(Index)
 If .ImgIndex >= 0 Then
  bmImg(.ImgIndex).AlphaPaintPicture hdc, x - .dX, y - .dy, .w, .h, .x, .y, Alpha, True
 End If
End With
End Sub

Private Sub pTheBitmapDraw3(ByVal hdc As Long, ByVal Index As Long, ByVal Index2 As Long, ByVal x As Long, ByVal y As Long, Optional ByVal Alpha As Byte = 255)
With Anis(Index).bm(Index2)
 If .ImgIndex >= 0 Then
  bmImg(.ImgIndex).AlphaPaintPicture hdc, x - .dX, y - .dy, .w, .h, .x, .y, Alpha, True
 End If
End With
End Sub

Private Sub pGameDrawBox(ByVal hdc As Long, ByVal Index As Long, ByVal Index2 As Long, ByVal x As Long, ByVal y As Long, Optional ByVal Alpha As Byte = 255)
With Anis(Index + 30)
 If Index2 <= .Count Then
  With .bm(Index2)
   If .ImgIndex >= 0 Then
    bmImg(.ImgIndex).AlphaPaintPicture hdc, x - .dX, y - .dy, .w, .h, .x, .y, Alpha \ 2, True
   End If
  End With
 End If
End With
With Anis(Index).bm(Index2)
 If .ImgIndex >= 0 Then
  bmImg(.ImgIndex).AlphaPaintPicture hdc, x - .dX, y - .dy, .w, .h, .x, .y, Alpha, True
 End If
End With
End Sub

Private Sub pGameDrawLayer0(ByVal hdc As Long, d() As Byte, ByVal datw As Long, ByVal dath As Long, ByVal StartX As Long, ByVal StartY As Long)
Dim i As Long, j As Long, x As Long, y As Long
StartX = StartX + datw * 32
StartY = StartY - datw * 5
For i = datw To 1 Step -1
 StartX = StartX - 32
 StartY = StartY + 5
 x = StartX
 y = StartY
 For j = 1 To dath
  pTheBitmapDraw3 hdc, Ani_Layer0, d(i, j), x, y
  x = x + 10
  y = y + 16
 Next j
Next i
End Sub

Private Sub pLoadBitmapData(b() As Byte, ByVal Index As Long)
Dim i As Long, j As Long, m As Long
Dim lp As Long
lp = LBound(b)
CopyMemory m, b(lp), 4&
lp = lp + 4
For i = 1 To m
 CopyMemory j, b(lp), 4
 lp = lp + 4
 With bmps(j)
  .ImgIndex = Index
  CopyMemory .x, b(lp), 32&
  lp = lp + 32
 End With
Next i
End Sub

Private Sub pShowPanel(ByVal n As Long)
Dim i As Long
For i = 0 To p0.UBound
 p0(i).BorderStyle = 0
 p0(i).Visible = i = n
Next i
If n >= 0 Then
 With p0(n)
  .Move (Me.ScaleWidth - .Width) \ 2, (Me.ScaleHeight - .Height) \ 2
 End With
End If
End Sub

Private Sub chkPos_Click(Index As Integer)
Dim i As Long
If chkPos(Index).Value = 1 Then
 For i = 0 To chkPos.UBound
  If i <> Index Then chkPos(i).Value = 0
 Next i
End If
End Sub

Private Sub cmbBehavior_Click()
Dim lv As Long, i As Long, j As Long
lv = 1 + cmbLv.ListIndex
If lv > 0 Then
 i = 1 + cmbS.ListIndex
 j = 1 + lstSwitch.ListIndex
 With Lev(lv)
  If i > 0 And i <= .SwitchCount Then
   If j > 0 And j <= .SwitchBridgeCount(i) Then
    If .SwitchBridgeBehavior(i, j) <> cmbBehavior.ListIndex Then
     .SwitchBridgeBehavior(i, j) = cmbBehavior.ListIndex
     lstSwitch.List(j - 1) = CStr(.SwitchBridgeX(i, j)) + "," + CStr(.SwitchBridgeY(i, j)) + vbTab + cmbBehavior.List(.SwitchBridgeBehavior(i, j))
     pEditRedraw
    End If
   End If
  End If
 End With
End If
End Sub

Private Sub cmbLv_Click()
eSX = 0
eSY = 0
pEditRefresh
pEditSwitch
End Sub

Private Sub cmbS_Click()
Dim lv As Long, i As Long, j As Long
lv = 1 + cmbLv.ListIndex
If lv > 0 Then
 i = 1 + cmbS.ListIndex
 With Lev(lv)
  If i > 0 And i <= .SwitchCount Then
   lstSwitch.Clear
   For j = 1 To .SwitchBridgeCount(i)
    lstSwitch.AddItem CStr(.SwitchBridgeX(i, j)) + "," + CStr(.SwitchBridgeY(i, j)) + vbTab + cmbBehavior.List(.SwitchBridgeBehavior(i, j))
   Next j
   chkPos(3).Value = 0
   pEditRedraw
  End If
 End With
End If
End Sub

Private Sub cmbSt_Click()
pSolveRedraw
End Sub

Private Sub cmbSwitch_Click()
Dim lv As Long, i As Long, j As Long
lv = 1 + cmbLv.ListIndex
If lv > 0 Then
 With Lev(lv)
  If eSX > 0 And eSY > 0 And eSX <= .Width And eSY <= .Height Then
   i = cmbSwitch.ListIndex
   j = .Data(eSX, eSY)
   If j = 2 Or j = 3 Then
    If i <> .Data2(eSX, eSY) Then
     .Data2(eSX, eSY) = i
     pEditRedraw
    End If
    If i > 0 And i - 1 <> cmbS.ListIndex Then cmbS.ListIndex = i - 1
   End If
  End If
 End With
End If
End Sub

Private Sub cmd0_Click(Index As Integer)
Dim i As Long
i = Val(cmd0(Index).Tag)
pShowPanel i
Select Case i
Case 1
 Select Case Index
 Case 0
  Game_Init
 Case 2
  Instruction_Init
 End Select
Case 2
 cmdEdit_Click 0
End Select
'On Error Resume Next
If GameStatus = -2 Then Unload Me
End Sub

Private Sub cmdEdit_Click(Index As Integer)
Dim s As String, i As Long, j As Long, k As Long, m As Long
Dim x As Long, y As Long, x2 As Long, y2 As Long
Dim lv As Long
Select Case Index
Case 0 'new
 f.Clear
 f.Signature = TheSignature
 LevCount = 1
 ReDim Lev(1 To 1)
 Set Lev(1) = New clsBloxorz
 Lev(1).Create 15, 10
 Lev(1).StartX = 1
 Lev(1).StartY = 1
 cmbLv.Clear
 cmbLv.AddItem "1"
 cmbLv.ListIndex = 0
 Me.Caption = objText.GetText("Turning Square")
Case 1 'open
 If cd.VBGetOpenFileName(s, , , , , True, objText.GetText("Turning Square level pack|*.box"), , CStr(App.Path), , , Me.hwnd) Then
  If f.LoadFile(s, TheSignature) Then
   k = f.FindNodeArray("LEV")
   If k <> 0 Then
    Erase Lev
    LevCount = 0
    cmbLv.Clear
    m = f.NodeCount(k)
    If m > 0 Then
     LevCount = m
     ReDim Lev(1 To m)
     For i = 1 To m
      Set Lev(i) = New clsBloxorz
      Lev(i).LoadLevel i, f
      cmbLv.AddItem CStr(i)
     Next i
     cmbLv.ListIndex = 0
    End If
   End If
   Me.Caption = objText.GetText("Turning Square") + " - " + s
  Else
   MsgBox objText.GetText("Error")
  End If
 End If
Case 2 'save
 s = f.FileName
 If cd.VBGetSaveFileName(s, , , objText.GetText("Turning Square level pack|*.box"), , CStr(App.Path), , "box", Me.hwnd) Then
  '??
  f.Clear
  f.Signature = TheSignature
  For i = 1 To LevCount
   Lev(i).SaveLevel i, f
  Next i
  If f.SaveFile(s) Then
   Me.Caption = objText.GetText("Turning Square") + " - " + s
  Else
   MsgBox objText.GetText("Error")
  End If
 End If
Case 3 'exit
 Erase Lev
 LevCount = 0
 f.Clear
 pShowPanel 0
 Me.Caption = objText.GetText("Turning Square")
Case 4 'add
 i = 15
 j = 10
 lv = 1 + cmbLv.ListIndex
 If lv > 0 Then
  i = Lev(lv).Width
  j = Lev(lv).Height
 End If
 LevCount = LevCount + 1
 ReDim Preserve Lev(1 To LevCount)
 Set Lev(LevCount) = New clsBloxorz
 Lev(LevCount).Create i, j
 cmbLv.AddItem CStr(LevCount)
 cmbLv.ListIndex = LevCount - 1
Case 5 'delete
 lv = 1 + cmbLv.ListIndex
 If lv > 0 And LevCount > 1 Then
  If MsgBox(objText.GetText("Are you sure?"), vbExclamation + vbYesNo) = vbYes Then
   LevCount = LevCount - 1
   Set Lev(lv) = Nothing
   For i = lv To LevCount
    Set Lev(i) = Lev(i + 1)
   Next i
   ReDim Preserve Lev(1 To LevCount)
   cmbLv.Clear
   For i = 1 To LevCount
    cmbLv.AddItem CStr(i)
   Next i
   If lv > LevCount Then lv = LevCount
   cmbLv.ListIndex = lv - 1
  End If
 End If
Case 6 'resize
 lv = 1 + cmbLv.ListIndex
 If lv > 0 Then
  With Lev(lv)
   On Error Resume Next
   s = InputBox(objText.GetText("Input map size:"), , CStr(.Width) + " x " + CStr(.Height))
   i = InStr(1, s, "x", vbTextCompare)
   If i > 0 Then
    j = Val(Mid(s, i + 1))
    i = Val(Left(s, i - 1))
    If i > 0 And j > 0 And i <= 255 And j <= 255 And Err.Number = 0 Then
     .Create i, j
     eSX = 0
     eSY = 0
     pEditRefresh
     pEditSwitch
    End If
   End If
  End With
 End If
Case 7 'add switch
 lv = 1 + cmbLv.ListIndex
 If lv > 0 Then
  With Lev(lv)
   .AddSwitch
   cmbS.AddItem CStr(.SwitchCount)
   cmbSwitch.AddItem CStr(.SwitchCount)
  End With
 End If
Case 8 'remove switch
 lv = 1 + cmbLv.ListIndex
 If lv > 0 Then
  With Lev(lv)
   i = 1 + cmbS.ListIndex
   If i > 0 And i <= .SwitchCount Then
    If .SwitchCount > 1 Then
     .RemoveSwitch i
     pEditSwitch
     If i > .SwitchCount Then i = .SwitchCount
     cmbS.ListIndex = i - 1
    Else
     .ClearSwitch
     pEditSwitch
    End If
   End If
  End With
 End If
Case 9 'add bridge
 lv = 1 + cmbLv.ListIndex
 If lv > 0 Then
  With Lev(lv)
   i = 1 + cmbS.ListIndex
   If i > 0 And i <= .SwitchCount Then
    .AddSwitchBridge i
    lstSwitch.AddItem "0,0" + vbTab + cmbBehavior.List(0)
   End If
  End With
 End If
Case 10 'remove bridge
 lv = 1 + cmbLv.ListIndex
 If lv > 0 Then
  i = 1 + cmbS.ListIndex
  j = 1 + lstSwitch.ListIndex
  With Lev(lv)
   If i > 0 And i <= .SwitchCount Then
    If j > 0 And j <= .SwitchBridgeCount(i) Then
     .RemoveSwitchBridge i, j
     cmbS_Click
    End If
   End If
  End With
 End If
Case 11 'clear bridge
 lv = 1 + cmbLv.ListIndex
 If lv > 0 Then
  With Lev(lv)
   i = 1 + cmbS.ListIndex
   If i > 0 And i <= .SwitchCount Then
    .ClearSwitchBridge i
    cmbS_Click
   End If
  End With
 End If
Case 15 'clear
 lv = 1 + cmbLv.ListIndex
 If lv > 0 Then
  With Lev(lv)
   .Clear
   eSX = 0
   eSY = 0
   pEditRefresh
   pEditSwitch
  End With
 End If
Case 12 'solve
 lv = 1 + cmbLv.ListIndex
 If lv > 0 Then
  pShowPanel 4
  DoEvents
  With Lev(lv)
   If .SolveIt(Me) Then
    pShowPanel 3
    txtGame(3).Text = ""
    cmbSt.Clear
    For i = 1 To .SolveItGetSwitchStatusCount
     cmbSt.AddItem CStr(i)
    Next i
    sSX = 0
    sSY = 0
    cmbSt.ListIndex = 0
    optSt(0).Value = True
    optSt(3).Enabled = .SolveItIsTrans
    i = .SolveItGetTimeUsed
    j = .SolveItGetNodeUsed
    s = objText.GetText("Time=") + CStr(i) + objText.GetText("ms, Nodes=") + CStr(j) + "/" + CStr(.SolveItGetNodeMax)
    If i > 0 Then s = s + vbCr + CStr(Round(j / i * 1000)) + objText.GetText("Nodes/s")
    Label1(14).Caption = s
    pSolution.Move 0, 24, bmEdit.Width + 4, bmEdit.Height + 4
   Else
    MsgBox objText.GetText("Error!!!"), vbCritical
    Lev(lv).SolveItClear
    pShowPanel 2
   End If
  End With
 End If
Case 13 'return
 lv = 1 + cmbLv.ListIndex
 If lv > 0 Then
  Lev(lv).SolveItClear
 End If
 pEditRedraw
 pShowPanel 2
Case 14 'show solution
 lv = 1 + cmbLv.ListIndex
 If lv > 0 Then
  With Lev(lv)
   m = .SolveItGetSolutionNodeIndex(x2, y2, k)
   If m = 0 Then
    txtGame(3).Text = objText.GetText("No solution.")
   Else
    optSt(0).Value = True
    sSX = x2
    sSY = y2
    cmbSt.ListIndex = k - 1
    pSolveRedraw
   End If
  End With
 End If
Case 16 'generateRnd
 If cmdEdit(17).Enabled Then
  cmdEdit(16).Caption = objText.GetText("&Abort")
  cmdEdit(17).Enabled = False
  pEditRandomMap
  cmdEdit(16).Caption = objText.GetText("&Generate")
  cmdEdit(17).Enabled = True
 Else 'abort
  GameStatus = -1
 End If
Case 17 'cancelRnd
 pShowPanel 2
Case 18 'showRnd
 cmdEdit_Click 19
 pShowPanel 6
Case 19 'newRndSeed
 txtGame(1).Text = objRnd.RndSeed
End Select
End Sub

Private Sub Command1_Click()
'currently do nothing
End Sub

'random map test
Private Sub pEditRandomMap()
Dim s As String
Dim xx As New clsBloxorz
Dim lv As Long, i As Long
lv = 1 + cmbLv.ListIndex
If lv <= 0 Then Exit Sub
s = txtGame(1).Text
i = Val(s)
If i > 0 And i <= cmbMode.ListCount Then cmbMode.ListIndex = i - 1 Else i = cmbMode.ListIndex + 1
GameStatus = 0
DoEvents
'start
objRnd.Randomize s
With Lev(lv)
 If chk1.Value Then
  i = pRandomMap(xx, , , Lev(lv), 200, 30, i) 'TODO:time?
 Else
  i = pRandomMap(xx, .Width, .Height, , 200, 30, i) 'TODO:time?
 End If
 If GameStatus < 0 Then
  MsgBox objText.GetText("Aborted!")
 ElseIf i = 0 Then
  MsgBox objText.GetText("Failed!")
 Else
  If MsgBox(Replace(objText.GetText("Moves=%d. Apply?"), "%d", CStr(i)), vbYesNo + vbQuestion) = vbYes Then
   .Clone xx
   eSX = 0
   eSY = 0
   pEditRefresh
   pEditSwitch
  End If
 End If
End With
cmdEdit_Click 19
Label1(20).Width = 1
End Sub

'random map
Private Sub Game_RndMap_Run()
Dim s As String
Dim xx As New clsBloxorz
Dim i As Long
s = txtGame(4).Text
i = cmbMode.ListIndex + 1
Do
 objRnd.Randomize s
 If pRandomMap(xx, , , , , , i) Then Exit Do 'TODO:time? map size?
 If GameStatus < 0 Then Exit Sub
 s = objRnd.RndSeed
Loop
Lev(GameLev).Clone xx
txtGame(0).Tag = CStr(i) + objRnd.ValidateRndSeed(s)
txtGame(4).Tag = "(" + cmbMode.Text + ")"
End Sub

Private Sub Form_Initialize()
InitCommonControls
End Sub

Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
Dim lv As Long
Dim obj As New clsBloxorz
If p0(2).Visible Then
 If Shift = vbCtrlMask Then
  Select Case KeyCode
  Case vbKeyX
  Case vbKeyC
   lv = 1 + cmbLv.ListIndex
   If lv <= 0 Then Exit Sub
   Lev(lv).CopyToClipboard
  Case vbKeyV
   lv = 1 + cmbLv.ListIndex
   If lv <= 0 Then Exit Sub
   If obj.PasteFromClipboard Then
    Lev(lv).Clone obj
    eSX = 0
    eSY = 0
    pEditRefresh
    pEditSwitch
   End If
  End Select
 End If
End If
End Sub

Private Function ISort_Compare(ByVal Index1 As Long, ByVal Index2 As Long, ByVal nUserData As Long) As Boolean
ISort_Compare = nFitness(Index1) < nFitness(Index2)
End Function

'stupidly, we use genetic algorithm again ... :-3
Private Function pRandomMap(objRet As clsBloxorz, Optional ByVal w As Long = 15, Optional ByVal h As Long = 10, Optional objInit As clsBloxorz, Optional ByVal PoolSize As Long = 200, Optional ByVal nTime As Long = 30, Optional ByVal nMode As Long = 1) As Long
Dim objSort As New ISort
Dim Pool() As New clsBloxorz
Dim idx() As Long 'right level
Dim idx2() As Long 'wrong level (??)
Dim idxSol() As Long 'solution index
Dim d() As Byte
Dim i As Long, j As Long, k As Long
Dim x As Long, y As Long
Dim sx As Long, sy As Long
Dim m As Long, ma As Long, mb As Long 'all count,right count,wrong count :-3
Dim t As Long
Dim ttt As Long 'time
'init array
ReDim Pool(1 To PoolSize)
ReDim nFitness(1 To PoolSize)
ReDim idx(1 To PoolSize)
ReDim idx2(1 To PoolSize)
ReDim idxSol(1 To PoolSize)
m = 1
'init state
If Not objInit Is Nothing Then
 With Pool(1)
  .Clone objInit
  w = .Width
  h = .Height
  sx = .StartX
  sy = .StartY
  'determine start
  If sx < 1 Or sx > w Or sy < 1 Or sy > h Then 'stupid!!!
   sx = 1 + Int(w * objRnd.Rnd / 4)
   sy = 1 + Int(h * objRnd.Rnd)
   .StartX = sx
   .StartY = sy
  End If
  .Data(sx, sy) = 1
  'determine end point
  If .GetSpecifiedObjectCount(8) = 0 Then 'stupid!!!
   x = w - Int(w * objRnd.Rnd / 4)
   y = 1 + Int(h * objRnd.Rnd)
   .Data(x, y) = 8
  End If
 End With
Else
 With Pool(1)
  .Create w, h
  'create a random map which is stupid
  For i = 1 To w
   For j = 1 To h
    '///
    Select Case nMode
    Case 4 'zigzag
     x = 1
     If j = (h + 1) \ 3 Then
      If i <= (w + w) \ 3 Then x = 0
     ElseIf j = (h + h + 2) \ 3 Then
      If i > w \ 3 Then x = 0
     End If
     If x Then
      x = 1 + Int(1.6 * objRnd.Rnd)
      If x = 2 Then x = 5
     End If
    Case 5 'ice mode
     x = Int(5 * objRnd.Rnd)
     If x >= 2 Then x = 9
    Case 6 'fragile mode
     x = Int(5 * objRnd.Rnd)
     If x >= 2 Then x = 5
    Case Else
     x = Int(3 * objRnd.Rnd)
     If x = 2 Then If nMode = 1 Then x = 1 Else x = 5
    End Select
    '///
    .Data(i, j) = x
   Next j
  Next i
  'determine start
  Select Case nMode
  Case 4 'zigzag
   sx = 1 + Int(w * objRnd.Rnd / 4)
   sy = 1 + Int(h * objRnd.Rnd / 4)
  Case Else
   sx = 1 + Int(w * objRnd.Rnd / 4)
   sy = 1 + Int(h * objRnd.Rnd)
  End Select
  .Data(sx, sy) = 1
  .StartX = sx
  .StartY = sy
  'determine end point
  Select Case nMode
  Case 4 'zigzag
   x = w - Int(w * objRnd.Rnd / 4)
   y = h - Int(h * objRnd.Rnd / 4)
  Case Else
   x = w - Int(w * objRnd.Rnd / 4)
   y = 1 + Int(h * objRnd.Rnd)
  End Select
  .Data(x, y) = 8
  If nMode = 3 Then 'just add some button
   i = 0
   Do Until objRnd.Rnd < 0.5
    x = 1 + Int(w * objRnd.Rnd)
    y = 1 + Int(h * objRnd.Rnd)
    If x <> sx Or y <> sy Then
     Select Case .Data(x, y)
     Case 2, 3, 6, 7, 8
     Case Else
      .Data(x, y) = 2 + Int(2 * objRnd.Rnd)
      i = i + 1
      .Data2(x, y) = i
      .AddSwitch
      'just add some bridge
      Do
       x = 1 + Int(w * objRnd.Rnd)
       y = 1 + Int(h * objRnd.Rnd)
       If x <> sx Or y <> sy Then
        Select Case .Data(x, y)
        Case 2, 3, 8
        Case Else
         .Data(x, y) = 6 + Int(2 * objRnd.Rnd)
         .AddSwitchBridge i, x, y, Int(3 * objRnd.Rnd)
        End Select
       End If
      Loop Until objRnd.Rnd < 0.5
     End Select
    End If
   Loop
  End If
 End With
End If
ReDim d(1 To w, 1 To h)
'start
ttt = 1
Do
 'calc fitness
 ma = 0
 mb = 0
 For k = 1 To m
  With Pool(k)
   If .SolveIt Then
    j = .SolveItGetSolutionNodeIndex
    If j = 0 Then i = 0 Else i = .SolveItGetDistance(j)
   Else 'failed!!!
    Debug.Assert False
    Exit Function
   End If
   If i = 0 Or i = &H7FFFFFFF Then
    mb = mb + 1
    idx2(mb) = k
    nFitness(k) = &HC0000000 + .SolveItGetNodeUsed
   Else
    ma = ma + 1
    idx(ma) = k
    nFitness(k) = i
    idxSol(k) = j
   End If
  End With
  'abort?
  If GameStatus < 0 Then Exit Function
 Next k
 'sort it
 If ma > 0 Then objSort.QuickSort idx, 1, ma, Me, 0
 If mb > 0 Then objSort.QuickSort idx2, 1, mb, Me, 0
 'over?
 'show progress
 If p0(1).Visible Then
  Game_RndMap_Progress ttt, nTime
  DoEvents
 Else
  Label1(20).Width = 1 + ((Label1(19).Width - 2) * ttt) \ nTime
  DoEvents
 End If
 If ttt >= nTime Then Exit Do
 ttt = ttt + 1
 'reproduction count=1 ???? TODO:crossover ????
 'mutation
 For k = 1 To ma
  'get new pos
  If m < PoolSize Then
   m = m + 1
   j = m
  Else
   If ma <= k Then Exit For
   j = idx(ma)
   ma = ma - 1
  End If
  Pool(j).Clone Pool(idx(k))
  With Pool(idx(k))
   .SolveItGetSolution idxSol(idx(k)), VarPtr(d(1, 1))
   t = 0
   Do
    x = 1 + Int(w * objRnd.Rnd)
    y = 1 + Int(h * objRnd.Rnd)
    If x <> sx And y <> sy And d(x, y) = 1 Then
     Select Case .Data(x, y)
     Case 1, 5
      '///change this point is OK
      Select Case nMode
      Case 1
       i = 0
      Case 2
       i = Int(2 * objRnd.Rnd)
       If i = 1 Then i = 5
      Case 5 'ice mode
       i = Int(4 * objRnd.Rnd)
       If i > 0 Then i = i - 1
       i = i + 9
      Case 6 'fragile mode
       i = Int(3 * objRnd.Rnd)
       If i = 1 Then i = 5 Else If i = 2 Then i = 10
      Case Else
       i = Int(4 * objRnd.Rnd)
       If i = 1 Then i = 5 Else If i >= 2 Then i = i + 7
      End Select
      .Data(x, y) = i
      '///
      If objRnd.Rnd < 0.5 Then Exit Do
     End Select
    End If
    t = t + 1
   Loop Until t > 200
  End With
 Next k
 'mutation2
 For k = 1 To mb
  'get new pos
  If m < PoolSize Then
   m = m + 1
   j = m
  Else
   If mb < k Then Exit For
   j = idx2(mb)
   mb = mb - 1
  End If
  With Pool(idx2(k)) 'flood-fill check
   .SolveItGetCanMoveArea d
   'expand von-neumann
   For x = 1 To w
    For y = 1 To h
     If d(x, y) = 1 Then
      If x > 1 Then If d(x - 1, y) = 0 Then d(x - 1, y) = 2
      If x < w Then If d(x + 1, y) = 0 Then d(x + 1, y) = 2
      If y > 1 Then If d(x, y - 1) = 0 Then d(x, y - 1) = 2
      If y < h Then If d(x, y + 1) = 0 Then d(x, y + 1) = 2
     End If
    Next y
   Next x
'   '(x2??)
'   For x = 1 To w
'    For y = 1 To h
'     If d(x, y) = 2 Then
'      If x > 1 Then If d(x - 1, y) = 0 Then d(x - 1, y) = 3
'      If x < w Then If d(x + 1, y) = 0 Then d(x + 1, y) = 3
'      If y > 1 Then If d(x, y - 1) = 0 Then d(x, y - 1) = 3
'      If y < h Then If d(x, y + 1) = 0 Then d(x, y + 1) = 3
'     End If
'    Next y
'   Next x
   'random select
   t = 0
   Do
    x = 1 + Int(w * objRnd.Rnd)
    y = 1 + Int(h * objRnd.Rnd)
    If x <> sx And y <> sy And d(x, y) > 1 Then 'd(x,y)>1 '???
     Select Case .Data(x, y)
     Case 0, 5, 9, 10, 11
      '///change this point is OK
      .Data(x, y) = 1
      '///
      If objRnd.Rnd < 0.2 Then Exit Do
     End Select
    End If
    t = t + 1
   Loop Until t > 200
  End With
  'reproduce
  If mb < k Then Exit For
  Pool(j).Clone Pool(idx2(k))
  'even more random
  With Pool(j)
   For i = 1 To 20
    x = 1 + Int(w * objRnd.Rnd)
    y = 1 + Int(h * objRnd.Rnd)
    If x <> sx And y <> sy Then
     Select Case .Data(x, y)
     Case 0, 5 ', 9 , 10, 11
      '///change this point is OK
      .Data(x, y) = 1
      '///
     End Select
    End If
   Next i
  End With
 Next k
Loop
'output result
If ma > 0 Then
 k = idx(1)
 With Pool(k)
  '///delete unused!?!?
  .SolveItGetSolution idxSol(k), VarPtr(d(1, 1))
  'expand von-neumann neighbors
  For i = 1 To w
   For j = 1 To h
    If d(i, j) = 1 Then
     If i > 1 Then If d(i - 1, j) = 0 Then d(i - 1, j) = 2
     If i < w Then If d(i + 1, j) = 0 Then d(i + 1, j) = 2
     If j > 1 Then If d(i, j - 1) = 0 Then d(i, j - 1) = 2
     If j < h Then If d(i, j + 1) = 0 Then d(i, j + 1) = 2
    End If
   Next j
  Next i
  'expand transport area and button
  For i = 1 To w
   For j = 1 To h
    x = .Data(i, j)
    Select Case x
    Case 4
     .GetTransportPosition i, j, x, y, sx, sy
     If x >= 1 And y >= 1 And x <= w And y <= h Then d(x, y) = 1
     If sx >= 1 And sy >= 1 And sx <= w And sy <= h Then d(sx, sy) = 1
    Case 2, 3, 6, 7
     d(i, j) = 1
    End Select
   Next j
  Next i
  'delete
  For i = 1 To w
   For j = 1 To h
    If d(i, j) = 0 Then
     Select Case .Data(i, j)
     Case 2, 3, 4, 8
     Case Else
      .Data(i, j) = 0
     End Select
    End If
   Next j
  Next i
  '///
 End With
 objRet.Clone Pool(k)
 pRandomMap = nFitness(k)
End If
End Function

Private Sub Form_Load()
'///
If Not objText.LoadFileWithLocale(CStr(App.Path) + "\locale\*.mo") Then _
objText.LoadFile CStr(App.Path) + "\locale\default.mo"
'///
Me.Show
Me.Caption = objText.GetText("Turning Square")
Randomize Timer
pShowPanel 0
p0(1).Move 0, 0, 640, 480
p0(3).Height = 472
Set sEdit = New cScrollBar
With sEdit
 .Create pEdit.hwnd
 .Visible(efsHorizontal) = True
 .Visible(efsVertical) = True
 .Enabled(efsHorizontal) = False
 .Enabled(efsVertical) = False
 .SmallChange(efsHorizontal) = 10
 .SmallChange(efsVertical) = 10
End With
pInitBitmap
With cmbBehavior
 .AddItem objText.GetText("Close")
 .AddItem objText.GetText("Open")
 .AddItem objText.GetText("Toggle")
End With
With cmbMode
 .AddItem objText.GetText("Beginner")
 .AddItem objText.GetText("Intermediate")
 .AddItem objText.GetText("Advanced")
 .AddItem objText.GetText("Zigzag")
 .AddItem objText.GetText("Ice mode")
 .AddItem objText.GetText("Fragile mode")
 .ListIndex = 2
End With
pEditSelect
'///
cmdEdit(17).Caption = objText.GetText("&Close")
cmdEdit(16).Caption = objText.GetText("&Generate")
chk1.Caption = objText.GetText("Use current level as template")
Frame1(2).Caption = objText.GetText("Random map")
Label1(16).Caption = objText.GetText("Mode")
Label1(17).Caption = objText.GetText("Seed")
Label1(18).Caption = objText.GetText("Iterations")
cmd0(2).Caption = objText.GetText("Game instructions")
cmd0(1).Caption = objText.GetText("Editor/Solver")
cmd0(0).Caption = objText.GetText("Start game")
cmdEdit(14).Caption = objText.GetText("&Solution")
optSt(3).Caption = objText.GetText("Single")
optSt(2).Caption = objText.GetText("Vertical")
optSt(1).Caption = objText.GetText("Horizontal")
optSt(0).Caption = objText.GetText("Up")
cmdEdit(13).Caption = objText.GetText("&Close")
cmdEdit(18).Caption = objText.GetText("Random Map(Beta)")
chkPos(3).Caption = objText.GetText("Set")
chkPos(2).Caption = objText.GetText("Set")
chkPos(1).Caption = objText.GetText("Set")
chkPos(0).Caption = objText.GetText("Set")
cmdEdit(15).Caption = objText.GetText("&Clear")
cmdEdit(12).Caption = objText.GetText("Solve...")
cmdEdit(11).Caption = objText.GetText("Clear")
optMode(1).Caption = objText.GetText("Select")
optMode(0).Caption = objText.GetText("Edit")
Label1(2).Caption = objText.GetText("Pos2")
Label1(1).Caption = objText.GetText("Pos1")
Label1(0).Caption = objText.GetText("Button number")
Frame1(0).Caption = objText.GetText("Properties")
Label1(5).Caption = objText.GetText("No properties.")
cmdEdit(6).Caption = objText.GetText("&Resize")
cmdEdit(5).Caption = objText.GetText("&Delete")
cmdEdit(4).Caption = objText.GetText("&Add")
cmdEdit(3).Caption = objText.GetText("&Quit")
cmdEdit(2).Caption = objText.GetText("&Save")
cmdEdit(1).Caption = objText.GetText("&Open")
cmdEdit(0).Caption = objText.GetText("&New")
Frame1(1).Caption = objText.GetText("Buttons")
Label1(9).Caption = objText.GetText("Behavior")
Label1(7).Caption = objText.GetText("Pos")
Label1(6).Caption = objText.GetText("No.")
Label1(12).Caption = objText.GetText("Start pos")
Label1(11).Caption = objText.GetText("Solving...")
Label1(10).Caption = objText.GetText("Solving...")
'///
End Sub

Private Sub pInitBitmap()
Dim bm As New cAlphaDibSection
Dim b() As Byte, b2() As Byte
Dim i As Long, m As Long
'bmG.Create 640, 480
'//////////////////load block
bmImg(0).CreateFromPicture i0(0).Picture
bm.CreateFromPicture i0(1).Picture
m = bm.BytesPerScanLine * bm.Height
ReDim b(1 To m)
ReDim b2(1 To m)
CopyMemory b(1), ByVal bmImg(0).DIBSectionBitsPtr, m
CopyMemory b2(1), ByVal bm.DIBSectionBitsPtr, m
For i = 1 To m Step 4
 b(i + 3) = b2(i)
Next i
CopyMemory ByVal bmImg(0).DIBSectionBitsPtr, b(1), m
'//////////////////load shadow
bmImg(1).CreateFromPicture i0(2).Picture
bm.CreateFromPicture i0(3).Picture
m = bm.BytesPerScanLine * bm.Height
ReDim b(1 To m)
ReDim b2(1 To m)
CopyMemory b(1), ByVal bmImg(1).DIBSectionBitsPtr, m
CopyMemory b2(1), ByVal bm.DIBSectionBitsPtr, m
For i = 1 To m Step 4
 b(i + 3) = b2(i)
Next i
CopyMemory ByVal bmImg(1).DIBSectionBitsPtr, b(1), m
'//////////////////load edit
bmImg(2).CreateFromPicture i0(4).Picture
'//////////////////load block2
bmImg(3).CreateFromPicture i0(5).Picture
bm.CreateFromPicture i0(6).Picture
m = bm.BytesPerScanLine * bm.Height
ReDim b(1 To m)
ReDim b2(1 To m)
CopyMemory b(1), ByVal bmImg(3).DIBSectionBitsPtr, m
CopyMemory b2(1), ByVal bm.DIBSectionBitsPtr, m
For i = 1 To m Step 4
 b(i + 3) = b2(i)
Next i
CopyMemory ByVal bmImg(3).DIBSectionBitsPtr, b(1), m
'//////////////////load bitmap data
For i = LBound(bmps) To UBound(bmps)
 bmps(i).ImgIndex = -1
Next i
With f
 .LoadData LoadResData(101, "CUSTOM")
 .GetNodeData 1, 1, b
 pLoadBitmapData b, 0
 .GetNodeData 1, 2, b
 pLoadBitmapData b, 1
 .Clear
End With
'//////////////////load bitmap array
ReDim Anis(1 To 100)
'layer 0
With Anis(Ani_Layer0)
 ReDim .bm(11)
 .bm(0).ImgIndex = -1 'empty
 pTheBitmapConvert bmps(108), .bm(1), 4, 8 'block
 pTheBitmapConvert bmps(119), .bm(2), 4, 8 'soft
 pTheBitmapConvert bmps(120), .bm(3), 4, 8 'heavy
 pTheBitmapConvert bmps(130), .bm(4), 4, 10 'transport
 pTheBitmapConvert bmps(131), .bm(5), 4, 8 'thin
 .bm(6) = .bm(0) 'bridge off
 With .bm(7) 'bridge on
  .ImgIndex = 3
  .x = 44
  .y = 28
  .w = 44
  .h = 28
  .dX = 0
  .dy = 5
 End With
 pTheBitmapConvert bmps(121), .bm(8), 5, 11 'end
 With .bm(9) 'ice
  .ImgIndex = 3
  .x = 0
  .y = 0
  .w = 44
  .h = 28
  .dX = 0
  .dy = 5
 End With
 With .bm(10) 'pyramid
  .ImgIndex = 3
  .x = 0
  .y = 28
  .w = 44
  .h = 28
  .dX = 0
  .dy = 5
 End With
 .bm(11) = .bm(1) 'stone TODO:layer 1
End With
'///////////////////////////////////////////////////////box animation
'state=up,direction=up
pInitBoxAnimation 1, 10, 366, 80, 98
'state=up,direction=down
pInitBoxAnimation 2, 10, 386, 80, 98
'state=up,direction=left
With Anis(3)
 .Count = 9
 ReDim .bm(1 To .Count)
 For i = 1 To 7
  pTheBitmapConvert bmps(i + 28), .bm(i), 80, 98
 Next i
 For i = 8 To 9
  pTheBitmapConvert bmps(i + 1), .bm(i), 80, 98
 Next i
End With
'state=up,direction=right
pInitBoxAnimation 4, 10, 376, 80, 98
'state=h,direction=up
pInitBoxAnimation 5, 9, 10, 80, 98
'state=h,direction=down
pInitBoxAnimation 6, 10, 448, 80, 98 'count=11?
'state=h,direction=left
pInitBoxAnimation 7, 9, 19, 80, 98
'state=h,direction=right
pInitBoxAnimation 8, 10, 438, 80, 98
'state=v,direction=up
pInitBoxAnimation 9, 10, 406, 70, 82
'state=v,direction=down
pInitBoxAnimation 10, 10, 426, 70, 82
'state=v,direction=left
pInitBoxAnimation 11, 10, 396, 70, 82
'state=v,direction=right
pInitBoxAnimation 12, 10, 416, 70, 82
'state=single,direction=up
pInitBoxAnimation 13, 10, 316, 80, 98
'state=single,direction=down
pInitBoxAnimation 14, 9, 336, 80, 98
'state=single,direction=left
pInitBoxAnimation 15, 9, 307, 80, 98
'state=single,direction=right
pInitBoxAnimation 16, 10, 326, 80, 98
'start
pInitBoxAnimation 29, 12, 504, 80, 98
'end
pInitBoxAnimation 30, 8, 516, 80, 98
'///////////////////////////////////////////////////////box shadow animation
'state=up,direction=up
pInitBoxAnimation 31, 10, 141, 80, 98
'state=up,direction=down
pInitBoxAnimation 32, 10, 161, 80, 98
'state=up,direction=left
pInitBoxAnimation 33, 9, 131, 80, 98
'state=up,direction=right
pInitBoxAnimation 34, 10, 151, 80, 98
'state=h,direction=up
pInitBoxAnimation 35, 9, 221, 80, 98
'state=h,direction=down
pInitBoxAnimation 36, 10, 241, 80, 98
'state=h,direction=left
pInitBoxAnimation 37, 9, 211, 80, 98
'state=h,direction=right
pInitBoxAnimation 38, 10, 231, 37, 98 '?
'state=v,direction=up
pInitBoxAnimation 39, 10, 181, 70, 82
'state=v,direction=down
pInitBoxAnimation 40, 10, 201, 70, 82
'state=v,direction=left
pInitBoxAnimation 41, 10, 171, 70, 82
'state=v,direction=right
pInitBoxAnimation 42, 10, 191, 70, 82
'state=single,direction=up
pInitBoxAnimation 43, 10, 275, 80, 98
'state=single,direction=down
pInitBoxAnimation 44, 9, 295, 80, 98
'state=single,direction=left
pInitBoxAnimation 45, 9, 265, 80, 98
'state=single,direction=right
pInitBoxAnimation 46, 10, 285, 80, 98
'start
pInitBoxAnimation 59, 12, 253, 80, 98
'///////////////////////////////////////////////////////fall animation
'state=up,dir=up
pInitBoxAnimation 71, 9, 35, 80, 98, True
'state=up,dir=down
pInitBoxAnimation 72, 9, 35, 80, 98
'state=up,dir=left
pInitBoxAnimation 73, 9, 459, 80, 98
'state=up,dir=right
pInitBoxAnimation 74, 9, 459, 80, 98, True
'state=h,dir=up
pInitBoxAnimation 75, 9, 494, 80, 98, True
'state=h,dir=down
pInitBoxAnimation 76, 9, 494, 80, 98
'state=h,dir=left
pInitBoxAnimation 77, 9, 485, 80, 98
'state=h,dir=right
pInitBoxAnimation 78, 9, 485, 80, 98, True
'state=v,dir=up
pInitBoxAnimation 79, 9, 467, 70, 82
'state=v,dir=down
pInitBoxAnimation 80, 9, 467, 70, 82, True
'state=v,dir=left
pInitBoxAnimation 81, 9, 476, 70, 82, True
'state=v,dir=right
pInitBoxAnimation 82, 9, 476, 70, 82
'state=single,dir=up
pInitBoxAnimation 83, 9, 356, 80, 98
'state=single,dir=down
pInitBoxAnimation 84, 9, 356, 80, 98, True
'state=single,dir=left
pInitBoxAnimation 85, 9, 347, 80, 98
'state=single,dir=right
pInitBoxAnimation 86, 9, 347, 80, 98, True
'misc
With Anis(Ani_Misc)
 ReDim .bm(1 To 20)
 With .bm(1) 'bridge off
  .ImgIndex = 3
  .x = 88
  .y = 0
  .w = 44
  .h = 28
  .dX = 0
  .dy = 5
 End With
 With .bm(2) 'bridge on
  .ImgIndex = 3
  .x = 44
  .y = 0
  .w = 44
  .h = 28
  .dX = 0
  .dy = 5
 End With
 With .bm(3) '"["
  .ImgIndex = 0
  .w = bmps(307).w \ 2
  .h = bmps(307).h
  .x = bmps(307).x
  .y = bmps(307).y
  .dX = .w
  .dy = .h \ 2
 End With
 With .bm(4) '"]"
  .ImgIndex = 0
  .w = bmps(307).w \ 2
  .h = bmps(307).h
  .x = bmps(307).x + .w
  .y = bmps(307).y
  .dX = 0
  .dy = .h \ 2
 End With
 pTheBitmapConvert bmps(504), .bm(5), 80, 98 'blur box
 With .bm(6) 'box
  .ImgIndex = 3
  .x = 228
  .y = 0
  .w = 44
  .h = 52 '53?
  .dX = 0
  .dy = 34
 End With
End With
'//////////////////
End Sub

Private Sub pInitBoxAnimation(ByVal Index As Long, ByVal Count As Long, ByVal Offset As Long, Optional ByVal NewX As Long, Optional ByVal NewY As Long, Optional ByVal IsReverse As Boolean)
Dim i As Long
With Anis(Index)
 .Count = Count
 ReDim .bm(1 To Count)
 If IsReverse Then
  pTheBitmapConvert bmps(1 + Offset), .bm(1), NewX, NewY
  For i = 2 To Count
   pTheBitmapConvert bmps(i + Offset), .bm(Count + 2 - i), NewX, NewY
  Next i
 Else
  For i = 1 To Count
   pTheBitmapConvert bmps(i + Offset), .bm(i), NewX, NewY
  Next i
 End If
End With
End Sub

Private Sub pTheBitmapConvert(bm As typeTheBitmap2, ret As typeTheBitmap3, Optional ByVal NewX As Long, Optional ByVal NewY As Long)
With ret
 .ImgIndex = bm.ImgIndex
 .x = bm.x
 .y = bm.y
 .w = bm.w
 .h = bm.h
 .dX = NewX - bm.dX
 .dy = NewY - bm.dy
End With
End Sub

Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)
GameStatus = -2
End Sub

Private Sub i0_MouseDown(Index As Integer, Button As Integer, Shift As Integer, x As Single, y As Single)
Dim i As Long
i = x \ 360
If i <> eSelect And i >= 0 And i <= 11 Then
 eSelect = i
 pEditSelect
End If
End Sub

Private Sub IBloxorzCallBack_SolveItCallBack(ByVal nNodeNow As Long, ByVal nNodeCount As Long, bAbort As Boolean)
Dim i As Long, j As Long
Dim w As Long, h As Long
Dim r As RECT, hbr As Long, hbr2 As Long
If p0(1).Visible Then 'game!
 'draw
 w = 320
 h = 48
 r.Left = 320 - w \ 2
 r.Right = r.Left + w
 r.Top = 240 - h \ 2
 r.Bottom = r.Top + h
 hbr = CreateSolidBrush(vbBlack)
 hbr2 = CreateSolidBrush(&H80FF&)
 bmG_Back.PaintPicture bmG.hdc
 FillRect bmG.hdc, r, hbr
 FrameRect bmG.hdc, r, hbr2
 r.Right = r.Left + (nNodeNow * w) \ nNodeCount
 FillRect bmG.hdc, r, hbr2
 DrawTextB bmG.hdc, Label1(10).Caption, Label1(10).Font, r.Left, r.Top, w, h, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
 Game_Paint
 DeleteObject hbr
 DeleteObject hbr2
 If GameStatus < 0 Then bAbort = True
Else 'edit!
 With p0(5)
  .Width = (nNodeNow * 320&) \ nNodeCount
  .Visible = True
 End With
End If
DoEvents
End Sub

Private Sub Game_RndMap_Progress(ByVal nNodeNow As Long, ByVal nNodeCount As Long)
Dim i As Long, j As Long
Dim w As Long, h As Long
Dim r As RECT, hbr As Long, hbr2 As Long
w = 320
h = 48
r.Left = 320 - w \ 2
r.Right = r.Left + w
r.Top = 240 - h \ 2
r.Bottom = r.Top + h
hbr = CreateSolidBrush(vbBlack)
hbr2 = CreateSolidBrush(&H80FF&)
bmG_Back.PaintPicture bmG.hdc
FillRect bmG.hdc, r, hbr
FrameRect bmG.hdc, r, hbr2
r.Right = r.Left + (nNodeNow * w) \ nNodeCount
FillRect bmG.hdc, r, hbr2
DrawTextB bmG.hdc, objText.GetText("Generating..."), Label1(10).Font, r.Left, r.Top, w, h, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbWhite, , True
Game_Paint
DeleteObject hbr
DeleteObject hbr2
DoEvents
End Sub

Private Sub lstSwitch_Click()
Dim lv As Long, i As Long, j As Long
lv = 1 + cmbLv.ListIndex
If lv > 0 Then
 i = 1 + cmbS.ListIndex
 j = 1 + lstSwitch.ListIndex
 With Lev(lv)
  If i > 0 And i <= .SwitchCount Then
   If j > 0 And j <= .SwitchBridgeCount(i) Then
    Label1(8).Caption = CStr(.SwitchBridgeX(i, j)) + "," + CStr(.SwitchBridgeY(i, j))
    cmbBehavior.ListIndex = .SwitchBridgeBehavior(i, j)
    chkPos(3).Value = 0
    pEditRedraw
   End If
  End If
 End With
End If
End Sub

Private Sub optMode_Click(Index As Integer)
eSX = 0
eSY = 0
pEditRefresh
End Sub

Private Sub optSt_Click(Index As Integer)
sSX = 0
sSY = 0
sSX2 = 0
sSY2 = 0
pSolveRedraw
End Sub

'Private Sub p0_MouseDown(Index As Integer, Button As Integer, Shift As Integer, x As Single, y As Single)
'GameClick = True
'End Sub
'
'Private Sub p0_MouseUp(Index As Integer, Button As Integer, Shift As Integer, x As Single, y As Single)
'GameClick = False
'End Sub

Private Sub p0_Paint(Index As Integer)
Select Case Index
Case 1
 Game_Paint
Case 6
 'TODO:
End Select
End Sub

Private Sub pEdit_MouseDown(Button As Integer, Shift As Integer, x As Single, y As Single)
Dim i As Long, j As Long, k As Long, lv As Long
Dim xo As Long, yo As Long, xo2 As Long, yo2 As Long, s As String
i = (x + sEdit.Value(efsHorizontal) + 24) \ 24
j = (y + sEdit.Value(efsVertical) + 24) \ 24
lv = 1 + cmbLv.ListIndex
If lv <= 0 Then Exit Sub
With Lev(lv)
 If i > 0 And j > 0 And i <= .Width And j <= .Height Then
  If chkPos(2).Value = 1 Then
    xo = i
    yo = j
    i = 1 + cmbS.ListIndex
    j = 1 + lstSwitch.ListIndex
    If i > 0 And i <= .SwitchCount Then
     If j > 0 And j <= .SwitchBridgeCount(i) Then
      If .SwitchBridgeX(i, j) <> xo Or .SwitchBridgeY(i, j) <> yo Then
       .SwitchBridgeX(i, j) = xo
       .SwitchBridgeY(i, j) = yo
       s = CStr(xo) + "," + CStr(yo)
       Label1(8).Caption = s
       lstSwitch.List(j - 1) = s + vbTab + cmbBehavior.List(.SwitchBridgeBehavior(i, j))
       pEditRedraw
      End If
     End If
    End If
    chkPos(2).Value = 0
  ElseIf optMode(0).Value Then 'edit
   If chkPos(3).Value = 1 Then
    .StartX = i
    .StartY = j
    chkPos(3).Value = 0
    pEditRedraw
   Else
    k = IIf(Button = 2, 0, eSelect)
    If .Data(i, j) <> k Then
     .Data(i, j) = k
     pEditRedraw
    End If
   End If
  ElseIf optMode(1).Value Then 'select
   If chkPos(0).Value = 1 Then
    If .Data(eSX, eSY) = 4 Then
     .GetTransportPosition eSX, eSY, xo, yo, xo2, yo2
     .SetTransportPosition eSX, eSY, i, j, xo2, yo2
     Label1(3).Caption = CStr(i) + "," + CStr(j)
     chkPos(0).Value = 0
     pEditRedraw
    End If
   ElseIf chkPos(1).Value = 1 Then
    If .Data(eSX, eSY) = 4 Then
     .GetTransportPosition eSX, eSY, xo, yo, xo2, yo2
     .SetTransportPosition eSX, eSY, xo, yo, i, j
     Label1(4).Caption = CStr(i) + "," + CStr(j)
     chkPos(1).Value = 0
     pEditRedraw
    End If
   ElseIf chkPos(2).Value = 1 Then
    xo = i
    yo = j
    i = 1 + cmbS.ListIndex
    j = 1 + lstSwitch.ListIndex
    If i > 0 And i <= .SwitchCount Then
     If j > 0 And j <= .SwitchBridgeCount(i) Then
      If .SwitchBridgeX(i, j) <> xo Or .SwitchBridgeY(i, j) <> yo Then
       .SwitchBridgeX(i, j) = xo
       .SwitchBridgeY(i, j) = yo
       s = CStr(xo) + "," + CStr(yo)
       Label1(8).Caption = s
       lstSwitch.List(j - 1) = s + vbTab + cmbBehavior.List(.SwitchBridgeBehavior(i, j))
       pEditRedraw
      End If
     End If
    End If
    chkPos(2).Value = 0
   ElseIf chkPos(3).Value = 1 Then
    .StartX = i
    .StartY = j
    chkPos(3).Value = 0
    pEditRedraw
   ElseIf eSX <> i Or eSY <> j Then
    eSX = i
    eSY = j
    pEditMapSelect lv
   End If
  End If
 End If
End With
End Sub

Private Sub pEdit_MouseMove(Button As Integer, Shift As Integer, x As Single, y As Single)
Dim i As Long, j As Long, k As Long, lv As Long
i = (x + sEdit.Value(efsHorizontal) + 24) \ 24
j = (y + sEdit.Value(efsVertical) + 24) \ 24
lv = 1 + cmbLv.ListIndex
If lv <= 0 Then Exit Sub
If optMode(0).Value And Button > 0 Then 'edit
 With Lev(lv)
  If i > 0 And j > 0 And i <= .Width And j <= .Height Then
   k = IIf(Button = 2, 0, eSelect)
   If .Data(i, j) <> k Then
    .Data(i, j) = k
    pEditRedraw
   End If
  End If
 End With
End If
End Sub

Private Sub pEdit_Paint()
bmEdit.PaintPicture pEdit.hdc, 0, 0, pEdit.ScaleWidth, pEdit.ScaleHeight, sEdit.Value(efsHorizontal), sEdit.Value(efsVertical)
End Sub

Private Sub pSolution_MouseDown(Button As Integer, Shift As Integer, x As Single, y As Single)
Dim i As Long, j As Long, lv As Long
lv = 1 + cmbLv.ListIndex
If lv <= 0 Then Exit Sub
With Lev(lv)
 If optSt(0).Value Then
  i = (x + 24) \ 24
  j = (y + 24) \ 24
  If i > 0 And j > 0 And i <= .Width And j <= .Height Then
   If i <> sSX Or j <> sSY Then
    sSX = i
    sSY = j
    pSolveRedraw
   End If
  End If
 ElseIf optSt(1).Value Then
  i = (x + 12) \ 24
  j = (y + 24) \ 24
  If i > 0 And j > 0 And i <= .Width And j <= .Height Then
   If i <> sSX Or j <> sSY Then
    sSX = i
    sSY = j
    pSolveRedraw
   End If
  End If
 ElseIf optSt(2).Value Then
  i = (x + 24) \ 24
  j = (y + 12) \ 24
  If i > 0 And j > 0 And i <= .Width And j <= .Height Then
   If i <> sSX Or j <> sSY Then
    sSX = i
    sSY = j
    pSolveRedraw
   End If
  End If
 ElseIf optSt(3).Value Then
  i = (x + 24) \ 24
  j = (y + 24) \ 24
  If i > 0 And j > 0 And i <= .Width And j <= .Height Then
   If Button = 2 Then
    If i <> sSX2 Or j <> sSY2 Then
     sSX2 = i
     sSY2 = j
     pSolveRedraw
    End If
   Else
    If i <> sSX Or j <> sSY Then
     sSX = i
     sSY = j
     pSolveRedraw
    End If
   End If
  End If
 End If
End With
End Sub

Private Sub pSolution_Paint()
bmEdit.PaintPicture pSolution.hdc
End Sub

Private Sub sEdit_Change(eBar As EFSScrollBarConstants)
pEdit_Paint
End Sub

Private Sub sEdit_MouseWheel(eBar As EFSScrollBarConstants, lAmount As Long)
pEdit_Paint
End Sub

Private Sub sEdit_Scroll(eBar As EFSScrollBarConstants)
pEdit_Paint
End Sub

Private Sub pEditMapSelect(ByVal lv As Long)
Dim i As Long, j As Long, k As Long
Dim x As Long, y As Long
With Lev(lv)
 If optMode(1).Value Then
  If eSX > 0 And eSY > 0 And eSX <= .Width And eSY <= .Height Then
   Select Case .Data(eSX, eSY)
   Case 2, 3 'switch
    k = 1
   Case 4 'trans
    k = 2
   End Select
  End If
 End If
 For i = 0 To p2.UBound
  p2(i).Visible = i = k - 1
 Next i
 chkPos(0).Value = 0
 chkPos(1).Value = 0
 Select Case k
 Case 1 'switch
  i = .Data2(eSX, eSY)
  If i > .SwitchCount Then i = 0
  If i >= 0 Then cmbSwitch.ListIndex = i
 Case 2 'trans
  .GetTransportPosition eSX, eSY, i, j, x, y
  Label1(3).Caption = CStr(i) + "," + CStr(j)
  Label1(4).Caption = CStr(x) + "," + CStr(y)
 End Select
End With
pEditRedraw
End Sub

Private Sub pEditSwitch()
Dim i As Long, j As Long, lv As Long
cmbS.Clear
cmbSwitch.Clear
cmbSwitch.AddItem objText.GetText("(None)")
lstSwitch.Clear
lv = 1 + cmbLv.ListIndex
If lv <= 0 Then Exit Sub
With Lev(lv)
 For i = 1 To .SwitchCount
  cmbS.AddItem CStr(i)
  cmbSwitch.AddItem CStr(i)
 Next i
End With
End Sub

Private Sub pEditSelect()
shpSelect.Move 8 + eSelect * 24&, 22, 24, 24
End Sub

Private Sub pEditRefresh()
Dim w As Long, h As Long, lv As Long
lv = 1 + cmbLv.ListIndex
If lv <= 0 Then Exit Sub
w = Lev(lv).Width * 24
h = Lev(lv).Height * 24
bmEdit.Create w, h
If w > pEdit.ScaleWidth Then
 sEdit.Max(efsHorizontal) = w - pEdit.ScaleWidth
 sEdit.LargeChange(efsHorizontal) = pEdit.ScaleWidth
 sEdit.Enabled(efsHorizontal) = True
Else
 sEdit.Max(efsHorizontal) = 1
 sEdit.Value(efsHorizontal) = 0
 sEdit.Enabled(efsHorizontal) = False
End If
If h > pEdit.ScaleHeight Then
 sEdit.Max(efsVertical) = h - pEdit.ScaleHeight
 sEdit.LargeChange(efsVertical) = pEdit.ScaleHeight
 sEdit.Enabled(efsVertical) = True
Else
 sEdit.Max(efsVertical) = 1
 sEdit.Value(efsVertical) = 0
 sEdit.Enabled(efsVertical) = False
End If
pEdit.Cls
pEditMapSelect lv
pEditRedraw
End Sub

Private Sub pEditRedraw()
Dim i As Long, j As Long, x As Long, y As Long
Dim lv As Long
lv = 1 + cmbLv.ListIndex
If lv <= 0 Then Exit Sub
With Lev(lv)
 'map
 For i = 1 To .Width
  For j = 1 To .Height
   bmImg(2).PaintPicture bmEdit.hdc, i * 24 - 24, j * 24 - 24, 24, 24, .Data(i, j) * 24, 0
  Next j
 Next i
 'selected
 If eSX > 0 And eSY > 0 Then
  bmImg(3).AlphaPaintPicture bmEdit.hdc, eSX * 24 - 24, eSY * 24 - 24, 24, 24, 132, 0, , True
  Select Case .Data(eSX, eSY)
  Case 2, 3
   j = .Data2(eSX, eSY)
   If j > 0 And j <= .SwitchCount Then
    For i = 1 To .SwitchBridgeCount(j)
     x = .SwitchBridgeX(j, i)
     y = .SwitchBridgeY(j, i)
     If x > 0 And y > 0 Then
      bmImg(3).AlphaPaintPicture bmEdit.hdc, x * 24 - 24, y * 24 - 24, 24, 24, 156 + .SwitchBridgeBehavior(j, i) * 24, 0, 64, False
     End If
    Next i
   End If
  Case 4  'trans??
   .GetTransportPosition eSX, eSY, i, j, x, y
   If i > 0 And j > 0 Then
    DrawTextB bmEdit.hdc, objText.GetText("Pos1"), Me.Font, i * 24 - 48, j * 24 - 24, 72, 24, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbRed, , True
   End If
   If x > 0 And y > 0 Then
    DrawTextB bmEdit.hdc, objText.GetText("Pos2"), Me.Font, x * 24 - 48, y * 24 - 24, 72, 24, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbRed, , True
   End If
  End Select
 End If
 'selected switch pos
 i = 1 + cmbS.ListIndex
 j = 1 + lstSwitch.ListIndex
 If i > 0 And i <= .SwitchCount Then
  If j > 0 And j <= .SwitchBridgeCount(i) Then
   x = .SwitchBridgeX(i, j)
   y = .SwitchBridgeY(i, j)
   If x > 0 And y > 0 Then
    bmImg(3).AlphaPaintPicture bmEdit.hdc, x * 24 - 24, y * 24 - 24, 24, 24, 156 + .SwitchBridgeBehavior(i, j) * 24, 0, 64, False
   End If
  End If
 End If
 'start
 i = .StartX
 j = .StartY
 If i > 0 And j > 0 Then
  Label1(13).Caption = CStr(i) + "," + CStr(j)
  DrawTextB bmEdit.hdc, objText.GetText("Start"), Me.Font, i * 24 - 48, j * 24 - 24, 72, 24, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbRed, , True
 End If
End With
pEdit_Paint
End Sub

Private Sub pSolveRedraw()
Dim i As Long, j As Long, x As Long, y As Long
Dim lv As Long, lv2 As Long
Dim d() As Byte, s As String
lv = 1 + cmbLv.ListIndex
If lv <= 0 Then Exit Sub
lv2 = 1 + cmbSt.ListIndex
If lv2 <= 0 Then Exit Sub
With Lev(lv)
 'map
 .SolveItGetSwitchStatus lv2, d
 For i = 1 To .Width
  For j = 1 To .Height
   If d(i, j) = 6 Then d(i, j) = 0
   bmImg(2).PaintPicture bmEdit.hdc, i * 24 - 24, j * 24 - 24, 24, 24, d(i, j) * 24, 0
  Next j
 Next i
 'distance
 For i = 1 To .Width
  For j = 1 To .Height
   If optSt(0).Value Then 'up
    x = .SolveItGetNodeIndex(lv2, 0, i, j)
    If x > 0 Then
     y = .SolveItGetDistance(x)
     If y < &H7FFFFFFF Then
      DrawTextB bmEdit.hdc, CStr(y), Me.Font, i * 24 - 48, j * 24 - 24, 72, 24, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbRed, , True
     End If
    End If
   ElseIf optSt(1).Value Then 'h
    x = .SolveItGetNodeIndex(lv2, 1, i, j)
    If x > 0 Then
     y = .SolveItGetDistance(x)
     If y < &H7FFFFFFF Then
      DrawTextB bmEdit.hdc, CStr(y), Me.Font, i * 24 - 36, j * 24 - 24, 72, 24, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbRed, , True
     End If
    End If
   ElseIf optSt(2).Value Then 'v
    x = .SolveItGetNodeIndex(lv2, 2, i, j)
    If x > 0 Then
     y = .SolveItGetDistance(x)
     If y < &H7FFFFFFF Then
      DrawTextB bmEdit.hdc, CStr(y), Me.Font, i * 24 - 48, j * 24 - 12, 72, 24, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbRed, , True
     End If
    End If
   ElseIf optSt(3).Value Then 'single
    If sSX > 0 And sSY > 0 Then
     x = .SolveItGetNodeIndex(lv2, 3, sSX, sSY, i, j)
     If x > 0 Then
      y = .SolveItGetDistance(x)
      If y < &H7FFFFFFF Then
       DrawTextB bmEdit.hdc, CStr(y), Me.Font, i * 24 - 48, j * 24 - 24, 72, 24, DT_CENTER Or DT_VCENTER Or DT_SINGLELINE, vbRed, , True
      End If
     End If
    End If
   End If
  Next j
 Next i
 'selected
 x = 0
 If sSX > 0 And sSY > 0 Then
  If optSt(1).Value Then
   bmImg(3).AlphaPaintPicture bmEdit.hdc, sSX * 24 - 24, sSY * 24 - 24, 12, 24, 132, 0, , True
   bmImg(3).AlphaPaintPicture bmEdit.hdc, sSX * 24 + 12, sSY * 24 - 24, 12, 24, 144, 0, , True
   x = .SolveItGetNodeIndex(lv2, 1, sSX, sSY)
  ElseIf optSt(2).Value Then
   bmImg(3).AlphaPaintPicture bmEdit.hdc, sSX * 24 - 24, sSY * 24 - 24, 24, 12, 132, 0, , True
   bmImg(3).AlphaPaintPicture bmEdit.hdc, sSX * 24 - 24, sSY * 24 + 12, 24, 12, 132, 12, , True
   x = .SolveItGetNodeIndex(lv2, 2, sSX, sSY)
  Else
   bmImg(3).AlphaPaintPicture bmEdit.hdc, sSX * 24 - 24, sSY * 24 - 24, 24, 24, 132, 0, , True
   If optSt(0).Value Then x = .SolveItGetNodeIndex(lv2, 0, sSX, sSY)
  End If
 End If
 If sSX2 > 0 And sSY2 > 0 And optSt(3).Value Then
  bmImg(3).AlphaPaintPicture bmEdit.hdc, sSX2 * 24 - 24, sSY2 * 24 - 24, 24, 24, 132, 0, , True
  If sSX > 0 And sSY > 0 Then x = .SolveItGetNodeIndex(lv2, 3, sSX, sSY, sSX2, sSY2)
 End If
 'show solution
 If x > 0 Then
  y = .SolveItGetDistance(x)
  If y < &H7FFFFFFF Then
   s = .SolveItGetSolution(x, VarPtr(d(1, 1)))
   s = Replace(s, "u", "↑")
   s = Replace(s, "d", "↓")
   s = Replace(s, "l", "←")
   s = Replace(s, "r", "→")
   s = Replace(s, "s", "◇")
   s = s + vbCrLf + objText.GetText("Moves:") + CStr(y)
   txtGame(3).Text = s
   For i = 1 To .Width
    For j = 1 To .Height
     If d(i, j) Then
      bmImg(3).AlphaPaintPicture bmEdit.hdc, i * 24 - 24, j * 24 - 24, 24, 24, 180, 0, 64, False
     End If
    Next j
   Next i
  End If
 End If
End With
pSolution_Paint
End Sub

Private Sub txtGame_GotFocus(Index As Integer)
With txtGame(Index)
 .SelStart = 0
 .SelLength = Len(.Text)
End With
End Sub

