/// Response from Julia environment
Class isc.julia.msg.StreamExecutionResponse Extends Ens.Response
{

/// Array of Julia variables
Property Variables As array Of %Stream.GlobalCharacter(XMLPROJECTION = "NONE");

/// Responses from Julia
Property Stdout As %VarString(XMLPROJECTION = "NONE");

Storage Default
{
<Data name="StreamExecutionResponseDefaultData">
<Subscript>"StreamExecutionResponse"</Subscript>
<Value name="1">
<Value>Stdout</Value>
</Value>
</Data>
<Data name="Variables">
<Attribute>Variables</Attribute>
<Structure>subnode</Structure>
<Subscript>"isc.julia.msg.StreamExecutionResponse.Variables"</Subscript>
</Data>
<DefaultData>StreamExecutionResponseDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

