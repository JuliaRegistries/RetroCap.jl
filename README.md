# RetroCap

[![Build Status](https://travis-ci.com/bcbi/RetroCap.jl.svg?branch=master)](https://travis-ci.com/bcbi/RetroCap.jl)
[![Codecov](https://codecov.io/gh/bcbi/RetroCap.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bcbi/RetroCap.jl)

RetroCap retroactively add "caps" (upper-bounded `[compat]` entries) to all
packages in one or more Julia package registries.

More specifically, RetroCap iterates over each registry in a list of one
or more registries. For each registry, RetroCap iterates over each package
in the registry. For each package, RetroCap iterates over each of the
package's registered versions. For each registered version of the package,
RetroCap iterates over each of the package's dependencies. For each
dependency:
- If the package does not have a `[compat]` entry for the dependency, then RetroCap adds an upper-bounded `[compat]` entry for the dependency.
- If the package has a `[compat]` entry for the dependency but the `[compat]` entry is not upper-bounded, then RetroCap replaces the original `[compat]` entry with an upper-bounded `[compat]` entry for the dependency.

There are two main "strategies" for adding bounds:
- `UpperBound` ensures the application of upper bounds, adding the latest version as an upper bound if needed.
- `MonotonicUpperBound` ensures that upper bounds are "monotonic," meaning that older releases have older dependencies.

## Installation
```julia
Pkg.add("RetroCap")
```

## Example

### Run on all repos in a registry

To cap all versions of all packages, use the `CapLatestVersion()` option:
```julia
julia> run(`git clone https://github.com/JuliaRegistries/General.git`)
julia> cd("General")
julia> using RetroCap
julia> add_caps(UpperBound(), CapLatestVersion(), pwd())  # or use MonotonicUpperBound
```
To cap all versions of all packages EXCEPT for the latest version of each
package, use the `ExcludeLatestVersion()` option:
```julia
julia> run(`git clone https://github.com/JuliaRegistries/General.git`)
julia> cd("General")
julia> using RetroCap
julia> add_caps(UpperBound(), ExcludeLatestVersion(), pwd())
```

### Run only on repos in a specific GitHub organization

```julia
using GitHub
using RetroCap

orgrepos, page_data = GitHub.repos("MY_GITHUB_ORGANIZATION")

run(`git clone https://github.com/JuliaRegistries/General.git`)

cd("General")

pkgs = RetroCap.Package[]
for r in orgrepos
    name = r.name
    if endswith(name, ".jl")
        push!(pkgs, RetroCap.Package(name[1:end-3]))
    end
end
unique!(pkgs)

pkg_to_path,
    pkg_to_num_versions,
    pkg_to_latest_version,
    pkg_to_latest_zero_version = RetroCap.parse_registry(String[pwd()])

for pkg in pkgs
    try
        add_caps(MonotonicUpperBound(),    # or use `UpperBound()`
                 CapLatestVersion(),
                 String[pwd()],
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

- This work was supported in part by National Institutes of Health grants U54GM115677, R01LM011963, R25MH116440, and R01DC010381. The content is solely the responsibility of the authors and does not necessarily represent the official views of the National Institutes of Health.
