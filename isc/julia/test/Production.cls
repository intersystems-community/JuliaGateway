/// Sample production
Class isc.julia.test.Production Extends Ens.Production
{

/// Register callout lib system-wide
ClassMethod OnStart(pTimeStarted As %String) As %Status
{
	set sc = ##class(isc.julia.Callout).Setup()
	quit sc
}

XData ProductionDefinition
{
<Production Name="isc.julia.test.Production" TestingEnabled="true" LogGeneralTraceEvents="true">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="isc.julia.ens.Operation" Category="" ClassName="isc.julia.ens.Operation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
  </Item>
  <Item Name="isc.julia.test.Process" Category="" ClassName="isc.julia.test.Process" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
  </Item>
</Production>
}

}

