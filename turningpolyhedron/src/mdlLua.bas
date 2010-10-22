Attribute VB_Name = "mdlLua"
Option Explicit

Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)

Public Const LUA_IDSIZE As Long = 60

Public Const LUAI_GCPAUSE As Long = 200
Public Const LUAI_GCMUL As Long = 200
Public Const LUAI_BITSINT As Long = 32
Public Const LUAI_MAXCALLS As Long = 20000
Public Const LUAI_MAXCSTACK As Long = 8000
Public Const LUAI_MAXCCALLS As Long = 200
Public Const LUAI_MAXVARS As Long = 200
Public Const LUAI_MAXUPVALUES As Long = 60
Public Const LUAL_BUFFERSIZE As Long = 512

Public Const LUA_MULTRET As Long = (-1)

Public Const LUA_REGISTRYINDEX As Long = (-10000)
Public Const LUA_ENVIRONINDEX As Long = (-10001)
Public Const LUA_GLOBALSINDEX As Long = (-10002)

Public Const LUA_YIELD_ As Long = 1
Public Const LUA_ERRRUN As Long = 2
Public Const LUA_ERRSYNTAX As Long = 3
Public Const LUA_ERRMEM As Long = 4
Public Const LUA_ERRERR As Long = 5

'typedef int (*lua_CFunction) (lua_State *L);
'
'
'/*
'** functions that read/write blocks when loading/dumping Lua chunks
'*/
'typedef const char * (*lua_Reader) (lua_State *L, void *ud, size_t *sz);
'
'typedef int (*lua_Writer) (lua_State *L, const void* p, size_t sz, void* ud);
'
'
'/*
'** prototype for memory-allocation functions
'*/
'typedef void * (*lua_Alloc) (void *ud, void *ptr, size_t osize, size_t nsize);

Public Const LUA_TNONE As Long = (-1)

Public Const LUA_TNIL As Long = 0
Public Const LUA_TBOOLEAN As Long = 1
Public Const LUA_TLIGHTUSERDATA As Long = 2
Public Const LUA_TNUMBER As Long = 3
Public Const LUA_TSTRING As Long = 4
Public Const LUA_TTABLE As Long = 5
Public Const LUA_TFUNCTION As Long = 6
Public Const LUA_TUSERDATA As Long = 7
Public Const LUA_TTHREAD As Long = 8

Public Const LUA_MINSTACK As Long = 20

'/* type of numbers in Lua */
'typedef LUA_NUMBER lua_Number; 'Double
'
'/* type for integer functions */
'typedef LUA_INTEGER lua_Integer; 'Long

'/*
'** state manipulation
'*/
Public Declare Function lua_newstate Lib "lua5.1.dll" (ByVal lpfnAlloc As Long, ByVal nUserData As Long) As Long
Public Declare Function lua_close Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function lua_newthread Lib "lua5.1.dll" (ByVal hState As Long) As Long

Public Declare Function lua_atpanic Lib "lua5.1.dll" (ByVal hState As Long, ByVal lpfnPanic As Long) As Long

'/*
'** basic stack manipulation
'*/
Public Declare Function lua_gettop Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function lua_settop Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_pushvalue Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_remove Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_insert Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_replace Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_checkstack Lib "lua5.1.dll" (ByVal hState As Long, ByVal nSize As Long) As Long
Public Declare Function lua_xmove Lib "lua5.1.dll" (ByVal hStateFrom As Long, ByVal hStateTo As Long, ByVal n As Long) As Long

'/*
'** access functions (stack -> C)
'*/
'
Public Declare Function lua_isnumber Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_isstring Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_iscfunction Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_isuserdata Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_type Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_typename Lib "lua5.1.dll" (ByVal hState As Long, ByVal nType As Long) As Long

Public Declare Function lua_equal Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex1 As Long, ByVal nIndex2 As Long) As Long
Public Declare Function lua_rawequal Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex1 As Long, ByVal nIndex2 As Long) As Long
Public Declare Function lua_lessthan Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex1 As Long, ByVal nIndex2 As Long) As Long

Public Declare Function lua_tonumber Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Double
Public Declare Function lua_tointeger Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_toboolean Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_tolstring Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long, ByRef lpLen As Long) As Long
Public Declare Function lua_objlen Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_tocfunction Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_touserdata Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_tothread Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_topointer Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long

'/*
'** push functions (C -> stack)
'*/
Public Declare Function lua_pushnil Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function lua_pushnumber Lib "lua5.1.dll" (ByVal hState As Long, ByVal n As Double) As Long
Public Declare Function lua_pushinteger Lib "lua5.1.dll" (ByVal hState As Long, ByVal n As Long) As Long
Public Declare Function lua_pushlstring Lib "lua5.1.dll" (ByVal hState As Long, ByVal s As String, ByVal nLen As Long) As Long
Public Declare Function lua_pushstring Lib "lua5.1.dll" (ByVal hState As Long, ByVal s As String) As Long
'LUA_API const char *(lua_pushvfstring) (lua_State *L, const char *fmt,
'                                                      va_list argp);
'LUA_API const char *(lua_pushfstring) (lua_State *L, const char *fmt, ...);
Public Declare Function lua_pushcclosure Lib "lua5.1.dll" (ByVal hState As Long, ByVal lpfn As Long, ByVal n As Long) As Long
Public Declare Function lua_pushboolean Lib "lua5.1.dll" (ByVal hState As Long, ByVal b As Long) As Long
Public Declare Function lua_pushlightuserdata Lib "lua5.1.dll" (ByVal hState As Long, ByVal nUserData As Long) As Long
Public Declare Function lua_pushthread Lib "lua5.1.dll" (ByVal hState As Long) As Long

'/*
'** get functions (Lua -> stack)
'*/
Public Declare Function lua_gettable Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_getfield Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long, ByVal k As String) As Long
Public Declare Function lua_rawget Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_rawgeti Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long, ByVal n As Long) As Long
Public Declare Function lua_createtable Lib "lua5.1.dll" (ByVal hState As Long, ByVal narr As Long, ByVal nrec As Long) As Long
Public Declare Function lua_newuserdata Lib "lua5.1.dll" (ByVal hState As Long, ByVal nSize As Long) As Long
Public Declare Function lua_getmetatable Lib "lua5.1.dll" (ByVal hState As Long, ByVal nObjIndex As Long) As Long
Public Declare Function lua_getfenv Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long

'/*
'** set functions (stack -> Lua)
'*/
Public Declare Function lua_settable Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_setfield Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long, ByVal k As String) As Long
Public Declare Function lua_rawset Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_rawseti Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long, ByVal n As Long) As Long
Public Declare Function lua_setmetatable Lib "lua5.1.dll" (ByVal hState As Long, ByVal nObjIndex As Long) As Long
Public Declare Function lua_setfenv Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long

'/*
'** `load' and `call' functions (load and run Lua code)
'*/
Public Declare Function lua_call Lib "lua5.1.dll" (ByVal hState As Long, ByVal nArgs As Long, ByVal nResults As Long) As Long
Public Declare Function lua_pcall Lib "lua5.1.dll" (ByVal hState As Long, ByVal nArgs As Long, ByVal nResults As Long, ByVal nErrFunc As Long) As Long
Public Declare Function lua_cpcall Lib "lua5.1.dll" (ByVal hState As Long, ByVal lpfn As Long, ByVal nUserData As Long) As Long
Public Declare Function lua_load Lib "lua5.1.dll" (ByVal hState As Long, ByVal lpfnReader As Long, ByVal dt As Long, ByVal sChunkName As String) As Long
Public Declare Function lua_dump Lib "lua5.1.dll" (ByVal hState As Long, ByVal lpfnWrite As Long, ByVal lpData As Long) As Long

'/*
'** coroutine functions
'*/
Public Declare Function lua_yield Lib "lua5.1.dll" (ByVal hState As Long, ByVal nResults As Long) As Long
Public Declare Function lua_resume Lib "lua5.1.dll" (ByVal hState As Long, ByVal nArg As Long) As Long
Public Declare Function lua_status Lib "lua5.1.dll" (ByVal hState As Long) As Long

'/*
'** garbage-collection function and options
'*/

Public Const LUA_GCSTOP As Long = 0
Public Const LUA_GCRESTART As Long = 1
Public Const LUA_GCCOLLECT As Long = 2
Public Const LUA_GCCOUNT As Long = 3
Public Const LUA_GCCOUNTB As Long = 4
Public Const LUA_GCSTEP As Long = 5
Public Const LUA_GCSETPAUSE As Long = 6
Public Const LUA_GCSETSTEPMUL As Long = 7

Public Declare Function lua_gc Lib "lua5.1.dll" (ByVal hState As Long, ByVal nWhat As Long, ByVal nData As Long) As Long

'/*
'** miscellaneous functions
'*/

Public Declare Function lua_error Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function lua_next Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long) As Long
Public Declare Function lua_concat Lib "lua5.1.dll" (ByVal hState As Long, ByVal n As Long) As Long
Public Declare Function lua_getallocf Lib "lua5.1.dll" (ByVal hState As Long, ByRef lpUserData As Long) As Long
Public Declare Function lua_setallocf Lib "lua5.1.dll" (ByVal hState As Long, ByVal lpfnAlloc As Long, ByVal nUserData As Long) As Long

'/* hack */
Public Declare Function lua_setlevel Lib "lua5.1.dll" (ByVal hStateFrom As Long, ByVal hStateTo As Long) As Long

'/*
'** {======================================================================
'** Debug API
'** =======================================================================
'*/

'/*
'** Event codes
'*/
Public Const LUA_HOOKCALL As Long = 0
Public Const LUA_HOOKRET As Long = 1
Public Const LUA_HOOKLINE As Long = 2
Public Const LUA_HOOKCOUNT As Long = 3
Public Const LUA_HOOKTAILRET As Long = 4

'/*
'** Event masks
'*/
Public Const LUA_MASKCALL As Long = (2 ^ LUA_HOOKCALL)
Public Const LUA_MASKRET As Long = (2 ^ LUA_HOOKRET)
Public Const LUA_MASKLINE As Long = (2 ^ LUA_HOOKLINE)
Public Const LUA_MASKCOUNT As Long = (2 ^ LUA_HOOKCOUNT)
'
'typedef struct lua_Debug lua_Debug;  /* activation record */
'
'
'/* Functions to be called by the debuger in specific events */
'typedef void (*lua_Hook) (lua_State *L, lua_Debug *ar);

Public Declare Function lua_getstack Lib "lua5.1.dll" (ByVal hState As Long, ByVal nLevel As Long, ByRef ar As lua_Debug) As Long
Public Declare Function lua_getinfo Lib "lua5.1.dll" (ByVal hState As Long, ByVal sWhat As String, ByRef ar As lua_Debug) As Long
Public Declare Function lua_getlocal Lib "lua5.1.dll" (ByVal hState As Long, ByRef ar As lua_Debug, ByVal n As Long) As Long
Public Declare Function lua_setlocal Lib "lua5.1.dll" (ByVal hState As Long, ByRef ar As lua_Debug, ByVal n As Long) As Long
Public Declare Function lua_getupvalue Lib "lua5.1.dll" (ByVal hState As Long, ByVal nFuncIndex As Long, ByVal n As Long) As Long
Public Declare Function lua_setupvalue Lib "lua5.1.dll" (ByVal hState As Long, ByVal nFuncIndex As Long, ByVal n As Long) As Long

Public Declare Function lua_sethook Lib "lua5.1.dll" (ByVal hState As Long, ByVal lpfnHook As Long, ByVal nMask As Long, ByVal nCount As Long) As Long
Public Declare Function lua_gethook Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function lua_gethookmask Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function lua_gethookcount Lib "lua5.1.dll" (ByVal hState As Long) As Long

'struct lua_Debug {
'  int event;
'  const char *name; /* (n) */
'  const char *namewhat; /* (n) `global', `local', `field', `method' */
'  const char *what; /* (S) `Lua', `C', `main', `tail' */
'  const char *source;   /* (S) */
'  int currentline;  /* (l) */
'  int nups;     /* (u) number of upvalues */
'  int linedefined;  /* (S) */
'  int lastlinedefined;  /* (S) */
'  char short_src[LUA_IDSIZE]; /* (S) */
'  /* private part */
'  int i_ci;  /* active function */
'};

Public Type lua_Debug
 nEvent As Long
 lpstrName As String
 lpstrNameWhat As String
 lpstrWhat As String
 lpstrSource As String
 nCurrentLine As Long
 nups As Long
 nLineDefined As Long
 nLastLineDefined As Long
 short_src(LUA_IDSIZE - 1) As Byte
 i_ci As Long
End Type

Public Declare Function luaopen_base Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function luaopen_table Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function luaopen_io Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function luaopen_os Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function luaopen_string Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function luaopen_math Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function luaopen_debug Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function luaopen_package Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function luaL_openlibs Lib "lua5.1.dll" (ByVal hState As Long) As Long

'/* extra error code for `luaL_load' */
Public Const LUA_ERRFILE As Long = (LUA_ERRERR + 1)

Public Type luaL_Reg
 lpstrName As Long
 lpFunc As Long
End Type

Public Declare Function luaL_openlib Lib "lua5.1.dll" (ByVal hState As Long, ByVal sLibName As String, ByRef l As luaL_Reg, ByVal nup As Long) As Long
Public Declare Function luaL_register Lib "lua5.1.dll" (ByVal hState As Long, ByVal sLibName As String, ByRef l As luaL_Reg) As Long
Public Declare Function luaL_getmetafield Lib "lua5.1.dll" (ByVal hState As Long, ByVal obj As Long, ByVal e As String) As Long
Public Declare Function luaL_callmeta Lib "lua5.1.dll" (ByVal hState As Long, ByVal obj As Long, ByVal e As String) As Long
Public Declare Function luaL_typerror Lib "lua5.1.dll" (ByVal hState As Long, ByVal nArg As Long, ByVal tname As String) As Long
Public Declare Function luaL_argerror Lib "lua5.1.dll" (ByVal hState As Long, ByVal numArg As Long, ByVal extramsg As String) As Long
Public Declare Function luaL_checklstring Lib "lua5.1.dll" (ByVal hState As Long, ByVal numArg As Long, ByRef l As Long) As Long
Public Declare Function luaL_optlstring Lib "lua5.1.dll" (ByVal hState As Long, ByVal numArg As Long, ByVal def As String, ByRef l As Long) As Long
Public Declare Function luaL_checknumber Lib "lua5.1.dll" (ByVal hState As Long, ByVal numArg As Long) As Double
Public Declare Function luaL_optnumber Lib "lua5.1.dll" (ByVal hState As Long, ByVal nArg As Long, ByVal def As Double) As Double
Public Declare Function luaL_checkinteger Lib "lua5.1.dll" (ByVal hState As Long, ByVal numArg As Long) As Long
Public Declare Function luaL_optinteger Lib "lua5.1.dll" (ByVal hState As Long, ByVal nArg As Long, ByVal def As Long) As Long

Public Declare Function luaL_checkstack Lib "lua5.1.dll" (ByVal hState As Long, ByVal sz As Long, ByVal sMsg As String) As Long
Public Declare Function luaL_checktype Lib "lua5.1.dll" (ByVal hState As Long, ByVal nArg As Long, ByVal t As Long) As Long
Public Declare Function luaL_checkany Lib "lua5.1.dll" (ByVal hState As Long, ByVal nArg As Long) As Long

Public Declare Function luaL_newmetatable Lib "lua5.1.dll" (ByVal hState As Long, ByVal tname As String) As Long
Public Declare Function luaL_checkudata Lib "lua5.1.dll" (ByVal hState As Long, ByVal ud As Long, ByVal tname As String) As Long

Public Declare Function luaL_where Lib "lua5.1.dll" (ByVal hState As Long, ByVal nLevel As Long) As Long
'LUALIB_API int (luaL_error) (lua_State *L, const char *fmt, ...);
Public Declare Function luaL_error_1 Lib "lua5.1.dll" (ByVal hState As Long, ByVal s As String) As Long

Public Declare Function luaL_checkoption Lib "lua5.1.dll" (ByVal hState As Long, ByVal nArg As Long, ByVal def As String, ByRef lst As Any) As Long

Public Declare Function luaL_ref Lib "lua5.1.dll" (ByVal hState As Long, ByVal t As Long) As Long
Public Declare Function luaL_unref Lib "lua5.1.dll" (ByVal hState As Long, ByVal t As Long, ByVal ref As Long) As Long

Public Declare Function luaL_loadfile Lib "lua5.1.dll" (ByVal hState As Long, ByVal sFileName As String) As Long
Public Declare Function luaL_loadbuffer Lib "lua5.1.dll" (ByVal hState As Long, ByRef lpBuffer As Any, ByVal sz As Long, ByVal sName As String) As Long
Public Declare Function luaL_loadstring Lib "lua5.1.dll" (ByVal hState As Long, ByVal s As String) As Long

Public Declare Function luaL_newstate Lib "lua5.1.dll" () As Long

Public Declare Function luaL_gsub Lib "lua5.1.dll" (ByVal hState As Long, ByVal s As String, ByVal p As String, ByVal r As String) As Long
Public Declare Function luaL_findtable Lib "lua5.1.dll" (ByVal hState As Long, ByVal nIndex As Long, ByVal fname As String, ByVal szHint As Long) As Long

'/*
'** {======================================================
'** Generic Buffer manipulation
'** =======================================================
'*/

Public Type luaL_Buffer
 p As Long '       /* current position in buffer */
 nLevel As Long '  /* number of strings in the stack (level) */
 hState As Long
 bBuffer(LUAL_BUFFERSIZE - 1) As Long
End Type

Public Declare Function luaL_buffinit Lib "lua5.1.dll" (ByVal hState As Long, ByRef b As luaL_Buffer) As Long
Public Declare Function luaL_prepbuffer Lib "lua5.1.dll" (ByRef b As luaL_Buffer) As Long
Public Declare Function luaL_addlstring Lib "lua5.1.dll" (ByRef b As luaL_Buffer, ByVal s As String, ByVal l As Long) As Long
Public Declare Function luaL_addstring Lib "lua5.1.dll" (ByRef b As luaL_Buffer, ByVal s As String) As Long
Public Declare Function luaL_addvalue Lib "lua5.1.dll" (ByRef b As luaL_Buffer) As Long
Public Declare Function luaL_pushresult Lib "lua5.1.dll" (ByRef b As luaL_Buffer) As Long

'/* }====================================================== */

'/* compatibility with ref system */
'
'/* pre-defined references */
Public Const LUA_NOREF As Long = (-2)
Public Const LUA_REFNIL As Long = (-1)

'#define luaL_reg    luaL_Reg

Public Function lua_upvalueindex(ByVal i As Long) As Long
lua_upvalueindex = (LUA_GLOBALSINDEX - (i))
End Function

'/*
'** ===============================================================
'** some useful macros
'** ===============================================================
'*/

Public Function lua_pop(ByVal hState As Long, ByVal n As Long) As Long
lua_pop = lua_settop(hState, -n - 1)
End Function

Public Function lua_newtable(ByVal hState As Long) As Long
lua_newtable = lua_createtable(hState, 0, 0)
End Function

Public Function lua_register(ByVal hState As Long, ByRef s As String, ByVal lpfn As Long) As Long
lua_pushcfunction hState, lpfn
lua_register = lua_setglobal(hState, s)
End Function

Public Function lua_pushcfunction(ByVal hState As Long, ByVal lpfn As Long) As Long
lua_pushcfunction = lua_pushcclosure(hState, lpfn, 0)
End Function

Public Function lua_strlen(ByVal hState As Long, ByVal nIndex As Long) As Long
lua_strlen = lua_objlen(hState, nIndex)
End Function

Public Function lua_isfunction(ByVal hState As Long, ByVal nIndex As Long) As Boolean
lua_isfunction = lua_type(hState, nIndex) = LUA_TFUNCTION
End Function

Public Function lua_istable(ByVal hState As Long, ByVal nIndex As Long) As Boolean
lua_istable = lua_type(hState, nIndex) = LUA_TTABLE
End Function

Public Function lua_islightuserdata(ByVal hState As Long, ByVal nIndex As Long) As Boolean
lua_islightuserdata = lua_type(hState, nIndex) = LUA_TLIGHTUSERDATA
End Function

Public Function lua_isnil(ByVal hState As Long, ByVal nIndex As Long) As Boolean
lua_isnil = lua_type(hState, nIndex) = LUA_TNIL
End Function

Public Function lua_isboolean(ByVal hState As Long, ByVal nIndex As Long) As Boolean
lua_isboolean = lua_type(hState, nIndex) = LUA_TBOOLEAN
End Function

Public Function lua_isthread(ByVal hState As Long, ByVal nIndex As Long) As Boolean
lua_isthread = lua_type(hState, nIndex) = LUA_TTHREAD
End Function

Public Function lua_isnone(ByVal hState As Long, ByVal nIndex As Long) As Boolean
lua_isnone = lua_type(hState, nIndex) = LUA_TNONE
End Function

Public Function lua_isnoneornil(ByVal hState As Long, ByVal nIndex As Long) As Boolean
lua_isnoneornil = lua_type(hState, nIndex) <= 0
End Function

'#define lua_pushliteral(L, s)   \
'    lua_pushlstring(L, "" s, (sizeof(s)/sizeof(char))-1)

Public Function lua_setglobal(ByVal hState As Long, ByRef s As String) As Long
lua_setglobal = lua_setfield(hState, LUA_GLOBALSINDEX, s)
End Function

Public Function lua_getglobal(ByVal hState As Long, ByRef s As String) As Long
lua_getglobal = lua_getfield(hState, LUA_GLOBALSINDEX, s)
End Function

Public Function lua_tostring(ByVal hState As Long, ByVal nIndex As Long) As String
Dim lp As Long, m As Long
Dim b() As Byte
lp = lua_tolstring(hState, nIndex, m)
If m > 0 Then
 ReDim b(m - 1)
 CopyMemory b(0), ByVal lp, m
 lua_tostring = StrConv(b, vbUnicode)
End If
End Function

'/*
'** compatibility macros and functions
'*/

Public Function lua_open() As Long
lua_open = luaL_newstate
End Function

Public Function lua_getregistry(ByVal hState As Long) As Long
lua_getregistry = lua_pushvalue(hState, LUA_REGISTRYINDEX)
End Function

Public Function lua_getgccount(ByVal hState As Long) As Long
lua_getgccount = lua_gc(hState, LUA_GCCOUNT, 0)
End Function

'#define lua_Chunkreader     lua_Reader
'#define lua_Chunkwriter     lua_Writer

'/*
'** ===============================================================
'** some useful macros
'** ===============================================================
'*/
'
'#define luaL_argcheck(L, cond,numarg,extramsg)  \
'        ((void)((cond) || luaL_argerror(L, (numarg), (extramsg))))

Public Function luaL_checkstring(ByVal hState As Long, ByVal n As Long) As Long
luaL_checkstring = luaL_checklstring(hState, n, ByVal 0)
End Function

Public Function luaL_optstring(ByVal hState As Long, ByVal n As Long, ByRef d As String) As Long
luaL_optstring = luaL_optlstring(hState, n, d, ByVal 0)
End Function

Public Function luaL_typename(ByVal hState As Long, ByVal i As Long) As String
Dim lp As Long
Dim s As String
lp = lua_typename(hState, lua_type(hState, i))
s = Space(1024)
CopyMemory ByVal StrPtr(s), lp, 2048&
lp = InStrB(1, s, ChrB(0))
If lp > 0 Then s = LeftB(s, lp - 1)
luaL_typename = StrConv(s, vbUnicode)
End Function

Public Function luaL_dofile(ByVal hState As Long, ByRef fn As String) As Boolean
luaL_dofile = luaL_loadfile(hState, fn)
If Not luaL_dofile Then luaL_dofile = lua_pcall(hState, 0, LUA_MULTRET, 0)
End Function

Public Function luaL_dostring(ByVal hState As Long, ByRef s As String) As Boolean
luaL_dostring = luaL_loadstring(hState, s)
If Not luaL_dostring Then luaL_dostring = lua_pcall(hState, 0, LUA_MULTRET, 0)
End Function

Public Function luaL_getmetatable(ByVal hState As Long, ByRef n As String) As Long
luaL_getmetatable = lua_getfield(hState, LUA_REGISTRYINDEX, n)
End Function

'#define luaL_opt(L,f,n,d)   (lua_isnoneornil(L,(n)) ? (d) : f(L,(n)))

Public Function luaL_addchar(ByRef b As luaL_Buffer, ByVal c As Byte) As Long
Dim lp As Long
lp = VarPtr(b.bBuffer(0))
If b.p >= lp + LUAL_BUFFERSIZE Then luaL_prepbuffer b
b.bBuffer(b.p - lp) = c
b.p = b.p + 1
luaL_addchar = c
End Function

'/* compatibility only */
'#define luaL_putchar(B,c)   luaL_addchar(B,c)

Public Function luaL_addsize(ByRef b As luaL_Buffer, ByVal n As Long) As Long
b.p = b.p + n
luaL_addsize = b.p
End Function

Public Function lua_ref(ByVal hState As Long) As Long
lua_ref = luaL_ref(hState, LUA_REGISTRYINDEX)
End Function

Public Function lua_unref(ByVal hState As Long, ByVal ref As Long) As Long
lua_unref = luaL_unref(hState, LUA_REGISTRYINDEX, ref)
End Function

Public Function lua_getref(ByVal hState As Long, ByVal ref As Long) As Long
lua_getref = lua_rawgeti(hState, LUA_REGISTRYINDEX, ref)
End Function
