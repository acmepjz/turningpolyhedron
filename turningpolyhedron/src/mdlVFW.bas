Attribute VB_Name = "mdlVFW"
Option Explicit

Public Declare Function VideoForWindowsVersion Lib "msvfw32.dll" () As Long

Declare Function ICClose Lib "msvfw32.dll" (ByVal hic As Long) As Long
Declare Function ICGetInfo Lib "msvfw32.dll" ( _
  ByVal hic As Long, _
  ByRef lpicinfo As tagICINFO, _
  ByVal cb As Long) As Long
Declare Function ICInfo Lib "msvfw32.dll" ( _
  ByVal fccType As Long, _
  ByVal fccHandler As Long, _
  ByRef lpicinfo As tagICINFO) As Long
Declare Function ICOpen Lib "msvfw32.dll" ( _
  ByVal fccType As Long, _
  ByVal fccHandler As Long, _
  ByVal wMode As Long) As Long
Declare Function ICSendMessage Lib "msvfw32.dll" ( _
  ByVal hic As Long, _
  ByVal wMsg As Long, _
  ByVal dw1 As Long, _
  ByVal dw2 As Long) As Long

Public Type RGBQUAD
    rgbBlue As Byte
    rgbGreen As Byte
    rgbRed As Byte
    rgbReserved As Byte
End Type

Public Type BITMAPINFOHEADER
    biSize As Long
    biWidth As Long
    biHeight As Long
    biPlanes As Integer
    biBitCount As Integer
    biCompression As Long
    biSizeImage As Long
    biXPelsPerMeter As Long
    biYPelsPerMeter As Long
    biClrUsed As Long
    biClrImportant As Long
End Type

Public Type BITMAPINFO
    bmiHeader As BITMAPINFOHEADER
    bmiColors As RGBQUAD
End Type

Type tagICINFO
  dwSize As Long
  fccType As Long
  fccHandler As Long
  dwFlags As Long
  dwVersion As Long
  dwVersionICM As Long
  szName(16 - 1) As Integer
  szDescription(128 - 1) As Integer
  szDriver(128 - 1) As Integer
End Type

Type COMPVARS
  cbSize As Long
  dwFlags As Long
  hic As Long
  fccType As Long
  fccHandler As Long
  lpbiIn As Long
  lpbiOut As Long
  lpBitsOut As Long
  lpBitsPrev As Long
  lFrame As Long
  lKey As Long
  lDataRate As Long
  lQ As Long
  lKeyCount As Long
  lpState As Long
  cbState As Long
End Type

'#define mmioFOURCC( ch0, ch1, ch2, ch3 )                \
'        ( (DWORD)(BYTE)(ch0) | ( (DWORD)(BYTE)(ch1) << 8 ) |    \
'        ( (DWORD)(BYTE)(ch2) << 16 ) | ( (DWORD)(BYTE)(ch3) << 24 ) )
'#define ICTYPE_VIDEO    mmioFOURCC('v', 'i', 'd', 'c')
'#define ICTYPE_AUDIO    mmioFOURCC('a', 'u', 'd', 'c')

Public Const ICTYPE_VIDEO As Long = &H63646976
Public Const ICTYPE_AUDIO As Long = &H63647561

Public Const ICMODE_COMPRESS As Long = 1
Public Const ICMODE_DECOMPRESS As Long = 2
Public Const ICMODE_DRAW As Long = 8
Public Const ICMODE_FASTCOMPRESS As Long = 5
Public Const ICMODE_FASTDECOMPRESS As Long = 3
Public Const ICMODE_QUERY As Long = 4

Public Const ICERR_ABORT As Long = -10&
Public Const ICERR_BADBITDEPTH As Long = -200&
Public Const ICERR_BADFLAGS As Long = -5&
Public Const ICERR_BADFORMAT As Long = -2&
Public Const ICERR_BADHANDLE As Long = -8&
Public Const ICERR_BADIMAGESIZE As Long = -201&
Public Const ICERR_BADPARAM As Long = -6&
Public Const ICERR_BADSIZE As Long = -7&
Public Const ICERR_CANTUPDATE As Long = -9&
Public Const ICERR_CUSTOM As Long = -400&
Public Const ICERR_DONTDRAW As Long = 1&
Public Const ICERR_ERROR As Long = -100&
Public Const ICERR_GOTOKEYFRAME As Long = 3&
Public Const ICERR_INTERNAL As Long = -4&
Public Const ICERR_MEMORY As Long = -3&
Public Const ICERR_NEWPALETTE As Long = 2&
Public Const ICERR_OK As Long = 0&
Public Const ICERR_STOPDRAWING As Long = 4&
Public Const ICERR_UNSUPPORTED As Long = -1&

Public Const DRV_USER As Long = &H4000
Public Const ICM_USER As Long = (DRV_USER + &H0)
Public Const ICM_RESERVED_LOW As Long = (DRV_USER + &H1000)
Public Const ICM_RESERVED As Long = ICM_RESERVED_LOW
Public Const ICM_GETSTATE As Long = (ICM_RESERVED + 0)
Public Const ICM_SETSTATE As Long = (ICM_RESERVED + 1)
Public Const ICM_GETINFO As Long = (ICM_RESERVED + 2)
Public Const ICM_CONFIGURE As Long = (ICM_RESERVED + 10)
Public Const ICM_ABOUT As Long = (ICM_RESERVED + 11)
Public Const ICM_GETERRORTEXT As Long = (ICM_RESERVED + 12)
Public Const ICM_GETFORMATNAME As Long = (ICM_RESERVED + 20)
Public Const ICM_ENUMFORMATS As Long = (ICM_RESERVED + 21)
Public Const ICM_GETDEFAULTQUALITY As Long = (ICM_RESERVED + 30)
Public Const ICM_GETQUALITY As Long = (ICM_RESERVED + 31)
Public Const ICM_SETQUALITY As Long = (ICM_RESERVED + 32)
Public Const ICM_GET As Long = (ICM_RESERVED + 41)
Public Const ICM_SET As Long = (ICM_RESERVED + 40)
Public Const ICM_GETDEFAULTKEYFRAMERATE As Long = (ICM_USER + 42)
Public Const ICM_DRAW_WINDOW As Long = (ICM_USER + 34)

Public Const ICM_COMPRESS_BEGIN As Long = (ICM_USER + 7)
Public Const ICM_COMPRESS_END As Long = (ICM_USER + 9)
Public Const ICM_COMPRESS_GET_FORMAT As Long = (ICM_USER + 4)
Public Const ICM_COMPRESS_GET_SIZE As Long = (ICM_USER + 5)
Public Const ICM_COMPRESS_QUERY As Long = (ICM_USER + 6)

Public Const ICM_DECOMPRESS_BEGIN As Long = (ICM_USER + 12)
Public Const ICM_DECOMPRESS_QUERY As Long = (ICM_USER + 11)
Public Const ICM_DECOMPRESS_GET_FORMAT As Long = (ICM_USER + 10)
Public Const ICM_DECOMPRESS_GET_PALETTE As Long = (ICM_USER + 30)
Public Const ICM_DECOMPRESS_SET_PALETTE As Long = (ICM_USER + 29)
Public Const ICM_DECOMPRESS_END As Long = (ICM_USER + 14)

Public Declare Function AVIFileOpenW Lib "avifil32.dll" (ByRef ppfile As Long, ByRef szFile As Any, ByVal uMode As Long, ByVal lpHandler As Long) As Long
Public Declare Function AVIFileCreateStreamW Lib "avifil32.dll" (ByVal pfile As Long, ByRef ppavi As Long, ByRef psi As AVISTREAMINFOW) As Long
Public Declare Function AVIMakeCompressedStream Lib "avifil32.dll" (ByRef ppsCompressed As Long, ByVal psSource As Long, ByRef lpOptions As AVICOMPRESSOPTIONS, ByRef pclsidHandler As Any) As Long
Public Declare Function AVIStreamSetFormat Lib "avifil32.dll" (ByVal pavi As Long, ByVal lPos As Long, ByRef lpFormat As Any, ByVal cbFormat As Long) As Long
Public Declare Function AVIStreamWrite Lib "avifil32.dll" (ByVal pavi As Long, ByVal lStart As Long, ByVal lSamples As Long, ByRef lpBuffer As Any, ByVal cbBuffer As Long, ByVal dwFlags As Long, ByRef plSampWritten As Long, ByRef plBytesWritten As Long) As Long
Public Declare Function AVISaveOptionsFree Lib "avifil32.dll" (ByVal nStreams As Long, ByRef plpOptions As Long) As Long
Public Declare Function AVIFileInit Lib "avifil32.dll" () As Long
Public Declare Function AVIFileExit Lib "avifil32.dll" () As Long
Public Declare Function AVIFileRelease Lib "avifil32.dll" (ByVal pfile As Long) As Long
Public Declare Function AVIStreamRelease Lib "avifil32.dll" (ByVal pavi As Long) As Long

Type AVISTREAMINFOW
  fccType As Long
  fccHandler As Long
  dwFlags As Long
  dwCaps As Long
  wPriority As Integer
  wLanguage As Integer
  dwScale As Long
  dwRate As Long
  dwStart As Long
  dwLength As Long
  dwInitialFrames As Long
  dwSuggestedBufferSize As Long
  dwQuality As Long
  dwSampleSize As Long
  rcFrameLeft As Long
  rcFrameTop As Long
  rcFrameRight As Long
  rcFrameBottom As Long
  dwEditCount As Long
  dwFormatChangeCount As Long
  szName(64 - 1) As Integer
End Type

Type AVICOMPRESSOPTIONS
  fccType As Long
  fccHandler As Long
  dwKeyFrameEvery As Long
  dwQuality As Long
  dwBytesPerSecond As Long
  dwFlags As Long
  lpFormat As Long
  cbFormat As Long
  lpParms As Long
  cbParms As Long
  dwInterleaveEvery As Long
End Type

Public Const OF_WRITE As Long = &H1
Public Const OF_READWRITE As Long = &H2
Public Const OF_READ As Long = &H0
Public Const OF_CREATE As Long = &H1000
Public Const AVIERR_OK As Long = 0&

Public Const streamtypeVIDEO As Long = &H73646976
Public Const streamtypeAUDIO As Long = &H73647561
Public Const streamtypeMIDI As Long = &H7364696D
Public Const streamtypeTEXT As Long = &H73747874

Public Const AVICOMPRESSF_DATARATE As Long = &H2
Public Const AVICOMPRESSF_INTERLEAVE As Long = &H1
Public Const AVICOMPRESSF_KEYFRAMES As Long = &H4
Public Const AVICOMPRESSF_VALID As Long = &H8

Public Function ICQueryAbout(ByVal hic As Long) As Boolean
ICQueryAbout = ICSendMessage(hic, ICM_ABOUT, -1, 1) = ICERR_OK
End Function

Public Function ICAbout(ByVal hic As Long, ByVal hWnd As Long) As Long
ICAbout = ICSendMessage(hic, ICM_ABOUT, hWnd, 0)
End Function

Public Function ICQueryConfigure(ByVal hic As Long) As Boolean
ICQueryConfigure = ICSendMessage(hic, ICM_CONFIGURE, -1, 1) = ICERR_OK
End Function

Public Function ICConfigure(ByVal hic As Long, ByVal hWnd As Long) As Long
ICConfigure = ICSendMessage(hic, ICM_CONFIGURE, hWnd, 0)
End Function

Public Function ICGetState(ByVal hic As Long, ByVal pv As Long, ByVal cb As Long) As Long
ICGetState = ICSendMessage(hic, ICM_GETSTATE, pv, cb)
End Function

Public Function ICSetState(ByVal hic As Long, ByVal pv As Long, ByVal cb As Long) As Long
ICSetState = ICSendMessage(hic, ICM_SETSTATE, pv, cb)
End Function

Public Function ICGetStateSize(ByVal hic As Long) As Long
ICGetStateSize = ICSendMessage(hic, ICM_GETSTATE, 0, 0)
End Function

Public Function ICGetDefaultQuality(ByVal hic As Long) As Long
Dim i As Long
ICSendMessage hic, ICM_GETDEFAULTQUALITY, VarPtr(i), 4
ICGetDefaultQuality = i
End Function

Public Function ICGetDefaultKeyFrameRate(ByVal hic As Long) As Long
Dim i As Long
ICSendMessage hic, ICM_GETDEFAULTKEYFRAMERATE, VarPtr(i), 4
ICGetDefaultKeyFrameRate = i
End Function

Public Function ICDrawWindow(ByVal hic As Long, ByVal prc As Long) As Long
ICDrawWindow = ICSendMessage(hic, ICM_DRAW_WINDOW, prc, 16&)
End Function

Public Function ICCompressBegin(ByVal hic As Long, ByVal lpbiInput As Long, ByVal lpbiOutput As Long) As Long
ICCompressBegin = ICSendMessage(hic, ICM_COMPRESS_BEGIN, lpbiInput, lpbiOutput)
End Function

Public Function ICCompressQuery(ByVal hic As Long, ByVal lpbiInput As Long, ByVal lpbiOutput As Long) As Long
ICCompressQuery = ICSendMessage(hic, ICM_COMPRESS_QUERY, lpbiInput, lpbiOutput)
End Function

Public Function ICCompressGetFormat(ByVal hic As Long, ByVal lpbiInput As Long, ByVal lpbiOutput As Long) As Long
ICCompressGetFormat = ICSendMessage(hic, ICM_COMPRESS_GET_FORMAT, lpbiInput, lpbiOutput)
End Function

Public Function ICCompressGetFormatSize(ByVal hic As Long, ByVal lpbiInput As Long) As Long
ICCompressGetFormatSize = ICSendMessage(hic, ICM_COMPRESS_GET_FORMAT, lpbiInput, 0)
End Function

Public Function ICCompressGetSize(ByVal hic As Long, ByVal lpbiInput As Long, ByVal lpbiOutput As Long) As Long
ICCompressGetSize = ICSendMessage(hic, ICM_COMPRESS_GET_SIZE, lpbiInput, 0)
End Function

Public Function ICCompressEnd(ByVal hic As Long) As Long
ICCompressEnd = ICSendMessage(hic, ICM_COMPRESS_BEGIN, 0, 0)
End Function

Public Function ICDecompressBegin(ByVal hic As Long, ByVal lpbiInput As Long, ByVal lpbiOutput As Long) As Long
ICDecompressBegin = ICSendMessage(hic, ICM_DECOMPRESS_BEGIN, lpbiInput, lpbiOutput)
End Function

Public Function ICDecompressQuery(ByVal hic As Long, ByVal lpbiInput As Long, ByVal lpbiOutput As Long) As Long
ICDecompressQuery = ICSendMessage(hic, ICM_DECOMPRESS_QUERY, lpbiInput, lpbiOutput)
End Function

Public Function ICDecompressGetFormat(ByVal hic As Long, ByVal lpbiInput As Long, ByVal lpbiOutput As Long) As Long
ICDecompressGetFormat = ICSendMessage(hic, ICM_DECOMPRESS_GET_FORMAT, lpbiInput, lpbiOutput)
End Function

Public Function ICDecompressGetFormatSize(ByVal hic As Long, ByVal lpbiInput As Long) As Long
ICDecompressGetFormatSize = ICSendMessage(hic, ICM_DECOMPRESS_GET_FORMAT, lpbiInput, 0)
End Function

Public Function ICDecompressGetPalette(ByVal hic As Long, ByVal lpbiInput As Long, ByVal lpbiOutput As Long) As Long
ICDecompressGetPalette = ICSendMessage(hic, ICM_DECOMPRESS_GET_PALETTE, lpbiInput, lpbiOutput)
End Function

Public Function ICDecompressSetPalette(ByVal hic As Long, ByVal lpbiPalette As Long) As Long
ICDecompressSetPalette = ICSendMessage(hic, ICM_DECOMPRESS_SET_PALETTE, lpbiPalette, 0)
End Function

Public Function ICDecompressEnd(ByVal hic As Long) As Long
ICDecompressEnd = ICSendMessage(hic, ICM_DECOMPRESS_END, 0, 0)
End Function

