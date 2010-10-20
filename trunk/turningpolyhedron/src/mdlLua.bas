Attribute VB_Name = "mdlLua"
Option Explicit

Public Const LUA_MULTRET As Long = (-1)

Public Const LUA_REGISTRYINDEX As Long = (-10000)
Public Const LUA_ENVIRONINDEX As Long = (-10001)
Public Const LUA_GLOBALSINDEX As Long = (-10002)

Public Const lua_yield As Long = 1
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

'/*
'** ===============================================================
'** some useful macros
'** ===============================================================
'*/

'#define lua_pop(L,n)        lua_settop(L, -(n)-1)
'
'#define lua_newtable(L)     lua_createtable(L, 0, 0)
'
'#define lua_register(L,n,f) (lua_pushcfunction(L, (f)), lua_setglobal(L, (n)))
'
'#define lua_pushcfunction(L,f)  lua_pushcclosure(L, (f), 0)
'
'#define lua_strlen(L,i)     lua_objlen(L, (i))
'
'#define lua_isfunction(L,n) (lua_type(L, (n)) == LUA_TFUNCTION)
'#define lua_istable(L,n)    (lua_type(L, (n)) == LUA_TTABLE)
'#define lua_islightuserdata(L,n)    (lua_type(L, (n)) == LUA_TLIGHTUSERDATA)
'#define lua_isnil(L,n)      (lua_type(L, (n)) == LUA_TNIL)
'#define lua_isboolean(L,n)  (lua_type(L, (n)) == LUA_TBOOLEAN)
'#define lua_isthread(L,n)   (lua_type(L, (n)) == LUA_TTHREAD)
'#define lua_isnone(L,n)     (lua_type(L, (n)) == LUA_TNONE)
'#define lua_isnoneornil(L, n)   (lua_type(L, (n)) <= 0)
'
'#define lua_pushliteral(L, s)   \
'    lua_pushlstring(L, "" s, (sizeof(s)/sizeof(char))-1)
'
'#define lua_setglobal(L,s)  lua_setfield(L, LUA_GLOBALSINDEX, (s))
'#define lua_getglobal(L,s)  lua_getfield(L, LUA_GLOBALSINDEX, (s))
'
'#define lua_tostring(L,i)   lua_tolstring(L, (i), NULL)
'
'
'
'/*
'** compatibility macros and functions
'*/
'
'#define lua_open()  luaL_newstate()
'
'#define lua_getregistry(L)  lua_pushvalue(L, LUA_REGISTRYINDEX)
'
'#define lua_getgccount(L)   lua_gc(L, LUA_GCCOUNT, 0)
'
'#define lua_Chunkreader     lua_Reader
'#define lua_Chunkwriter     lua_Writer
'
'
'/* hack */
'LUA_API void lua_setlevel   (lua_State *from, lua_State *to);
'
'
'/*
'** {======================================================================
'** Debug API
'** =======================================================================
'*/
'
'
'/*
'** Event codes
'*/
'#define LUA_HOOKCALL    0
'#define LUA_HOOKRET 1
'#define LUA_HOOKLINE    2
'#define LUA_HOOKCOUNT   3
'#define LUA_HOOKTAILRET 4
'
'
'/*
'** Event masks
'*/
'#define LUA_MASKCALL    (1 << LUA_HOOKCALL)
'#define LUA_MASKRET (1 << LUA_HOOKRET)
'#define LUA_MASKLINE    (1 << LUA_HOOKLINE)
'#define LUA_MASKCOUNT   (1 << LUA_HOOKCOUNT)
'
'typedef struct lua_Debug lua_Debug;  /* activation record */
'
'
'/* Functions to be called by the debuger in specific events */
'typedef void (*lua_Hook) (lua_State *L, lua_Debug *ar);
'
'
'LUA_API int lua_getstack (lua_State *L, int level, lua_Debug *ar);
'LUA_API int lua_getinfo (lua_State *L, const char *what, lua_Debug *ar);
'LUA_API const char *lua_getlocal (lua_State *L, const lua_Debug *ar, int n);
'LUA_API const char *lua_setlocal (lua_State *L, const lua_Debug *ar, int n);
'LUA_API const char *lua_getupvalue (lua_State *L, int funcindex, int n);
'LUA_API const char *lua_setupvalue (lua_State *L, int funcindex, int n);
'
'LUA_API int lua_sethook (lua_State *L, lua_Hook func, int mask, int count);
'LUA_API lua_Hook lua_gethook (lua_State *L);
'LUA_API int lua_gethookmask (lua_State *L);
'LUA_API int lua_gethookcount (lua_State *L);
'
'
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

Public Declare Function luaopen_base Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function luaopen_table Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function luaopen_io Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function luaopen_os Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function luaopen_string Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function luaopen_math Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function luaopen_debug Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function luaopen_package Lib "lua5.1.dll" (ByVal hState As Long) As Long
Public Declare Function luaL_openlibs Lib "lua5.1.dll" (ByVal hState As Long) As Long

Public Function lua_upvalueindex(ByVal i As Long) As Long
lua_upvalueindex = (LUA_GLOBALSINDEX - (i))
End Function


