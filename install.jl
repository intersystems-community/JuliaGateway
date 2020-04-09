using Pkg
packages = ["JSON", "CSV", "DataFrames", "MLJ", "MLJModels", "Statistics", "MultivariateStats", "NearestNeighbors"]
Pkg.add(packages)
using JSON, CSV, DataFrames, MLJ, MLJModels, Statistics, MultivariateStats, NearestNeighbors