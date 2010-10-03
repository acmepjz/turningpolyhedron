Attribute VB_Name = "mdlLibMini"
Option Explicit

'   ministub(short int *image, // height field is a short int array
'            int *size,float *dim,float scale,float cellaspect, // grid definition
'            float centerx,float centery,float centerz, // grid center
'            void (*beginfan)(),void (*fanvertex)(float i,float y,float j), // mandatory callbacks
'            void (*notify)(int i,int j,int s)=0, // optional callback
'            short int (*getelevation)(int i,int j,int S,void *data)=0, // optional elevation callback
'            void *objref=0, // optional data pointer that is passed to the elevation callback
'            unsigned char *fogimage=0, // optional ground fog layer
'            int fogsize=0,float lambda=0.0f,float displace=0.0f,float attenuation=1.0f,
'            void (*prismedge)(float x,float y,float yf,float z)=0,
'            void **d2map2=0,int *size2=0,
'            float minres=0.0f,float minoff=0.0f,
'            float maxd2=0.0f,float sead2=0.0f,
'            float seamin=0.0f,float seamax=0.0f,
'            int maxcull=0);

Public Declare Function MiniStub_Create Lib "libmini.dll" (ByRef lpImage As Any, _
ByRef nSize As Long, ByRef nDim As Single, ByVal nScale As Single, ByVal nCellAspect As Single, _
ByVal nCenterX As Single, ByVal nCenterY As Single, ByVal nCenterZ As Single, _
ByVal lpfnBeginFan As Long, ByVal lpfnFanVertex As Long, _
ByVal lpfnNotify As Long, _
ByVal lpfnGetElevation As Long, _
ByVal nUserData As Long, _
ByRef lpFogImage As Any, _
ByVal nFogSize As Long, ByVal nLambda As Single, ByVal nDisplace As Single, ByVal nAttenuation As Single, _
ByVal lpfnPrismEdge As Long, _
ByRef d2map2 As Any, ByRef nSize2 As Any, _
ByVal nMinRes As Single, ByVal nMinOff As Single, _
ByVal maxd2 As Single, ByVal sead2 As Single, _
ByVal nSeaMin As Single, ByVal nSeaMax As Single, _
ByVal nMaxCull As Long) As Long

'   ministub(float *image, // height field is a float array
'            int *size,float *dim,float scale,float cellaspect, // grid definition
'            float centerx,float centery,float centerz, // grid center
'            void (*beginfan)(),void (*fanvertex)(float i,float y,float j), // mandatory callbacks
'            void (*notify)(int i,int j,int s)=0, // optional callback
'            float (*getelevation)(int i,int j,int S,void *data)=0, // optional elevation callback
'            void *objref=0, // optional data pointer that is passed to the elevation callback
'            unsigned char *fogimage=0, // optional ground fog layer
'            int fogsize=0,float lambda=0.0f,float displace=0.0f,float attenuation=1.0f,
'            void (*prismedge)(float x,float y,float yf,float z)=0,
'            void **d2map2=0,int *size2=0,
'            float minres=0.0f,float minoff=0.0f,
'            float maxd2=0.0f,float sead2=0.0f,
'            float seamin=0.0f,float seamax=0.0f,
'            int maxcull=0);

Public Declare Function MiniStub_CreateFloat Lib "libmini.dll" (ByRef lpImage As Any, _
ByRef nSize As Long, ByRef nDim As Single, ByVal nScale As Single, ByVal nCellAspect As Single, _
ByVal nCenterX As Single, ByVal nCenterY As Single, ByVal nCenterZ As Single, _
ByVal lpfnBeginFan As Long, ByVal lpfnFanVertex As Long, _
ByVal lpfnNotify As Long, _
ByVal lpfnGetElevation As Long, _
ByVal nUserData As Long, _
ByRef lpFogImage As Any, _
ByVal nFogSize As Long, ByVal nLambda As Single, ByVal nDisplace As Single, ByVal nAttenuation As Single, _
ByVal lpfnPrismEdge As Long, _
ByRef d2map2 As Any, ByRef nSize2 As Any, _
ByVal nMinRes As Single, ByVal nMinOff As Single, _
ByVal maxd2 As Single, ByVal sead2 As Single, _
ByVal nSeaMin As Single, ByVal nSeaMax As Single, _
ByVal nMaxCull As Long) As Long

Public Declare Sub MiniStub_Destroy Lib "libmini.dll" (ByVal stub As Long)

'   //! draw scene
'   void draw(float res, // resolution
'             float ex,float ey,float ez, // eye point
'             float dx,float dy,float dz, // view direction
'             float ux,float uy,float uz, // up vector
'             float fovy,float aspect, // field of view and aspect
'             float nearp,float farp); // near and far plane

Public Declare Sub MiniStub_Draw Lib "libmini.dll" (ByVal stub As Long, ByVal res As Single, _
ByVal ex As Single, ByVal ey As Single, ByVal ez As Single, _
ByVal dx As Single, ByVal dy As Single, ByVal dz As Single, _
ByVal ux As Single, ByVal uy As Single, ByVal uz As Single, _
ByVal fovy As Single, ByVal aspect As Single, _
ByVal nearp As Single, ByVal farp As Single)

'//! set focus of interest (equal to eye point by default)
Public Declare Sub MiniStub_SetFocus Lib "libmini.dll" (ByVal stub As Long, ByVal bEnabled As Long, ByVal fx As Single, ByVal fy As Single, ByVal fz As Single)

'//! define relative scaling (0<=scale<=1)
Public Declare Sub MiniStub_SetRelScale Lib "libmini.dll" (ByVal stub As Long, ByVal nScale As Single)

'//! set sea level
'void MiniStub_SetSeaLevel(ministub* stub,float level){stub->setsealevel(level);}
Public Declare Sub MiniStub_SetSeaLevel Lib "libmini.dll" (ByVal stub As Long, ByVal nLevel As Single)

'//! get-functions for geometric properties
Public Declare Function MiniStub_GetHeight Lib "libmini.dll" (ByVal stub As Long, ByVal i As Long, ByVal j As Long) As Single
Public Declare Function MiniStub_GetHeightFloat Lib "libmini.dll" (ByVal stub As Long, ByVal x As Single, ByVal z As Single) As Single
Public Declare Function MiniStub_GetFogHeight Lib "libmini.dll" (ByVal stub As Long, ByVal x As Single, ByVal z As Single) As Single
Public Declare Sub MiniStub_GetNormal Lib "libmini.dll" (ByVal stub As Long, ByVal x As Single, ByVal z As Single, ByRef nx As Single, ByRef ny As Single, ByRef nz As Single)

'//! get-functions for geometric settings
Public Declare Function MiniStub_GetSize Lib "libmini.dll" (ByVal stub As Long) As Long

Public Declare Function MiniStub_GetDim Lib "libmini.dll" (ByVal stub As Long) As Single
Public Declare Function MiniStub_GetScale Lib "libmini.dll" (ByVal stub As Long) As Single
Public Declare Function MiniStub_GetCellAspect Lib "libmini.dll" (ByVal stub As Long) As Single
Public Declare Function MiniStub_GetCenterX Lib "libmini.dll" (ByVal stub As Long) As Single
Public Declare Function MiniStub_GetCenterY Lib "libmini.dll" (ByVal stub As Long) As Single
Public Declare Function MiniStub_GetCenterZ Lib "libmini.dll" (ByVal stub As Long) As Single
Public Declare Function MiniStub_GetLambda Lib "libmini.dll" (ByVal stub As Long) As Single
Public Declare Function MiniStub_GetDisplace Lib "libmini.dll" (ByVal stub As Long) As Single
Public Declare Function MiniStub_GetRelScale Lib "libmini.dll" (ByVal stub As Long) As Single
Public Declare Function MiniStub_GetSeaLevel Lib "libmini.dll" (ByVal stub As Long) As Single

'//! modify the terrain at run time
Public Declare Sub MiniStub_SetHeight Lib "libmini.dll" (ByVal stub As Long, ByVal i As Long, ByVal j As Long, ByVal h As Single)
Public Declare Sub MiniStub_SetHeightFloat Lib "libmini.dll" (ByVal stub As Long, ByVal x As Single, ByVal z As Single, ByVal h As Single)
Public Declare Sub MiniStub_SetRealHeight Lib "libmini.dll" (ByVal stub As Long, ByVal i As Long, ByVal j As Long, ByVal h As Single)
Public Declare Sub MiniStub_SetRealHeightFloat Lib "libmini.dll" (ByVal stub As Long, ByVal x As Single, ByVal z As Single, ByVal h As Single)

'//! enable fast update
Public Declare Sub MiniStub_SetFastUpdate Lib "libmini.dll" (ByVal stub As Long, ByVal bEnabled As Long)

'////////////////////////////////

'void SetMiniErrorHandler(void (*handler)(const char *file,int line,int fatal)=0){setminierrorhandler(handler);}
Public Declare Sub SetMiniErrorHandler Lib "libmini.dll" (ByVal lpfnHandler As Long)

'////////////////////////////////

'void Mini_SetParams(float minr=9.0f,
'               float maxd2=100.0f,
'               float sead2=0.5f,
'               float mino=0.1f,
'               int maxc=8){return mini::setparams(minr,maxd2,sead2,mino,maxc);}
Public Declare Sub Mini_SetParams Lib "libmini.dll" (ByVal minr As Single, ByVal maxd2 As Single, ByVal sead2 As Single, ByVal mino As Single, ByVal maxc As Long)

'void *Mini_InitMap(short int *image,void **d2map,
'              int *size,float *dim,float scale,
'              float cellaspect=1.0f,
'              short int (*getelevation)(int i,int j,int size,void *data)=0,
'              void *objref=0,
'              int fast=0,float avgd2=0.0f){return mini::initmap(image,d2map,size,dim,scale,cellaspect,getelevation,objref,fast,avgd2);}
Public Declare Function Mini_InitMap Lib "libmini.dll" (ByRef lpImage As Any, ByRef d2map As Long, ByRef nSize As Long, ByRef nDim As Single, ByVal nScale As Single, ByVal nCellAspect As Single, ByVal lpfnGetElevation As Long, _
ByVal nUserData As Long, ByVal bFast As Long, ByVal avgd2 As Single) As Long

'int Mini_InitTexMap(unsigned char *image=0,int *width=0,int *height=0,
'               int mipmaps=1,int s3tc=0,int rgba=0,int bytes=0,int mipmapped=0){return mini::inittexmap(image,width,height,mipmaps,s3tc,rgba,bytes,mipmapped);}
Public Declare Function Mini_InitTexMap Lib "libmini.dll" (ByRef lpImage As Any, ByRef lpWidth As Any, ByRef lpHeight As Any, ByVal nMipMaps As Long, ByVal s3tc As Long, ByVal rgba As Long, ByVal bytes As Long, ByVal bMipMapped As Long) As Long

'void *Mini_InitFogMap(unsigned char *image,int size,
'                 float lambda,float displace,float emission,
'                 float fogatt=1.0f,float fogR=1.0f,float fogG=1.0f,float fogB=1.0f,
'                 int fast=0){return mini::initfogmap(image,size,lambda,displace,emission,fogatt,fogR,fogG,fogB,fast);}
Public Declare Function Mini_InitFogMap Lib "libmini.dll" (ByRef lpImage As Any, ByVal nFogSize As Long, ByVal nLambda As Single, ByVal nDisplace As Single, ByVal nEmission As Single, ByVal nAttenuation As Single, _
ByVal nFogR As Single, ByVal nFogG As Single, ByVal nFogB As Single, ByVal bFast As Long) As Long

'void Mini_SetMaps(void *map,void *d2map,
'             int size,float dim,float scale,
'             int texid=0,int width=0,int height=0,int mipmaps=1,
'             float cellaspect=1.0f,
'             float ox=0.0f,float oy=0.0f,float oz=0.0f,
'             void **d2map2=0,int *size2=0,
'             void *fogmap=0,float lambda=0.0f,float displace=0.0f,
'             float emission=0.0f,float fogatt=1.0f,float fogR=1.0f,float fogG=1.0f,float fogB=1.0f){return mini::setmaps(map,d2map,size,dim,scale,texid,width,height,mipmaps,cellaspect,ox,oy,oz,d2map2,size2,fogmap,lambda,displace,emission,fogatt,fogR,fogG,fogB);}
Public Declare Sub Mini_SetMaps Lib "libmini.dll" (ByVal hMap As Long, ByVal d2map As Long, ByVal nSize As Long, ByVal nDim As Single, ByVal nScale As Single, ByVal nTexId As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal nMipMaps As Long, ByVal nCellAspect As Single, _
ByVal ox As Single, ByVal oy As Single, ByVal oz As Single, ByRef d2map2 As Any, ByRef nSize2 As Any, _
ByVal hFogMap As Long, ByVal nLambda As Single, ByVal nDisplace As Single, ByVal nEmission As Single, ByVal nAttenuation As Single, _
ByVal nFogR As Single, ByVal nFogG As Single, ByVal nFogB As Single)

Public Declare Sub Mini_SetSea Lib "libmini.dll" (ByVal nLevel As Single)
Public Declare Sub Mini_SetSeaRange Lib "libmini.dll" (ByVal nSeaMin As Single, ByVal nSeaMax As Single)

'void Mini_DrawLandScape(float res,
'                   float ex,float ey,float ez,
'                   float fx,float fy,float fz,
'                   float dx,float dy,float dz,
'                   float ux,float uy,float uz,
'                   float fovy,float aspect,
'                   float nearp,float farp,
'                   void (*beginfan)()=0,
'                   void (*fanvertex)(float i,float y,float j)=0,
'                   void (*notify)(int i,int j,int s)=0,
'                   void (*prismedge)(float x,float y,float yf,float z)=0,
'                   int state=0){return mini::drawlandscape(res,ex,ey,ez,fx,fy,fz,dx,dy,dz,ux,uy,uz,fovy,aspect,nearp,farp,beginfan,fanvertex,notify,prismedge,state);}
Public Declare Sub Mini_DrawLandScape Lib "libmini.dll" (ByVal res As Single, _
ByVal ex As Single, ByVal ey As Single, ByVal ez As Single, _
ByVal fx As Single, ByVal fy As Single, ByVal fz As Single, _
ByVal dx As Single, ByVal dy As Single, ByVal dz As Single, _
ByVal ux As Single, ByVal uy As Single, ByVal uz As Single, _
ByVal fovy As Single, ByVal aspect As Single, _
ByVal nearp As Single, ByVal farp As Single, ByVal lpfnBeginFan As Long, ByVal lpfnFanVertex As Long, _
ByVal lpfnNotify As Long, ByVal lpfnPrismEdge As Long, ByVal nState As Long)

Public Declare Sub Mini_CheckLandScape Lib "libmini.dll" (ByVal ex As Single, ByVal ey As Single, ByVal ez As Single, _
ByVal dx As Single, ByVal dy As Single, ByVal dz As Single, _
ByVal ux As Single, ByVal uy As Single, ByVal uz As Single, _
ByVal fovy As Single, ByVal aspect As Single, _
ByVal nearp As Single, ByVal farp As Single)

'void Mini_DrawPrismCache(float ex,float ey,float ez,
'                    float dx,float dy,float dz,
'                    float nearp,float farp,
'                    float emission=0.0f,float fogR=1.0f,float fogG=1.0f,float fogB=1.0f,
'                    float *prismcache=0,int prismcnt=0){return mini::drawprismcache(ex,ey,ez,dx,dy,dz,nearp,farp,emission,fogR,fogG,fogB,prismcache,prismcnt);}
Public Declare Sub Mini_DrawPrismCache Lib "libmini.dll" (ByVal ex As Single, ByVal ey As Single, ByVal ez As Single, _
ByVal dx As Single, ByVal dy As Single, ByVal dz As Single, _
ByVal nearp As Single, ByVal farp As Single, ByVal nEmission As Single, _
ByVal nFogR As Single, ByVal nFogG As Single, ByVal nFogB As Single, ByRef lpPrismCache As Any, ByVal nPrismCount As Long)

Public Declare Function Mini_GetHeight Lib "libmini.dll" (ByVal i As Long, ByVal j As Long) As Single
Public Declare Function Mini_GetHeightFloatByCoordinates Lib "libmini.dll" (ByVal s As Single, ByVal t As Single) As Single
Public Declare Function Mini_GetHeightFloatByPosition Lib "libmini.dll" (ByVal x As Single, ByVal z As Single) As Single
Public Declare Function Mini_GetFogHeight Lib "libmini.dll" (ByVal x As Single, ByVal z As Single) As Single
Public Declare Sub Mini_GetNormalByCoordinates Lib "libmini.dll" (ByVal s As Single, ByVal t As Single, ByRef nx As Single, ByRef nz As Single)
Public Declare Sub Mini_GetNormalByPosition Lib "libmini.dll" (ByVal x As Single, ByVal y As Single, ByRef nx As Single, ByRef ny As Single, ByRef nz As Single)
Public Declare Function Mini_GetMaxSize Lib "libmini.dll" (ByVal res As Single, ByVal fx As Single, ByVal fy As Single, ByVal fz As Single, ByVal fovy As Single) As Long

Public Declare Sub Mini_SetHeight Lib "libmini.dll" (ByVal i As Long, ByVal j As Long, ByVal h As Single)
Public Declare Sub Mini_SetHeightFloat Lib "libmini.dll" (ByVal x As Single, ByVal z As Single, ByVal h As Single)
Public Declare Sub Mini_SetRealHeight Lib "libmini.dll" (ByVal i As Long, ByVal j As Long, ByVal h As Single)
Public Declare Sub Mini_SetRealHeightFloat Lib "libmini.dll" (ByVal x As Single, ByVal z As Single, ByVal h As Single)

Public Declare Sub Mini_UpdateMaps Lib "libmini.dll" (ByVal bFast As Long, ByVal avgd2 As Single, ByVal bReCalc As Long)
Public Declare Sub Mini_DeleteMaps Lib "libmini.dll" ()

'inline float getX(const float i)
'   {return((i-S/2)*Dx+OX);}
'inline float getY(const float y)
'   {return(y*SCALE+OY);}
'inline float getZ(const float j)
'   {return((S/2-j)*Dz+OZ);}
Public Declare Function Mini_GetX Lib "libmini.dll" (ByVal i As Single) As Single
Public Declare Function Mini_GetY Lib "libmini.dll" (ByVal y As Single) As Single
Public Declare Function Mini_GetZ Lib "libmini.dll" (ByVal j As Single) As Single

'////////////////////////////////

Public Declare Sub MiniFloat_SetParams Lib "libmini.dll" (ByVal minr As Single, ByVal maxd2 As Single, ByVal sead2 As Single, ByVal mino As Single, ByVal maxc As Long)

'void *MiniFloat_InitMap(float *image,void **d2map,
'              int *size,float *dim,float scale,
'              float cellaspect=1.0f,
'              float (*getelevation)(int i,int j,int size,void *data)=0,
'              void *objref=0,
'              int fast=0,float avgd2=0.0f){return Mini::initmap(image,d2map,size,dim,scale,cellaspect,getelevation,objref,fast,avgd2);}
Public Declare Function MiniFloat_InitMap Lib "libmini.dll" (ByRef lpImage As Any, ByRef d2map As Long, ByRef nSize As Long, ByRef nDim As Single, ByVal nScale As Single, ByVal nCellAspect As Single, ByVal lpfnGetElevation As Long, _
ByVal nUserData As Long, ByVal bFast As Long, ByVal avgd2 As Single) As Long

Public Declare Function MiniFloat_InitTexMap Lib "libmini.dll" (ByRef lpImage As Any, ByRef lpWidth As Any, ByRef lpHeight As Any, ByVal nMipMaps As Long, ByVal s3tc As Long, ByVal rgba As Long, ByVal bytes As Long, ByVal bMipMapped As Long) As Long

Public Declare Function MiniFloat_InitFogMap Lib "libmini.dll" (ByRef lpImage As Any, ByVal nFogSize As Long, ByVal nLambda As Single, ByVal nDisplace As Single, ByVal nEmission As Single, ByVal nAttenuation As Single, _
ByVal nFogR As Single, ByVal nFogG As Single, ByVal nFogB As Single, ByVal bFast As Long) As Long

Public Declare Sub MiniFloat_SetMaps Lib "libmini.dll" (ByVal hMap As Long, ByVal d2map As Long, ByVal nSize As Long, ByVal nDim As Single, ByVal nScale As Single, ByVal nTexId As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal nMipMaps As Long, ByVal nCellAspect As Single, _
ByVal ox As Single, ByVal oy As Single, ByVal oz As Single, ByRef d2map2 As Any, ByRef nSize2 As Any, _
ByVal hFogMap As Long, ByVal nLambda As Single, ByVal nDisplace As Single, ByVal nEmission As Single, ByVal nAttenuation As Single, _
ByVal nFogR As Single, ByVal nFogG As Single, ByVal nFogB As Single)

Public Declare Sub MiniFloat_SetSea Lib "libmini.dll" (ByVal nLevel As Single)
Public Declare Sub MiniFloat_SetSeaRange Lib "libmini.dll" (ByVal nSeaMin As Single, ByVal nSeaMax As Single)

Public Declare Sub MiniFloat_DrawLandScape Lib "libmini.dll" (ByVal res As Single, _
ByVal ex As Single, ByVal ey As Single, ByVal ez As Single, _
ByVal fx As Single, ByVal fy As Single, ByVal fz As Single, _
ByVal dx As Single, ByVal dy As Single, ByVal dz As Single, _
ByVal ux As Single, ByVal uy As Single, ByVal uz As Single, _
ByVal fovy As Single, ByVal aspect As Single, _
ByVal nearp As Single, ByVal farp As Single, ByVal lpfnBeginFan As Long, ByVal lpfnFanVertex As Long, _
ByVal lpfnNotify As Long, ByVal lpfnPrismEdge As Long, ByVal nState As Long)

Public Declare Sub MiniFloat_CheckLandScape Lib "libmini.dll" (ByVal ex As Single, ByVal ey As Single, ByVal ez As Single, _
ByVal dx As Single, ByVal dy As Single, ByVal dz As Single, _
ByVal ux As Single, ByVal uy As Single, ByVal uz As Single, _
ByVal fovy As Single, ByVal aspect As Single, _
ByVal nearp As Single, ByVal farp As Single)

Public Declare Sub MiniFloat_DrawPrismCache Lib "libmini.dll" (ByVal ex As Single, ByVal ey As Single, ByVal ez As Single, _
ByVal dx As Single, ByVal dy As Single, ByVal dz As Single, _
ByVal nearp As Single, ByVal farp As Single, ByVal nEmission As Single, _
ByVal nFogR As Single, ByVal nFogG As Single, ByVal nFogB As Single, ByRef lpPrismCache As Any, ByVal nPrismCount As Long)

Public Declare Function MiniFloat_GetHeight Lib "libmini.dll" (ByVal i As Long, ByVal j As Long) As Single
Public Declare Function MiniFloat_GetHeightFloatByCoordinates Lib "libmini.dll" (ByVal s As Single, ByVal t As Single) As Single
Public Declare Function MiniFloat_GetHeightFloatByPosition Lib "libmini.dll" (ByVal x As Single, ByVal z As Single) As Single
Public Declare Function MiniFloat_GetFogHeight Lib "libmini.dll" (ByVal x As Single, ByVal z As Single) As Single
Public Declare Sub MiniFloat_GetNormalByCoordinates Lib "libmini.dll" (ByVal s As Single, ByVal t As Single, ByRef nx As Single, ByRef nz As Single)
Public Declare Sub MiniFloat_GetNormalByPosition Lib "libmini.dll" (ByVal x As Single, ByVal y As Single, ByRef nx As Single, ByRef ny As Single, ByRef nz As Single)
Public Declare Function MiniFloat_GetMaxSize Lib "libmini.dll" (ByVal res As Single, ByVal fx As Single, ByVal fy As Single, ByVal fz As Single, ByVal fovy As Single) As Long

Public Declare Sub MiniFloat_SetHeight Lib "libmini.dll" (ByVal i As Long, ByVal j As Long, ByVal h As Single)
Public Declare Sub MiniFloat_SetHeightFloat Lib "libmini.dll" (ByVal x As Single, ByVal z As Single, ByVal h As Single)
Public Declare Sub MiniFloat_SetRealHeight Lib "libmini.dll" (ByVal i As Long, ByVal j As Long, ByVal h As Single)
Public Declare Sub MiniFloat_SetRealHeightFloat Lib "libmini.dll" (ByVal x As Single, ByVal z As Single, ByVal h As Single)

Public Declare Sub MiniFloat_UpdateMaps Lib "libmini.dll" (ByVal bFast As Long, ByVal avgd2 As Single, ByVal bReCalc As Long)
Public Declare Sub MiniFloat_DeleteMaps Lib "libmini.dll" ()

Public Declare Function MiniFloat_GetX Lib "libmini.dll" (ByVal i As Single) As Single
Public Declare Function MiniFloat_GetY Lib "libmini.dll" (ByVal y As Single) As Single
Public Declare Function MiniFloat_GetZ Lib "libmini.dll" (ByVal j As Single) As Single


