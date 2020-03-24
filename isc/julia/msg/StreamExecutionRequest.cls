/// Same as ExecutionRequest but Code is a stream
Class isc.julia.msg.StreamExecutionRequest Extends Ens.Request
{

/// Julia code to execute
Property Code As %Stream.GlobalCharacter;

/// Comma-separated list of variables to get in response message
Property Variables As %VarString;

/// Separate incoming message into lines for execution.
/// $c(10) is used for line separation
/// Note that it's NOT recommended to process whole message at once, 
/// this feature is only for `def` and similar multi-line expressions processing.
Property SeparateLines As %Boolean [ InitialExpression = {$$$YES} ];

/// How to serialize variables we want to return
Property Serialization As %String(VALUELIST = ",string,json") [ InitialExpression = "json" ];

}

