Attribute VB_Name = "mdlExternalSolver"
Option Explicit

'mersenne twister functions

Public Declare Sub MTInit Lib "SolverTest2.dll" (ByVal s As Long)
Public Declare Sub MTInitFromString Lib "SolverTest2.dll" (ByVal s As String)
Public Declare Function MTGenRandInt32 Lib "SolverTest2.dll" () As Long
Public Declare Function MTGenRandInt31 Lib "SolverTest2.dll" () As Long
Public Declare Function MTGenRandReal1 Lib "SolverTest2.dll" () As Double
Public Declare Function MTGenRandReal2 Lib "SolverTest2.dll" () As Double
Public Declare Function MTGenRandReal3 Lib "SolverTest2.dll" () As Double
Public Declare Function MTGenRandRes53 Lib "SolverTest2.dll" () As Double

'std::map functions

Public Declare Function StdMapCreate Lib "SolverTest2.dll" () As Long
Public Declare Sub StdMapDestroy Lib "SolverTest2.dll" (ByVal obj As Long)
Public Declare Sub StdMapAdd Lib "SolverTest2.dll" (ByVal obj As Long, ByVal sKey As String, ByVal sValue As String)
Public Declare Sub StdMapAddFromString Lib "SolverTest2.dll" (ByVal obj As Long, ByVal s As String, ByVal delim1 As Long, ByVal delim2 As Long, ByVal bRemoveSpace As Boolean)
Public Declare Function StdMapQuery Lib "SolverTest2.dll" (ByVal obj As Long, ByVal sKey As String, ByVal sValue As String, ByVal nLen As Long) As Long
Public Declare Function StdMapCreateFromString Lib "SolverTest2.dll" (ByVal s As String, ByVal delim1 As Long, ByVal delim2 As Long, ByVal bRemoveSpace As Boolean) As Long

'GA base object function

Public Declare Function GABaseCreate Lib "SolverTest2.dll" (ByVal objMap As Long) As Long
Public Declare Sub GABaseDestroy Lib "SolverTest2.dll" (ByVal obj As Long)
Public Declare Function GABaseOutputToString Lib "SolverTest2.dll" (ByVal obj As Long, ByRef s As Any, ByVal nLen As Long, ByVal OutputSolution As Byte) As Long
Public Declare Sub GABaseOutputToFile Lib "SolverTest2.dll" (ByVal obj As Long, ByVal s As String, ByVal OutputSolution As Byte)

'GA random level generator functions

Public Declare Function GACreate Lib "SolverTest2.dll" () As Long
Public Declare Sub GADestroy Lib "SolverTest2.dll" (ByVal obj As Long)
Public Declare Function GACreatePool Lib "SolverTest2.dll" (ByVal obj As Long, ByVal objMap As Long, ByVal PoolSize As Long) As Byte
Public Declare Sub GADestroyPool Lib "SolverTest2.dll" (ByVal obj As Long)
Public Declare Function GARun Lib "SolverTest2.dll" (ByVal obj As Long, ByVal GenerationCount As Long, ByVal objMap As Long, ByVal Callback As Long, ByVal UserData As Long) As Byte
Public Declare Function GAGetPoolItem Lib "SolverTest2.dll" (ByVal obj As Long, ByVal Index As Long) As Long
Public Declare Function GAGetFitness Lib "SolverTest2.dll" (ByVal obj As Long, ByVal Index As Long) As Long

'settings function

Public Declare Function GetAvaliableRandomMapGenerators Lib "SolverTest2.dll" (ByRef lpOut As Any, ByVal SizePerString As Long, ByVal MaxCount As Long) As Long
Public Declare Function GetAvaliableRandomMapOptions Lib "SolverTest2.dll" (ByVal sType As String, ByRef lpOut As Any, ByVal SizePerString As Long, ByVal MaxCount As Long) As Long
Public Declare Function GetAvaliableGAOptions Lib "SolverTest2.dll" (ByRef lpOut As Any, ByVal SizePerString As Long, ByVal MaxCount As Long) As Long
Public Declare Function GetAvaliableSolvers Lib "SolverTest2.dll" (ByRef lpOut As Any, ByVal SizePerString As Long, ByVal MaxCount As Long) As Long

'solver functions

Public Declare Function SolverCreate Lib "SolverTest2.dll" (ByVal objMap As Long) As Long
Public Declare Sub SolverDestroy Lib "SolverTest2.dll" (ByVal obj As Long)
Public Declare Function SolverSetData Lib "SolverTest2.dll" (ByVal obj As Long, ByVal objMap As Long) As Byte
Public Declare Function SolverSolve Lib "SolverTest2.dll" (ByVal obj As Long, ByRef s As Any, ByRef nLen As Long, ByRef nStep As Long, ByRef NodesUsed As Long) As Byte
Public Declare Function SolverOutputToString Lib "SolverTest2.dll" (ByVal obj As Long, ByRef s As Any, ByVal nLen As Long, ByVal OutputSolution As Byte) As Long
Public Declare Sub SolverOutputToFile Lib "SolverTest2.dll" (ByVal obj As Long, ByVal s As String, ByVal OutputSolution As Byte)

'////////

Public FakeDXAppSolverNotFound As Boolean
