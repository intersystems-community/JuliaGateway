# JuliaGateway
Interface to Julia programming language for InterSystems IRIS. Execute Julia code and more from InterSystems IRIS.
This projects brings you the power of Julia right into your InterSystems IRIS environment:
- Execute arbitrary Julia code
- Seamlessly transfer data from InterSystems IRIS into Julia
- Build intelligent Interoperability business processes with Julia Interoperability Adapter
- Save, examine, modify and restore Julia context from InterSystems IRIS
 
# ML Toolkit user group

ML Toolkit user group is a private GitHub repository set up as part of InterSystems corporate GitHub organization. It is addressed to the external users that are installing, learning or are already using ML Toolkit components. To join ML Toolkit user group, please send a short e-mail at the following address: [MLToolkit@intersystems.com](mailto:MLToolkit@intersystems.com?subject=MLToolkit%20user%20group&body=Hello.%0A%0APlease%20add%20me%20to%20ML%20Toolkit%20user%20group%3A%0A%0A-%20GitHub%20username%3A%20%0A%0A-%20Name%3A%20%0A%0A-%20Company%3A%20%0A%0A-%20Position%3A%0A-%20Country%3A%20%0A%0A) and indicate in your e-mail the following details (needed for the group members to get to know and identify you during discussions):

- GitHub username
- Full Name (your first name followed by your last name in Latin script)
- Organization (you are working for, or you study at, or your home office)
- Position (your actual position in your organization, or “Student”, or “Independent”)
- Country (you are based in)

# Installation

1. [Install Julia 1.4.0 64 bit](https://julialang.org/downloads/) (other Julia versions are untested). 
2. Download latest JuliaGateway [release](https://github.com/intersystems-ru/JuliaGateway/releases) and unpack it.
4. From the InterSystems IRIS terminal, load ObjectScript code. To do that execute: `do $system.OBJ.ImportDir("/path/to/unpacked/juliagateway","*.cls","c",,1)`) in Production (Ensemble-enabled) namespace. In case you want to Production-enable namespace call: `write ##class(%EnsembleMgr).EnableNamespace($Namespace, 1)`.
5. Place [callout DLL/SO/DYLIB](https://github.com/intersystems-community/JuliaGateway/releases) in the `bin` folder of your InterSystems IRIS installation. Library file should be placed into a path returned by `write ##class(isc.julia.Callout).GetLib()`. 

## Windows 

6. Check that your `JULIA_HOME` environment variable points to Julia 1.4.0.
7. Check that your SYSTEM `PATH` environment variable has:
  - `%JULIA_HOME%\bin` variable (or directory it points to) 
8. In the InterSystems IRIS Terminal, run:
  - `write $SYSTEM.Util.GetEnviron("JULIA_HOME")` and verify it prints out the directory of Julia installation
  - `write $SYSTEM.Util.GetEnviron("PATH")` and verify it prints out the bin directory of Julia installation
  
 ## Linux and Mac
 
6. Check that your `JULIA_HOME` environment variable points to Julia 1.4.0.
7. Check that your SYSTEM `PATH` environment variable has:
  - `$JULIA_HOME%/bin` variable (or directory it points to) 
8. Set [LibPath](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RACS_LibPath) configuration parameter to the value of `$JULIA_HOME/lib` (if you installed to `/tmp/julia`, set `LibPath=/tmp/julia/lib`).
9. Restart InterSystems IRIS.

## Post installation (Windows, Mac, Linux)

After installation you'll need these packages. In julia bash run:

```
import Pkg;
Pkg.add(["CSV", "DataFrames"])
using CSV, DataFrames
```

## Docker

1. To build docker image:
  - Copy `iscjulia.so` into repository root (if it's not there already)
  - Execute in the repository root `docker build --force-rm --tag intersystemscommunity/irisjulia:latest .` By default the image is built upon `store/intersystems/iris-community:2019.4.0.383.0` image, however you can change that by providing `IMAGE` variable. To build from InterSystems IRIS execute: `docker build  --build-arg IMAGE=store/intersystems/iris:2019.4.0.383.0 --force-rm --tag intersystemscommunity/irisjulia:latest .`
2. To run docker image execute (key is not needed for Community based images): 

```
docker run -d \
  -p 52773:52773 \
  -v /<HOST-DIR-WITH-iris.key>/:/mount \
  --name iris \
  intersystemscommunity/irisjulia:latest \
  --key /mount/iris.key \
```
3. For terminal access execute: `docker exec -it iris iris session iris`.
5. Access SMP with SuperUser/SYS or Admin/SYS user/password.
6. To stop container execute: `docker stop iris && docker rm --force iris`.

# Use

1. Call: `set sc = ##class(isc.julia.Callout).Setup()` once per systems start (add to ZSTART: [docs](https://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=GSTU_customize#GSTU_customize_startstop), sample routine available in `rtn` folder).
2. Initialize julia once per process start: `set sc = ##class(isc.julia.Callout).Initialize()`
2. Call main method (can be called many times, context persists): `write ##class(isc.julia.Main).SimpleString(code, .result)`
3. Call: `set sc = ##class(isc.julia.Callout).Finalize()` to free Julia context.
4. Call: `set sc = ##class(isc.julia.Callout).Unload()` to free callout library.

```
set sc = ##class(isc.julia.Callout).Setup() 
set sc = ##class(isc.julia.Callout).Initialize()
set sc = ##class(isc.julia.Main).SimpleString("sqrt(4)", .result)
write result
set sc = ##class(isc.julia.Callout).Finalize()
set sc = ##class(isc.julia.Callout).Unload()
```

# Test Business process

1. Execute in OS bash:
```
import Pkg;
Pkg.add(["CSV", "DataFrames", "MLJ", "MLJModels", "Statistics", "MultivariateStats", "NearestNeighbors"])
using CSV, DataFrames, MLJ, MLJModels, Statistics, MultivariateStats, NearestNeighbors
```

2. In InterSystems IRIS terminal execute: `write ##class(isc.julia.test.AMES).Import()` to load the dataset.
3. Start `isc.julia.test.Production` production.
4. Send empty `Ens.Request` message to the `isc.julia.test.Process`.
