import Pkg
import RegistryTools
import UUIDs

function add_caps(strategy::CapStrategy,
                  option::LatestVersionOption,
                  registry_path::AbstractString)
    _registry_paths = Any[registry_path]
    add_caps(strategy, option, _registry_paths)
    return nothing
end

function add_caps(strategy::CapStrategy,
                  option::LatestVersionOption,
                  registry_paths::AbstractVector)
    _registry_paths = Vector{String}(undef, 0)
    for path in registry_paths
        push!(_registry_paths, strip(path))
    end
    add_caps(strategy, option, _registry_paths)
    return nothing
end

function add_caps(strategy::CapStrategy,
                  option::LatestVersionOption,
                  registry_path::AbstractString,
                  pkg::Package)
    _registry_paths = String[registry_path]
    pkg_to_path,
        pkg_to_num_versions,
        pkg_to_latest_version,
        pkg_to_latest_zero_version = parse_registry(_registry_paths)
    add_caps(strategy,
             option,
             _registry_paths,
             pkg_to_latest_version,
             pkg_to_latest_zero_version,
             pkg,
             pkg_to_path[pkg])
    return nothing
end

function add_caps(strategy::CapStrategy,
                  option::LatestVersionOption,
                  registry_paths::Vector{String})
    pkg_to_path,
        pkg_to_num_versions,
        pkg_to_latest_version,
        pkg_to_latest_zero_version = parse_registry(registry_paths)
    add_caps(strategy,
             option,
             registry_paths,
             pkg_to_path,
             pkg_to_num_versions,
             pkg_to_latest_version,
             pkg_to_latest_zero_version)
    return nothing
end

function add_caps(strategy::CapStrategy,
                  option::LatestVersionOption,
                  registry_paths::Vector{String},
                  pkg_to_path::AbstractDict{Package, String},
                  pkg_to_num_versions::AbstractDict{Package, Int},
                  pkg_to_latest_version::AbstractDict{Package, VersionNumber},
                  pkg_to_latest_zero_version::AbstractDict{Package, <:Union{VersionNumber, Nothing}})
    all_pkgs = collect(keys(pkg_to_path))
    n = length(all_pkgs)
    for i = 1:n
        pkg = all_pkgs[i]
        @debug("Package $(i) of $(n)", pkg)
        pkg_path = pkg_to_path[pkg]::String
        add_caps(strategy,
                 option,
                 registry_paths,
                 pkg_to_latest_version,
                 pkg_to_latest_zero_version,
                 pkg,
                 pkg_path)
    end
    return nothing
end

function add_caps(strategy::CapStrategy,
                  option::LatestVersionOption,
                  registry_paths::Vector{String},
                  pkg_to_latest_version::AbstractDict{Package, VersionNumber},
                  pkg_to_latest_zero_version::AbstractDict{Package, <:Union{VersionNumber, Nothing}},
                  pkg::Package,
                  pkg_path::String)
    all_versions = get_all_versions(pkg_path)
    latest_version = _get_latest_version(all_versions)
    compat_toml = joinpath(pkg_path, "Compat.toml")
    deps_toml = joinpath(pkg_path, "Deps.toml")
    if isfile(compat_toml) && isfile(deps_toml)
        compat = RegistryTools.Compress.load(compat_toml)
        deps = RegistryTools.Compress.load(deps_toml)
        m = length(all_versions)
        for j = 1:m
            version = all_versions[j]
            if (version != latest_version) | (option isa CapLatestVersion)
                add_caps!(compat,
                          deps,
                          strategy,
                          registry_paths,
                          pkg_to_latest_version,
                          pkg_to_latest_zero_version,
                          pkg,
                          pkg_path,
                          version)
            end
        end
        RegistryTools.Compress.save(compat_toml, compat)
    end
    return nothing
end

function add_caps(strategy::MonotonicUpperBound,
                  option::LatestVersionOption,
                  registry_paths::Vector{String},
                  pkg_to_latest_version::AbstractDict{Package, VersionNumber},
                  pkg_to_latest_zero_version::AbstractDict{Package, <:Union{VersionNumber, Nothing}},
                  pkg::Package,
                  pkg_path::String)
    option isa CapLatestVersion || error("MonotonicUpperBound requires CapLatestVersion")
    all_versions = get_all_versions(pkg_path)
    latest_version = _get_latest_version(all_versions)
    compat_toml = joinpath(pkg_path, "Compat.toml")
    deps_toml = joinpath(pkg_path, "Deps.toml")
    if isfile(compat_toml) && isfile(deps_toml)
        compat = RegistryTools.Compress.load(compat_toml)
        deps = RegistryTools.Compress.load(deps_toml)
        m = length(all_versions)
        # Bound the latest version
        version = all_versions[end]
        add_caps!(compat,
                  deps,
                  UpperBound(),
                  registry_paths,
                  pkg_to_latest_version,
                  pkg_to_latest_zero_version,
                  pkg,
                  pkg_path,
                  version)
        # Propagate the bounds backwards
        for j = m-1:-1:1
            lastcompat = compat[version]
            version = all_versions[j]
            pkg_to_latest_version_tmp = copy(pkg_to_latest_version)
            pkg_to_latest_zero_version_tmp = copy(pkg_to_latest_zero_version)
            monotonize!(pkg_to_latest_version_tmp, lastcompat)
            monotonize!(pkg_to_latest_zero_version_tmp, lastcompat)
            add_caps!(compat,
                      deps,
                      UpperBound(),
                      registry_paths,
                      pkg_to_latest_version_tmp,
                      pkg_to_latest_zero_version_tmp,
                      pkg,
                      pkg_path,
                      version)
        end
        RegistryTools.Compress.save(compat_toml, compat)
    end
    return nothing
end

function add_caps!(compat::AbstractDict{VersionNumber, <:Any},
                   deps::AbstractDict{VersionNumber, <:Any},
                   strategy::CapStrategy,
                   registry_paths::Vector{String},
                   pkg_to_latest_version::AbstractDict{Package, VersionNumber},
                   pkg_to_latest_zero_version::AbstractDict{Package, <:Union{VersionNumber, Nothing}},
                   pkg::Package,
                   pkg_path::String,
                   version::VersionNumber)
    if haskey(deps, version)
        get!(() -> Dict{Any, Any}(), compat, version)
        always_assert(haskey(compat, version), "haskey(compat, version); pkg=$(pkg)")
        for dep in keys(deps[version])
            pdep = Package(dep)
            if !is_stdlib(dep) && !is_jll(dep) && haskey(pkg_to_latest_version, pdep)
                latest_dep_version = pkg_to_latest_version[pdep]
                latest_dep_zero_version = pkg_to_latest_zero_version[pdep]
                current_compat_for_dep = _strip(get(compat[version], dep, ""))
                new_compat_for_dep = generate_compat_entry(pkg,
                                                           Package(dep),
                                                           strategy,
                                                           current_compat_for_dep,
                                                           latest_dep_version,
                                                           latest_dep_zero_version)
                compat[version][dep] = new_compat_for_dep
            end
        end
    end
    return nothing
end
