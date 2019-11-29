# RetroCap

[![Build Status](https://travis-ci.com/bcbi/RetroCap.jl.svg?branch=master)](https://travis-ci.com/bcbi/RetroCap.jl)
[![Codecov](https://codecov.io/gh/bcbi/RetroCap.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bcbi/RetroCap.jl)

RetroCap retroactively add "caps" (upper-bounded compat entries) to all
packages in a registry.

More specifically, RetroCap adds upper-bounded compat entries to every
version of every package in a
registry **except the latest version of each package**.

## Installation
```julia
Pkg.add("RetroCap")
```

## Example

### Run on all repos in a registry

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

### Run only on repos in a specific GitHub organization

First, define an environment variable named `GITHUB_AUTH` that contains a
GitHub personal access token. Then, run the following script:

```julia
using GitHub

using RetroCap

auth = GitHub.authenticate("ENV["GITHUB_AUTH"]")

orgrepos = GitHub.repos("MY_GITHUB_ORGANIZATION", auth = auth)[1]

run(`git clone https://github.com/JuliaRegistries/General.git`)

cd("General")

pkgs = [RetroCap.Package(r.name[1:end-3]) for r in orgrepos]

pkg_to_path,
    pkg_to_num_versions,
    pkg_to_latest_version,
    pkg_to_latest_zero_version = RetroCap.parse_registry(pwd())

for pkg in pkgs
    try
        add_caps(NoUpperBound(),
                 pwd(),
                 pkg_to_latest_version,
                 pkg_to_latest_zero_version,
                 pkg,
                 pkg_to_path[pkg])
    catch
        println("Package $(pkg) not affected")
    end
end
```

## Acknowledgements

- This work was supported in part by National Institutes of Health grants U54GM115677, R01LM011963, and R25MH116440. The content is solely the responsibility of the authors and does not necessarily represent the official views of the National Institutes of Health.
