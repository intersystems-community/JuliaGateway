/// Request to execute code for Julia operation
Class isc.julia.msg.ExecutionRequest Extends Ens.Request
{

/// Python code to execute
Property Code As %VarString;

/// Comma-separated list of variables to get in response message
Property Variables As %VarString;

/// Separate incoming message into lines for execution.
/// $c(10) is used for line separation
/// Note that it's NOT recommended to process whole message at once, 
/// this feature is only for `def` and similar multi-line expressions processing.
Property SeparateLines As %Boolean [ InitialExpression = {$$$YES} ];

/// How to serialize variables we want to return
Property Serialization As %String(VALUELIST = ",string,json") [ InitialExpression = "json" ];

Storage Default
{
<Data name="ExecutionRequestDefaultData">
<Subscript>"ExecutionRequest"</Subscript>
<Value name="1">
<Value>Code</Value>
</Value>
<Value name="2">
<Value>Variables</Value>
</Value>
<Value name="3">
<Value>SeparateLines</Value>
</Value>
<Value name="4">
<Value>Serialization</Value>
</Value>
</Data>
<DefaultData>ExecutionRequestDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

