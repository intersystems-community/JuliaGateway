Class isc.julia.Main
{

/// Eval code vaiable in initialized context and return result if possible.
/// Always check sc. If it's not $$$OK, result is invalid.
/// If sc is $$$OK result is returned if it's a string, bool, int8, int16, int32, int64, float32, float64 or ASCII char.
/// write ##class(isc.julia.Main).SimpleString()
ClassMethod SimpleString(code As %String, Output result As %String) As %Status [ CodeMode = expression ]
{
##class(isc.julia.Callout).SimpleString(code, .result)
}

/// Executes code. If variable is not empty sets variable=code.
/// If variable is undefined just executes the code
/// code may be a string or a stream
/// write ##class(isc.julia.Main).ExecuteCode()
ClassMethod ExecuteCode(code As %Stream.Object, variable As %String = "", Output result As %String) As %Status
{
	kill result
	#dim sc As %Status = $$$OK
	quit:$d(code)'=1 $$$ERROR($$$GeneralError, "Code argument should be set to stream or to string") 
	
	if $isObject(code) {
		do code.Rewind()
		set codeLength = code.Size
	} else {
		set codeLength = $l(code)
	}
	
	#dim hasVar As %Boolean = $l(variable)>0
	
	// length of code + length of var name + 1 char for '='
	set length = codeLength + $select(hasVar :$l(variable) + 1, 1:0)

	
	if length>($$$MaxStringLength \ 2) {
		set sc = ##class(isc.julia.Callout).StreamInit(length)
		quit:$$$ISERR(sc) sc
		set:hasVar sc = ##class(isc.julia.Callout).StreamWrite(variable _ "=")
		quit:$$$ISERR(sc) sc
		
		if $isObject(code) {
			while 'code.AtEnd {
				set codePiece = code.Read($$$MaxStringLength \ 2)
				set sc = ##class(isc.julia.Callout).StreamWrite(codePiece)
				quit:$$$ISERR(sc)
			}
		} else {
			set sc = ##class(isc.julia.Callout).StreamWrite(code)
			quit:$$$ISERR(sc)
		}
		quit:$$$ISERR(sc) sc
		set sc = ##class(isc.julia.Callout).StreamExecute(.result)
	} else {
		set tempCode = $select(hasVar : variable _ "=", 1:"")
		if $isObject(code) {
			set tempCode = tempCode _ code.Read($$$MaxStringLength)
		} else {
			set tempCode = tempCode _ code
		}
		
		set sc = ..SimpleString(tempCode, .result)
	}
	
	if $$$ISERR(sc) {
		if $isObject(code) {
			do code.Rewind()
			set errorCode = code.Read(1000)
		} else {
			set errorCode = $e(code, 1, 1000)
		}
		set sc = $$$ADDSC(sc, $$$ERROR($$$GeneralError, $$$FormatText("code: %1, variable: %2", $replace(errorCode, $c(10), $$$NL), variable)))
	}
	
	
	quit sc
}

/// Populate variable from sql query
/// variable - python variable to set
/// type - variable type (Currently supported: dataframe and list.
/// query - text of the SQL query
/// namespace - namespace to execute query in. 'isc.julia' package must be available in this namespace.
/// DataFrames is imported automatically if required.
/// set sc = ##class(isc.julia.Main).ExecuteQuery("SELECT * FROM isc_py_test.CannibalizationData", "df")
ClassMethod ExecuteQuery(query As %String, variable As %String, type As %String(VALUELIST=",dataframe,list") = "list", namespace As %String = {$namespace}) As %Status
{
}

/// variable - variable name
/// serialization - string or json
/// useString - if variable length is less than $$$MaxStringLength, return string instead of stream. Ignored if variable length is more than $$$MaxStringLength
/// set sc = ##class(isc.julia.Main).GetVariable()
ClassMethod GetVariable(variable As %String, serialization As %String(VALUELIST=",string,json") = "string", ByRef stream As %Stream.Object, useString As %Boolean = {$$$NO}) As %Status
{
}

/// Get variable metainformation.
/// variable - variable name
/// serialization - serialization type (strig or json)
/// defined - is variable defined
/// type - variable type
/// length - length (in symbols) of variable chosen serialization
/// set sc = ##class(isc.julia.Main).GetVariableInfo()
ClassMethod GetVariableInfo(variable As %String = "", serialization As %String(VALUELIST=",string,json") = "string", Output defined As %Boolean, Output type As %String, Output length As %String) As %Status
{
	#dim sc As %Status = $$$OK
	set type = ""
	set length = ""
	
	set sc = ##class(isc.julia.Main).GetVariableDefined("", .defined)
	quit:$$$ISERR(sc) sc
	quit:defined=$$$NO sc
	
	set sc = ##class(isc.julia.Main).GetVariableType("", .type)
	quit:$$$ISERR(sc) sc
	
	if serialization="string" {
		set sc = ##class(isc.julia.Callout).SimpleString("string(" _ variable _ ")", .length)
	} elseif serialization="json" {
		set sc = ##class(isc.julia.Callout).SimpleString("!!!(" _ variable _ ")", .length)
	}
	
	quit sc
}

/// Is variable defined?
/// variable - variable name
/// defined - is variable defined
/// set sc = ##class(isc.julia.Main).GetVariableDefined("", .defined)
ClassMethod GetVariableDefined(variable As %String = "", Output defined As %Boolean) As %Status [ CodeMode = expression ]
{
##class(isc.julia.Callout).SimpleString("@isdefined(" _ variable _ ")", .defined)
}

/// Get variable type
/// variable - variable name
/// type - variable FQCN
/// set sc = ##class(isc.julia.Main).GetVariableType("", .type)
ClassMethod GetVariableType(variable As %String = "", Output type As %String) As %Status [ CodeMode = expression ]
{
##class(isc.julia.Callout).SimpleString("string(typeof(" _ variable _ "))", .type)
}

/// Import module.
/// set sc = ##class(isc.julia.Main).ImportModule()
ClassMethod ImportModule(module As %String) As %Status
{
}

}

