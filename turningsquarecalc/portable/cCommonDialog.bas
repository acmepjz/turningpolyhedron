#include once "cCommonDialog.bi"
#include once "crt/string.bi"

Declare Function _ToUTF8(s As String) As String
Declare Function _ToUCS2(s As String) As String

#ifdef __FB_WIN32__

Type OPENFILENAME
	lStructSize As Long
	hwndOwner As Long
	hInstance As Long
	lpstrFilter As UByte ptr
	lpstrCustomFilter As UByte ptr
	nMaxCustFilter As Long
	nFilterIndex As Long
	lpstrFile As UByte ptr
	nMaxFile As Long
	lpstrFileTitle As UByte ptr
	nMaxFileTitle As Long
	lpstrInitialDir As UByte ptr
	lpstrTitle As UByte ptr
	flags As Long
	nFileOffset As Short
	nFileExtension As Short
	lpstrDefExt As UByte ptr
	lCustData As Long
	lpfnHook As Long
	lpTemplateName As UByte ptr
End Type

Declare Function GetOpenFileName Lib "comdlg32" Alias "GetOpenFileNameW" (ByRef pOpenfilename As OPENFILENAME) As Long
Declare Function GetSaveFileName Lib "comdlg32" Alias "GetSaveFileNameW" (ByRef pOpenfilename As OPENFILENAME) As Long

Const OFN_FILEMUSTEXIST As Long = &H1000
Const OFN_ALLOWMULTISELECT As Long = &H200
Const OFN_READONLY As Long = &H1
Const OFN_HIDEREADONLY As Long = &H4
Const OFN_ENABLEHOOK As Long = &H20
Const OFN_ENABLETEMPLATE As Long = &H40
Const OFN_EXPLORER As Long = &H80000
Const OFN_OVERWRITEPROMPT As Long = &H2

#else
#include once "gtk/gtk.bi"

Declare Sub gtk_file_chooser_set_create_folders cdecl Alias "gtk_file_chooser_set_create_folders" (byval chooser as GtkFileChooser ptr, byval b as gboolean)
Declare Sub gtk_file_chooser_set_do_overwrite_confirmation cdecl Alias "gtk_file_chooser_set_do_overwrite_confirmation" (byval chooser as GtkFileChooser ptr, byval b as gboolean)

#endif

Sub _FileName_WindowsToLinux(byref s as string)
	dim as long m=Len(s),i
	if(m>0) then
		for i=0 to m-1
			if s[i]=92 then s[i]=47
		next i
	end if
end sub

Sub _FileName_LinuxToWindows(byref s as string)
	dim as long m=Len(s),i
	if(m>0) then
		for i=0 to m-1
			if s[i]=47 then s[i]=92
		next i
	end if
end sub

Function cCommonDialog.VBGetOpenFileName(FileName As String, _
                           FileTitle As String = "", _
                           FileMustExist As Short = -1, _
                           MultiSelect As Short = 0, _
                           ReadOnly As Short = 0, _
                           HideReadOnly As Short = -1, _
                           _Filter As String = "All (*.*)| *.*", _
                           FilterIndex As Long = 1, _
                           _InitDir As String = "", _
                           _DlgTitle As String = "", _
                           _DefaultExt As String = "", _
                           Owner As Long = -1, _
                           Flags As Long = 0) As Short
'///
#ifdef __FB_WIN32__
	dim as OPENFILENAME opfile
	dim as String s,Filter=_Filter,InitDir=_ToUCS2(_InitDir),DefaultExt=_ToUCS2(_DefaultExt),DlgTitle=_ToUCS2(_DlgTitle)
	dim as long i,j,m,m_lApiReturn
	opfile.lStructSize=sizeof(opfile)
	opfile.Flags = ((FileMustExist<>0) and OFN_FILEMUSTEXIST) or _
		((MultiSelect<>0) and OFN_ALLOWMULTISELECT) or _
		((ReadOnly<>0) and OFN_READONLY) or _
		((HideReadOnly<>0) and OFN_HIDEREADONLY) or _
		(Flags and (not (OFN_ENABLEHOOK or OFN_ENABLETEMPLATE))) or OFN_EXPLORER
	if(Owner<>-1 andalso Owner<>0) then opfile.hwndOwner=Owner
	opfile.lpstrInitialDir=strptr(InitDir)
	opfile.lpstrDefExt=strptr(DefaultExt)
	opfile.lpstrTitle=strptr(DlgTitle)
	m=Len(Filter)
	for i=0 to m-1
		if (Filter[i]=124 orelse Filter[i]=58) then Filter[i]=0
	next i
	Filter=_ToUCS2(Filter+!"\0\0\0\0")
	opfile.lpstrFilter=strptr(Filter)
	FileName=_ToUCS2(FileName+String(32768,!"\0"))
	FileTitle=_ToUCS2(FileTitle+String(32768,!"\0"))
	opfile.lpstrFile=strptr(FileName)
	opfile.lpstrFileTitle=strptr(FileTitle)
	opfile.nMaxFile=Len(FileName) shr 1
	opfile.nMaxFileTitle=Len(FileTitle) shr 1
	m_lApiReturn=GetOpenFileName(opfile)
	FileName=_ToUTF8(FileName)
	FileTitle=_ToUTF8(FileTitle)
	select case m_lApiReturn
	case 1
		if opfile.Flags and OFN_ALLOWMULTISELECT then
			i=strlen(strptr(FileName))
			if opfile.lpstrFile[i+1]=0 then
				FileName=Left(FileName,i)
			else
				dim as String s1=Left(FileName,i)
				dim as long count=0
				if s1[i-1]<>47 orelse s1[i-1]<>92 then s1+="\"
				do
					j=strlen(strptr(FileName)+i+1)
					if(j<=0) then exit do
					if(count>0) then
                        s+="|"+s1+Mid(FileName,i+2,j) '//TODO:use vbNullChar instead of "|"
					else
					    s+=s1+Mid(FileName,i+2,j)
					end if
					i+=j+1
					count=count+1
				loop
				FileName=s
			end if
		else
			FileName=Left(FileName,strlen(strptr(FileName)))
		end if
		FileTitle=Left(FileTitle,strlen(strptr(FileTitle)))
		Flags=opfile.Flags
		FilterIndex=opfile.nFilterIndex
		if(opfile.Flags and OFN_READONLY) then ReadOnly=-1
		return -1
	case else
		FileName = ""
		FileTitle = ""
		Flags = 0
		FilterIndex = -1
		return 0
	end select
#else
	dim as String s,Filter=_Filter,InitDir=_InitDir,DefaultExt=_DefaultExt,DlgTitle=_DlgTitle
	dim as GtkWidget ptr dialog
	dim as gchar ptr lpTitle
	dim as UByte ptr lp1,lp2
	dim as Short bReturn
	dim as long i,m
	'//get title
	if(Len(DlgTitle)<=0) then
		dim as GtkStockItem item
		if gtk_stock_lookup(GTK_STOCK_OPEN,@item) then
			'//process caption
			m=strlen(item.label)
			DlgTitle=Space(m)
			lp1=strptr(DlgTitle)
			lp2=item.label
			do until *lp2 = 0
				if *lp2=40 then exit do
				if *lp2<>95 then
				 *lp1=*lp2
				 lp1+=1
				end if
			    lp2+=1
			loop
			*lp1=0
			lpTitle=strptr(DlgTitle)
		else
			lpTitle = @"Open"
		end if
	else
		lpTitle=strptr(DlgTitle)
	end if
	'//compatible with Micro$oft
	_FileName_WindowsToLinux(FileName)
	_FileName_WindowsToLinux(InitDir)
	'//create
	dialog = gtk_file_chooser_dialog_new(lpTitle, _
		NULL, _
		GTK_FILE_CHOOSER_ACTION_OPEN, _
		GTK_STOCK_OPEN, GTK_RESPONSE_ACCEPT, _
		GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL, _
		NULL)
	'//filename
	if(Len(FileName)>0) then
		gtk_file_chooser_set_filename(GTK_FILE_CHOOSER(dialog),strptr(FileName))
	end if
	'//initdir
	if(Len(InitDir)>0) then
		gtk_file_chooser_set_current_folder(GTK_FILE_CHOOSER(dialog),strptr(InitDir))
	end if
	'//multiselect
	if(MultiSelect)  then
		gtk_file_chooser_set_select_multiple(GTK_FILE_CHOOSER(dialog),1)
	end if
	'//misc
	gtk_file_chooser_set_create_folders(GTK_FILE_CHOOSER(dialog),1)
	'//filter
	m=Len(Filter)
	if(m>0) then
		lp1=strptr(Filter)
		lp2=NULL
		for i=0 to m
			if(Filter[i]=124 orelse Filter[i]=58) then Filter[i]=0
			if(Filter[i]=0) then
				if(lp2=NULL) then
				    lp2=strptr(Filter)+i+1
				else
					dim as GtkFileFilter ptr _filter=gtk_file_filter_new()
					dim as UByte ptr lp3=lp2
					gtk_file_filter_set_name(_filter,lp1)
					do while lp3<strptr(Filter)+i
						dim as long m1=strlen(lp3)
						if(m1>0) then
							if(strcmp(lp3,@"*.*"))=0 then lp3[1]=0
							gtk_file_filter_add_pattern(_filter,lp3)
						end if
						lp3+=m1+1
					loop
					gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(dialog),_filter)
					gtk_object_destroy(GTK_OBJECT(_filter)) '//???
					'//
					lp1=strptr(Filter)+i+1
					lp2=NULL
				end if
			elseif Filter[i]=59 andalso lp2<>NULL then
				Filter[i]=0
			end if
		next i
	end if
	'//TODO:return other arguments
	if(gtk_dialog_run(GTK_DIALOG(dialog)) = GTK_RESPONSE_ACCEPT) then
		if(MultiSelect) then
            '//MultiSelect
            dim as GSList ptr filelist=gtk_file_chooser_get_filenames(GTK_FILE_CHOOSER(dialog))
            dim as GSList ptr lp=filelist
            dim as long count=0
            do while lp
            	dim as UByte ptr _filename=lp->data
            	if _filename then
            		dim as long m=strlen(_filename)
            		if count>0 then
						dim as String s=Space(m)
						memcpy(strptr(s),_filename,m)
						FileName+="|"+s '//TODO:use vbNullChar instead of "|"
            		else
						FileName=Space(m)
						memcpy(strptr(FileName),_filename,m)
            		end if
            		g_free(_filename)
            	end if
            	count+=1
            	lp=lp->next
            loop
            g_slist_free(filelist)
			'//compatible with Micro$oft
			_FileName_LinuxToWindows(FileName)
		else
            dim as ubyte ptr _filename = gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog))
            dim as long m=strlen(_filename)
            FileName=(Space(m))
            if(m>0) then
                memcpy(strptr(FileName),_filename,m)
                '//compatible with Micro$oft
                _FileName_LinuxToWindows(FileName)
            end if
            g_free(_filename)
		end if
		bReturn=-1
	else
		FileName = ""
		FileTitle = ""
		Flags = 0
		FilterIndex = -1
	end if
	gtk_widget_destroy(dialog)
	do while(gtk_events_pending()) 
	 gtk_main_iteration()
	loop
	return bReturn
#endif
'///
End Function

Function cCommonDialog.VBGetSaveFileName(FileName As String, _
                           FileTitle As String = "", _
                           OverWritePrompt As Short = -1, _
                           _Filter As String = "All (*.*)| *.*", _
                           FilterIndex As Long = 1, _
                           _InitDir As String = "", _
                           _DlgTitle As String = "", _
                           _DefaultExt As String = "", _
                           Owner As Long = -1, _
                           Flags As Long = 0) As Short
'///
#ifdef __FB_WIN32__
	dim as OPENFILENAME opfile
	dim as String s,Filter=_Filter,InitDir=_ToUCS2(_InitDir),DefaultExt=_ToUCS2(_DefaultExt),DlgTitle=_ToUCS2(_DlgTitle)
	dim as long i,m,m_lApiReturn
	opfile.lStructSize=sizeof(opfile)
	opfile.Flags = ((OverWritePrompt<>0) and OFN_OVERWRITEPROMPT) or _
		OFN_HIDEREADONLY or _
		(Flags and (not (OFN_ENABLEHOOK or OFN_ENABLETEMPLATE))) or OFN_EXPLORER
	if(Owner<>-1 andalso Owner<>0) then opfile.hwndOwner=Owner
	opfile.lpstrInitialDir=strptr(InitDir)
	opfile.lpstrDefExt=strptr(DefaultExt)
	opfile.lpstrTitle=strptr(DlgTitle)
	m=Len(Filter)
	for i=0 to m-1
		if (Filter[i]=124 orelse Filter[i]=58) then Filter[i]=0
	next i
	Filter=_ToUCS2(Filter+!"\0\0")
	opfile.lpstrFilter=strptr(Filter)
	FileName=_ToUCS2(FileName+String(32768,!"\0"))
	FileTitle=_ToUCS2(FileTitle+String(32768,!"\0"))
	opfile.lpstrFile=strptr(FileName)
	opfile.lpstrFileTitle=strptr(FileTitle)
	opfile.nMaxFile=Len(FileName) shr 1
	opfile.nMaxFileTitle=Len(FileTitle) shr 1
	m_lApiReturn=GetSaveFileName(opfile)
	FileName=_ToUTF8(FileName)
	FileTitle=_ToUTF8(FileTitle)
	select case m_lApiReturn
	case 1
		FileName=Left(FileName,strlen(strptr(FileName)))
		FileTitle=Left(FileTitle,strlen(strptr(FileTitle)))
		Flags=opfile.Flags
		FilterIndex=opfile.nFilterIndex
		return -1
	case else
		FileName = ""
		FileTitle = ""
		Flags = 0
		FilterIndex = -1
		return 0
	end select
#else
	dim as String s,Filter=_Filter,InitDir=_InitDir,DefaultExt=_DefaultExt,DlgTitle=_DlgTitle
	dim as GtkWidget ptr dialog
	dim as gchar ptr lpTitle
	dim as UByte ptr lp1,lp2
	dim as Short bReturn
	dim as long i,m
	'//get title
	if(Len(DlgTitle)<=0) then
		dim as GtkStockItem item
		if gtk_stock_lookup(GTK_STOCK_SAVE_AS,@item) then
			'//process caption
			m=strlen(item.label)
			DlgTitle=Space(m)
			lp1=strptr(DlgTitle)
			lp2=item.label
			do until *lp2 = 0
				if *lp2=40 then exit do
				if *lp2<>95 then
				 *lp1=*lp2
				 lp1+=1
				end if
			    lp2+=1
			loop
			*lp1=0
			lpTitle=strptr(DlgTitle)
		else
			lpTitle = @"Save As"
		end if
	else
		lpTitle=strptr(DlgTitle)
	end if
	'//compatible with Micro$oft
	_FileName_WindowsToLinux(FileName)
	_FileName_WindowsToLinux(InitDir)
	'//create
	dialog = gtk_file_chooser_dialog_new(lpTitle, _
		NULL, _
		GTK_FILE_CHOOSER_ACTION_SAVE, _
		GTK_STOCK_SAVE, GTK_RESPONSE_ACCEPT, _
		GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL, _
		NULL)
	'//filename
	if(Len(FileName)>0) then
		gtk_file_chooser_set_filename(GTK_FILE_CHOOSER(dialog),strptr(FileName))
	'//initdir
	elseif Len(InitDir)>0 then
		gtk_file_chooser_set_current_folder(GTK_FILE_CHOOSER(dialog),strptr(InitDir))
	end if
	'//OverWritePrompt
	if(OverWritePrompt) then
		gtk_file_chooser_set_do_overwrite_confirmation(GTK_FILE_CHOOSER(dialog),1)
	end if
	'//misc
	gtk_file_chooser_set_create_folders(GTK_FILE_CHOOSER(dialog),1)
	'//filter
	m=Len(Filter)
	if(m>0) then
		lp1=strptr(Filter)
		lp2=NULL
		for i=0 to m
			if(Filter[i]=124 orelse Filter[i]=58) then Filter[i]=0
			if(Filter[i]=0) then
				if(lp2=NULL) then
				    lp2=strptr(Filter)+i+1
				else
					dim as GtkFileFilter ptr _filter=gtk_file_filter_new()
					dim as UByte ptr lp3=lp2
					gtk_file_filter_set_name(_filter,lp1)
					do while lp3<strptr(Filter)+i
						dim as long m1=strlen(lp3)
						if(m1>0) then
							if(strcmp(lp3,@"*.*"))=0 then lp3[1]=0
							gtk_file_filter_add_pattern(_filter,lp3)
						end if
						lp3+=m1+1
					loop
					gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(dialog),_filter)
					gtk_object_destroy(GTK_OBJECT(_filter)) '//???
					'//
					lp1=strptr(Filter)+i+1
					lp2=NULL
				end if
			elseif Filter[i]=59 andalso lp2<>NULL then
				Filter[i]=0
			end if
		next i
	end if
	'//TODO:return other arguments
	if(gtk_dialog_run(GTK_DIALOG(dialog)) = GTK_RESPONSE_ACCEPT) then
		dim as UByte ptr _filename = gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog))
		dim as long m=strlen(_filename)
		FileName=Space(m)
		if(m>0) then
			memcpy(strptr(FileName),_filename,m)
			'//compatible with Micro$oft
			_FileName_LinuxToWindows(FileName)
			'//new:DefaultExt in linux
			m=Len(DefaultExt)
			if(m>0) then
				dim as long m1=Len(FileName),b=0
				if(m1>0) then
					for i=m1-1 to 0 step -1
						dim as short j=FileName[i]
						if j=46 then
							b=1
							exit for
						end if
						if j=47 orelse j=92 then exit for
					next i
					if(b=0) then
						FileName+="."+DefaultExt
					end if
				end if
			end if
		end if
		g_free(_filename)
		bReturn=-1
	else
		FileName = ""
		FileTitle = ""
		Flags = 0
		FilterIndex = -1
	end if
	gtk_widget_destroy(dialog)
	do while(gtk_events_pending())
	    gtk_main_iteration()
	loop
	return bReturn
#endif
'///
End Function
