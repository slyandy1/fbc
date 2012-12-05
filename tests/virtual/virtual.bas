# include "fbcu.bi"

namespace fbc_tests.virt.virt

namespace declarations
	type A extends object
		declare				function f01( ) as integer
		declare		virtual		function f02( ) as integer
		declare		virtual		function f03( ) as integer
		declare	const	virtual		function f04( ) as integer
		declare	const	virtual		function f05( ) as integer
		declare	const	virtual		function f06( ) as integer
		declare	const	virtual		function f07( ) as integer
		declare		abstract	function f08( ) as integer
		declare		abstract	function f09( ) as integer
		declare	const	abstract	function f10( ) as integer
		declare	const	abstract	function f11( ) as integer
		declare	const	abstract	function f12( ) as integer
		declare	const	abstract	function f13( ) as integer

		declare				sub s01( )
		declare		virtual		sub s02( )
		declare		virtual		sub s03( )
		declare	const	virtual		sub s04( )
		declare	const	virtual		sub s05( )
		declare	const	virtual		sub s06( )
		declare	const	virtual		sub s07( )
		declare		abstract	sub s08( )
		declare		abstract	sub s09( )
		declare	const	abstract	sub s10( )
		declare	const	abstract	sub s11( )
		declare	const	abstract	sub s12( )
		declare	const	abstract	sub s13( )

		declare		virtual		function fOverrideMe1( ) as integer
		declare		abstract	function fOverrideMe2( ) as integer
		declare		virtual		sub sOverrideMe1( )
		declare		abstract	sub sOverrideMe2( )
	end type

				function A.f01( ) as integer : function = 1 : end function
				function A.f02( ) as integer : function = 2 : end function
		virtual		function A.f03( ) as integer : function = 3 : end function
				function A.f04( ) as integer : function = 4 : end function
	const			function A.f05( ) as integer : function = 5 : end function
		virtual		function A.f06( ) as integer : function = 6 : end function
	const	virtual		function A.f07( ) as integer : function = 7 : end function

				sub A.s01( ) : end sub
				sub A.s02( ) : end sub
		virtual		sub A.s03( ) : end sub
				sub A.s04( ) : end sub
	const			sub A.s05( ) : end sub
		virtual		sub A.s06( ) : end sub
	const	virtual		sub A.s07( ) : end sub

	function A.fOverrideMe1( ) as integer : function = 1 : end function
	sub A.sOverrideMe1( ) : end sub

	type B extends A
		declare function fOverrideMe1( ) as integer override
		declare function fOverrideMe2( ) as integer override
		declare sub sOverrideMe1( ) override
		declare sub sOverrideMe2( ) override
	end type

	function B.fOverrideMe1( ) as integer : function = 1 : end function
	function B.fOverrideMe2( ) as integer : function = 2 : end function
	sub B.sOverrideMe1( ) : end sub
	sub B.sOverrideMe2( ) : end sub
end namespace

namespace overridingWorks
	type A extends object
		i as integer
		declare constructor( byval j as integer )
		declare virtual sub add( byval j as integer )
		declare virtual sub subtract( byval j as integer )
		declare virtual function toString( ) as string
	end type

	constructor A( byval j as integer )
		this.i = j
	end constructor

	sub A.add( byval j as integer )
	end sub

	sub A.subtract( byval j as integer )
		this.i -= j
	end sub

	function A.toString( ) as string
		function = str( this.i )
	end function

	type B extends A
		declare constructor( )
		declare constructor( byref as B )
		declare constructor( byval j as integer )
		declare sub add( byval j as integer )
		declare function toString( ) as string
	end type

	constructor B( byval j as integer )
		base( j )
	end constructor

	sub B.add( byval j as integer )
		this.i += j
	end sub

	function B.toString( ) as string
		function = "&h" + hex( this.i, 8 )
	end function

	sub testAToByrefA( byref ra as A )
		CU_ASSERT( ra.i = 10 ) : CU_ASSERT( ra.toString( ) = "10" )
		ra.subtract( 4 )
		CU_ASSERT( ra.i =  6 ) : CU_ASSERT( ra.toString( ) = "6" )
	end sub

	sub testBToByrefA( byref ra as A )
		CU_ASSERT( ra.i = 16 ) : CU_ASSERT( ra.toString( ) = "&h00000010" )
		ra.subtract( 10 )
		CU_ASSERT( ra.i =  6 ) : CU_ASSERT( ra.toString( ) = "&h00000006" )
		ra.add( 4 )
		CU_ASSERT( ra.i = 10 ) : CU_ASSERT( ra.toString( ) = "&h0000000A" )
	end sub

	sub testBToByrefB( byref rb as B )
		CU_ASSERT( rb.i = 10 ) : CU_ASSERT( rb.toString( ) = "&h0000000A" )
		rb.subtract( 10 )
		CU_ASSERT( rb.i =  0 ) : CU_ASSERT( rb.toString( ) = "&h00000000" )
		rb.add( 4 )
		CU_ASSERT( rb.i =  4 ) : CU_ASSERT( rb.toString( ) = "&h00000004" )
	end sub

	sub test cdecl( )
		dim xa as A = A( 10 )
		CU_ASSERT( xa.i = 10 ) : CU_ASSERT( xa.toString( ) = "10" )
		xa.subtract( 4 )
		CU_ASSERT( xa.i =  6 ) : CU_ASSERT( xa.toString( ) = "6" )

		dim xb as B = B( 10 )
		CU_ASSERT( xb.i = 10 ) : CU_ASSERT( xb.toString( ) = "&h0000000A" )
		xb.subtract( 4 )
		CU_ASSERT( xb.i =  6 ) : CU_ASSERT( xb.toString( ) = "&h00000006" )
		xb.add( 5 )
		CU_ASSERT( xb.i = 11 ) : CU_ASSERT( xb.toString( ) = "&h0000000B" )

		dim pa as A ptr = @xa
		CU_ASSERT( pa->i =  6 ) : CU_ASSERT( pa->toString( ) = "6" )
		pa->subtract( -4 )
		CU_ASSERT( pa->i = 10 ) : CU_ASSERT( pa->toString( ) = "10" )

		pa = @xb
		CU_ASSERT( pa->i = 11 ) : CU_ASSERT( pa->toString( ) = "&h0000000B" )
		pa->subtract( 1 )
		CU_ASSERT( pa->i = 10 ) : CU_ASSERT( pa->toString( ) = "&h0000000A" )
		pa->add( 6 )
		CU_ASSERT( pa->i = 16 ) : CU_ASSERT( pa->toString( ) = "&h00000010" )

		testAToByrefA( xa )
		testBToByrefA( xb )
		testBToByrefB( xb )
	end sub
end namespace

namespace overridingVsShadowing
	type A extends object
		declare virtual function f1( ) as integer  '' overridable
		declare         function f2( ) as integer  '' shadowable
	end type

	function A.f1( ) as integer
		function = &hA1
	end function

	function A.f2( ) as integer
		function = &hA2
	end function

	type B extends A
		declare function f1( ) as integer  '' overrides
		declare function f2( ) as integer  '' shadows
	end type

	function B.f1( ) as integer
		function = &hB1
	end function

	function B.f2( ) as integer
		function = &hB2
	end function

	sub testAToByrefA( byref ra as A )
		CU_ASSERT( ra.f1( ) = &hA1 )  '' vtable lookup, not overridden
		CU_ASSERT( ra.f2( ) = &hA2 )
	end sub

	sub testBToByrefA( byref ra as A )
		CU_ASSERT( ra.f1( ) = &hB1 )  '' vtable lookup, overridden
		CU_ASSERT( ra.f2( ) = &hA2 )
	end sub

	sub testBToByrefB( byref rb as B )
		CU_ASSERT( rb.f1( ) = &hB1 )
		CU_ASSERT( rb.f2( ) = &hB2 )
	end sub

	sub test cdecl( )
		dim xa as A
		CU_ASSERT( xa.f1( ) = &hA1 )
		CU_ASSERT( xa.f2( ) = &hA2 )

		dim xb as B
		CU_ASSERT( xb.f1( ) = &hB1 )
		CU_ASSERT( xb.f2( ) = &hB2 )

		dim pa as A ptr

		'' A ptr pointing to A object
		pa = @xa
		CU_ASSERT( pa->f1( ) = &hA1 )  '' vtable lookup, not overridden
		CU_ASSERT( pa->f2( ) = &hA2 )

		'' A ptr pointing to B object (which is a specialized A object)
		pa = @xb
		CU_ASSERT( pa->f1( ) = &hB1 )  '' vtable lookup, overridden
		CU_ASSERT( pa->f2( ) = &hA2 )

		testAToByrefA( xa )
		testBToByrefA( xb )
		testBToByrefB( xb )
	end sub
end namespace

namespace overridingOverloadedMethods
	type A extends object
		declare virtual function f(            ) as integer
		declare virtual function f( as integer ) as integer
		declare virtual function f( as longint ) as integer
	end type

	type B extends A
		declare function f( as integer ) as integer
		declare function f( as longint ) as integer
		declare function f(            ) as integer
	end type

	function A.f(              ) as integer
		function = &hA1
	end function

	function A.f( i as integer ) as integer
		function = &hA2
	end function

	function A.f( i as longint ) as integer
		function = &hA3
	end function

	function B.f(              ) as integer
		function = &hB1
	end function

	function B.f( i as integer ) as integer
		function = &hB2
	end function

	function B.f( i as longint ) as integer
		function = &hB3
	end function

	sub test cdecl( )
		dim pa as A ptr

		pa = new A
		CU_ASSERT( pa->f(              ) = &hA1 )
		CU_ASSERT( pa->f(          1   ) = &hA2 )
		CU_ASSERT( pa->f( clngint( 1 ) ) = &hA3 )

		pa = new B
		CU_ASSERT( pa->f(              ) = &hB1 )
		CU_ASSERT( pa->f(          1   ) = &hB2 )
		CU_ASSERT( pa->f( clngint( 1 ) ) = &hB3 )
	end sub
end namespace

namespace overridingProperties
	dim shared as integer Agets, Asets, Bgets, Bsets

	type A extends object
		declare virtual property f(            ) as integer
		declare virtual property f( as integer )
	end type

	type B extends A
		declare property f(            ) as integer
		declare property f( as integer )
	end type

	property A.f(              ) as integer
		Agets += 1
		property = &hA
	end property

	property A.f( i as integer )
		Asets += 1
	end property

	property B.f(              ) as integer
		Bgets += 1
		property = &hB
	end property

	property B.f( i as integer )
		Bsets += 1
	end property

	sub test cdecl( )
		dim pa as A ptr

		Agets = 0
		Asets = 0
		Bgets = 0
		Bsets = 0
		pa = new A
		CU_ASSERT( pa->f = &hA )
		pa->f = 123
		CU_ASSERT( Agets = 1 )
		CU_ASSERT( Asets = 1 )
		CU_ASSERT( Bgets = 0 )
		CU_ASSERT( Bsets = 0 )

		Agets = 0
		Asets = 0
		Bgets = 0
		Bsets = 0
		pa = new B
		CU_ASSERT( pa->f = &hB )
		pa->f = 123
		CU_ASSERT( Agets = 0 )
		CU_ASSERT( Asets = 0 )
		CU_ASSERT( Bgets = 1 )
		CU_ASSERT( Bsets = 1 )
	end sub
end namespace

namespace differentSignatureIsntOverridden
	type A extends object
		declare virtual function f1( ) as integer
	end type

	function A.f1( ) as integer
		function = &hA1
	end function

	type B extends A
		'' different signature, should not override
		declare function f1( byval i as integer ) as integer
	end type

	function B.f1( byval i as integer ) as integer
		function = &hB1
	end function

	sub test cdecl( )
		dim pa as A ptr
		dim xb as B
		pa = @xb
		CU_ASSERT( pa->f1( ) = &hA1 )  '' vtable lookup, not overridden
		CU_ASSERT( xb.f1( 123 ) = &hB1 )
	end sub
end namespace

namespace virtualDtor
	dim shared as integer callsA, callsB

	type A extends object
		declare virtual destructor( )
	end type

	destructor A( )
		callsA += 1
	end destructor

	type B extends A
		declare destructor( )
	end type

	destructor B( )
		callsB += 1
	end destructor

	sub test cdecl( )
		callsA = 0 : callsB = 0
		scope
			dim x as A
		end scope
		CU_ASSERT( callsA = 1 ) : CU_ASSERT( callsB = 0 )

		callsA = 0 : callsB = 0
		scope
			dim x as B
		end scope
		CU_ASSERT( callsA = 1 ) : CU_ASSERT( callsB = 1 )

		callsA = 0 : callsB = 0
		scope
			dim p as A ptr = new A
			delete p
		end scope
		CU_ASSERT( callsA = 1 ) : CU_ASSERT( callsB = 0 )

		callsA = 0 : callsB = 0
		scope
			dim p as B ptr = new B
			delete p
		end scope
		CU_ASSERT( callsA = 1 ) : CU_ASSERT( callsB = 1 )

		callsA = 0 : callsB = 0
		scope
			dim p as A ptr = new B
			delete p
		end scope
		CU_ASSERT( callsA = 1 ) : CU_ASSERT( callsB = 1 )
	end sub
end namespace

namespace virtualDtorDestructsField
	dim shared as integer callsA, callsFA, callsB

	type FA
		dummy as integer
		declare destructor( )
	end type

	destructor FA( )
		callsFA += 1
	end destructor

	type A extends object
		f as FA
		declare virtual destructor( )
	end type

	destructor A( )
		callsA += 1
	end destructor

	type B extends A
		declare destructor( )
	end type

	destructor B( )
		callsB += 1
	end destructor

	sub test cdecl( )
		#macro check( stmt, expectedA, expectedFA, expectedB )
			callsA = 0
			callsFA = 0
			callsB = 0
			scope
				stmt
			end scope
			CU_ASSERT( callsA = expectedA )
			CU_ASSERT( callsFA = expectedFA )
			CU_ASSERT( callsB = expectedB )
		#endmacro

		check( dim x as A, 1, 1, 0 )
		check( dim x as B, 1, 1, 1 )
		check( dim p as A ptr = new A : delete p, 1, 1, 0 )
		check( dim p as B ptr = new B : delete p, 1, 1, 1 )

		'' A.dtor is virtual, so B.dtor will be called,
		'' and that in turn calls A.dtor
		check( dim p as A ptr = new B : delete p, 1, 1, 1 )
	end sub
end namespace

namespace virtualDtorDestructsBase
	dim shared as integer callsA, callsB, callsC

	type A extends object
		declare destructor( )
	end type

	destructor A( )
		callsA += 1
	end destructor

	type B extends A
		declare virtual destructor( )
	end type

	destructor B( )
		callsB += 1
	end destructor

	type C extends B
		declare destructor( )
	end type

	destructor C( )
		callsC += 1
	end destructor

	sub test cdecl( )
		#macro check( stmt, expectedA, expectedB, expectedC )
			callsA = 0
			callsB = 0
			callsC = 0
			scope
				stmt
			end scope
			CU_ASSERT( callsA = expectedA )
			CU_ASSERT( callsB = expectedB )
			CU_ASSERT( callsC = expectedC )
		#endmacro

		check( dim x as A, 1, 0, 0 )
		check( dim x as B, 1, 1, 0 )
		check( dim x as C, 1, 1, 1 )
		check( dim p as A ptr = new A : delete p, 1, 0, 0 )
		check( dim p as B ptr = new B : delete p, 1, 1, 0 )
		check( dim p as C ptr = new C : delete p, 1, 1, 1 )

		'' B.dtor won't be called since A.dtor is not virtual
		check( dim p as A ptr = new B : delete p, 1, 0, 0 )

		'' ditto, B.dtor and C.dtor not called
		check( dim p as A ptr = new C : delete p, 1, 0, 0 )

		'' B.dtor is virtual, so C.dtor will be called instead;
		'' it in turn calls B.dtor, and that calls A.dtor
		check( dim p as B ptr = new C : delete p, 1, 1, 1 )
	end sub
end namespace

namespace implicitDtorOverrides
	dim shared as integer callsA, callsFB

	type A extends object
		declare virtual destructor( )
	end type

	destructor A( )
		callsA += 1
	end destructor

	type FB
		dummy as integer
		declare destructor( )
	end type

	destructor FB( )
		callsFB += 1
	end destructor

	type B extends A
		f as FB
		'' B has a field with a dtor, but B has no explicit dtor,
		'' so an implicit dtor will be generated.
		'' Since A's dtor is virtual, B's implicit dtor should
		'' override it.
	end type

	sub test cdecl( )
		callsA = 0
		callsFB = 0
		scope
			dim x as B
		end scope
		CU_ASSERT( callsA = 1 )
		CU_ASSERT( callsFB = 1 )

		callsA = 0
		callsFB = 0
		scope
			dim as B ptr p = new B
			delete p
		end scope
		CU_ASSERT( callsA = 1 )
		CU_ASSERT( callsFB = 1 )

		callsA = 0
		callsFB = 0
		scope
			dim as A ptr p = new B
			delete p
		end scope
		CU_ASSERT( callsA = 1 )
		CU_ASSERT( callsFB = 1 )
	end sub
end namespace

namespace vtableSlotsReused1
	'' Both ABSTRACTs and VIRTUALs, the overrides should use the same vtable
	'' slots like the overridden methods, no matter what nesting level...

	type A extends object
		declare virtual  function f1( ) as integer
		declare abstract function f2( ) as integer
		declare abstract function f3( ) as integer
	end type

	type B extends A
		declare virtual  function f1( ) as integer
		declare virtual  function f2( ) as integer
		declare abstract function f3( ) as integer
	end type

	type C extends B
		declare function f1( ) as integer
		declare function f2( ) as integer
		declare function f3( ) as integer
	end type

	function A.f1( ) as integer : function = &hA1 : end function
	function B.f1( ) as integer : function = &hB1 : end function
	function B.f2( ) as integer : function = &hB2 : end function
	function C.f1( ) as integer : function = &hC1 : end function
	function C.f2( ) as integer : function = &hC2 : end function
	function C.f3( ) as integer : function = &hC3 : end function

	sub test cdecl( )
		scope
			dim p as A ptr = new C
			CU_ASSERT( p->f1( ) = &hC1 )
			CU_ASSERT( p->f2( ) = &hC2 )
			CU_ASSERT( p->f3( ) = &hC3 )
			delete p
		end scope

		scope
			dim p as B ptr = new C
			CU_ASSERT( p->f1( ) = &hC1 )
			CU_ASSERT( p->f2( ) = &hC2 )
			CU_ASSERT( p->f3( ) = &hC3 )
			delete p
		end scope

		scope
			dim p as C ptr = new C
			CU_ASSERT( p->f1( ) = &hC1 )
			CU_ASSERT( p->f2( ) = &hC2 )
			CU_ASSERT( p->f3( ) = &hC3 )
			delete p
		end scope
	end sub
end namespace

namespace vtableSlotsReused2
	'' Same test but only with VIRTUALs

	type A extends object
		declare virtual function f1( ) as integer
		declare virtual function f2( ) as integer
		declare virtual function f3( ) as integer
	end type

	type B extends A
		declare virtual function f1( ) as integer
		declare virtual function f2( ) as integer
		declare virtual function f3( ) as integer
	end type

	type C extends B
		declare function f1( ) as integer
		declare function f2( ) as integer
		declare function f3( ) as integer
	end type

	function A.f1( ) as integer : function = &hA1 : end function
	function A.f2( ) as integer : function = &hA2 : end function
	function A.f3( ) as integer : function = &hA3 : end function
	function B.f1( ) as integer : function = &hB1 : end function
	function B.f2( ) as integer : function = &hB2 : end function
	function B.f3( ) as integer : function = &hB3 : end function
	function C.f1( ) as integer : function = &hC1 : end function
	function C.f2( ) as integer : function = &hC2 : end function
	function C.f3( ) as integer : function = &hC3 : end function

	sub test cdecl( )
		scope
			dim p as A ptr = new A
			CU_ASSERT( p->f1( ) = &hA1 )
			CU_ASSERT( p->f2( ) = &hA2 )
			CU_ASSERT( p->f3( ) = &hA3 )
			delete p
		end scope

		scope
			dim p as A ptr = new B
			CU_ASSERT( p->f1( ) = &hB1 )
			CU_ASSERT( p->f2( ) = &hB2 )
			CU_ASSERT( p->f3( ) = &hB3 )
			delete p
		end scope

		scope
			dim p as A ptr = new C
			CU_ASSERT( p->f1( ) = &hC1 )
			CU_ASSERT( p->f2( ) = &hC2 )
			CU_ASSERT( p->f3( ) = &hC3 )
			delete p
		end scope

		scope
			dim p as B ptr = new B
			CU_ASSERT( p->f1( ) = &hB1 )
			CU_ASSERT( p->f2( ) = &hB2 )
			CU_ASSERT( p->f3( ) = &hB3 )
			delete p
		end scope

		scope
			dim p as B ptr = new C
			CU_ASSERT( p->f1( ) = &hC1 )
			CU_ASSERT( p->f2( ) = &hC2 )
			CU_ASSERT( p->f3( ) = &hC3 )
			delete p
		end scope

		scope
			dim p as C ptr = new C
			CU_ASSERT( p->f1( ) = &hC1 )
			CU_ASSERT( p->f2( ) = &hC2 )
			CU_ASSERT( p->f3( ) = &hC3 )
			delete p
		end scope
	end sub
end namespace

namespace noImplicitVirtual
	type A extends object
		'' new ABSTRACT
		declare abstract function f1( ) as integer
	end type

	type B extends A
		'' overrides the ABSTRACT, but should not become ABSTRACT/VIRTUAL itself implicitly
		declare          function f1( ) as integer

		'' new VIRTUAL
		declare virtual  function f2( ) as integer
	end type

	type C extends B
		'' shadows B.f1() but shouldn't become VIRTUAL implicitly
		declare function f1( ) as integer

		'' overrides B.f2() but shouldn't become VIRTUAL implicitly
		declare function f2( ) as integer
	end type

	type D extends C
		'' shadows C.f2() but shouldn't become VIRTUAL implicitly
		declare function f2( ) as integer
	end type

	function B.f1( ) as integer : function = &hB1 : end function
	function B.f2( ) as integer : function = &hB2 : end function
	function C.f1( ) as integer : function = &hC1 : end function
	function C.f2( ) as integer : function = &hC2 : end function
	function D.f2( ) as integer : function = &hD2 : end function

	sub test cdecl( )
		scope
			dim p as A ptr = new B
			CU_ASSERT( p->f1( ) = &hB1 ) '' A.f1() is overridden by B.f1()
			delete p
		end scope

		scope
			dim p as A ptr = new C
			CU_ASSERT( p->f1( ) = &hB1 ) '' A.f1() is overridden by B.f1(), but not C.f1() since B.f1() isn't VIRTUAL
			delete p
		end scope

		scope
			dim p as A ptr = new D
			CU_ASSERT( p->f1( ) = &hB1 ) '' ditto
			delete p
		end scope

		scope
			dim p as B ptr = new B
			CU_ASSERT( p->f1( ) = &hB1 )
			CU_ASSERT( p->f2( ) = &hB2 )
			delete p
		end scope

		scope
			dim p as B ptr = new C
			CU_ASSERT( p->f1( ) = &hB1 ) '' B.f1() isn't VIRTUAL, so not overridden by C.f1()
			CU_ASSERT( p->f2( ) = &hC2 ) '' B.f2() is VIRTUAL though, and overridden by C.f2()
			delete p
		end scope

		scope
			dim p as B ptr = new D
			CU_ASSERT( p->f1( ) = &hB1 )
			CU_ASSERT( p->f2( ) = &hC2 ) '' B.f2() is overridden by C.f2(), but not D.f2() (since C.f2() isn't VIRTUAL)
			delete p
		end scope

		scope
			dim p as C ptr = new C
			CU_ASSERT( p->f1( ) = &hC1 )
			CU_ASSERT( p->f2( ) = &hC2 )
			delete p
		end scope

		scope
			dim p as C ptr = new D
			CU_ASSERT( p->f1( ) = &hC1 )
			CU_ASSERT( p->f2( ) = &hC2 ) '' C.f2() isn't VIRTUAL, so not overridden by D.f2()
			delete p
		end scope

		scope
			dim p as D ptr = new D
			CU_ASSERT( p->f1( ) = &hC1 )
			CU_ASSERT( p->f2( ) = &hD2 )
			delete p
		end scope
	end sub
end namespace

namespace virtualsAreInherited1
	'' With a class hierarchy like A>B>C, C should be able to override A's
	'' virtuals even if B does not.

	type A extends object
		declare virtual function f1( ) as integer
	end type

	type B extends A
		'' not overriding anything
	end type

	type C extends B
		declare function f1( ) as integer
	end type

	function A.f1( ) as integer : function = &hA1 : end function
	function C.f1( ) as integer : function = &hC1 : end function

	sub test cdecl( )
		scope
			dim p as A ptr = new A
			CU_ASSERT( p->f1( ) = &hA1 )
			delete p
		end scope

		scope
			dim p as A ptr = new B
			CU_ASSERT( p->f1( ) = &hA1 )
			delete p
		end scope

		scope
			dim p as A ptr = new C
			CU_ASSERT( p->f1( ) = &hC1 )
			delete p
		end scope

		scope
			dim p as B ptr = new B
			CU_ASSERT( p->f1( ) = &hA1 )
			delete p
		end scope

		scope
			dim p as B ptr = new C
			CU_ASSERT( p->f1( ) = &hC1 )
			delete p
		end scope

		scope
			dim p as C ptr = new C
			CU_ASSERT( p->f1( ) = &hC1 )
			delete p
		end scope
	end sub
end namespace

namespace virtualsAreInherited2
	'' same with an ABSTRACT

	type A extends object
		declare abstract function f1( ) as integer
	end type

	type B extends A
		'' not overriding anything
	end type

	type C extends B
		declare function f1( ) as integer
	end type

	function C.f1( ) as integer : function = &hC1 : end function

	sub test cdecl( )
		scope
			dim p as A ptr = new C
			CU_ASSERT( p->f1( ) = &hC1 ) '' should not crash because it should have been overridden
			delete p
		end scope

		scope
			dim p as B ptr = new C
			CU_ASSERT( p->f1( ) = &hC1 ) '' ditto
			delete p
		end scope

		scope
			dim p as C ptr = new C
			CU_ASSERT( p->f1( ) = &hC1 )
			delete p
		end scope
	end sub
end namespace

private sub ctor( ) constructor
	fbcu.add_suite( "tests/virtual/virtual" )
	fbcu.add_test( "basic overriding", @overridingWorks.test )
	fbcu.add_test( "Overriding vs. shadowing", @overridingVsShadowing.test )
	fbcu.add_test( "Methods with a different signature are not overridden", @differentSignatureIsntOverridden.test )
	fbcu.add_test( "Overriding overloaded methods", @overridingOverloadedMethods.test )
	fbcu.add_test( "Overriding properties", @overridingProperties.test )
	fbcu.add_test( "VIRTUAL dtor", @virtualDtor.test )
	fbcu.add_test( "VIRTUAL dtor still calls field dtor", @virtualDtorDestructsField.test )
	fbcu.add_test( "VIRTUAL dtor still calls base dtor", @virtualDtorDestructsBase.test )
	fbcu.add_test( "implicit dtor also overrides", @implicitDtorOverrides.test )
	fbcu.add_test( "virtuals overriding virtuals reuse the vtable slots #1", @vtableSlotsReused1.test )
	fbcu.add_test( "virtuals overriding virtuals reuse the vtable slots #2", @vtableSlotsReused2.test )
	fbcu.add_test( "overrides are not made virtual automatically", @noImplicitVirtual.test )
	fbcu.add_test( "VIRTUALs are inherited even if not overridden #1", @virtualsAreInherited1.test )
	fbcu.add_test( "VIRTUALs are inherited even if not overridden #2", @virtualsAreInherited2.test )
end sub

end namespace
