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

1. [Install Julia 1.3.1 64 bit]https://julialang.org/downloads/) (other Julia versions are untested). 
2. Download latest JuliaGateway [release](https://github.com/intersystems-ru/JuliaGateway/releases) and unpack it.
4. From the InterSystems IRIS terminal, load ObjectScript code. To do that execute: `do $system.OBJ.ImportDir("/path/to/unpacked/juliagateway","*.cls","c",,1)`) in Production (Ensemble-enabled) namespace. In case you want to Production-enable namespace call: `write ##class(%EnsembleMgr).EnableNamespace($Namespace, 1)`.
5. Place [callout DLL/SO/DYLIB](https://github.com/intersystems-community/JuliaGateway/releases) in the `bin` folder of your InterSystems IRIS installation. Library file should be placed into a path returned by `write ##class(isc.julia.Callout).GetLib()`. 

## Windows 

6. Check that your `JULIA_HOME` environment variable points to Julia 1.3.1.
7. Check that your SYSTEM `PATH` environment variable has:
  - `%JULIA_HOME%\bin` variable (or directory it points to) 
8. In the InterSystems IRIS Terminal, run:
  - `write $SYSTEM.Util.GetEnviron("JULIA_HOME")` and verify it prints out the directory of Julia installation
  - `write $SYSTEM.Util.GetEnviron("PATH")` and verify it prints out the bin directory of Julia installation
