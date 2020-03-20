Class isc.julia.util.Converter
{

/// Escapes list of strings to be used as an argument in Python functions, etc.
/// Should always eval as a string
/// If usePython = 1 then Python is used to escape the string.
/// If usePython = 0 then $zcvt is used.
/// Please report if you found a faulty string, which $zcvt does not escape correctly.
/// Python escape uses PyUnicode_FromString -> PyUnicode_DecodeUTF8Stateful
/// Source: https://github.com/python/cpython/blob/master/Objects/unicodeobject.c#L4813
ClassMethod EscapeStringList(list As %List, usePython As %Boolean = {$$$NO}) As %String
{
	for i=1:1:$ll(list) {
		set $list(list, i) = ..EscapeString($lg(list, i), usePython)
	}
	
	quit list
}

/// Escapes string to be used as an argument in Julia functions, etc.
/// Should always eval as a string
/// Please report if you found a faulty string, which $zcvt does not escape correctly.
ClassMethod EscapeString(string As %String) As %String [ CodeMode = expression ]
{
"""" _ $zcvt(string, "O", "JS") _ """"
}

/// Escapes string to be used as an argument in Julia functions, etc.
/// Should always eval as a string
/// Please report if you found a faulty string, which $zcvt does not escape correctly.
ClassMethod EscapeStringQuoted(string As %String) As %String [ CodeMode = expression ]
{
"\""" _ $zcvt(string, "O", "JS") _ "\"""
}

/// Convert boolean to Julia
/// w ##class(isc.julia.util.Converter).BooleanToJulia(1)
ClassMethod BooleanToJulia(boolean As %Boolean) As %String [ CodeMode = expression ]
{
$case(boolean, $$$YES:"true", $$$NO:"false", :"""" _ boolean _ "'")
}

/// Convert Julia boolean to boolean
/// w ##class(isc.julia.util.Converter).JuliaToBoolean("true")
ClassMethod JuliaToBoolean(boolean As %String) As %Boolean [ CodeMode = expression ]
{
$case(boolean, "true":$$$YES, "false":$$$NO, :"")
}

/// Convert ODBC Date to Julia Date
/// date in ODBC format: YYYY-MM-DD
/// w ##class(isc.julia.util.Converter).ODBCDateToJulia("2019-01-01")
ClassMethod ODBCDateToJulia(date As %String) As %String [ CodeMode = expression ]
{
"Date("_ $tr(date,"-",",") _ ")"
}

/// Convert ODBC Time to Julia Time
/// time in ODBC format: hh:mm:ss
/// w ##class(isc.julia.util.Converter).ODBCTimeToJulia("11:12:13")
ClassMethod ODBCTimeToJulia(time As %String) As %String [ CodeMode = expression ]
{
"Time(" _ $tr(time,":",",") _ ")"
}

/// Convert ODBC Timestamp to Julia Timestamp
/// datetime - alias of datetime module
/// timestamp - timesptamp in ODBC format: YYYY-MM-DD hh:ss:mm
/// w ##class(isc.julia.util.Converter).ODBCTimeStampToJulia("2011-01-01 01:01:01")
ClassMethod ODBCTimeStampToJulia(timestamp As %TimeStamp) [ CodeMode = expression ]
{
"DateTime(" _ $tr(timestamp, "- :",",,,") _ ")"
}

}

