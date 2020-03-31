Class isc.julia.unit.TestCase Extends %UnitTest.TestCase
{

Method OnBeforeAllTests() As %Status
{
	set sc = ##class(isc.julia.Callout).Setup()
	quit:$$$ISERR(sc) sc
	set sc = ##class(isc.julia.Callout).Initialize()
	quit sc
}

Method TestSimpleString()
{
	set sc = ##class(isc.julia.Callout).SimpleString("sqrt(5)", .x)
	do $$$AssertStatusOK(sc, "SimpleString")
}

Method TestLimit()
{
	for limit = 32767,135108,$$$MaxStringLength {
		set sc = ##class(isc.julia.Callout).SimpleString("repeat(""A"", " _ limit _ " )", .str1)
		do $$$AssertEquals($l(str1), limit, "Returned " _ limit _ " characters") 
	}
}

Method TestPassSpeedIn()
{
	set setChars = 6
	set limit = 32767 - setChars
	set str = $tr($j("", limit), " ", "A")
	
	set rounds = 295
	set start = $zh
	for i = 1:1:rounds {
		do ##class(isc.julia.Callout).SimpleString("str1=""" _ str _ """")
	}
	set end = $zh
	
	set time = end - start
	set megabytes = $fnumber((limit+setChars)*rounds/(1024**2), "", 2)
	set speed = $fnumber(megabytes/time, "", 2)
	
	do $$$LogMessage($$$FormatText("Passed in %1 Mb in %2 sec. Speed: %3 Mb/sec.", megabytes, time, speed))
}

Method TestPassSpeedOut()
{
	set limit = $$$MaxStringLength
	set sc= ##class(isc.julia.Callout).SimpleString("str1 = repeat(""A"", " _ limit _ " )")

	set rounds = 295
	set start = $zh
	for i = 1:1:rounds {
		set sc = ##class(isc.julia.Callout).SimpleString("str1", .str1)
		kill str1
	}
	set end = $zh
	
	set time = end - start
	set megabytes = $fnumber(limit*rounds/(1024**2), "", 2)
	set speed = $fnumber(megabytes/time, "", 2)
	
	do $$$LogMessage($$$FormatText("Passed out %1 Mb in %2 sec. Speed: %3 Mb/sec.", megabytes, time, speed))
}

Method TestSetCallSpeed()
{
	set sc = ##class(isc.julia.Callout).SimpleString("str1=''")
	set rounds = 100000
	set start = $zh
	for i = 1:1:rounds {
		do ##class(isc.julia.Callout).SimpleString("str1=" _ i)
	}
	set end = $zh
	
	set time = end - start
	set speed = $fnumber(rounds/time, "", 2)
	
	do $$$LogMessage($$$FormatText("Called Julia %1 times in %2 sec. Speed: %3 calls/sec.", rounds, time, speed))
}

Method TestUnicode()
{
	set unicode = "ПРИВЕТ"
	set sc = ##class(isc.julia.Callout).SimpleString("result=""" _ unicode _ """", .result)
	do $$$AssertEquals(unicode, result, "Passing unicode characters works")
}

Method TestMultiline()
{
	set sc = ##class(isc.julia.Callout).SimpleString("function cube(num)"_ $c(10) _ "    num*num*num" _ $c(10) _ "end")
											
	do $$$AssertStatusOK(sc, "function created")
	
	set num = 6
	set sc = ##class(isc.julia.Callout).SimpleString("cube(" _ num _ ")", .cube)
	do $$$AssertStatusOK(sc, "function called")
	do $$$AssertEquals(num**3, cube, "function works")
}

/// Test how fast we can pass and execute the stream
Method TestPassSpeedInStream()
{
	set variable = "x"
	set length = 1024 * 1024 * 10
	set code = ..GetCodeStreamOneVar(variable, length) 
	
	set start = $zh
	set sc = ##class(isc.julia.Main).ExecuteCode(code)
	set end = $zh
	do $$$AssertStatusOK(sc, "Stream set")
	
	set time = end - start
	set megabytes = $fnumber(length/(1024**2), "", 2)
	set speed = $fnumber(megabytes/time, "", 2)
	
	do $$$LogMessage($$$FormatText("Passed in %1 Mb in %2 sec. Speed: %3 Mb/sec.", megabytes, time, speed))
}

Method TestStream()
{
	set variable = "x"
	set iterations = 1000000
	set code = ..GetCodeStream(variable, iterations)
	
	set sc = ##class(isc.julia.Main).ExecuteCode(code)
	do $$$AssertStatusOK(sc, "Stream executed")
	
	set sc = ##class(isc.julia.Main).GetVariable(variable,, .result, $$$YES)
	do $$$AssertStatusOK(sc, "Variable returned")
	
	do $$$AssertEquals(iterations, result, "Variable value is correct")
}

Method TestGetVariableInfo()
{
	set variable = "x" _ $random(10000000)
	set value = "123"
	
	set sc = ##class(isc.julia.Main).GetVariableInfo(variable, , .defined, .type, .length)
	do $$$AssertStatusOK(sc, "Variable info returned")
	do $$$AssertEquals(defined, $$$NO, "Variable not defined")
	
	set sc = ##class(isc.julia.Main).ExecuteCode(value, variable)
	
	kill defined, type, length
	set sc = ##class(isc.julia.Main).GetVariableInfo(variable, , .defined, .type, .length)
	do $$$AssertStatusOK(sc, "Variable info returned")
	do $$$AssertEquals(defined, $$$YES, "Variable defined")
	do $$$AssertEquals(type, "Int64", "Variable type is Int64")
	do $$$AssertEquals(length, $l(value), "Variable length matches")
}

Method TestGetStatus()
{
	set sc = ##class(isc.julia.Main).SimpleString("sqrt(4)")
	do $$$AssertStatusOK(sc, "Initial status OK")
	
	set sc = ##class(isc.julia.Main).SimpleString("sqrt(-1)")
	do $$$AssertStatusNotOK(sc, "Error caught")
}

Method TestJSON()
{
	set variable = "list"
	set arg1 = 1
	set arg2 = "abc"
	set sc = ##class(isc.julia.Main).ExecuteCode("(" _ arg1 _ ",""" _ arg2 _ """)", variable)
	do $$$AssertStatusOK(sc, "List set")
	
	set sc = ##class(isc.julia.Main).GetVariable(variable, "json", .string, $$$YES)
	do $$$AssertStatusOK(sc, "Get JSON string OK")
	
	#dim stream As %Stream.TmpCharacter
	set sc = ##class(isc.julia.Main).GetVariable(variable, "json", .stream, $$$NO)
	do $$$AssertStatusOK(sc, "Get JSON stream OK")
	
	try {
		set obj = {}.%FromJSON(string)
		
		if $isObject(obj) {
			set stringArg1 = obj.%Get(0)
			do $$$AssertEquals(arg1, stringArg1, "JSON string is correct")
			set stringArg2 = obj.%Get(1)
			do $$$AssertEquals(arg2, stringArg2,  "JSON string is correct")
		} else {
			do $$$AssertFailure("string->dynObj failed")
		}
		
	} catch ex {
		#dim ex As %Exception.General
		do $$$AssertFailure("string->dynObj failed with exception: " _ ex.DisplayString())
	}
	
	try {
		set obj = {}.%FromJSON(stream)
		
		if $isObject(obj) {
			set stringArg1 = obj.%Get(0)
			do $$$AssertEquals(arg1, stringArg1, "JSON stream is correct")
			set stringArg2 = obj.%Get(1)
			do $$$AssertEquals(arg2, stringArg2, "JSON stream is correct")
		} else {
			do $$$AssertFailure("stream->dynObj failed")
		}
		
	} catch ex {
		do $$$AssertFailure("stream->dynObj failed with exception: " _ ex.DisplayString())
	}
}

ClassMethod GetCodeStream(variable As %String, iterations As %Integer = 1000000) As %Stream.GlobalCharacter
{
	set stream = ##class(%Stream.GlobalCharacter).%New()
	for i=1:1:iterations {
		do stream.WriteLine((variable _ "=" _ i))
	}
	do stream.%Save()
	quit stream
}

/// Get code stream which contains assignment on ne variable to a string with length - length(var+2) symbols
/// do ##class(isc.julia.unit.TestCase).GetCodeStreamOneVar("x",10)
ClassMethod GetCodeStreamOneVar(variable, length) As %Stream.GlobalCharacter
{
	set stream = ##class(%Stream.TmpCharacter).%New()
	set str = $tr($j("", $$$MaxStringLength), " ", "A")
	
	do stream.Write(variable _ "=""")
	set length = length - $l(variable) - 2
	
	while length>1 {
		if length>$$$MaxStringLength {
			do stream.Write(str)
			set length = length - $$$MaxStringLength
		} else {
			do stream.Write($e(str,1,length - 1))
			set length = 1
		}
	}
	do stream.Write("""")
	
	quit stream
}

/// Manually test production.
/// do ##class(isc.julia.unit.TestCase).PassProductionStream()
ClassMethod PassProductionStream(count As %Integer = 1000000, separateLines As %Boolean = {$$$YES})
{
	set variable = "x"
	set stream = ..GetCodeStream(variable, count)
	
	write "Count: ", count, !
	write "SeparateLines: ", separateLines, !
	write "Size: ", stream.Size, !
	
	set request = ##class(isc.julia.msg.StreamExecutionRequest).%New()
	set request.Code = stream
	set request.Variables = variable
	set request.SeparateLines = $$$YES
	
	#dim response As isc.julia.msg.StreamExecutionResponse
	set sc = ##class(EnsLib.Testing.Service).SendTestRequest("isc.julia.ens.Operation", request, .response, .sessionId, $$$YES)
	
	set:$$$ISOK(sc) value = response.Variables.GetAt(variable).Read()
	
	write "Status: ", $select($$$ISOK(sc):sc, 1:$System.Status.GetErrorText(sc)), !
	write "Value: ", $g(value), !
	write "SessionId: ", $g(sessionId), !
}

}

