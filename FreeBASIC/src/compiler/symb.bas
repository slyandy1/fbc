''	FreeBASIC - 32-bit BASIC Compiler.
''	Copyright (C) 2004-2005 Andre Victor T. Vicentini (av1ctor@yahoo.com.br)
''
''	This program is free software; you can redistribute it and/or modify
''	it under the terms of the GNU General Public License as published by
''	the Free Software Foundation; either version 2 of the License, or
''	(at your option) any later version.
''
''	This program is distributed in the hope that it will be useful,
''	but WITHOUT ANY WARRANTY; without even the implied warranty of
''	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
''	GNU General Public License for more details.
''
''	You should have received a copy of the GNU General Public License
''	along with this program; if not, write to the Free Software
''	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA.


'' symbol table module
''
'' chng: sep/2004 written [v1ctor]
''		 jan/2005 updated to use real linked-lists [v1ctor]

option explicit
option escape

defint a-z
'$include once: 'inc\fb.bi'
'$include once: 'inc\fbint.bi'
'$include once: 'inc\hash.bi'
'$include once: 'inc\list.bi'
'$include once: 'inc\rtl.bi'
'$include once: 'inc\ast.bi'
'$include once: 'inc\ir.bi'
'$include once: 'inc\emit.bi'
'$include once: 'inc\lex.bi'

type SYMBCTX
	inited			as integer

	symlist			as TLIST					'' symbols (VAR, CONST, FUNCTION, UDT, ENUM, LABEL, etc)
	symhash			as THASH
	loclist			as TLIST					'' local symbols (/)

	liblist 		as TLIST					'' libraries
	libhash			as THASH

	dimlist			as TLIST					'' array dimensions
	defarglist		as TLIST					'' define arguments
	fwdlist			as TLIST					'' forward typedef refs

	lastlbl			as FBSYMBOL ptr

	fwdrefcnt 		as integer
end type

declare sub 		hFreeSymbol		( byval s as FBSYMBOL ptr, byval freeup as integer = TRUE )

declare function 	hCalcDiff		( byval dimensions as integer, dTB() as FBARRAYDIM, byval lgt as integer ) as integer

declare function 	hCalcElements2	( byval dimensions as integer, dTB() as FBARRAYDIM ) as integer

declare function	hDefFile		( ) as string
declare function	hDefFunction	( ) as string
declare function	hDefLine		( ) as string
declare function	hDefDate		( ) as string
declare function	hDefTime		( ) as string


''globals
	dim shared ctx as SYMBCTX

#define PROC_NONE			0
#define PROC_FILE			1
#define PROC_FUNCTION		2
#define PROC_LINE			3
#define PROC_DATE			4
#define PROC_TIME			5


'' predefined #defines: name, value, proc
definesdata:
data "__FB_VERSION__",			FB.VERSION,		PROC_NONE
data "__FB_SIGNATURE__",		FB.SIGN,		PROC_NONE
#ifdef TARGET_WIN32
data "__FB_WIN32__",			"",				PROC_NONE
#elseif defined(TARGET_LINUX)
data "__FB_LINUX__",			"",				PROC_NONE
#elseif defined(TARGET_DOS)
data "__FB_DOS__",			    "",				PROC_NONE
#endif
data "__FILE__",				"",				PROC_FILE
data "__FUNCTION__",			"",				PROC_FUNCTION
data "__LINE__",				"",				PROC_LINE
data "__DATE__",				"",				PROC_DATE
data "__TIME__",				"",				PROC_TIME
data ""


'' keywords: name, id (token), class
keyworddata:
data "AND"		, FB.TK.AND			, FB.TKCLASS.OPERATOR
data "OR"		, FB.TK.OR			, FB.TKCLASS.OPERATOR
data "XOR"		, FB.TK.XOR			, FB.TKCLASS.OPERATOR
data "EQV"		, FB.TK.EQV			, FB.TKCLASS.OPERATOR
data "IMP"		, FB.TK.IMP			, FB.TKCLASS.OPERATOR
data "NOT"		, FB.TK.NOT			, FB.TKCLASS.OPERATOR
data "MOD"		, FB.TK.MOD			, FB.TKCLASS.OPERATOR
data "SHL"		, FB.TK.SHL			, FB.TKCLASS.OPERATOR
data "SHR"		, FB.TK.SHR			, FB.TKCLASS.OPERATOR
data "REM"		, FB.TK.REM			, FB.TKCLASS.KEYWORD
data "DIM"		, FB.TK.DIM			, FB.TKCLASS.KEYWORD
data "STATIC"	, FB.TK.STATIC		, FB.TKCLASS.KEYWORD
data "SHARED"	, FB.TK.SHARED		, FB.TKCLASS.KEYWORD
data "INTEGER"	, FB.TK.INTEGER		, FB.TKCLASS.KEYWORD
data "LONG"		, FB.TK.LONG		, FB.TKCLASS.KEYWORD
data "SINGLE"	, FB.TK.SINGLE		, FB.TKCLASS.KEYWORD
data "DOUBLE"	, FB.TK.DOUBLE		, FB.TKCLASS.KEYWORD
data "STRING"	, FB.TK.STRING		, FB.TKCLASS.KEYWORD
data "CALL"		, FB.TK.CALL		, FB.TKCLASS.KEYWORD
data "BYVAL"	, FB.TK.BYVAL		, FB.TKCLASS.KEYWORD
data "INCLUDE"	, FB.TK.INCLUDE		, FB.TKCLASS.KEYWORD
data "DYNAMIC"	, FB.TK.DYNAMIC		, FB.TKCLASS.KEYWORD
data "AS"		, FB.TK.AS			, FB.TKCLASS.KEYWORD
data "DECLARE"	, FB.TK.DECLARE		, FB.TKCLASS.KEYWORD
data "GOTO"		, FB.TK.GOTO		, FB.TKCLASS.KEYWORD
data "GOSUB"	, FB.TK.GOSUB		, FB.TKCLASS.KEYWORD
data "DEFBYTE"	, FB.TK.DEFBYTE		, FB.TKCLASS.KEYWORD
data "DEFUBYTE"	, FB.TK.DEFUBYTE	, FB.TKCLASS.KEYWORD
data "DEFSHORT"	, FB.TK.DEFSHORT	, FB.TKCLASS.KEYWORD
data "DEFUSHORT", FB.TK.DEFUSHORT	, FB.TKCLASS.KEYWORD
data "DEFINT"	, FB.TK.DEFINT		, FB.TKCLASS.KEYWORD
data "DEFUINT"	, FB.TK.DEFUINT		, FB.TKCLASS.KEYWORD
data "DEFLNG"	, FB.TK.DEFLNG		, FB.TKCLASS.KEYWORD
data "DEFLONGINT", FB.TK.DEFLNGINT	, FB.TKCLASS.KEYWORD
data "DEFULONGINT", FB.TK.DEFULNGINT, FB.TKCLASS.KEYWORD
data "DEFSNG"	, FB.TK.DEFSNG		, FB.TKCLASS.KEYWORD
data "DEFDBL"	, FB.TK.DEFDBL		, FB.TKCLASS.KEYWORD
data "DEFSTR"	, FB.TK.DEFSTR		, FB.TKCLASS.KEYWORD
data "CONST"	, FB.TK.CONST		, FB.TKCLASS.KEYWORD
data "FOR"		, FB.TK.FOR			, FB.TKCLASS.KEYWORD
data "STEP"		, FB.TK.STEP		, FB.TKCLASS.KEYWORD
data "NEXT"		, FB.TK.NEXT		, FB.TKCLASS.KEYWORD
data "TO"		, FB.TK.TO			, FB.TKCLASS.KEYWORD
data "TYPE"		, FB.TK.TYPE		, FB.TKCLASS.KEYWORD
data "END"		, FB.TK.END			, FB.TKCLASS.KEYWORD
data "SUB"		, FB.TK.SUB			, FB.TKCLASS.KEYWORD
data "FUNCTION"	, FB.TK.FUNCTION	, FB.TKCLASS.KEYWORD
data "CDECL"	, FB.TK.CDECL		, FB.TKCLASS.KEYWORD
data "STDCALL"	, FB.TK.STDCALL		, FB.TKCLASS.KEYWORD
data "ALIAS"	, FB.TK.ALIAS		, FB.TKCLASS.KEYWORD
data "LIB"		, FB.TK.LIB			, FB.TKCLASS.KEYWORD
data "LET"		, FB.TK.LET			, FB.TKCLASS.KEYWORD
data "BYTE"		, FB.TK.BYTE		, FB.TKCLASS.KEYWORD
data "UBYTE"	, FB.TK.UBYTE		, FB.TKCLASS.KEYWORD
data "SHORT"	, FB.TK.SHORT		, FB.TKCLASS.KEYWORD
data "USHORT"	, FB.TK.USHORT		, FB.TKCLASS.KEYWORD
data "UINTEGER"	, FB.TK.UINT		, FB.TKCLASS.KEYWORD
data "EXIT"		, FB.TK.EXIT		, FB.TKCLASS.KEYWORD
data "DO"		, FB.TK.DO			, FB.TKCLASS.KEYWORD
data "LOOP"		, FB.TK.LOOP		, FB.TKCLASS.KEYWORD
data "RETURN"	, FB.TK.RETURN		, FB.TKCLASS.KEYWORD
data "ANY"		, FB.TK.ANY			, FB.TKCLASS.KEYWORD
data "PTR"		, FB.TK.PTR			, FB.TKCLASS.KEYWORD
data "POINTER"	, FB.TK.POINTER		, FB.TKCLASS.KEYWORD
data "VARPTR"	, FB.TK.VARPTR		, FB.TKCLASS.KEYWORD
data "WHILE"	, FB.TK.WHILE		, FB.TKCLASS.KEYWORD
data "UNTIL"	, FB.TK.UNTIL		, FB.TKCLASS.KEYWORD
data "WEND"		, FB.TK.WEND		, FB.TKCLASS.KEYWORD
data "CONTINUE"	, FB.TK.CONTINUE	, FB.TKCLASS.KEYWORD
data "CBYTE"	, FB.TK.CBYTE		, FB.TKCLASS.KEYWORD
data "CSHORT"	, FB.TK.CSHORT		, FB.TKCLASS.KEYWORD
data "CINT"		, FB.TK.CINT		, FB.TKCLASS.KEYWORD
data "CLNG"		, FB.TK.CLNG		, FB.TKCLASS.KEYWORD
data "CLNGINT"	, FB.TK.CLNGINT		, FB.TKCLASS.KEYWORD
data "CUBYTE"	, FB.TK.CUBYTE		, FB.TKCLASS.KEYWORD
data "CUSHORT"	, FB.TK.CUSHORT		, FB.TKCLASS.KEYWORD
data "CUINT"	, FB.TK.CUINT		, FB.TKCLASS.KEYWORD
data "CULNGINT"	, FB.TK.CULNGINT	, FB.TKCLASS.KEYWORD
data "CSNG"		, FB.TK.CSNG		, FB.TKCLASS.KEYWORD
data "CDBL"		, FB.TK.CDBL		, FB.TKCLASS.KEYWORD
data "CSIGN"	, FB.TK.CSIGN		, FB.TKCLASS.KEYWORD
data "CUNSG"	, FB.TK.CUNSG		, FB.TKCLASS.KEYWORD
data "IF"		, FB.TK.IF			, FB.TKCLASS.KEYWORD
data "THEN"		, FB.TK.THEN		, FB.TKCLASS.KEYWORD
data "ELSE"		, FB.TK.ELSE		, FB.TKCLASS.KEYWORD
data "ELSEIF"	, FB.TK.ELSEIF		, FB.TKCLASS.KEYWORD
data "SELECT"	, FB.TK.SELECT		, FB.TKCLASS.KEYWORD
data "CASE"		, FB.TK.CASE		, FB.TKCLASS.KEYWORD
data "IS"		, FB.TK.IS			, FB.TKCLASS.KEYWORD
data "UNSIGNED"	, FB.TK.UNSIGNED	, FB.TKCLASS.KEYWORD
data "REDIM"	, FB.TK.REDIM		, FB.TKCLASS.KEYWORD
data "ERASE"	, FB.TK.ERASE		, FB.TKCLASS.KEYWORD
data "LBOUND"	, FB.TK.LBOUND		, FB.TKCLASS.KEYWORD
data "UBOUND"	, FB.TK.UBOUND		, FB.TKCLASS.KEYWORD
data "UNION"	, FB.TK.UNION		, FB.TKCLASS.KEYWORD
data "PUBLIC"	, FB.TK.PUBLIC		, FB.TKCLASS.KEYWORD
data "PRIVATE"	, FB.TK.PRIVATE		, FB.TKCLASS.KEYWORD
data "STR"		, FB.TK.STR			, FB.TKCLASS.KEYWORD
data "INSTR"	, FB.TK.INSTR		, FB.TKCLASS.KEYWORD
data "MID"		, FB.TK.MID			, FB.TKCLASS.KEYWORD
data "BYREF"	, FB.TK.BYREF		, FB.TKCLASS.KEYWORD
data "OPTION"	, FB.TK.OPTION		, FB.TKCLASS.KEYWORD
data "BASE"		, FB.TK.BASE		, FB.TKCLASS.KEYWORD
data "EXPLICIT"	, FB.TK.EXPLICIT	, FB.TKCLASS.KEYWORD
data "PASCAL"	, FB.TK.PASCAL		, FB.TKCLASS.KEYWORD
data "PROCPTR"	, FB.TK.PROCPTR		, FB.TKCLASS.KEYWORD
data "SADD"		, FB.TK.SADD		, FB.TKCLASS.KEYWORD
data "RESTORE"	, FB.TK.RESTORE		, FB.TKCLASS.KEYWORD
data "READ"		, FB.TK.READ		, FB.TKCLASS.KEYWORD
data "DATA"		, FB.TK.DATA		, FB.TKCLASS.KEYWORD
data "ABS"		, FB.TK.ABS			, FB.TKCLASS.KEYWORD
data "SGN"		, FB.TK.SGN			, FB.TKCLASS.KEYWORD
data "FIX"		, FB.TK.FIX			, FB.TKCLASS.KEYWORD
data "PRINT"	, FB.TK.PRINT		, FB.TKCLASS.KEYWORD
data "USING"	, FB.TK.USING		, FB.TKCLASS.KEYWORD
data "LEN"		, FB.TK.LEN			, FB.TKCLASS.KEYWORD
data "PEEK"		, FB.TK.PEEK		, FB.TKCLASS.KEYWORD
data "POKE"		, FB.TK.POKE		, FB.TKCLASS.KEYWORD
data "SWAP"		, FB.TK.SWAP		, FB.TKCLASS.KEYWORD
data "COMMON"	, FB.TK.COMMON		, FB.TKCLASS.KEYWORD
data "OPEN"		, FB.TK.OPEN		, FB.TKCLASS.KEYWORD
data "CLOSE"	, FB.TK.CLOSE		, FB.TKCLASS.KEYWORD
data "SEEK"		, FB.TK.SEEK		, FB.TKCLASS.KEYWORD
data "PUT"		, FB.TK.PUT			, FB.TKCLASS.KEYWORD
data "GET"		, FB.TK.GET			, FB.TKCLASS.KEYWORD
data "ACCESS"	, FB.TK.ACCESS		, FB.TKCLASS.KEYWORD
data "WRITE"	, FB.TK.WRITE		, FB.TKCLASS.KEYWORD
data "LOCK"		, FB.TK.LOCK		, FB.TKCLASS.KEYWORD
data "INPUT"	, FB.TK.INPUT		, FB.TKCLASS.KEYWORD
data "OUTPUT"	, FB.TK.OUTPUT		, FB.TKCLASS.KEYWORD
data "BINARY"	, FB.TK.BINARY		, FB.TKCLASS.KEYWORD
data "RANDOM"	, FB.TK.RANDOM		, FB.TKCLASS.KEYWORD
data "APPEND"	, FB.TK.APPEND		, FB.TKCLASS.KEYWORD
data "PRESERVE"	, FB.TK.PRESERVE	, FB.TKCLASS.KEYWORD
data "ON"		, FB.TK.ON			, FB.TKCLASS.KEYWORD
data "ERROR"	, FB.TK.ERROR		, FB.TKCLASS.KEYWORD
data "ENUM"		, FB.TK.ENUM		, FB.TKCLASS.KEYWORD
data "INCLIB"	, FB.TK.INCLIB		, FB.TKCLASS.KEYWORD
data "ASM"		, FB.TK.ASM			, FB.TKCLASS.KEYWORD
data "SPC"		, FB.TK.SPC			, FB.TKCLASS.KEYWORD
data "TAB"		, FB.TK.TAB			, FB.TKCLASS.KEYWORD
data "LINE"		, FB.TK.LINE		, FB.TKCLASS.KEYWORD
data "VIEW"		, FB.TK.VIEW		, FB.TKCLASS.KEYWORD
data "UNLOCK"	, FB.TK.UNLOCK		, FB.TKCLASS.KEYWORD
data "FIELD"	, FB.TK.FIELD		, FB.TKCLASS.KEYWORD
data "LOCAL"	, FB.TK.LOCAL		, FB.TKCLASS.KEYWORD
data "ERR"		, FB.TK.ERR			, FB.TKCLASS.KEYWORD
data "DEFINE"	, FB.TK.DEFINE		, FB.TKCLASS.KEYWORD
data "UNDEF"	, FB.TK.UNDEF		, FB.TKCLASS.KEYWORD
data "IFDEF"	, FB.TK.IFDEF		, FB.TKCLASS.KEYWORD
data "IFNDEF"	, FB.TK.IFNDEF		, FB.TKCLASS.KEYWORD
data "ENDIF"	, FB.TK.ENDIF		, FB.TKCLASS.KEYWORD
data "DEFINED"	, FB.TK.DEFINED		, FB.TKCLASS.KEYWORD
data "RESUME"	, FB.TK.RESUME		, FB.TKCLASS.KEYWORD
data "PSET"		, FB.TK.PSET		, FB.TKCLASS.KEYWORD
data "PRESET"	, FB.TK.PRESET		, FB.TKCLASS.KEYWORD
data "POINT"	, FB.TK.POINT		, FB.TKCLASS.KEYWORD
data "CIRCLE"	, FB.TK.CIRCLE		, FB.TKCLASS.KEYWORD
data "WINDOW"	, FB.TK.WINDOW		, FB.TKCLASS.KEYWORD
data "PALETTE"	, FB.TK.PALETTE		, FB.TKCLASS.KEYWORD
data "SCREEN"	, FB.TK.SCREEN		, FB.TKCLASS.KEYWORD
data "SCREENRES", FB.TK.SCREENRES	, FB.TKCLASS.KEYWORD
data "PAINT"	, FB.TK.PAINT		, FB.TKCLASS.KEYWORD
data "DRAW"		, FB.TK.DRAW		, FB.TKCLASS.KEYWORD
data "EXTERN"	, FB.TK.EXTERN		, FB.TKCLASS.KEYWORD
data "STRPTR"	, FB.TK.STRPTR		, FB.TKCLASS.KEYWORD
data "WITH"		, FB.TK.WITH		, FB.TKCLASS.KEYWORD
data "EXPORT"	, FB.TK.EXPORT		, FB.TKCLASS.KEYWORD
data "IMPORT"	, FB.TK.IMPORT		, FB.TKCLASS.KEYWORD
data "LIBPATH"	, FB.TK.LIBPATH		, FB.TKCLASS.KEYWORD
data "BLOAD"	, FB.TK.BLOAD		, FB.TKCLASS.KEYWORD
data "BSAVE"	, FB.TK.BSAVE		, FB.TKCLASS.KEYWORD
data "CHR"		, FB.TK.CHR			, FB.TKCLASS.KEYWORD
data "ASC"		, FB.TK.ASC			, FB.TKCLASS.KEYWORD
data "LSET"		, FB.TK.LSET		, FB.TKCLASS.KEYWORD
data "IIF"		, FB.TK.IIF			, FB.TKCLASS.KEYWORD
data "..."		, FB.TK.VARARG		, FB.TKCLASS.KEYWORD
data "VA_FIRST"	, FB.TK.VA_FIRST	, FB.TKCLASS.KEYWORD
data "LONGINT"	, FB.TK.LONGINT		, FB.TKCLASS.KEYWORD
data "ULONGINT" , FB.TK.ULONGINT	, FB.TKCLASS.KEYWORD
data "ZSTRING"	, FB.TK.ZSTRING		, FB.TKCLASS.KEYWORD
data "SIZEOF"	, FB.TK.SIZEOF		, FB.TKCLASS.KEYWORD
data "THREADCREATE", FB.TK.THREADCREATE, FB.TKCLASS.KEYWORD
data ""


''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' init/end
''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
sub symbInitSymbols static

	'' globals/module-level
	listNew( @ctx.symlist, FB.INITSYMBOLNODES, len( FBSYMBOL ) )

	hashNew( @ctx.symhash, FB.INITSYMBOLNODES )

	'' locals
	listNew( @ctx.loclist, FB.INITLOCSYMBOLNODES, len( FBLOCSYMBOL ) )

	ctx.lastlbl = NULL

end sub

'':::::
sub symbInitFwdRef static

	listNew( @ctx.fwdlist, FB.INITFWDREFNODES, len( FBFWDREF ) )

	ctx.fwdrefcnt = 0

end sub

'':::::
sub symbInitDims static

	listNew( @ctx.dimlist, FB.INITDIMNODES, len( FBVARDIM ) )

end sub

'':::::
sub symbInitLibs static

	listNew( @ctx.liblist, FB.INITLIBNODES, len( FBLIBRARY ) )

    hashNew( @ctx.libhash, FB.INITLIBNODES )

end sub

'':::::
sub symbInitDefines static
	dim def as string, value as string, proc_id as integer, proc as function() as string

    listNew( @ctx.defarglist, FB.INITDEFARGNODES, len( FBDEFARG ) )

    restore definesdata
    do
    	read def
    	if( len( def ) = 0 ) then
    		exit do
    	end if
    	read value
    	if( value <> "" ) then
    		value = "\"" + value + "\""
    	end if
    	read proc_id
    	select case as const proc_id
    	case PROC_NONE
    		proc = NULL
    	case PROC_FILE
    		proc = @hDefFile
    	case PROC_FUNCTION
    		proc = @hDefFunction
    	case PROC_LINE
    		proc = @hDefLine
    	case PROC_DATE
    		proc = @hDefDate
    	case PROC_TIME
    		proc = @hDefTime
    	end select
    	symbAddDefine( def, value, 0, NULL, FALSE, proc )
    loop

end sub

'':::::
sub symbInitKeywords static
	dim kname as string
	dim id as integer, class as integer

	restore keyworddata
	do
    	read kname
    	if( len( kname ) = 0 ) then
    		exit do
    	end if
    	read id, class
    	if( symbAddKeyword( kname, id, class ) = NULL ) then
    		exit sub
    	end if
    loop

end sub

'':::::
sub symbInit

	''
	if( ctx.inited ) then
		exit sub
	end if


	''
	hashInit

	''
	'' vars, arrays, procs & consts
	''
	symbInitSymbols

	''
	'' keywords
	symbInitKeywords

	''
	'' defines
	''
	symbInitDefines

	''
	'' forward refs
	''
	symbInitFwdRef

	''
	'' arrays dim tb
	''
	symbInitDims

	''
	'' libraries
	''
	symbInitLibs

    ''
    ctx.inited 	= TRUE

end sub

'':::::
sub symbEnd

    if( not ctx.inited ) then
    	exit sub
    end if

    ''
	hashFree( @ctx.libhash )

    hashFree( @ctx.symhash )

	''
	listFree( @ctx.liblist )

	listFree( @ctx.dimlist )

	listFree( @ctx.fwdlist )

	listFree( @ctx.defarglist )

	listFree( @ctx.loclist )

	listFree( @ctx.symlist )

	''
	ctx.inited = FALSE

end sub

'':::::
function hDefFile( ) as string static
	hDefFile = env.infile
end function

'':::::
function hDefFunction( ) as string static
	if( env.currproc = NULL ) then
		hDefFunction = "(main)"
	else
		hDefFunction = symbGetName( env.currproc )
	end if
end function

'':::::
function hDefLine( ) as string static
	hDefLine = ltrim$( str$( lexLineNum ) )
end function

'':::::
function hDefDate( ) as string static
	hDefDate = date$
end function

'':::::
function hDefTime( ) as string static
	hDefTime = time$
end function

''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' add
''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
private function hCanDuplicate( byval n as FBSYMBOL ptr, _
								byval s as FBSYMBOL ptr ) as integer

	select case as const s->class
	'' adding a define or keyword? no dups can exist
	case FB.SYMBCLASS.DEFINE, FB.SYMBCLASS.KEYWORD
		hCanDuplicate = FALSE
		exit function

	'' adding a type field? anything is allowed (udt elms are not added to a hash tb)
	case FB.SYMBCLASS.UDTELM, FB.SYMBCLASS.PROCARG

	'' adding a label, udt or enum? anything but a define or keyword is
	'' allowed, if the same class doesn't exist already
	case FB.SYMBCLASS.LABEL, FB.SYMBCLASS.UDT, FB.SYMBCLASS.ENUM, _
		 FB.SYMBCLASS.TYPEDEF, FB.SYMBCLASS.FWDREF

		hCanDuplicate = FALSE

		do
			select case as const n->class
			case FB.SYMBCLASS.DEFINE, FB.SYMBCLASS.KEYWORD
				exit function

			case else
				if( n->class = s->class ) then
					exit function
				end if
			end select

			n = n->right
		loop while( n <> NULL )

	'' adding a constant or proc? only dup allowed are labels, udts or enums
	case FB.SYMBCLASS.CONST, FB.SYMBCLASS.PROC

		hCanDuplicate = FALSE

		do
			select case as const n->class
			case FB.SYMBCLASS.LABEL, FB.SYMBCLASS.UDT, FB.SYMBCLASS.ENUM, _
				 FB.SYMBCLASS.TYPEDEF, FB.SYMBCLASS.FWDREF

			case else
				exit function
			end select

			n = n->right
		loop while( n <> NULL )

	'' adding a variable? labels, udts or enums are allowed as dups AND
	'' other vars if they have different suffixes -- if any with suffix
	'' exists, a suffix-less will not be accepted (and vice-versa)
	case FB.SYMBCLASS.VAR

		hCanDuplicate = FALSE

		do
			select case as const n->class
			case FB.SYMBCLASS.LABEL, FB.SYMBCLASS.UDT, FB.SYMBCLASS.ENUM, _
				 FB.SYMBCLASS.TYPEDEF, FB.SYMBCLASS.FWDREF

			case FB.SYMBCLASS.VAR
				if( s->scope = n->scope ) then
					if( (s->var.suffix = INVALID) or (n->var.suffix = INVALID) ) then
	    				exit function
					end if

    				'' same suffix?
    				if( n->var.suffix = s->var.suffix ) then
    					exit function
    				end if
    			end if

			case else
				exit function
			end select

			n = n->right
		loop while( n <> NULL )

	end select

	''
	hCanDuplicate = TRUE
	exit function

end function

'':::::
private sub hFixForwardRef( byval f as FBSYMBOL ptr, _
							byval sym as FBSYMBOL ptr, _
							byval class as integer )
    dim as FBFWDREF ptr n, p
    dim as FBSYMBOL ptr ref
    dim as integer typ, ptrcnt

	select case as const class
	case FB.SYMBCLASS.UDT
		typ 	= FB.SYMBTYPE.USERDEF
		ptrcnt 	= 0
	case FB.SYMBCLASS.ENUM
		typ 	= FB.SYMBTYPE.UINT
		ptrcnt 	= 0
	case FB.SYMBCLASS.TYPEDEF
		typ 	= sym->typ
		ptrcnt 	= sym->ptrcnt
		sym 	= sym->subtype
	end select

	n = f->fwd.reftail
	do while( n <> NULL )
		p = n->l

		ref = n->ref

		ref->typ     = typ + (ref->ptrcnt * FB.SYMBTYPE.POINTER)
		ref->subtype = sym
		ref->ptrcnt  = ptrcnt
		ref->lgt	 = symbCalcLen( ref->typ, sym )

		listDelNode( @ctx.fwdlist, n )
		n = p
	loop

	hFreeSymbol f

	ctx.fwdrefcnt -= 1

end sub

'':::::
private sub hAddToFwdRef( byval f as FBSYMBOL ptr, _
						  byval ref as FBSYMBOL ptr ) static
	dim n as FBFWDREF ptr

	n = listNewNode( @ctx.fwdlist )

	n->ref 	= ref
	n->l 	= f->fwd.reftail
	f->fwd.reftail = n

	f->fwd.refs += 1

end sub

'':::::
function hNewSymbol( byval class as integer, _
					 byval dohash as integer = TRUE, _
					 byval symbol as string, _
					 byval aliasname as string, _
					 byval islocal as integer = FALSE, _
					 byval typ as integer = INVALID, _
					 byval subtype as FBSYMBOL ptr = NULL, _
					 byval ptrcnt as integer = 0, _
					 byval suffix as integer = INVALID, _
					 byval preservecase as integer = FALSE ) as FBSYMBOL ptr static

    dim l as FBLOCSYMBOL ptr
    dim s as FBSYMBOL ptr, n as FBSYMBOL ptr
    dim sname as string, slen as integer

    hNewSymbol = NULL

    s = listNewNode( @ctx.symlist )
    if( s = NULL ) then
    	exit function
    end if

    ''
    s->class		= class
    s->scope		= env.scope
    s->typ			= typ
    s->subtype		= subtype
    s->ptrcnt		= ptrcnt

	s->alloctype	= 0
    s->lgt			= 0
    s->ofs			= 0

    if( class = FB.SYMBCLASS.VAR ) then
    	s->var.suffix = suffix
    	s->var.emited = FALSE
    end if

    ''
    slen = len( symbol )
    if( slen > 0 ) then
    	if( not preservecase ) then
    		sname = ucase$( symbol )
    	else
    	    sname = symbol
		end if
    end if

    if( len( aliasname ) > 0 ) then
    	s->alias = aliasname
    else
    	if( slen > 0 ) then
    		s->alias = sname
    	else
    		s->alias = ""
    	end if
    end if

	'' add node to local symbol table for fast deletion later
	if( islocal ) then
		l = listNewNode( @ctx.loclist )
		l->s = s
	end if

	s->left  = NULL
	s->right = NULL

	if( dohash ) then

		'' doesn't exist yet?
		n = hashLookup( @ctx.symhash, sname )
		if( n = NULL ) then
			'' add to hash table
			s->hashitem = hashAdd( @ctx.symhash, sname, s, s->hashindex )

		else
			'' can be duplicated?
			if( not hCanDuplicate( n, s ) ) then
				if( islocal ) then
					listDelNode( @ctx.loclist, l )
				end if
				listDelNode( @ctx.symlist, s )
				exit function
			end if

			s->hashitem  = n->hashitem
			s->hashindex = n->hashindex

			if( not islocal ) then
				'' add to tail
				do while( n->right <> NULL )
					n = n->right
				loop

				n->right = s
				s->left  = n

			else
				'' add to head
				n->hashitem->idx = s
			    n->left	 = s
			    s->right = n

			end if
		end if

	else
		s->hashitem  = NULL
		s->hashindex = 0
	end if

	''
	typ -= ptrcnt * FB.SYMBTYPE.POINTER
	if( typ = FB.SYMBTYPE.FWDREF ) then
		hAddToFwdRef subtype, s
	end if

    ''
    hNewSymbol = s

end function

'':::::
function symbAddKeyword( byval symbol as string, _
						 byval id as integer, _
						 byval class as integer ) as FBSYMBOL ptr
    dim k as FBSYMBOL ptr

    k = hNewSymbol( FB.SYMBCLASS.KEYWORD, TRUE, symbol, "" )
    if( k = NULL ) then
    	symbAddKeyword = NULL
    	exit function
    end if

    ''
    k->key.id		= id
    k->key.class	= class

    symbAddKeyword = k

end function

'':::::
function symbAddDefine( byval symbol as string, _
						byval text as string, _
						byval args as integer = 0, _
						byval arghead as FBDEFARG ptr = NULL, _
						byval isargless as integer = FALSE, _
						byval proc as function( ) as string = NULL ) as FBSYMBOL ptr static
    dim d as FBSYMBOL ptr

    symbAddDefine = NULL

    '' allocate new node
    d = hNewSymbol( FB.SYMBCLASS.DEFINE, TRUE, symbol, "", env.scope > 0 )
    if( d = NULL ) then
    	exit function
    end if

	''
	d->def.text 	= text
	d->def.args		= args
	d->def.arghead	= arghead
	d->def.isargless= isargless
	d->def.proc     = proc

	''
	symbAddDefine = d

end function

'':::::
function symbAddDefineArg( byval lastarg as FBDEFARG ptr, _
						   byval symbol as string ) as FBDEFARG ptr static
    dim a as FBDEFARG ptr

    symbAddDefineArg = NULL

    a = listNewNode( @ctx.defarglist )
    if( a = NULL ) then
    	exit function
    end if

	if( lastarg <> NULL ) then
		lastarg->r = a
	end if

	''
    a->name		= ucase$( symbol )
    a->r		= NULL

    symbAddDefineArg = a

end function

'':::::
private sub hCheckFwdRef( byval s as FBSYMBOL ptr, _
						  byval class as integer ) static
	dim as FBSYMBOL ptr f, n

	'' go to head
	n = s
	do while( n->left <> NULL )
		n = n->left
	loop

	f = symbFindByClass( n, FB.SYMBCLASS.FWDREF )
	if( f <> NULL ) then
		hFixForwardRef f, s, class
	end if

end sub

'':::::
function symbAddTypedef( byval symbol as string, _
						 byval typ as integer, _
						 byval subtype as FBSYMBOL ptr, _
						 byval ptrcnt as integer, _
						 byval lgt as integer ) as FBSYMBOL ptr static
    dim as FBSYMBOL ptr t

    symbAddTypedef = NULL

    '' allocate new node
    t = hNewSymbol( FB.SYMBCLASS.TYPEDEF, TRUE, symbol, "", env.scope > 0, typ, subtype, ptrcnt )
    if( t = NULL ) then
    	exit function
    end if

	''
	t->lgt 	= lgt

	'' check for forward references
	if( ctx.fwdrefcnt > 0 ) then
		hCheckFwdRef t, FB.SYMBCLASS.TYPEDEF
	end if

	''
	symbAddTypedef = t

end function

'':::::
function symbAddFwdRef( byval symbol as string ) as FBSYMBOL ptr static
    dim f as FBSYMBOL ptr

    symbAddFwdRef = NULL

    '' allocate new node
    f = hNewSymbol( FB.SYMBCLASS.FWDREF, TRUE, symbol, "", env.scope > 0 )
    if( f = NULL ) then
    	exit function
    end if

   	f->fwd.refs = 0
   	f->fwd.reftail = NULL

   	''
   	ctx.fwdrefcnt += 1

    symbAddFwdRef = f

end function

'':::::
function hCreateArrayDesc( byval s as FBSYMBOL ptr, _
						   byval dimensions as integer ) as FBSYMBOL ptr static
    dim as string sname, aname
    dim as FBSYMBOL ptr d
    dim as integer lgt, ofs
    dim as integer isshared, isstatic, isdynamic, iscommon, ispubext

	hCreateArrayDesc = NULL

	isshared 	= (s->alloctype and FB.ALLOCTYPE.SHARED) > 0
	isstatic 	= (s->alloctype and FB.ALLOCTYPE.STATIC) > 0
	isdynamic	= (s->alloctype and FB.ALLOCTYPE.DYNAMIC) > 0
	iscommon 	= (s->alloctype and FB.ALLOCTYPE.COMMON) > 0
	ispubext 	= (s->alloctype and (FB.ALLOCTYPE.PUBLIC or FB.ALLOCTYPE.EXTERN)) > 0

	if( (iscommon) or (ispubext and isdynamic) ) then
		sname = symbGetName( s )
	else
		sname = hMakeTmpStr
	end if

	if( (env.scope = 0) or (isshared) or (isstatic) ) then
		aname = sname
		ofs = 0
	else
		lgt = FB.ARRAYDESCSIZE + dimensions * (FB.INTEGERSIZE+FB.INTEGERSIZE)
		aname = emitAllocLocal( lgt, ofs )
	end if

	d = hNewSymbol( FB.SYMBCLASS.VAR, FALSE, "", aname, (env.scope > 0) and (not isshared), _
					FB.SYMBTYPE.USERDEF, FB.DESCTYPE.ARRAY, 0 )
    if( d = NULL ) then
    	exit function
    end if

	''
	if( isshared ) then
		d->alloctype	= FB.ALLOCTYPE.SHARED
	elseif( isstatic ) then
		d->alloctype	= FB.ALLOCTYPE.STATIC
	else
		d->alloctype	= 0
	end if

	d->ofs				= ofs
	d->var.array.desc 	= NULL
	d->var.array.dif  	= 0
	d->var.array.dims 	= 0

    d->var.suffix 		= INVALID
    d->var.initialized 	= FALSE

	''
	hCreateArrayDesc = d

end function

'':::::
function hNewDim( head as FBVARDIM ptr, _
				  tail as FBVARDIM ptr, _
				  byval lower as integer, _
				  byval upper as integer ) as FBVARDIM ptr static
    dim as FBVARDIM ptr d, n

    hNewDim = NULL

    d = listNewNode( @ctx.dimlist )
    if( d = NULL ) then
    	exit function
    end if

    d->lower = lower
    d->upper = upper

	n = tail
	d->r = NULL
	tail = d
	if( n <> NULL ) then
		n->r = d
	else
		head = d
	end if

    hNewDim = d

end function

'':::::
sub symbSetArrayDims( byval s as FBSYMBOL ptr, _
					  byval dimensions as integer, _
					  dTB() as FBARRAYDIM )

    dim as integer i
    dim as FBVARDIM ptr d

	s->var.array.dims = dimensions

	if( dimensions > 0 ) then
		s->var.array.dif = hCalcDiff( dimensions, dTB(), s->lgt )

		if( s->var.array.dimhead = NULL ) then
			for i = 0 to dimensions-1
				if( hNewDim( s->var.array.dimhead, s->var.array.dimtail, _
							 dTB(i).lower, dTB(i).upper ) = NULL ) then
				end if
			next i
		else
			d = s->var.array.dimhead
			for i = 0 to dimensions-1
				d->lower = dTB(i).lower
				d->upper = dTB(i).upper
				d = d->r
			next i
		end if

	else
		s->var.array.dif = 0
	end if

	'' dims can be -1 with COMMON arrays..
	if( dimensions <> 0 ) then
		if( s->var.array.desc = NULL ) then
			s->var.array.desc = hCreateArrayDesc( s, dimensions )
		end if
	else
		s->var.array.desc = NULL
	end if

end sub

'':::::
private sub hSetupVar( byval s as FBSYMBOL ptr, _
			   		   byval symbol as string, _
			   		   byval aname as string, _
			   		   byval typ as integer, _
			   		   byval subtype as FBSYMBOL ptr, _
			   		   byval lgt as integer, _
			   		   byval ofs as integer, _
			   		   byval dimensions as integer, _
			   		   dTB() as FBARRAYDIM, _
			   		   byval alloctype as integer ) static

	if( typ = INVALID ) then
		typ = hGetDefType( symbol )
	end if

	''
	s->alloctype= alloctype
	s->acccnt 	= 0

	s->lgt		= lgt
	s->ofs		= ofs

	'' array fields
	s->var.array.dimhead = NULL
	s->var.array.dimtail = NULL

	s->var.array.elms = 0						'' real value doesn't matter
	s->var.array.desc = NULL
	if( dimensions <> 0 ) then
		symbSetArrayDims( s, dimensions, dTB() )
	else
		s->var.array.dims = 0
		s->var.array.dif  = 0
	end if

	''
    s->var.initialized 	= FALSE

end sub

'':::::
function symbAddVarEx( byval symbol as string, _
					   byval aliasname as string, _
					   byval typ as integer, _
					   byval subtype as FBSYMBOL ptr, _
					   byval ptrcnt as integer, _
					   byval lgt as integer, _
					   byval dimensions as integer, _
					   dTB() as FBARRAYDIM, _
				       byval alloctype as integer, _
				       byval addsuffix as integer, _
				       byval preservecase as integer, _
				       byval clearname as integer ) as FBSYMBOL ptr static

    dim as FBSYMBOL ptr s
    dim as string aname
    dim as integer elms, suffix, arglen
    dim as integer isshared, isstatic, ispublic, isextern
    dim as integer isarg, islocal, ofs

    symbAddVarEx = NULL

    ''
    isshared = (alloctype and FB.ALLOCTYPE.SHARED) > 0
    isstatic = (alloctype and FB.ALLOCTYPE.STATIC) > 0
    ispublic = (alloctype and FB.ALLOCTYPE.PUBLIC) > 0
    isextern = (alloctype and FB.ALLOCTYPE.EXTERN) > 0
    isarg    = (alloctype and (FB.ALLOCTYPE.ARGUMENTBYDESC or _
    						   FB.ALLOCTYPE.ARGUMENTBYVAL or _
    						   FB.ALLOCTYPE.ARGUMENTBYREF)) > 0
	islocal  = FALSE

    ''
    if( lgt <= 0 ) then
		if( typ = INVALID ) then
			suffix = hGetDefType( symbol )
		else
			suffix = typ
 		end if
    	lgt	= symbCalcLen( suffix, subtype )
    end if

    ''
    if( addsuffix ) then
    	suffix = typ
    else
    	suffix = INVALID
    end if

    ''
    ofs = 0

	'' create an alias name (the real one that will be emited)
	if( len( aliasname ) > 0 ) then
		aname = aliasname
	else
		if( (not isshared) and (isstatic) ) then
			aname = hMakeTmpStr
		else
			if( (ispublic) or (isextern) ) then
			    aname = hCreateName( symbol, suffix, preservecase, TRUE, clearname )
			elseif( (isshared) or (env.scope = 0) ) then
				aname = hCreateName( symbol, suffix, preservecase, TRUE, clearname )
			else
				if( not isarg ) then
					elms = hCalcElements2( dimensions, dTB() )
					aname = emitAllocLocal( lgt * elms, ofs )
					islocal = TRUE
				else
        			if( alloctype = FB.ALLOCTYPE.ARGUMENTBYVAL ) then
        				arglen = lgt
        			else
        				arglen = FB.POINTERSIZE
        			end if
					aname = emitAllocArg( arglen, ofs )
				end if
			end if
		end if
	end if

	''
	s = hNewSymbol( FB.SYMBCLASS.VAR, TRUE, symbol, aname, (env.scope > 0) and (not isshared), _
					typ, subtype, ptrcnt, suffix, preservecase )

	if( s = NULL ) then
		'' remove a local or arg or else emit will reserve unused space for it..
		if( islocal ) then
			emitFreeLocal( lgt * elms )
		elseif( isarg ) then
			emitFreeArg( arglen )
		end if

		exit function
	end if

	''
	hSetupVar( s, symbol, aname, typ, subtype, lgt, ofs, dimensions, dTB(), alloctype )

	symbAddVarEx = s

end function

'':::::
function symbAddVar( byval symbol as string, _
					 byval typ as integer, _
					 byval subtype as FBSYMBOL ptr, _
				     byval ptrcnt as integer, _
				     byval dimensions as integer, _
				     dTB() as FBARRAYDIM, _
				     byval alloctype as integer ) as FBSYMBOL ptr static

    symbAddVar = symbAddVarEx( symbol, "", typ, subtype, ptrcnt, _
    						   0, dimensions, dTB(), _
    						   alloctype, _
    						   TRUE, FALSE, TRUE )
end function

'':::::
function symbAddTempVar( byval typ as integer, _
						 byval subtype as FBSYMBOL ptr = NULL ) as FBSYMBOL ptr static
	dim sname as string, s as FBSYMBOL ptr, alloctype as integer
    dim dTB(0) as FBARRAYDIM

	sname = hMakeTmpStr

	alloctype = FB.ALLOCTYPE.TEMP
	if( (env.scope > 0) and (env.isprocstatic) ) then
		alloctype = alloctype or FB.ALLOCTYPE.STATIC
	end if

	s = symbAddVar( sname, typ, subtype, 0, 0, dTB(), alloctype )

	symbAddTempVar = s

end function

'':::::
function hAllocNumericConst( byval sname as string, _
							 byval typ as integer ) as FBSYMBOL ptr static
	dim s as FBSYMBOL ptr, dTB(0) as FBARRAYDIM
    dim cname as string, aname as string
    dim p as integer

	hAllocNumericConst = NULL

	cname = "_fbnc_" + sname

	s = symbFindByNameAndSuffix( cname, typ, FALSE )
	if( s <> NULL ) then
		hAllocNumericConst = s
		exit function
	end if

	aname = hMakeTmpStr

	s = symbAddVarEx( cname, aname, typ, NULL, 0, 0, 0, dTB(), FB.ALLOCTYPE.SHARED, TRUE, FALSE, FALSE )

	s->var.initialized = TRUE

	if( typ = FB.SYMBTYPE.DOUBLE ) then
		p = instr( sname, "D" )
		if( p <> 0 ) then
			sname[p-1] = asc( "E" )
		end if
	end if
	s->var.inittext	= sname

	hAllocNumericConst = s

end function

'':::::
function hAllocStringConst( byval sname as string, _
							byval lgt as integer ) as FBSYMBOL ptr static
	dim s as FBSYMBOL ptr, dTB(0) as FBARRAYDIM
    dim cname as string, aname as string

	hAllocStringConst = NULL

	cname = "_fbsc_" + sname

	''
	s = symbFindByNameAndClass( cname, FB.SYMBCLASS.VAR, TRUE )
	if( s <> NULL ) then
		hAllocStringConst = s 's->var.array.desc
		exit function
	end if

	''
	if( lgt < 0 ) then
		lgt = len( sname )
	end if

	aname = hMakeTmpStr

	'' plus the null-char as rtlib wrappers will take it into account
	lgt += 1

	s = symbAddVarEx( cname, aname, FB.SYMBTYPE.FIXSTR, NULL, 0, lgt, 0, dTB(), _
					  FB.ALLOCTYPE.SHARED, FALSE, TRUE, FALSE )

	s->var.initialized = TRUE
	s->var.inittext = sname

	'' can't fake a descriptor as the literal string passed to user procs can be modified/reused
	's->var.array.desc = hCreateStringDesc( s )

	hAllocStringConst = s 's->var.array.desc

end function

'':::::
function symbAddConst( byval symbol as string, _
					   byval typ as integer, _
					   byval text as string, _
					   byval lgt as integer ) as FBSYMBOL ptr static
    dim c as FBSYMBOL ptr

    symbAddConst = NULL

    ''
    c = hNewSymbol( FB.SYMBCLASS.CONST, TRUE, symbol, "", env.scope > 0, typ )
	if( c = NULL ) then
		exit function
	end if

	c->lgt		= lgt
	c->con.text	= text

	symbAddConst = c

end function

'':::::
function symbAddLabel( byval symbol as string, _
					   byval declaring as integer = TRUE, _
					   byval createalias as integer = FALSE ) as FBSYMBOL ptr static
    dim l as FBSYMBOL ptr
    dim lname as string, aname as string

    symbAddLabel = NULL

    '' check if label already exists
    l = symbFindByNameAndClass( symbol, FB.SYMBCLASS.LABEL )
    if( l <> NULL ) then
    	if( declaring ) then
    		if( l->lbl.declared ) then
    			exit function
    		else
    			l->lbl.declared = TRUE
    			symbAddLabel = l
    			exit function
    		end if
    	else
    		symbAddLabel = l
    		exit function
    	end if
    end if

	'' add the new label
	if( not createalias ) then
    	aname = symbol
	else
		aname = hMakeTmpStr
	end if

    l = hNewSymbol( FB.SYMBCLASS.LABEL, TRUE, symbol, aname, env.scope > 0 )
    if( l = NULL ) then
    	exit function
    end if

	l->lbl.declared = declaring

	symbAddLabel = l

end function


'':::::
function symbAddUDT( byval symbol as string, _
					 byval isunion as integer, _
					 byval align as integer ) as FBSYMBOL ptr static
    dim t as FBSYMBOL ptr

    symbAddUDT = NULL

    t = hNewSymbol( FB.SYMBCLASS.UDT, TRUE, symbol, "", env.scope > 0 )
	if( t = NULL ) then
		exit function
	end if

	t->udt.isunion	= isunion
	t->udt.elements	= 0
	t->udt.head 	= NULL
	t->udt.tail 	= NULL
	t->udt.ofs		= 0
	t->udt.align	= align
	t->udt.lfldlen	= 0
	t->udt.innerlgt	= 0
	t->udt.bitpos	= 0

	symbAddUDT = t

end function

'':::::
function hCalcALign( byval lgt as integer, _
					 byval ofs as integer, _
					 byval align as integer, _
					 byval typ as integer, _
					 byval subtype as FBSYMBOL ptr ) as integer static
    dim pad as integer
    dim e as FBSYMBOL ptr

	hCalcALign = 0

	if( align <= 1 ) then
		exit function
	end if

	'' if field is another UDT, loop until a non-UDT header field is found
	if( typ = FB.SYMBTYPE.USERDEF ) then
		do
			e = subtype->udt.head
    		typ = e->typ
    		subtype = e->subtype
		loop while( typ = FB.SYMBTYPE.USERDEF )

		lgt = e->lgt

		'' len = field's len + pad from current field to the next field, if any
		e = e->var.elm.r
		if( e <> NULL ) then
			lgt += (e->var.elm.ofs - lgt)
		end if
	end if

	select case typ
	'' don't align strings
	case FB.SYMBTYPE.CHAR, FB.SYMBTYPE.FIXSTR

	case else
		select case as const lgt
		'' align byte, short, int's, float's and double's to the nearest boundary
		case 1, 2, 4, 8
			pad = lgt - 1

		'' anything else to align given (default: sizeof( int ))
		case else
			pad = align - 1
			lgt = align
		end select

		if( pad > 0 ) then
			hCalcALign = (lgt - (ofs and pad)) mod lgt
		end if

	end select

end function

'':::::
function symbCheckBitField( byval udt as FBSYMBOL ptr, _
							byval typ as integer, _
							byval lgt as integer, _
							byval bits as integer ) as integer

	if( (bits <= 0) or _
		(bits > lgt*8) or _
		(typ >= FB.SYMBTYPE.SINGLE) ) then
		return FALSE
	end if

    return TRUE

end function

'':::::
function symbAddUDTElement( byval t as FBSYMBOL ptr, _
							byval elmname as string, _
						    byval dimensions as integer, _
						    dTB() as FBARRAYDIM, _
						    byval typ as integer, _
						    byval subtype as FBSYMBOL ptr, _
						    byval ptrcnt as integer, _
						    byval lgt as integer, _
						    byval bits as integer, _
						    byval isinner as integer ) as FBSYMBOL ptr static

    dim as FBSYMBOL ptr e, tail
    dim as integer align, i, updateudt
    dim as string ename

    symbAddUDTElement = NULL

    ename = ucase$( elmname )

    '' check if element already exists in the current struct
    e = t->udt.head
    do while( e <> NULL )

    	if( e->alias = ename ) then
    		exit function
    	end if

    	'' next
    	e = e->var.elm.r
    loop

	tail = t->udt.tail

    ''
	if( (lgt <= 0) or (typ = FB.SYMBTYPE.USERDEF) ) then
		lgt	= symbCalcLen( typ, subtype, TRUE )
	end if

    '' check if the parent ofs must be updated
    updateudt = TRUE
    if( bits > 0 ) then
    	if( t->udt.bitpos > 0 ) then
    		'' does it fit? if not, start at a new pos..
    		if( t->udt.bitpos + bits > tail->lgt*8 ) then
    			t->udt.bitpos = 0
    		else
    			'' if it fits but len is different, make it the same
    			if( lgt <> tail->lgt ) then
    				typ = tail->typ
    				lgt = tail->lgt
    			end if
    		end if
    	end if

		'' don't update if there are enough bits left
		if( t->udt.bitpos <> 0 ) then
			updateudt = FALSE
		end if

    else
    	t->udt.bitpos = 0
    end if

	''
    e = hNewSymbol( FB.SYMBCLASS.UDTELM, FALSE, ename, "", FALSE, typ, subtype, ptrcnt )
    if( e = NULL ) then
    	exit function
    end if

	'' add to parent's linked-list
	e->var.elm.l 		= tail
	e->var.elm.r 		= NULL
    e->var.elm.parent	= t
	t->udt.tail 		= e
	if( tail <> NULL ) then
		tail->var.elm.r = e
	else
		t->udt.head 	= e
	end if

    t->udt.elements	+= 1

	''
	if( updateudt ) then
		align = hCalcALign( lgt, t->udt.ofs, t->udt.align, typ, subtype )
		if( align > 0 ) then
			t->udt.ofs += align
		end if
	end if

	e->lgt 				= lgt
	if( updateudt ) then
		e->var.elm.ofs	= t->udt.ofs
	else
		e->var.elm.ofs	= t->udt.ofs - lgt
	end if
	e->var.elm.bitpos	= t->udt.bitpos
	e->var.elm.bits		= bits

	'' array fields
	e->var.array.dif	= hCalcDiff( dimensions, dTB(), lgt )
	e->var.array.dimhead= NULL
	e->var.array.dimtail= NULL

	e->var.array.dims	= dimensions
	if( dimensions > 0 ) then
		for i = 0 to dimensions-1
			if( hNewDim( e->var.array.dimhead, e->var.array.dimtail, dTB(i).lower, dTB(i).upper ) = NULL ) then
			end if
		next i
	end if

	e->var.array.elms 	= hCalcElements( e )

	'' update UDT length
	lgt *= e->var.array.elms

	if( updateudt ) then
		if( not t->udt.isunion ) then
			if( not isinner ) then
				t->udt.ofs += lgt
				t->lgt = t->udt.ofs
			else
				if( lgt > t->udt.innerlgt ) then
					t->udt.innerlgt = lgt
				end if
			end if

		else
			if( not isinner ) then
				t->udt.ofs = 0
				if( lgt > t->lgt ) then
					t->lgt = lgt
					t->udt.lfldlen = lgt
				end if
			else
				t->udt.ofs += lgt
				t->udt.innerlgt = t->udt.ofs
			end if
		end if
	end if

	'' update the bit position, wrapping around
	if( bits > 0 ) then
		t->udt.bitpos += bits
		t->udt.bitpos and= (irGetDataBits( typ ) - 1)
	end if

	''
    e->var.initialized 	= FALSE

    symbAddUDTElement = e

end function

'':::::
sub symbRoundUDTSize( byval t as FBSYMBOL ptr ) static
    dim round as integer, align as integer

	align = t->udt.align

	if( align > 1 ) then

		round = (align - (t->lgt and (align-1))) and (align-1)

		if( round > 0 ) then
			t->lgt += round
		end if

	end if

	'' check for forward references
	if( ctx.fwdrefcnt > 0 ) then
		hCheckFwdRef t, FB.SYMBCLASS.UDT
	end if

end sub

'':::::
sub symbRecalcUDTSize( byval t as FBSYMBOL ptr ) static
    dim lgt as integer

	lgt = t->udt.innerlgt
	if( lgt > 0 ) then

		if( not t->udt.isunion ) then
			t->udt.ofs += lgt
			t->lgt = t->udt.ofs
		else
			t->udt.ofs = 0
			if( lgt > t->lgt ) then
				t->lgt = lgt
				t->udt.lfldlen = lgt
			end if
		end if

		t->udt.innerlgt = 0
	end if

end sub

'':::::
function symbAddEnum( byval symbol as string ) as FBSYMBOL ptr static
    dim i as integer, e as FBSYMBOL ptr

    symbAddEnum = NULL

    ''
    e = hNewSymbol( FB.SYMBCLASS.ENUM, TRUE, symbol, "", env.scope > 0 )
	if( e = NULL ) then
		exit function
	end if

	'' check for forward references
	if( ctx.fwdrefcnt > 0 ) then
		hCheckFwdRef e, FB.SYMBCLASS.ENUM
	end if


	symbAddEnum = e

end function

'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' procs
'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function symbAddLib( byval libname as string ) as FBLIBRARY ptr static
    dim l as FBLIBRARY ptr

    symbAddLib = NULL

    '' check if not already declared
    l = hashLookup( @ctx.libhash, libname )
    if( l <> NULL ) then
    	symbAddLib = l
    	exit function
    end if

    l = listNewNode( @ctx.liblist )
	if( l = NULL ) then
		exit function
	end if

	''
	l->name		= libname

	l->hashitem = hashAdd( @ctx.libhash, libname, l, l->hashindex )

	symbAddLib = l

end function

'':::::
function hCalcProcArgsLen( byval args as integer, _
						   byval argtail as FBSYMBOL ptr ) as integer
	dim i as integer, lgt as integer

	lgt	= 0
	do while( argtail <> NULL )
		select case argtail->arg.mode
		case FB.ARGMODE.BYVAL
			lgt	+= ((argtail->lgt + 3) and not 3)			'' x86 assumption!

		case FB.ARGMODE.BYREF, FB.ARGMODE.BYDESC
			lgt	+= FB.POINTERSIZE
		end select

		argtail = argtail->arg.l
	loop

	hCalcProcArgsLen = lgt

end function

'':::::
function symbAddArg( byval symbol as string, _
					 byval tail as FBSYMBOL ptr, _
					 byval typ as integer, _
					 byval subtype as FBSYMBOL ptr, _
					 byval ptrcnt as integer, _
					 byval lgt as integer, _
					 byval mode as integer, _
					 byval suffix as integer, _
					 byval optional as integer, _
					 byval optval as FBVALUE ptr ) as FBSYMBOL ptr static
    dim a as FBSYMBOL ptr

    symbAddArg = NULL

    a = hNewSymbol( FB.SYMBCLASS.PROCARG, FALSE, "", _
    				symbol, FALSE, typ, subtype, ptrcnt, INVALID, TRUE )
    if( a = NULL ) then
    	exit function
    end if

	a->arg.l = tail
	a->arg.r = NULL
	if( tail <> NULL ) then
		tail->arg.r = a
	end if

	''
	a->lgt			= lgt
	a->arg.mode		= mode
	a->arg.suffix	= suffix
	a->arg.optional	= optional

	if( optional ) then
		select case as const typ
		case IR.DATATYPE.FIXSTR, IR.DATATYPE.STRING, IR.DATATYPE.CHAR
			a->arg.optval.valuestr = optval->valuestr
		case IR.DATATYPE.LONGINT, IR.DATATYPE.ULONGINT
			a->arg.optval.value64 = optval->value64
		case IR.DATATYPE.SINGLE, IR.DATATYPE.DOUBLE
			a->arg.optval.valuef = optval->valuef
		case else
			a->arg.optval.valuei = optval->valuei
		end select
	end if

    symbAddArg = a

end function

'':::::
private function hGetProcRealType( byval typ as integer, _
								   byval subtype as FBSYMBOL ptr ) as integer static

    select case typ
    '' string? it's actually a pointer to a string descriptor
    case FB.SYMBTYPE.STRING
    	 return FB.SYMBTYPE.POINTER + FB.SYMBTYPE.STRING

    '' UDT? follow GCC 3.x's ABI
    case FB.SYMBTYPE.USERDEF

		'' use the un-padded UDT len
		select case as const symbGetUDTLen( subtype )
		case 1
			return FB.SYMBTYPE.BYTE

		case 2
			return FB.SYMBTYPE.SHORT

		case 3
			'' return as int only if first is a short
			if( subtype->udt.head->lgt = 2 ) then
				'' and if the struct is not packed
				if( subtype->lgt >= FB.INTEGERSIZE ) then
					return FB.SYMBTYPE.INTEGER
				end if
			end if

		case FB.INTEGERSIZE

			'' return in ST(0) if there's only one element and it's a SINGLE
			if( subtype->udt.elements = 1 ) then
				do
					if( subtype->udt.head->typ = FB.SYMBTYPE.SINGLE ) then
						return FB.SYMBTYPE.SINGLE
					end if

					if( subtype->udt.head->typ <> FB.SYMBTYPE.USERDEF ) then
						exit do
					end if

					subtype = subtype->udt.head->subtype

					if( subtype->udt.elements <> 1 ) then
						exit do
					end if
				loop
			end if

			return FB.SYMBTYPE.INTEGER

		case FB.INTEGERSIZE + 1, FB.INTEGERSIZE + 2, FB.INTEGERSIZE + 3

			'' return as longint only if first is a int
			if( subtype->udt.head->lgt = FB.INTEGERSIZE ) then
				'' and if the struct is not packed
				if( subtype->lgt >= FB.INTEGERSIZE*2 ) then
					return FB.SYMBTYPE.LONGINT
				end if
			end if

		case FB.INTEGERSIZE*2

			'' return in ST(0) if there's only one element and it's a DOUBLE
			if( subtype->udt.elements = 1 ) then
				do
					if( subtype->udt.head->typ = FB.SYMBTYPE.DOUBLE ) then
						return FB.SYMBTYPE.DOUBLE
					end if

					if( subtype->udt.head->typ <> FB.SYMBTYPE.USERDEF ) then
						exit do
					end if

					subtype = subtype->udt.head->subtype

					if( subtype->udt.elements <> 1 ) then
						exit do
					end if
				loop
			end if

			return FB.SYMBTYPE.LONGINT

		end select

		'' if nothing matched, it's the pointer that was passed as the 1st arg
		return FB.SYMBTYPE.POINTER + FB.SYMBTYPE.USERDEF

	'' type is the same
	case else
    	return typ

	end select

end function

'':::::
private function hSetupProc( byval symbol as string, _
							 byval aliasname as string, _
							 byval libname as string, _
				             byval typ as integer, _
				             byval subtype as FBSYMBOL ptr, _
				             byval ptrcnt as integer, _
				             byval alloctype as integer, _
				             byval mode as integer, _
				             byval argc as integer, _
				             byval argtail as FBSYMBOL ptr, _
			                 byval declaring as integer, _
			                 byval preservecase as integer = FALSE ) as FBSYMBOL ptr static

    dim as integer lgt, i, realtype
    dim as FBSYMBOL ptr f, a
    dim as string sname, aname

    hSetupProc = NULL

	''
	if( typ = INVALID ) then
		typ = hGetDefType( symbol )
		subtype = NULL
	end if

    realtype = hGetProcRealType( typ, subtype )

    lgt = hCalcProcArgsLen( argc, argtail )

    ''
    if( len( aliasname ) = 0 ) then
    	if( len( libname ) = 0 ) then
    		aname = ucase$( symbol )
    	else
    		aname = symbol
    	end if
    else
    	aname = aliasname
    end if

#ifdef TARGET_WIN32
    if( instr( aname, "@" ) = 0 ) then
    	aname = hCreateProcAlias( aname, lgt, mode )
    end if
#else
	aname = hCreateProcAlias( aname, lgt, mode )
#endif

	f = hNewSymbol( FB.SYMBCLASS.PROC, TRUE, symbol, aname, FALSE, typ, subtype, ptrcnt, _
					INVALID, preservecase )
	if( f = NULL ) then
		exit function
	end if

    ''
	f->alloctype	= alloctype or FB.ALLOCTYPE.SHARED

    '' if proc returns an UDT, add the hidden pointer passed as the 1st arg
    if( typ = FB.SYMBTYPE.USERDEF ) then
    	if( realtype = FB.SYMBTYPE.POINTER + FB.SYMBTYPE.USERDEF ) then
    		lgt += FB.POINTERSIZE
    	end if
    end if

	f->lgt			= lgt

	f->proc.isdeclared = declaring
	f->proc.mode	= mode
	f->proc.realtype= realtype

	if( len( libname ) > 0 ) then
		f->proc.lib = symbAddLib( libname )
	else
		f->proc.lib = NULL
	end if

	'' add arguments (w/o declaring them as symbols)
	f->proc.args 	= argc
	f->proc.argtail	= argtail

	if( argtail <> NULL ) then
		do while( argtail->arg.l <> NULL )
			argtail = argtail->arg.l
		loop
	end if

	f->proc.arghead	= argtail

	hSetupProc = f

end function

'':::::
function symbAddPrototype( byval symbol as string, _
						   byval aliasname as string, _
						   byval libname as string, _
						   byval typ as integer, _
						   byval subtype as FBSYMBOL ptr, _
						   byval ptrcnt as integer, _
						   byval alloctype as integer, _
						   byval mode as integer, _
						   byval argc as integer, _
						   byval argtail as FBSYMBOL ptr, _
						   byval isexternal as integer, _
						   byval preservecase as integer = FALSE ) as FBSYMBOL ptr static

    dim f as FBSYMBOL ptr

    symbAddPrototype = NULL

	f = hSetupProc( symbol, aliasname, libname, typ, subtype, ptrcnt, alloctype, mode, _
					argc, argtail, isexternal, preservecase )
	if( f = NULL ) then
		exit function
	end if

	symbAddPrototype = f

end function

'':::::
function symbAddProc( byval symbol as string, _
					  byval aliasname as string, _
					  byval libname as string, _
					  byval typ as integer, _
					  byval subtype as FBSYMBOL ptr, _
					  byval ptrcnt as integer, _
					  byval alloctype as integer, _
					  byval mode as integer, _
					  byval argc as integer, _
					  byval argtail as FBSYMBOL ptr ) as FBSYMBOL ptr static

    dim f as FBSYMBOL ptr

    symbAddProc = NULL

	f = hSetupProc( symbol, aliasname, libname, typ, subtype, ptrcnt, alloctype, mode, _
					argc, argtail, TRUE, FALSE )
	if( f = NULL ) then
		exit function
	end if

	symbAddProc = f

end function

'':::::
function symbAddArgAsVar( byval symbol as string, _
						  byval arg as FBSYMBOL ptr ) as FBSYMBOL ptr
    dim dTB(0) as FBARRAYDIM
    dim s as FBSYMBOL ptr, alloctype as integer, typ as integer

	symbAddArgAsVar = NULL

	typ = arg->typ

	select case as const arg->arg.mode
    case FB.ARGMODE.BYVAL
    	'' byval string? it's actually an pointer to a zstring
    	if( typ = FB.SYMBTYPE.STRING ) then
    		alloctype = FB.ALLOCTYPE.ARGUMENTBYREF
    		typ = FB.SYMBTYPE.CHAR
    	else
    		alloctype = FB.ALLOCTYPE.ARGUMENTBYVAL
    	end if
	case FB.ARGMODE.BYREF
	    alloctype = FB.ALLOCTYPE.ARGUMENTBYREF
	case FB.ARGMODE.BYDESC
    	alloctype = FB.ALLOCTYPE.ARGUMENTBYDESC
	case else
    	exit function
	end select

    s = symbAddVarEx( symbol, "", typ, arg->subtype, 0, 0, _
    				  0, dTB(), alloctype, arg->arg.suffix <> INVALID, FALSE, TRUE )

    if( s = NULL ) then
    	exit function
    end if

	symbAddArgAsVar = s

end function

'':::::
function symbAddProcResult( byval f as FBSYMBOL ptr ) as FBSYMBOL ptr static
	dim rname as string
	dim dTB(0) as FBARRAYDIM
	dim s as FBSYMBOL ptr

	rname = "_fbpr_" + f->alias

	s = symbAddVarEx( rname, "", f->typ, f->subtype, 0, 0, 0, dTB(), 0, TRUE, TRUE, FALSE )

	symbAddProcResult = s

end function

''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' lookups
''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function symbLookup( byval symbol as string, _
					 id as integer, _
					 class as integer, _
					 byval preservecase as integer = FALSE ) as FBSYMBOL ptr static
    dim s as FBSYMBOL ptr

    if( not preservecase ) then
    	s = hashLookup( @ctx.symhash, ucase$( symbol ) )
    else
    	s = hashLookup( @ctx.symhash, symbol )
    end if

	'' assume it's an unknown identifier
	id 	  = FB.TK.ID
	class = FB.TKCLASS.IDENTIFIER

	if( s <> NULL ) then
		'' if it's a keyword, return id and class
		if( s->class = FB.SYMBCLASS.KEYWORD ) then
			id 	  = s->key.id
			class = s->key.class
		end if
	end if

	symbLookup = s

end function

'':::::
function symbGetUDTElmOffset( elm as FBSYMBOL ptr, _
							  typ as integer, _
							  subtype as FBSYMBOL ptr, _
							  byval fields as string ) as integer
	dim e as FBSYMBOL ptr, ename as string
	dim p as integer, ofs as integer, o as integer
	dim flen as integer

	symbGetUDTElmOffset = -1

    flen = len( fields )

    '' find next dot
    p = instr( 1, fields, "." )
    if( p > 0 ) then
    	ename = left$( fields, p-1 )
    else
    	p = flen + 1
    	ename = fields
    end if

    '' to upper
    hUcase ename

	''
	elm = NULL
	ofs = INVALID

    '' no subtupe? can't be an UDT
    if( subtype = NULL ) then
    	exit function
    end if

	'' for each field
	e = subtype->udt.head
	do while( e <> NULL )

        '' names match?
        if( e->alias = ename ) then

        	elm 		= e
        	ofs 		= e->var.elm.ofs
        	typ 		= e->typ
        	subtype 	= e->subtype

        	'' another UDT? recurse..
        	if( typ = FB.SYMBTYPE.USERDEF ) then

    			if( p >= flen ) then
    				exit do
    			end if

    			o = symbGetUDTElmOffset( elm, typ, subtype, mid$( fields, p+1 ) )
    			if( o < 0 ) then
    				exit function
    			end if
    			ofs = ofs + o

    		else
    			if( p < flen ) then
    				exit function
    			end if
    		end if

        	exit do
        end if

		'' next
		e = e->var.elm.r
    loop

    symbGetUDTElmOffset = ofs

end function

'':::::
function symbLookupUDTVar( byval symbol as string, _
						   byval dotpos as integer, _
						   typ as integer, _
						   ofs as integer, _
					       elm as FBSYMBOL ptr, _
					       subtype as FBSYMBOL ptr ) as FBSYMBOL ptr static
    dim s as FBSYMBOL ptr
    dim sname as string, fields as string

    symbLookupUDTVar = NULL

    '' symbol contains no dots?
    if( dotpos < 1 ) then
    	exit function
    end if

	'' check if it's an UDT field
    sname = left$( symbol, dotpos-1 )
    s = symbFindByNameAndClass( sname, FB.SYMBCLASS.VAR )
	if( s = NULL ) then
		exit function
	end if

	if( s->typ <> FB.SYMBTYPE.USERDEF ) then
		exit function
	end if

	''
	fields = mid$( symbol, dotpos+1 )

    ''
    elm	    = NULL
    subtype	= s->subtype
    typ 	= s->typ

	'' find the offset
	ofs = symbGetUDTElmOffset( elm, typ, subtype, fields )
	if( ofs < 0 ) then
		hReportError FB.ERRMSG.ELEMENTNOTDEFINED
    	exit function
	end if

	'' update the access counter
	s->acccnt += 1

	symbLookupUDTVar = s

end function

'':::::
function symbLookupProcResult( byval f as FBSYMBOL ptr ) as FBSYMBOL ptr static
	dim rname as string

	rname = "_fbpr_" + f->alias

	symbLookupProcResult = symbFindByNameAndClass( rname, FB.SYMBCLASS.VAR, TRUE )

end function

'':::::
function symbFindByClass( byval s as FBSYMBOL ptr, _
						  byval class as integer ) as FBSYMBOL ptr static

    '' lookup a symbol with the same class
    do while( s <> NULL )
    	if( s->class = class ) then
			exit do
		end if
    	s = s->right
    loop

	'' check if symbol isn't a non-shared module level one
	if( class = FB.SYMBCLASS.VAR ) then
		if( env.scope > 0 ) then
			if( s <> NULL ) then
				if( s->scope = 0 ) then
					if( (s->alloctype and FB.ALLOCTYPE.SHARED) = 0 ) then
						s = NULL
					end if
				end if
			end if
		end if
	end if

	'' update the access counter
	if( s <> NULL ) then
		s->acccnt += 1
	end if

	symbFindByClass = s

end function

'':::::
function symbFindBySuffix( byval s as FBSYMBOL ptr, _
						   byval suffix as integer, _
						   byval deftyp as integer ) as FBSYMBOL ptr static

    '' symbol has a suffix? lookup a symbol with the same type, suffixed or not
    if( suffix <> INVALID ) then
    	do while( s <> NULL )
    		if( s->class = FB.SYMBCLASS.VAR ) then
     			if( s->typ = suffix ) then
     				exit do
     			end if
     		end if
    		s = s->right
    	loop

    '' symbol has no suffix, lookup a symbol w/o suffix or with the same type as deftyp
    else
    	do while( s <> NULL )
    		if( s->class = FB.SYMBCLASS.VAR ) then
     			if( s->var.suffix = INVALID ) then
     				exit do
     			elseif( s->typ = deftyp ) then
     				exit do
     			end if
     		end if
    		s = s->right
    	loop
    end if

	'' check if symbol isn't a non-shared module level one
	if( env.scope > 0 ) then
		if( s <> NULL ) then
			if( s->scope = 0 ) then
				if( (s->alloctype and FB.ALLOCTYPE.SHARED) = 0 ) then
					s = NULL
				end if
			end if
		end if
	end if

    '' update the access counter
	if( s <> NULL ) then
		s->acccnt += 1
	end if

	symbFindBySuffix = s

end function

'':::::
function symbFindByNameAndClass( byval symbol as string, _
								 byval class as integer, _
								 byval preservecase as integer = FALSE ) as FBSYMBOL ptr static
	dim s as FBSYMBOL ptr
	dim tkid as integer, tkclass as integer

    s = symbLookup( symbol, tkid, tkclass, preservecase )

    '' any found?
    if( s <> NULL ) then
    	'' check if classes match
    	symbFindByNameAndClass = symbFindByClass( s, class )
    else
    	symbFindByNameAndClass = NULL
    end if

end function

'':::::
function symbFindByNameAndSuffix( byval symbol as string, _
								  byval suffix as integer, _
								  byval preservecase as integer = FALSE ) as FBSYMBOL ptr static
	dim s as FBSYMBOL ptr
	dim deftyp as integer
	dim tkid as integer, tkclass as integer

	s = symbLookup( symbol, tkid, tkclass, preservecase )

    '' any found?
    if( s <> NULL ) then
    	'' get default type if no suffix was given
    	if( suffix = INVALID ) then
    		deftyp = hGetDefType( symbol )
    	end if

		'' check if types match
		symbFindByNameAndSuffix = symbFindBySuffix( s, suffix, deftyp )
	else
		symbFindByNameAndSuffix = NULL
	end if

end function


''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' helpers
''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function symbCalcLen( byval typ as integer, _
					  byval subtype as FBSYMBOL ptr, _
					  byval realsize as integer = FALSE ) as integer static
    dim lgt as integer
    dim e as FBSYMBOL ptr

	lgt = 0

	select case as const typ
	case FB.SYMBTYPE.FWDREF
		lgt = 0

	case FB.SYMBTYPE.BYTE, FB.SYMBTYPE.UBYTE, FB.SYMBTYPE.CHAR
		lgt = 1

	case FB.SYMBTYPE.SHORT, FB.SYMBTYPE.USHORT
		lgt = 2

	case FB.SYMBTYPE.INTEGER, FB.SYMBTYPE.LONG, FB.SYMBTYPE.UINT
		lgt = FB.INTEGERSIZE

	case FB.SYMBTYPE.LONGINT, FB.SYMBTYPE.ULONGINT
		lgt = FB.INTEGERSIZE*2

	case FB.SYMBTYPE.SINGLE
		lgt = 4

	case FB.SYMBTYPE.DOUBLE
    	lgt = 8

	case FB.SYMBTYPE.FIXSTR
		lgt = 0									'' 0-len literal-strings

	case FB.SYMBTYPE.STRING
		lgt = FB.STRSTRUCTSIZE

	case FB.SYMBTYPE.USERDEF
		if( not realsize ) then
			lgt = subtype->lgt

		else
			if( not subtype->udt.isunion ) then
				e = subtype->udt.tail
				lgt = e->var.elm.ofs + (e->lgt * e->var.array.elms)

			'' union, use the largest field len
			else
				lgt = subtype->udt.lfldlen
			end if
		end if

	case else
		if( typ >= FB.SYMBTYPE.POINTER ) then
			lgt = FB.POINTERSIZE
		end if
	end select

	symbCalcLen = lgt

end function

'':::::
function symbCalcArgLen( byval typ as integer, _
						 byval subtype as FBSYMBOL ptr, _
						 byval mode as integer ) as integer static
    dim lgt as integer

	select case mode
	case FB.ARGMODE.BYREF, FB.ARGMODE.BYDESC
		lgt = FB.POINTERSIZE
	case else
		if( typ = FB.SYMBTYPE.STRING ) then
			lgt = FB.POINTERSIZE
		else
			lgt = symbCalcLen( typ, subtype )
		end if
	end select

	symbCalcArgLen = lgt

end function

'':::::
function hCalcDiff( byval dimensions as integer, _
					dTB() as FBARRAYDIM, _
					byval lgt as integer ) as integer
    dim d as integer, diff as integer, elms as integer, mult as integer

	if( dimensions <= 0 ) then
		hCalcDiff = 0
		exit function
	end if

	diff = 0
	for d = 0 to (dimensions-1)-1
		elms = (dTB(d+1).upper - dTB(d+1).lower) + 1
		diff = (diff+dTB(d).lower) * elms
	next d

	diff = diff + dTB(dimensions-1).lower

	diff = diff * lgt

	hCalcDiff = -diff

end function

'':::::
function hCalcElements( byval s as FBSYMBOL ptr, _
						byval n as FBVARDIM ptr = NULL ) as integer static
    dim e as integer, d as integer

	if( n = NULL ) then
		n = s->var.array.dimhead
	end if

	e = 1
	do while( n <> NULL )
		d = (n->upper - n->lower) + 1
		e = e * d
		n = n->r
	loop

	hCalcElements = e

end function

'':::::
function hCalcElements2( byval dimensions as integer, _
						 dTB() as FBARRAYDIM ) as integer static
    dim e as integer, i as integer, d as integer

	e = 1
	for i = 0 to dimensions-1
		d = (dTB(i).upper - dTB(i).lower) + 1
		e = e * d
	next i

	hCalcElements2 = e

end function

''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' getters and setters
''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function symbGetUDTLen( byval udt as FBSYMBOL ptr, _
						byval realsize as integer = TRUE ) as integer static
    dim e as FBSYMBOL ptr

	if( not realsize ) then
		symbGetUDTLen = udt->lgt

	else
		if( not udt->udt.isunion ) then
			e = udt->udt.tail
			symbGetUDTLen = e->var.elm.ofs + (e->lgt * e->var.array.elms)

		'' union, use the largest field len
		else
			e = udt->udt.lfldlen
		end if
	end if

end function

'':::::
function symbGetFirstNode as FBSYMBOL ptr static

	symbGetFirstNode = ctx.symlist.head

end function

'':::::
function symbGetNextNode( byval n as FBSYMBOL ptr ) as FBSYMBOL ptr static

	if( n <> NULL ) then
		symbGetNextNode = n->nxt
	else
		symbGetNextNode = NULL
	end if

end function

'':::::
function symbGetProcLib( byval p as FBSYMBOL ptr ) as string static
    dim l as FBLIBRARY ptr

	l = p->proc.lib
	if( l <> NULL ) then
		symbGetProcLib = l->name
	else
	    symbGetProcLib = ""
	end if

end function


'':::::
function symbGetVarDscName( byval s as FBSYMBOL ptr ) as string static
	dim d as FBSYMBOL ptr

	d = s->var.array.desc
	if( d <> NULL ) then
		symbGetVarDscName = d->alias
	else
		symbGetVarDscName = ""
	end if

end function

'':::::
function symbGetVarText( byval s as FBSYMBOL ptr ) as string static

	if( s->var.initialized ) then
		symbGetVarText = s->var.inittext
	else
		symbGetVarText = ""
	end if

end function

'':::::
function symbGetProcPrevArg( byval f as FBSYMBOL ptr, _
							 byval a as FBSYMBOL ptr, _
							 byval checkconv as integer = TRUE ) as FBSYMBOL ptr static

	if( a = NULL ) then
		symbGetProcPrevArg = NULL
		exit function
	end if

	if( checkconv ) then
		if( f->proc.mode = FB.FUNCMODE.PASCAL ) then
			symbGetProcPrevArg = a->arg.l
		else
			symbGetProcPrevArg = a->arg.r
		end if
	else
		symbGetProcPrevArg = a->arg.l
	end if

end function

'':::::
function symbGetProcNextArg( byval f as FBSYMBOL ptr, _
							 byval a as FBSYMBOL ptr, _
							 byval checkconv as integer = TRUE ) as FBSYMBOL ptr static

	if( a = NULL ) then
		symbGetProcNextArg = NULL
		exit function
	end if

	if( checkconv ) then
		if( f->proc.mode = FB.FUNCMODE.PASCAL ) then
			symbGetProcNextArg = a->arg.r
		else
			symbGetProcNextArg = a->arg.l
		end if
	else
		symbGetProcNextArg = a->arg.r
	end if

end function

''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' del
''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
sub hFreeSymbol( byval s as FBSYMBOL ptr, _
				 byval freeup as integer = TRUE )
    dim prv as FBSYMBOL ptr, nxt as FBSYMBOL ptr

    '' del from string pool
    if( freeup ) then
    	s->alias = ""
    end if

	if( s->hashitem <> NULL ) then
    	'' relink
    	prv = s->left
    	nxt = s->right
    	if( prv <> NULL ) then
    		prv->right = nxt
    	end if
    	if( nxt <> NULL ) then
    		nxt->left = prv
    	end if

    	'' nothing left? remove from hash table
    	if( (prv = NULL) and (nxt = NULL) ) then
    		hashDel( @ctx.symhash, s->hashitem, s->hashindex )
    	else
    		'' update list head
    		if( prv = NULL ) then
        		s->hashitem->idx = nxt
    		end if
    	end if
    end if

    '' remove from symbol list
    if( freeup ) then
    	listDelNode @ctx.symlist, s
    else
    	s->hashitem  = NULL
    	s->hashindex = 0
    end if

end sub

'':::::
function symbDelKeyword( byval s as FBSYMBOL ptr ) as integer

    symbDelKeyword = FALSE

	'' exists?
	s = symbFindByClass( s, FB.SYMBCLASS.KEYWORD )
	if( s = NULL ) then
		exit function
	end if

	hFreeSymbol s

	symbDelKeyword = TRUE

end function

'':::::
private sub hDelDefineArgs( byval s as FBSYMBOL ptr )
	dim a as FBDEFARG ptr, n as FBDEFARG ptr

    a = s->def.arghead
    do while( a <> NULL )
    	n = a->r
    	a->name = ""
    	listDelNode( @ctx.defarglist, a )
    	a = n
    loop

end sub

'':::::
function symbDelDefine( byval s as FBSYMBOL ptr ) as integer static
    dim arg as FBDEFARG ptr, narg as FBDEFARG ptr

    symbDelDefine = FALSE

	'' exists?
	s = symbFindByClass( s, FB.SYMBCLASS.DEFINE )
    if( s = NULL ) then
    	exit function
    end if

	''
	s->def.text = ""

	hDelDefineArgs s

    ''
    hFreeSymbol s

	''
	symbDelDefine = TRUE

end function

'':::::
sub symbDelLabel( byval s as FBSYMBOL ptr ) static

    s = symbFindByClass( s, FB.SYMBCLASS.LABEL )
    if( s = NULL ) then
    	exit sub
    end if

    hFreeSymbol s

end sub

'':::::
sub symbDelConst( byval s as FBSYMBOL ptr )

    s = symbFindByClass( s, FB.SYMBCLASS.CONST )
    if( s = NULL ) then
    	exit sub
    end if

    ''
    s->con.text = ""

	hFreeSymbol s

end sub

'':::::
sub symbDelUDT( byval s as FBSYMBOL ptr )

    s = symbFindByClass( s, FB.SYMBCLASS.UDT )
    if( s = NULL ) then
    	exit sub
    end if

    ''
    ''!!!FIXME!!! del all udt elements

	hFreeSymbol s

end sub

'':::::
sub symbDelEnum( byval s as FBSYMBOL ptr )

    s = symbFindByClass( s, FB.SYMBCLASS.ENUM )
    if( s = NULL ) then
    	exit sub
    end if

    ''
    ''!!!FIXME!!! del all enum constants

	hFreeSymbol s

end sub

'':::::
private sub hDelArgs( byval f as FBSYMBOL ptr )
	dim a as FBSYMBOL ptr, n as FBSYMBOL ptr

    a = f->proc.arghead
    do while( a <> NULL )
    	n = a->arg.r
    	hFreeSymbol( a )
    	a = n
    loop

end sub

'':::::
sub symbDelPrototype( byval s as FBSYMBOL ptr )

    s = symbFindByClass( s, FB.SYMBCLASS.PROC )
    if( s = NULL ) then
    	exit sub
    end if

	if( s->proc.args > 0 ) then
		hDelArgs s
	end if

    hFreeSymbol s

end sub

'':::::
sub hDelVarDims( byval s as FBSYMBOL ptr ) static
    dim n as FBVARDIM ptr, nxt as FBVARDIM ptr

    n = s->var.array.dimhead
    do while( n <> NULL )
    	nxt = n->r

    	listDelNode @ctx.dimlist, n

    	n = nxt
    loop

    s->var.array.dimhead = NULL
    s->var.array.dimtail = NULL
    s->var.array.dims	  = 0

end sub

'':::::
sub symbDelVar( byval s as FBSYMBOL ptr )
    dim freeup as integer

    if( s = NULL ) then
    	exit sub
    end if

	freeup = TRUE

	'' local?
	if( s->scope > 0 ) then
    	'' static? don't remove node or EMIT won't output it
    	if( (s->alloctype and FB.ALLOCTYPE.STATIC) > 0 ) then
    		freeup = FALSE
    	end if
	end if

	if( freeup ) then
    	if( s->var.array.dims > 0 ) then
    		hDelVarDims s
    		'' del the array descriptor, recursively
    		symbDelVar s->var.array.desc
    	end if
    end if

    if( s->var.initialized ) then
    	s->var.initialized = FALSE
    	s->var.inittext = ""
    end if

    hFreeSymbol s, freeup

end sub

'':::::
sub symbDelLib( byval l as FBLIBRARY ptr ) static

	if( l = NULL ) then
		exit sub
	end if

	hashDel( @ctx.libhash, l->hashitem, l->hashindex )

	l->name = ""

    listDelNode( @ctx.liblist, l )

end sub


'':::::
sub symbDelLocalSymbols static
    dim node as FBLOCSYMBOL ptr, nxt as FBLOCSYMBOL ptr
    dim s as FBSYMBOL ptr

	node = ctx.loclist.head
    do while( node <> NULL )
    	nxt = node->nxt

    	s = node->s
    	if( (s->alloctype and FB.ALLOCTYPE.SHARED) = 0 ) then

    		select case as const s->class
    		case FB.SYMBCLASS.VAR
    			symbDelVar s
    		case FB.SYMBCLASS.CONST
    			symbDelConst s
    		case FB.SYMBCLASS.UDT
    			symbDelUDT s
    		case FB.SYMBCLASS.ENUM
    			symbDelEnum s
    		case FB.SYMBCLASS.LABEL
    			symbDelLabel s
    		end select

    	end if

		listDelNode @ctx.loclist, node

		node = nxt
    loop

end sub

'':::::
sub symbFreeLocalDynSymbols( byval proc as FBSYMBOL ptr, _
							 byval issub as integer ) static
    dim node as FBLOCSYMBOL ptr, nxt as FBLOCSYMBOL ptr
    dim s as FBSYMBOL ptr
    dim strg as integer
    dim fres as FBSYMBOL ptr

    '' can't free function's result, that's will be done by the rtlib
    if( issub ) then
    	fres = NULL
    else
    	fres = symbLookupProcResult( proc )
	end if

	node = ctx.loclist.head
    do while( node <> NULL )
    	nxt = node->nxt

    	s = node->s
    	if( s->class = FB.SYMBCLASS.VAR ) then
    		if( (s->alloctype and (FB.ALLOCTYPE.SHARED or FB.ALLOCTYPE.STATIC)) = 0 ) then

				'' not an argument?
    			if( (s->alloctype and (FB.ALLOCTYPE.ARGUMENTBYDESC or _
    				  				   FB.ALLOCTYPE.ARGUMENTBYVAL or _
    				  				   FB.ALLOCTYPE.ARGUMENTBYREF or _
    				  				   FB.ALLOCTYPE.TEMP)) = 0 ) then

					if( s->var.array.dims > 0 ) then
						if( (s->alloctype and FB.ALLOCTYPE.DYNAMIC) > 0 ) then
							rtlArrayErase astNewVAR( s, NULL, 0, s->typ )
						elseif( s->typ = FB.SYMBTYPE.STRING ) then
							rtlArrayStrErase s
						end if

					elseif( s->typ = FB.SYMBTYPE.STRING ) then
						'' not funct's result?
						if( s <> fres ) then
							strg = astNewVAR( s, NULL, 0, IR.DATATYPE.STRING )
							astFlush( rtlStrDelete( strg ) )
						end if
					end if

				end if

    		end if
    	end if

    	node = nxt
    loop

end sub

''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' misc
''::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function symbGetLastLabel as FBSYMBOL ptr static

	symbGetLastLabel = ctx.lastlbl

end function

'':::::
sub symbSetLastLabel( byval l as FBSYMBOL ptr ) static

	ctx.lastlbl = l

end sub

'':::::
function symbCheckLabels as FBSYMBOL ptr
    dim s as FBSYMBOL ptr

    s = symbGetFirstNode
    do while( s <> NULL )

    	if( s->scope = env.scope ) then
    		if( s->class = FB.SYMBCLASS.LABEL ) then
    			if( not s->lbl.declared ) then
    				symbCheckLabels = s
    				exit function
    			end if
    		end if
    	end if

    	s = symbGetNextNode( s )
    loop

	symbCheckLabels = NULL

end function

'':::::
function hFindLib( libname as string, _
				   namelist() as string ) as integer
    dim i as integer

	hFindLib = INVALID

	for i = 0 to ubound( namelist ) - 1

		if( len( namelist(i) ) = 0 ) then
			exit function
		end if

		if( namelist(i) = libname ) then
			hFindLib = i
			exit function
		end if
	next i

end function

'':::::
function symbListLibs( namelist() as string, _
					   byval index as integer ) as integer static
    dim cnt as integer, node as FBLIBRARY ptr

	cnt = index
	node = ctx.liblist.head
	do while( node <> NULL )

		if( hFindLib( node->name, namelist() ) = INVALID ) then
			namelist(cnt) = node->name
			cnt = cnt + 1
		end if

		node = node->nxt
	loop

	symbListLibs = cnt - index

end function

