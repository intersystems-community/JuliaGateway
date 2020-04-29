/// Sample operation. 
/// Process requests to:
///  - Execute Julia code and return requsted variables (string/stream)
///  - Load data into Julia
Class isc.julia.ens.Operation Extends Ens.BusinessOperation
{

/// Class implementing isc.julia.init.Abstract interface.
/// Can be used to load modules and functions on process startup.
Property Initializer As %String;

Parameter SETTINGS = "Initializer:Basic:selector?context={isc.julia.ens.ContextSearch/SubclassOf?class=isc.julia.init.Abstract}";

Method OnInit() As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(isc.julia.Callout).Setup()
	quit:$$$ISERR(sc) sc
	set sc = ##class(isc.julia.Callout).Initialize()
	quit:$$$ISERR(sc) sc
	
	if (..Initializer'="") {
		if ##class(%Dictionary.CompiledClass).%ExistsId(..Initializer) {
			set sc = $classmethod(..Initializer, "Initialize") 
		} else {
			set sc = $$$ERROR($$$GeneralError, "Initializer class does not exist or is uncompiled: ", ..Initializer) 
		}
	}
	quit sc
}

/// Free Julia library
Method OnTearDown() As %Status
{
	do ##class(isc.julia.Callout).Finalize()
	do ##class(isc.julia.Callout).Unload()
	quit $$$OK
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="isc.julia.msg.StreamExecutionRequest">
    <Method>StreamExecute</Method>
  </MapItem>
  <MapItem MessageType="isc.julia.msg.ExecutionRequest">
    <Method>Execute</Method>
  </MapItem>
  <MapItem MessageType="isc.julia.msg.QueryRequest">
    <Method>ExecuteQuery</Method>
  </MapItem>
</MapItems>
}

/// Execute arbitrary Julia code
Method Execute(request As isc.julia.msg.ExecutionRequest, Output response As isc.julia.msg.ExecutionResponse) As %Status
{
	#dim sc As %Status = $$$OK
	set response = ##class(isc.julia.msg.ExecutionResponse).%New()
	
	if request.SeparateLines = $$$YES {
		set codeList=$lfs(request.Code, $c(10))
	} else {
		set codeList=$lb(request.Code)
	}
	
	for i=1:1:$ll(codeList) {
		set line = $lg(codeList, i)
		continue:line=""
		$$$TRACE(line)	
		set sc = ##class(isc.julia.Main).SimpleString(line, .stdout)
		
		set response.Stdout = response.Stdout + stdout + $$$NL
		
		quit:$$$ISERR(sc)
	}
	quit:$$$ISERR(sc) sc
	
	set serialization = request.Serialization
	set variables = $lfs(request.Variables)
	for i=1:1:$ll(variables) {
		set variable = $lg(variables, i)
		continue:variable=""
		$$$TRACE("Getting variable: " _ variable)
		
		kill value
		
		set sc = ##class(isc.julia.Main).GetVariable(variable, serialization, .value, $$$YES)
		
		quit:$$$ISERR(sc)
		do response.Variables.SetAt(value, variable)
	}
	
	quit sc
}

/// Execute arbitrary Julia code
Method StreamExecute(request As isc.julia.msg.StreamExecutionRequest, Output response As isc.julia.msg.StreamExecutionResponse) As %Status
{
	#dim sc As %Status = $$$OK
	set response = ##class(isc.julia.msg.StreamExecutionResponse).%New()
	
	
	set code = request.Code
	
	if request.SeparateLines = $$$YES {
		set code.LineTerminator = $c(10)
		
		while 'code.AtEnd {
			set line = code.ReadLine($$$MaxLocalLength)
			$$$TRACE(line)
			set sc = ##class(isc.julia.Main).SimpleString(line, .stdout)
			set response.Stdout = response.Stdout + stdout + $$$NL
			quit:$$$ISERR(sc)
		}	
	} else {
		set sc = ##class(isc.julia.Main).ExecuteCode(code, .stdout)
		set response.Stdout = stdout
	}
	
	quit:$$$ISERR(sc) sc
	
	set serialization = request.Serialization
	set variables = $lfs(request.Variables)
	for i=1:1:$ll(variables) {
		set variable = $lg(variables, i)
		continue:variable=""
		$$$TRACE("Getting variable: " _ variable)
		
		kill value
		
		set sc = ##class(isc.julia.Main).GetVariable(variable, serialization, .value)
		
		quit:$$$ISERR(sc)
		do response.Variables.SetAt(value, variable)
	}
	
	quit sc
}

/// Create pandas dataframe or list form sql.
Method ExecuteQuery(request As isc.julia.msg.QueryRequest, Output response As Ens.Response) As %Status
{
	#dim sc As %Status = $$$OK
	set response = ##class(Ens.Response).%New()	
	set sc = ##class(isc.julia.Main).ExecuteQuery(request.Query, request.Variable, request.Type, request.Namespace)
	quit sc
}

}

