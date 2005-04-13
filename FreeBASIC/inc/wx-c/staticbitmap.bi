''
''
'' staticbitmap -- header translated with help of SWIG FB wrapper
''
'' NOTICE: This file is part of the FreeBASIC Compiler package and can't
''         be included in other distributions without authorization.
''
''
#ifndef __staticbitmap_bi__
#define __staticbitmap_bi__

#include once "wx-c/wx.bi"


declare function wxStaticBitmap cdecl alias "wxStaticBitmap_ctor" () as wxStaticBitmap ptr
declare function wxStaticBitmap_Create cdecl alias "wxStaticBitmap_Create" (byval self as wxStaticBitmap ptr, byval parent as wxWindow ptr, byval id as wxWindowID, byval bitmap as wxBitmap ptr, byval pos as wxPoint ptr, byval size as wxSize ptr, byval style as integer, byval name as string) as integer
declare sub wxStaticBitmap_dtor cdecl alias "wxStaticBitmap_dtor" (byval self as wxStaticBitmap ptr)
declare sub wxStaticBitmap_SetIcon cdecl alias "wxStaticBitmap_SetIcon" (byval self as wxStaticBitmap ptr, byval icon as wxIcon ptr)
declare sub wxStaticBitmap_SetBitmap cdecl alias "wxStaticBitmap_SetBitmap" (byval self as wxStaticBitmap ptr, byval bitmap as wxBitmap ptr)
declare function wxStaticBitmap_GetBitmap cdecl alias "wxStaticBitmap_GetBitmap" (byval self as wxStaticBitmap ptr) as wxBitmap ptr

#endif
