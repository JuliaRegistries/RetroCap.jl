# RetroCap

[![Build Status](https://travis-ci.com/bcbi/RetroCap.jl.svg?branch=master)](https://travis-ci.com/bcbi/RetroCap.jl)
[![Codecov](https://codecov.io/gh/bcbi/RetroCap.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bcbi/RetroCap.jl)

RetroCap retroactively add "caps" (upper-bounded compat entries) to all packages in a registry.

More specifically, RetroCap adds upper-bounded compat entries to every version of every package in a registry **except the latest version of each package**.

## Installation
```julia
] add https://github.com/bcbi/RetroCap.jl#master
```

## Example usage

The recommended strategy is `NoUpperBound`. The `NoUpperBound` strategy will:
1. Add compat entries if they are missing
2. Replace non-upper-bounded compat entries with upper-bounded compat entries

```julia
julia> run(`git clone https://github.com/JuliaRegistries/General.git`)
julia> cd("General")
julia> using RetroCap
julia> add_caps(NoUpperBound(), pwd())
```

The `NoCompatEntry` strategy will only:
1. Add compat entries if they are missing

```julia
julia> run(`git clone https://github.com/JuliaRegistries/General.git`)
julia> cd("General")
julia> using RetroCap
julia> add_caps(NoCompatEntry(), pwd())
```
