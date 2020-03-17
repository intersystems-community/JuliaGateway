/// Raw callout wrapper. Use isc.py.Main
/// To use:
/// 1. Call: do ##class(isc.julia.Callout).Setup() once per systems start
/// 2. Call main method (can be called many times, context persists): write ##class(isc.julia.Callout).SimpleString(code, variable)
/// 3. Call: do ##class(isc.julia.Callout).Finalize() to clear Python context
/// 4. Call: write ##class(isc.julia.Callout).Unload() to free callout library
Class isc.julia.Callout
{

/// Serialization by str() function
Parameter SerializationStr = 0;

/// Serialization by repr() function
Parameter SerializationRepr = 1;

Parameter JuliaLibId As Integer = 4938;

Parameter Initialize As Integer = 1;

Parameter Finalize As Integer = 2;

Parameter SimpleString As Integer = 3;

Parameter StreamInit As Integer = 4;

Parameter StreamWrite As Integer = 5;

Parameter StreamExecute As Integer = 6;

/// Get path to the shared library file. 
/// Library file is assumed to be in a bin folder, unless specified otherwise in ^isc.julia.Callout global.
/// write ##class(isc.julia.Callout).GetLib()
ClassMethod GetLib() [ CodeMode = expression ]
{
$g(^isc.julia.Callout, $g(^%SYS("bindir")) _ "iscjulia." _ $select($$$isWINDOWS:"dll", $$$isMACOSX:"dylib", 1:"so"))
}

/// Should be executed once per system start. Idempotent.
/// Add to ZSTART or production start.
/// write ##class(isc.julia.Callout).Setup()
ClassMethod Setup() As %Status
{
	#dim sc As %Status = $$$OK
	set file = ..GetLib()
	quit:'##class(%File).Exists(file) $$$ERROR($$$GeneralError, "Library file: " _ file _ " does not exist")	

	try {
		set result = $ZF(-4,6,..#JuliaLibId)
		if result'=0 {
			set sc = $$$ERROR($$$GeneralError, "Failed $ZF(-4, 6,..#JuliaLibId) call with result: " _ result _ " expected 0")
			quit
		}
		
		set result =$ZF(-4,5,..#JuliaLibId, file)
		if result'=0 {
			set sc = $$$ERROR($$$GeneralError, "Failed $ZF(-4, 5,..GetLib()) call with result: " _ result _ " expected 0")
			quit
		}
	} catch ex {
		set sc = ex.AsStatus()
	}
	
	
    quit sc
}

/// Initializes Julia environment. Idempotent.
/// Currently this is done automatically on a C side of things.
ClassMethod Initialize(file As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	try {
		do $ZF(-6, ..#JuliaLibId, ..#Initialize, file)
	} catch ex {
		set sc = ex.AsStatus()
	}
	quit sc
}

/// Eval code vaiable in initialized context and return result if possible.
/// Always check sc. If it's not $$$OK, result is invalid.
/// If sc is $$$OK result is returned if it's a string, bool, int8, int16, int32, int64, float32, float64 or ASCII char.
/// write ##class(isc.julia.Callout).SimpleString()
ClassMethod SimpleString(code As %String = "x=sqrt(2)", Output sc As %Status) As %String
{
	try {
		set sc = $$$OK
		set:$ZISWIDE(code) code = $zcvt(code, "O", "UTF8")
		set result = $ZF(-6, ..#JuliaLibId, ..#SimpleString, code)
		
		// Slows getting result by ~50%
		set result = $zcvt(result, "I", "UTF8")
		
		if $extract(result, 1, 5) = $c(1,1,1,1,1) {
			set sc = $$$ERROR($$$GeneralError, $replace($extract(result, 6, *), $c(10), $$$NL))
			set result = ""
		} 
	} catch ex {
		#dim ex As %Exception.AbstractException
		set sc = ex.AsStatus()
		set result = ""
	}
	
	quit result
}

/// Init incoming Stream
/// write ##class(isc.julia.Callout).StreamInit()
ClassMethod StreamInit(length As %Integer = 32000) As %Status
{
	#dim sc As %Status = $$$OK
	try {
		do $ZF(-6, ..#JuliaLibId, ..#StreamInit, length)
	} catch ex {
		#dim ex As %Exception.General
		if (ex.Name = "<FUNCTION>") {
			set sc = $$$ERROR($$$GeneralError, "Unable to allocate memory")
		} else {
			set sc = ex.AsStatus()
		}
	}
	
	quit sc
}

/// Write piece into incoming Stream.
/// If initial length is not enough, additional allocation is performed.
/// write ##class(isc.julia.Callout).StreamWrite()
ClassMethod StreamWrite(code As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	try {
		set:$ZISWIDE(code) code = $zcvt(code, "O", "UTF8")
		do $ZF(-6, ..#JuliaLibId, ..#StreamWrite, code)
	} catch ex {
		#dim ex As %Exception.General
		if (ex.Name = "<FUNCTION>") {
			set sc = $$$ERROR($$$GeneralError, "Call StreamInit before calling StreamWrite. Or reallocation failed as initial allocation in StreamInit could not hold all the data.")
		} else {
			set sc = ex.AsStatus()
		}
	}
	
	quit sc
}

/// Send incoming stream to Julia for execution and free it.
/// write ##class(isc.julia.Callout).StreamExecute()
ClassMethod StreamExecute() As %Status
{
	#dim sc As %Status = $$$OK
	try {
		do $ZF(-6, ..#JuliaLibId, ..#StreamExecute)
	} catch ex {
		#dim ex As %Exception.General
		if (ex.Name = "<FUNCTION>") {
			set sc = $$$ERROR($$$GeneralError, "Call StreamInit and StreamWrite before calling StreamExecute")
		} else {
			set sc = ex.AsStatus()
		}
	}
	
	quit sc
}

/// d ##class(isc.julia.Callout).Test()
ClassMethod Test()
{
	//set code = $lts($lb("try", "using DataFrames", "df = DataFrame(A = 1:4, B = 'A':'D')", "catch e", "bt = backtrace()", "msg = sprint(showerror, e, bt)", "end"), $$$NL)
	//write ##class(isc.julia.Callout).SimpleString(code)
	
	write ##class(isc.julia.Callout).SimpleString("x=sqrt(3)")
	write ##class(isc.julia.Callout).SimpleString("string(x)")
	write ##class(isc.julia.Callout).SimpleString("using DataFrames")
	write ##class(isc.julia.Callout).SimpleString("df = DataFrame(A = 1:4, B = 'A':'D')")
	write $replace(##class(isc.julia.Callout).SimpleString("string(df)"),$c(10),$c(10,13))
}

/// Finalize Julia. Idempotent.
/// write ##class(isc.julia.Callout).Finalize()
ClassMethod Finalize() As %Status
{
	#dim sc As %Status = $$$OK
	try {
		do $ZF(-6, ..#JuliaLibId, ..#Finalize)
	} catch ex {
		#dim ex As %Exception.General
		set sc = ex.AsStatus()
	}
	quit sc
}

/// Unload library. Idempotent.
/// write ##class(isc.julia.Callout).Unload()
ClassMethod Unload() As %Status
{
	#dim sc As %Status = $$$OK
	
	try {
		set result = $ZF(-4, 4, ..#JuliaLibId)
		set:result'=0 sc = $$$ERROR($$$GeneralError, "Failed $ZF(-4, 4,..#JuliaLibId) call with result: " _ result _ " expected 0")
	} catch ex {
		set sc = ex.AsStatus()
	}

	quit sc
}

}

