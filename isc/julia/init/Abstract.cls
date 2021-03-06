Class isc.julia.init.Abstract [ Abstract ]
{

/// List of modules to import in a form of:
/// $lb("module1", "module2", "module3", ...)
Parameter Modules;

Query MethodsList(class = {$classname()}) As %SQLQuery
{
SELECT 
      Name
FROM  %Dictionary.CompiledMethod
WHERE ClassMethod=1
  AND Name %STARTSWITH 'Init'
  AND Name != 'Initialize'
  AND parent = :class
ORDER BY Name ASC
}

/// Initializes Julia environment. Idempotent.
/// Extend this or Default class to execute code on Python process startup
/// set sc = ##class(isc.julia.init.Abstract).Initialize()
ClassMethod Initialize(verbose As %Boolean = {$$$NO}) As %Status
{
	try {
		#dim sc As %Status = $$$OK
		
		do:verbose ..Log("Initializing callout library, file argument: '" _ file _ "'")
		set sc = ##class(isc.julia.Callout).Initialize()
		do:verbose ..LogStatus("Initializing callout library", sc)
		quit:$$$ISERR(sc)
		
		do:verbose ..Log("Start Importing modules")
		set scModules = ..ImportModules(verbose)	
		do:verbose ..Log("Finished Importing modules")
		
		
		do:verbose ..Log("Executing Init methods")
		set scMethods = ..ExecuteInitMethods(verbose)
		do:verbose ..Log("Finished executing Init methods")
		
		set sc = $$$ADDSC(scModules, scMethods)
		
		if verbose {
			if $$$ISERR(sc) {
				do ..Log("There were errors during initialization")
			} else {
				do ..Log("Initialization completed successfully")
			}
		}

	} catch ex {
		do:verbose ..LogException("Initialize", ex)
		set sc = ex.AsStatus()
	}
	
	quit sc
}

ClassMethod ImportModules(verbose As %Boolean = {$$$NO}) As %Status
{
	#dim sc As %Status = $$$OK
	if '$listvalid(..#Modules) {	
		do:verbose ..Log("Modules parameter must be list")
		set sc = $$$ERROR($$$AttributeValueMustBeList, "Modules parameter")
		quit sc
	}
	for i=1:1:$ll(..#Modules) {
		set module = $lg(..#Modules, i)
		set sc1 = ##class(isc.py.Main).ImportModule(module)
		do:verbose ..LogStatus("Importing module: " _ module, sc1)
		set sc = $$$ADDSC(sc, sc1)				
	}
	
	quit sc
}

ClassMethod ExecuteInitMethods(verbose As %Boolean = {$$$NO})
{
	#dim sc As %Status = $$$OK

	#dim rs As %SQL.ISelectResult
	set rs = ..MethodsListFunc()
	while rs.%Next() {
		set method = rs.Name
		set sc1 = $classmethod(, method)
		do:verbose ..LogStatus("Executing method: " _ method, sc1)
		
		set sc = $$$ADDSC(sc, sc1)	
	}
	
	quit sc
}

/// do ##class(isc.py.init.Abstract).LogException()
ClassMethod LogException(msg As %String, ex As %Exception.AbstractException)
{
	Do ..Log(msg _ ". Caught exception: " _ ex.DisplayString())
}

/// do ##class(isc.py.init.Abstract).LogStatus()
ClassMethod LogStatus(msg As %String, sc As %Status)
{
	Do ..Log(msg _ ". Completed with " _ $select($$$ISERR(sc):$System.Status.GetErrorText(sc), 1:"success."))
}

/// do ##class(isc.py.init.Abstract).Log()
ClassMethod Log(msg As %String)
{
	Write $ZDATETIME($ZTIMESTAMP, 3, 1) _ " " _ msg,!
}

}

