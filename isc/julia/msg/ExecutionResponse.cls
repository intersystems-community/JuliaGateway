/// Response from Julia environment
Class isc.julia.msg.ExecutionResponse Extends Ens.Response
{

/// Array of Julia variables
Property Variables As array Of %VarString;

Property Stdout As %VarString;

Storage Default
{
<Data name="ExecutionResponseDefaultData">
<Subscript>"ExecutionResponse"</Subscript>
<Value name="1">
<Value>Stdout</Value>
</Value>
</Data>
<Data name="Variables">
<Attribute>Variables</Attribute>
<Structure>subnode</Structure>
<Subscript>"isc.julia.msg.ExecutionResponse.Variables"</Subscript>
</Data>
<DefaultData>ExecutionResponseDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

