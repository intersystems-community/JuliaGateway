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

/// Eval code vaiable in initialized context and return result if possible.
/// Always check sc. If it's not $$$OK, result is invalid.
/// If sc is $$$OK result is returned if it's a string, bool, int8, int16, int32, int64, float32, float64 or ASCII char.
/// write ##class(isc.julia.Main).IOSimpleString()
ClassMethod IOSimpleString(code As %String, Output result As %String) As %Status [ CodeMode = expression ]
{
..SimpleString($lts($lb("open(""nul"", ""w"") do out;", "redirect_stdout(out) do;", code, "end", "end"), $c(10)), .result)
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
/// type - variable type (Currently supported: dataframe)
/// query - text of the SQL query
/// namespace - namespace to execute query in. 'isc.julia' package must be available in this namespace.
/// CSV, DataFrames is imported automatically if required.
/// set sc = ##class(isc.julia.Main).ExecuteQuery("SELECT Age, %truncate(Age/2, 4) As Fl, DOB, Name FROM Sample.Person", "df")
ClassMethod ExecuteQuery(query As %String, variable As %String, type As %String(VALUELIST=",dataframe") = "dataframe", namespace As %String = {$namespace}) As %Status
{
	#include %occODBC
	#dim sc As %Status = $$$OK	
	quit:",dataframe,"'[type $$$ERROR($$$GeneralError, "Invalid type: " _ $g(type) _ ". Expected types: dataframe")
	
	set sc = ..ImportModule("CSV")
	quit:$$$ISERR(sc) sc
	
	set sc = ..ImportModule("Dates")
	quit:$$$ISERR(sc) sc

	new $namespace
	set oldNamespace = $namespace
	set $namespace = namespace
	
	set st =  ##class(%SQL.Statement).%New()
	set st.%SelectMode = 1 // ODBC
	set sc = st.%Prepare(query)
	quit:$$$ISERR(sc) sc
	
	#dim result As %SQL.StatementResult
	set result = st.%Execute()
	quit:result.%SQLCODE'=0 $$$ERROR($$$SQLError, result.%SQLCODE, result.%Message)

	#dim metadata As SQL.StatementMetadata
	set metadata = result.%GetMetadata()
	set columnCount = metadata.columns.Count()
	
	set columnList = ""
	set typeList = ""
	for i=1:1:columnCount {
		#dim column As %SQL.StatementColumn
		set column = metadata.columns.GetAt(i)
		
		if (column.IsNumeric() || (column.ODBCType = $$$ODBCTYPEnumeric)) {
			set typeList = typeList _ $lb($$$ODBCTYPEnumeric)
		} elseif (column.ODBCType=$$$ODBCTYPEtimestamp) {
			set typeList = typeList _ $lb($$$ODBCTYPEtimestamp)
		} elseif (column.ODBCType=$$$ODBCTYPEdate) {
			set typeList = typeList _ $lb($$$ODBCTYPEdate)
		} elseif column.ODBCType = $$$ODBCTYPEtime  {
			set typeList = typeList _ $lb($$$ODBCTYPEtime)
		} elseif column.clientType = 16 {
			// boolean
			set typeList = typeList _ $lb($$$ODBCTYPEbit)
		} elseif column.ODBCType = $$$ODBCTYPElongvarchar {
			set typeList = typeList _ $lb($$$ODBCTYPElongvarchar)
		} else {
			set typeList = typeList _ $lb($$$ODBCTYPEvarchar)
		}
		
		set columnList = columnList _ $lb((##class(isc.julia.util.Converter).EscapeString(column.colName)))
	}
	
	set dataStr = ""
	set sc = ##class(isc.julia.Callout).SimpleString(variable _ " = IOBuffer()")
	
	while result.%Next() {		
		set rowList = ""
		for i=1:1:columnCount {
			set value = result.%GetData(i)
			set:$lv(value) value = $lts(value)
			
			set colType = $lg(typeList, i)
			if colType = $$$ODBCTYPEbit {
				set rowList = rowList _ $lb(##class(isc.julia.util.Converter).BooleanToJulia(value))
			} elseif colType = $$$ODBCTYPEnumeric {
				set rowList = rowList _ $lb(value)
			} elseif colType = $$$ODBCTYPEtimestamp {
				set rowList = rowList _ $lb($tr(value, " ", "T"))
			} elseif colType = $$$ODBCTYPEdate {
				set rowList = rowList _ $lb(value)
			} elseif colType = $$$ODBCTYPEtime {
				set rowList = rowList _ $lb(value)
			} elseif colType = $$$ODBCTYPElongvarchar {
				set stream = ##class(%Stream.Object).%Open($lfs(value))
				set rowList = rowList _ $lb(##class(isc.julia.util.Converter).EscapeStringQuoted(stream.Read(1000000)))
				kill stream
			} else {
				set rowList = rowList _ $lb(##class(isc.julia.util.Converter).EscapeStringQuoted(value))
			}
		}
		
		set dataStr = dataStr _ $lts(rowList, ",") _ "\n"
		
		if $l(dataStr)>3000000 {
			set sc = ##class(isc.julia.Callout).SimpleString("write(" _ variable _ ", """ _ dataStr _ """)")
			quit:$$$ISERR(sc)
			set dataStr=""
		}
	}
	quit:$$$ISERR(sc) sc
	
	set $namespace = oldNamespace
	zw dataStr
	set sc = ##class(isc.julia.Callout).SimpleString("write(" _ variable _ ", """ _ dataStr _ """)")
	quit:$$$ISERR(sc) sc
	
	set sc = ..SimpleString("seek(" _ variable _ ", 0)")
	quit:$$$ISERR(sc) sc
	
	
	// zzzcolumns = ["col1", "col2", "col3"]
	set code = "zzzcolumns=[" _ $lts(columnList, ",") _ "]"
	
	set sc = ..SimpleString(code)
	quit:$$$ISERR(sc) sc
	
	
	set sc = ..SimpleString(variable _ "= CSV.read(" _ variable _ ", header=zzzcolumns)")
	quit:$$$ISERR(sc) sc

	set sc = ..SimpleString("zzzcolumns = nothing")	
	
	quit sc
}

/// variable - variable name
/// serialization - string or json
/// useString - if variable length is less than $$$MaxStringLength, return string instead of stream. Ignored if variable length is more than $$$MaxStringLength
/// set sc = ##class(isc.julia.Main).GetVariable()
ClassMethod GetVariable(variable As %String, serialization As %String(VALUELIST=",string,json") = "string", ByRef stream As %Stream.Object, useString As %Boolean = {$$$NO}) As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(isc.julia.Main).GetVariableInfo(variable, serialization, .defined, .type, .length)
	quit:$$$ISERR(sc) sc
	quit:defined=$$$NO $$$ERROR($$$GeneralError, $$$FormatText("Variable %1 is not defined", variable))
	
	set code = $case(serialization, "string": "string(" _ variable _ ")", "json":"JSON.json(" _ variable _ ")")
	
	if ((length<=$$$MaxStringLength) && useString) {	
		set sc = ##class(isc.julia.Callout).SimpleString(code, .stream)
	} else {
		set step = $$$MaxStringLength \ 2
		set:'$isObject($g(stream)) stream = ##class(%Stream.GlobalCharacter).%New()
		
		set sc = ##class(isc.julia.Callout).SimpleString("zzzvar = " _ code)
		
		if (length<=step) {
			set sc = ##class(isc.julia.Callout).SimpleString("zzzvar", .zzzvar)
			do stream.Write(zzzvar)
		} else {
			
			for i=1:step:length {
				set end = i + step
				set:end>length end = length
				set sc = ##class(isc.julia.Callout).SimpleString("zzzvar[" _ i _ ":" _ end _ "]", .zzzvar)
				quit:$$$ISERR(sc)
				do stream.Write(zzzvar)
			}
		}
		
		kill zzzvar
		
		// Julia does not have "delete" function
		// https://docs.julialang.org/en/latest/manual/faq/#How-do-I-delete-an-object-in-memory?-1
		do ##class(isc.julia.Callout).SimpleString("zzzvar = nothing")
		
		quit:$$$ISERR(sc) sc
		set sc = stream.%Save()
		do stream.Rewind()
	}
	
	quit sc
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
	
	set sc = ##class(isc.julia.Main).GetVariableDefined(variable, .defined)
	quit:$$$ISERR(sc) sc
	quit:defined=$$$NO sc
	
	set sc = ##class(isc.julia.Main).GetVariableType(variable, .type)
	quit:$$$ISERR(sc) sc
	
	if serialization="string" {
		set sc = ##class(isc.julia.Callout).SimpleString("length(string(" _ variable _ "))", .length)
	} elseif serialization="json" {
		set sc = ..ImportModule("JSON")
		quit:$$$ISERR(sc) sc
		set sc = ##class(isc.julia.Callout).SimpleString("length(JSON.json(" _ variable _ "))", .length)
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
/// module - module name. Case sensitive
/// install - attempt installation if not found.
/// set sc = ##class(isc.julia.Main).ImportModule()
ClassMethod ImportModule(module As %String, install As %Boolean = {$$$NO}) As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(isc.julia.Callout).SimpleString("using " _ module)
	
	if (($system.Status.GetErrorText(sc) [ "not found in current path") && (install)) {
		set sc = ..ImportModule("Pkg")
		quit:$$$ISERR(sc)
		
		set cmd = $lb("open(""nul"", ""w"") do out;", "redirect_stdout(out) do;", "Pkg.add(""" _ module _ """)", "end", "end")
		set sc = ##class(isc.julia.Callout).SimpleString($lts(cmd, $$$NL), .result)
		
		//set sc = ##class(isc.julia.Callout).SimpleString("Pkg.add(""" _ module _ """)", .result)
		//zw result
	}
	
	quit sc
}

}

