''
''
'' showevent -- header translated with help of SWIG FB wrapper
''
'' NOTICE: This file is part of the FreeBASIC Compiler package and can't
''         be included in other distributions without authorization.
''
''
#ifndef __showevent_bi__
#define __showevent_bi__

#include once "wx-c/wx.bi"

declare function wxShowEvent cdecl alias "wxShowEvent_ctor" (byval type as wxEventType) as wxShowEvent ptr
declare function wxShowEvent_GetShow cdecl alias "wxShowEvent_GetShow" (byval self as wxShowEvent ptr) as integer
declare sub wxShowEvent_SetShow cdecl alias "wxShowEvent_SetShow" (byval self as wxShowEvent ptr, byval show as integer)

#endif
