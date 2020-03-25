/// Sample process
/// Adapted from https://alan-turing-institute.github.io/MLJTutorials/end-to-end/AMES/
Class isc.julia.test.Process Extends (Ens.BusinessProcessBPL, isc.julia.ens.ProcessUtils) [ DependsOn = isc.julia.ens.ProcessUtils ]
{

/// Where to save images. 
/// Refer to this property from process proper with #{process.WorkDirectory}
Property WorkDirectory As %VarString [ InitialExpression = {##class(%File).NormalizeDirectory(##class(%SYS.System).TempDirectory())} ];

Property JuliaOperation As %String(MAXLEN = 128) [ InitialExpression = "isc.julia.ens.Operation" ];

Parameter SETTINGS = "PythonOperation:Basic:selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},ConnectionType:Basic,WorkDirectory:Basic";

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='Ens.Request' response='Ens.Response'>
<context>
<property name="pricePredict" type="%VarString"/>
</context>
<sequence >
<call name='Import modules' target='@..%Process.JuliaOperation' async='1' >
<annotation><![CDATA[using MLJ
using DataFrames
using Statistics
@load RidgeRegressor pkg="MultivariateStats"
@load KNNRegressor]]></annotation>
<request type='isc.julia.msg.ExecutionRequest' >
<assign property="callrequest.Code" value='process.GetAnnotation("Import modules")' action="set" />
</request>
<response type='isc.julia.msg.ExecutionResponse' />
</call>
<sync name='Wait for Import modules' calls='Import modules' type='all' />

<call name='Load Data' target='@..%Process.JuliaOperation' async='1' >
<annotation><![CDATA[SELECT * FROM isc_julia_test.AMES]]></annotation>
<request type='isc.julia.msg.QueryRequest' >
<assign property="callrequest.Query" value='process.GetAnnotation("Load Data")' action="set" />
<assign property="callrequest.Variable" value='"X"' action="set" />
<assign property="callrequest.Type" value='"dataframe"' action="set" />
</request>
<response type='Ens.Response' />
</call>
<sync name='Wait for Load Data' calls='Load Data' type='all'/>

<call name='Prepare Data' target='@..%Process.JuliaOperation' async='1'>
<annotation><![CDATA[
y = X.Price
ids = X.ID

select!(X, Not(:Price))
select!(X, Not(:ID))
select!(X, Not(:PricePredict))

X.OverallQual = CategoricalArray(X.OverallQual)
X.Neighborhood = CategoricalArray(X.Neighborhood)
X.MSSubClass = CategoricalArray(X.MSSubClass)
]]></annotation>
<request type='isc.julia.msg.ExecutionRequest' >
<assign property="callrequest.Code" value='process.GetAnnotation("Prepare Data")' action="set" />
<assign property="callrequest.Variables" value='"X"' action="set" />
<assign property="callrequest.Serialization" value='"string"' action="set" />
</request>
<response type='isc.julia.msg.ExecutionResponse' />
</call>
<sync name='Wait for Prepare Data' calls='Prepare Data' type='all' />

<call disabled="true" name='Load Data Fake' target='@..%Process.JuliaOperation' async='1'>
<annotation><![CDATA[
X, y1 = @load_reduced_ames
X = DataFrame(X)
]]></annotation>
<request type='isc.julia.msg.ExecutionRequest' >
<assign property="callrequest.Code" value='process.GetAnnotation("Load Data Fake")' action="set" />
<assign property="callrequest.Variables" value='"X"' action="set" />
</request>
<response type='isc.julia.msg.ExecutionResponse' />
</call>
<sync name='Wait for Load Data Fake' calls='Load Data Fake' type='all' />

<call name='Split Data' target='@..%Process.JuliaOperation' async='1'>
<annotation><![CDATA[train, test = partition(eachindex(y), 0.70, shuffle=true); # 70:30 split
]]></annotation>
<request type='isc.julia.msg.ExecutionRequest' >
<assign property="callrequest.Code" value='process.GetAnnotation("Split Data")' action="set" />
</request>
<response type='isc.julia.msg.ExecutionResponse' />
</call>
<sync name='Wait for Split Data' calls='Split Data' type='all' />

<call name='Train' target='@..%Process.JuliaOperation' async='1'>
<annotation><![CDATA[
# Let's start by defining the source nodes:

Xs = source(X)
ys = source(y, kind=:target)

# First layer: one hot encoding and log transform:

W = Xs |> OneHotEncoder()
z = ys |> log;

# Second layer: KNN Regression and Ridge regression

ẑ₁ = (W, z) |> KNNRegressor(K=5)
ẑ₂ = (W, z) |> RidgeRegressor(lambda=2.5);

# Third layer: weighted sum of the two models:

ẑ = 0.3ẑ₁ + 0.7ẑ₂;

# then the inverse transform

ŷ = exp(ẑ);
]]></annotation>
<request type='isc.julia.msg.ExecutionRequest' >
<assign property="callrequest.Code" value='process.GetAnnotation("Train")' action="set" />
</request>
<response type='isc.julia.msg.ExecutionResponse' />
</call>
<sync name='Wait for Train' calls='Train' type='all' />

<call name='Predict' target='@..%Process.JuliaOperation' async='1'>
<annotation><![CDATA[

# You can then fit and evaluate the model as usual:

fit!(ŷ, rows=train)

ypreds = ŷ(rows=test)

modrmsl = rmsl(y[test], ypreds)

ypredsAll = ŷ(rows=[1:1:size(X, 1);])
]]></annotation>
<request type='isc.julia.msg.ExecutionRequest' >
<assign property="callrequest.Code" value='process.GetAnnotation("Predict")' action="set" />
<assign property="callrequest.Variables" value='"ypredsAll,modrmsl"' action="set" />
<assign property="callrequest.Serialization" value='"string"' action="set" />
</request>
<response type='isc.julia.msg.ExecutionResponse'>
<assign property="context.pricePredict" value='callresponse.Variables.GetAt("ypredsAll")'/>
</response>
</call>
<sync name='Wait for Predict' calls='Predict' type='all' />

<assign name="Save Predicted Price" property="status" value="process.FillPricePredict(context.pricePredict)" />
</sequence>
</process>
}

ClassMethod FillPricePredict(data As %String) As %Status
{
	#dim sc As %Status = $$$OK
	
	try {
		set:'$isObject(data) data = [].%FromJSON(data)
		set iterator = data.%GetIterator()
		while iterator.%GetNext(.id, .price) {
			
			set $list(^isc.julia.test.AMESD(id + 1),15) = $number(price, 0)
		}
	} catch ex {
		set sc = ex.AsStatus()
	}
	
	quit sc
}

XData Sample
{
<xml>
<call name='' target='@..%Process.JuliaOperation' async='1'>
<annotation><![CDATA[
]]></annotation>
<request type='isc.julia.msg.ExecutionRequest' >
<assign property="callrequest.Code" value='process.GetAnnotation("")' action="set" />
</request>
<response type='isc.julia.msg.ExecutionResponse' />
</call>
<sync name='Wait for ' calls='' type='all' />
</xml>
}

Storage Default
{
<Data name="ProcessDefaultData">
<Subscript>"Process"</Subscript>
<Value name="1">
<Value>WorkDirectory</Value>
</Value>
<Value name="2">
<Value>JuliaOperation</Value>
</Value>
</Data>
<DefaultData>ProcessDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

