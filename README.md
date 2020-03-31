# JuliaGateway
Interface to Julia programming language for InterSystems IRIS. Execute Julia code and more from InterSystems IRIS.
This projects brings you the power of Julia right into your InterSystems IRIS environment:
- Execute arbitrary Julia code
- Seamlessly transfer data from InterSystems IRIS into Julia
- Build intelligent Interoperability business processes with Julia Interoperability Adapter

# ML Toolkit user group

ML Toolkit user group is a private GitHub repository set up as part of InterSystems corporate GitHub organization. It is addressed to the external users that are installing, learning or are already using ML Toolkit components. To join ML Toolkit user group, please send a short e-mail at the following address: [MLToolkit@intersystems.com](mailto:MLToolkit@intersystems.com?subject=MLToolkit%20user%20group&body=Hello.%0A%0APlease%20add%20me%20to%20ML%20Toolkit%20user%20group%3A%0A%0A-%20GitHub%20username%3A%20%0A%0A-%20Name%3A%20%0A%0A-%20Company%3A%20%0A%0A-%20Position%3A%0A-%20Country%3A%20%0A%0A) and indicate in your e-mail the following details (needed for the group members to get to know and identify you during discussions):

- GitHub username
- Full Name (your first name followed by your last name in Latin script)
- Organization (you are working for, or you study at, or your home office)
- Position (your actual position in your organization, or “Student”, or “Independent”)
- Country (you are based in)

# Installation

1. [Install Julia 1.4.0 64 bit](https://julialang.org/downloads/) (other Julia versions are untested). Follow OS specific instructions for installing Julia ([Windows](https://julialang.org/downloads/platform/#windows), [Linux](https://julialang.org/downloads/platform/#linux_and_freebsd), [Mac](https://julialang.org/downloads/platform/#macos)).
2. Download latest JuliaGateway [release](https://github.com/intersystems-ru/JuliaGateway/releases) and unpack it.
4. From the InterSystems IRIS terminal, load ObjectScript code. To do that execute: `do $system.OBJ.ImportDir("/path/to/unpacked/juliagateway","*.cls","c",,1)`) in Production (Ensemble-enabled) namespace. In case you want to Production-enable namespace call: `write ##class(%EnsembleMgr).EnableNamespace($Namespace, 1)`.
5. Place [callout DLL/SO/DYLIB](https://github.com/intersystems-community/JuliaGateway/releases) in the `bin` folder of your InterSystems IRIS installation. Library file should be placed into a path returned by `write ##class(isc.julia.Callout).GetLib()`. 

## Windows 

6. Check that your `JULIA_HOME` environment variable points to Julia 1.4.0.
7. Check that your SYSTEM `PATH` environment variable has:
  - `%JULIA_HOME%\bin` variable (or directory it points to) 
8. Restart InterSystems IRIS.
9. In the InterSystems IRIS Terminal, run:
  - `write $SYSTEM.Util.GetEnviron("JULIA_HOME")` and verify it prints out the directory of Julia installation
  - `write $SYSTEM.Util.GetEnviron("PATH")` and verify it prints out the bin directory of Julia installation
  
 ## Linux and Mac
 
6. Set [LibPath](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RACS_LibPath) configuration parameter to the value of `$JULIA_HOME/lib` (if you installed to `/tmp/julia`, set `LibPath=/tmp/julia/lib`).
7. Restart InterSystems IRIS.

## Post installation (Windows, Mac, Linux)

After installation you'll need these packages. In julia bash run:

```
import Pkg;
Pkg.add(["JSON", "CSV", "DataFrames"])
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

# Terminal API

Generally the main interface to Julia is `isc.julia.Main`. It offers these methods (all return `%Status`), which can be separated into three categories:
- Code execution
- Data transfer
- Auxiliary

## Code execution

These methods allow execution of arbitrary Julia code:

- `ImportModule(module)` -  import module.
- `SimpleString(code, .result)` - execute `code` for cases where both `code` and `result` are less than `$$$MaxStringLength` in length.
- `ExecuteCode(code, variable, .result)` - execute `code` (it may be a stream or string), optionally set code into `variable`.

## Data Transfer

Transfer data into and from Julia.

### Julia -> InterSystems IRIS

- `GetVariable(variable, serialization, .stream, useString)` - get `serialization` of `variable` in `stream`. If `useString` is 1 and variable serialization can fit into string then string is returned instead of the stream.

### InterSystems IRIS -> Julia

- `ExecuteQuery(query, variable, type, namespace)` - create `DataFrame` from sql `query` and set it into `variable`. `isc.julia` package must be available in `namespace` (Available `type` is `DataFrame`).

## Auxiliary

Support methods.

- `GetVariableInfo(variable, serialization, .defined, .type, .length)` - get info about variable: is it defined, type and serialized length.
- `GetVariableDefined(variable, .defined)` - is variable defined.
- `GetVariableType(variable, .type)` - get variable FQCN.

Possible Serializations:
- `string` - Serialization by `string()` function
- `json` - Serialization by `JSON` module

# Shell

To open Julia shell: `do ##class(isc.julia.util.Shell).Shell()`. To exit press enter.

In `rtn` folder `zj` command example is also available. Import into `%SYS` namespace.

# Interoperability adapter

Interoperability adapter `isc.julia.ens.Operation` offers ability to interact with Julia process from Interoperability productions. Currently three requests are supported:

- Execute Julia code via `isc.julia.msg.ExecutionRequest`. Returns `isc.julia.msg.ExecutionResponse` with requested variable values
- Execute Julia code via `isc.julia.msg.StreamExecutionRequest`. Returns `isc.julia.msg.StreamExecutionResponse` with requested variable values. Same as above, but accepts and returns streams instead of strings.
- Set dataset from SQL Query with `isc.julia.msg.QueryRequest`. Returns `Ens.Response`.


Check request/response classes documentation for details.

Settings:
 - `Initializer` - select a class implementing `isc.julia.init.Abstract`. It can be used to load functions, modules, classes and so on. It would be executed at process start.
 
# Test Business process

1. Execute in OS bash:
```
import Pkg;
Pkg.add(["JSON", "CSV", "DataFrames", "MLJ", "MLJModels", "Statistics", "MultivariateStats", "NearestNeighbors"])
using CSV, DataFrames, MLJ, MLJModels, Statistics, MultivariateStats, NearestNeighbors
```

2. In InterSystems IRIS terminal execute: `write ##class(isc.julia.test.AMES).Import()` to load the dataset.
3. Start `isc.julia.test.Production` production.
4. Send empty `Ens.Request` message to the `isc.julia.test.Process`.


## Variable substitution

All business processes inheriting from `isc.julia.ens.ProcessUtils` can use `GetAnnotation(name)` method to get value of activity annotation by activity name. Activity annotation can contain variables which would be calculated on ObjectScript side before being passed to Julia. This is the syntax for variable substitution:

- `${class:method:arg1:...:argN}` - execute method
- `#{expr}` - execute ObjectScript code

Example: `save(r'#{process.WorkDirectory}SHOWCASE${%PopulateUtils:Integer:1:100}.png')`

In this example:
- `#{process.WorkDirectory}` returns WorkDirectory property of `process` object which is an instance of the current business process.
- `${%PopulateUtils:Integer:1:100}` calls `Integer` method of `%PopulateUtils` class passing arguments `1` and `100`, returning random integer in range `1...100`.

# Unit tests

To run tests execute:

```
set repo = ##class(%SourceControl.Git.Utils).TempFolder()
set ^UnitTestRoot = ##class(%File).SubDirectoryName(##class(%File).SubDirectoryName(##class(%File).SubDirectoryName(repo,"isc"),"julia"),"unit",1)
set sc = ##class(%UnitTest.Manager).RunTest(,"/nodelete")
```

# ZLANGC00

Install ZLANG routine from `rtn` folder to add `zj` command:

```
zj "sqrt(2)"
zj
```

Argumentless `zpy` command opens Julia shell.

# Limitations

There are several limitations associated with the use of JuliaGateway.

1. `Pkg` is not supported on Windows.
2. Variables. Do not use these variables: `zzz*` variables. Please report any leakage of these variables. System code should always clear them.
3. Functions  Do not redefine `zzz*()` functions.

# Development

Development of ObjectScript is done via [cache-tort-git](https://github.com/MakarovS96/cache-tort-git) in UDL mode. 
Development of C code is done in Eclipse.

# Commits

Commits should follow the pattern: `moule: description issue`. List of modules:

- Callout - C and ObjectScript callout interface in `isc.julia.Callout`.
- API - terminal API, mainly `isc.julia.Main`.
- Interoperability - support utilities for Interoperability Business Processes.
- Tests - unit tests and test production.
- Docker - containers.
- Docs - documentation.

# Building

## Windows

1. Install [MinGW-w64](https://sourceforge.net/projects/mingw-w64/) you'll need `make` and `gcc`. 
2. Rename `mingw32-make.exe` to `make.exe` in `mingw64\bin` directory.
3. Set `GLOBALS_HOME` environment variable to the root of InterSystems IRIS installation.
4. Set `JULIA_HOME` environment variable to the root of Julia installation.
5. Open MinGW bash (`mingw64env.cmd` or `mingw-w64.bat`).
6. In `<Repository>\c\` execute `make`.

## Linux / Mac

1. Install Julia.
2. Install: `apt install build-essential` (for Mac install gcc compiler and make).
3. Set `GLOBALS_HOME` environment variable to the root of InterSystems IRIS installation.
4. Set `JULIA_HOME` environment variable to the root of Julia installation.
5. In `<Repository>/c/` execute `make`.
