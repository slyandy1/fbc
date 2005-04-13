''
''
'' gridctrl -- header translated with help of SWIG FB wrapper
''
'' NOTICE: This file is part of the FreeBASIC Compiler package and can't
''         be included in other distributions without authorization.
''
''
#ifndef __gridctrl_bi__
#define __gridctrl_bi__

#include once "wx-c/wx.bi"

declare function wxGridCellDateTimeRenderer cdecl alias "wxGridCellDateTimeRenderer_ctor" (byval outformat as string, byval informat as string) as wxGridCellDateTimeRenderer ptr
declare sub wxGridCellDateTimeRenderer_dtor cdecl alias "wxGridCellDateTimeRenderer_dtor" (byval self as wxGridCellDateTimeRenderer ptr)
declare sub wxGridCellDateTimeRenderer_Draw cdecl alias "wxGridCellDateTimeRenderer_Draw" (byval self as wxGridCellDateTimeRenderer ptr, byval grid as wxGrid ptr, byval attr as wxGridCellAttr ptr, byval dc as wxDC ptr, byval rect as wxRect ptr, byval row as integer, byval col as integer, byval isSelected as integer)
declare sub wxGridCellDateTimeRenderer_GetBestSize cdecl alias "wxGridCellDateTimeRenderer_GetBestSize" (byval self as wxGridCellDateTimeRenderer ptr, byval grid as wxGrid ptr, byval attr as wxGridCellAttr ptr, byval dc as wxDC ptr, byval row as integer, byval col as integer, byval size as wxSize ptr)
declare function wxGridCellDateTimeRenderer_Clone cdecl alias "wxGridCellDateTimeRenderer_Clone" (byval self as wxGridCellDateTimeRenderer ptr) as wxGridCellRenderer ptr
declare sub wxGridCellDateTimeRenderer_SetParameters cdecl alias "wxGridCellDateTimeRenderer_SetParameters" (byval self as wxGridCellDateTimeRenderer ptr, byval params as string)
declare function wxGridCellEnumRenderer cdecl alias "wxGridCellEnumRenderer_ctor" (byval n as integer, byval choices as byte ptr ptr) as wxGridCellEnumRenderer ptr
declare sub wxGridCellEnumRenderer_dtor cdecl alias "wxGridCellEnumRenderer_dtor" (byval self as wxGridCellEnumRenderer ptr)
declare sub wxGridCellEnumRenderer_Draw cdecl alias "wxGridCellEnumRenderer_Draw" (byval self as wxGridCellEnumRenderer ptr, byval grid as wxGrid ptr, byval attr as wxGridCellAttr ptr, byval dc as wxDC ptr, byval rect as wxRect ptr, byval row as integer, byval col as integer, byval isSelected as integer)
declare sub wxGridCellEnumRenderer_GetBestSize cdecl alias "wxGridCellEnumRenderer_GetBestSize" (byval self as wxGridCellEnumRenderer ptr, byval grid as wxGrid ptr, byval attr as wxGridCellAttr ptr, byval dc as wxDC ptr, byval row as integer, byval col as integer, byval size as wxSize ptr)
declare function wxGridCellEnumRenderer_Clone cdecl alias "wxGridCellEnumRenderer_Clone" (byval self as wxGridCellEnumRenderer ptr) as wxGridCellRenderer ptr
declare sub wxGridCellEnumRenderer_SetParameters cdecl alias "wxGridCellEnumRenderer_SetParameters" (byval self as wxGridCellEnumRenderer ptr, byval params as string)

declare function wxGridCellAutoWrapStringRenderer cdecl alias "wxGridCellAutoWrapStringRenderer_ctor" () as wxGridCellAutoWrapStringRenderer ptr
declare sub wxGridCellAutoWrapStringRenderer_dtor cdecl alias "wxGridCellAutoWrapStringRenderer_dtor" (byval self as wxGridCellAutoWrapStringRenderer ptr)
declare sub wxGridCellAutoWrapStringRenderer_RegisterDisposable cdecl alias "wxGridCellAutoWrapStringRenderer_RegisterDisposable" (byval self as _GridCellAutoWrapStringRenderer ptr, byval onDispose as Virtual_Dispose)
declare sub wxGridCellAutoWrapStringRenderer_Draw cdecl alias "wxGridCellAutoWrapStringRenderer_Draw" (byval self as wxGridCellAutoWrapStringRenderer ptr, byval grid as wxGrid ptr, byval attr as wxGridCellAttr ptr, byval dc as wxDC ptr, byval rect as wxRect ptr, byval row as integer, byval col as integer, byval isSelected as integer)
declare sub wxGridCellAutoWrapStringRenderer_GetBestSize cdecl alias "wxGridCellAutoWrapStringRenderer_GetBestSize" (byval self as wxGridCellAutoWrapStringRenderer ptr, byval grid as wxGrid ptr, byval attr as wxGridCellAttr ptr, byval dc as wxDC ptr, byval row as integer, byval col as integer, byval size as wxSize ptr)
declare function wxGridCellAutoWrapStringRenderer_Clone cdecl alias "wxGridCellAutoWrapStringRenderer_Clone" (byval self as wxGridCellAutoWrapStringRenderer ptr) as wxGridCellRenderer ptr
declare function wxGridCellEnumEditor cdecl alias "wxGridCellEnumEditor_ctor" (byval n as integer, byval choices as byte ptr ptr) as wxGridCellEnumEditor ptr
declare sub wxGridCellEnumEditor_dtor cdecl alias "wxGridCellEnumEditor_dtor" (byval self as wxGridCellEnumEditor ptr)
declare sub wxGridCellEnumEditor_BeginEdit cdecl alias "wxGridCellEnumEditor_BeginEdit" (byval self as wxGridCellEnumEditor ptr, byval row as integer, byval col as integer, byval grid as wxGrid ptr)
declare function wxGridCellEnumEditor_EndEdit cdecl alias "wxGridCellEnumEditor_EndEdit" (byval self as wxGridCellEnumEditor ptr, byval row as integer, byval col as integer, byval grid as wxGrid ptr) as integer
declare function wxGridCellEnumEditor_Clone cdecl alias "wxGridCellEnumEditor_Clone" (byval self as wxGridCellEnumEditor ptr) as wxGridCellEditor ptr

declare function wxGridCellAutoWrapStringEditor cdecl alias "wxGridCellAutoWrapStringEditor_ctor" () as wxGridCellAutoWrapStringEditor ptr
declare sub wxGridCellAutoWrapStringEditor_dtor cdecl alias "wxGridCellAutoWrapStringEditor_dtor" (byval self as wxGridCellAutoWrapStringEditor ptr)
declare sub wxGridCellAutoWrapStringEditor_RegisterDisposable cdecl alias "wxGridCellAutoWrapStringEditor_RegisterDisposable" (byval self as _GridCellAutoWrapStringEditor ptr, byval onDispose as Virtual_Dispose)
declare sub wxGridCellAutoWrapStringEditor_Create cdecl alias "wxGridCellAutoWrapStringEditor_Create" (byval self as wxGridCellAutoWrapStringEditor ptr, byval parent as wxWindow ptr, byval id as wxWindowID, byval evtHandler as wxEvtHandler ptr)
declare function wxGridCellAutoWrapStringEditor_Clone cdecl alias "wxGridCellAutoWrapStringEditor_Clone" (byval self as wxGridCellAutoWrapStringEditor ptr) as wxGridCellEditor ptr

#endif
