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

Public Declare Function LibMiniCreateStub Lib "libmini.dll" (ByRef lpImage As Any, _
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

Public Declare Function LibMiniCreateStubFloat Lib "libmini.dll" (ByRef lpImage As Any, _
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

Public Declare Sub LibMiniDestroyStub Lib "libmini.dll" (ByVal stub As Long)

'   //! draw scene
'   void draw(float res, // resolution
'             float ex,float ey,float ez, // eye point
'             float dx,float dy,float dz, // view direction
'             float ux,float uy,float uz, // up vector
'             float fovy,float aspect, // field of view and aspect
'             float nearp,float farp); // near and far plane

Public Declare Sub LibMiniStub_Draw Lib "libmini.dll" (ByVal stub As Long, ByVal res As Single, _
ByVal ex As Single, ByVal ey As Single, ByVal ez As Single, _
ByVal dx As Single, ByVal dy As Single, ByVal dz As Single, _
ByVal ux As Single, ByVal uy As Single, ByVal uz As Single, _
ByVal fovy As Single, ByVal aspect As Single, _
ByVal nearp As Single, ByVal farp As Single)

