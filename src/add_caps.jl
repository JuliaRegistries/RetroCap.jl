import Pkg
import UUIDs

@inline function add_caps(strategy::CapStrategy,
                          registry_path::AbstractString)
    _registry_path = convert(String, registry_path)::String
    add_caps(strategy, _registry_path)
    return nothing
end

@inline function add_caps(strategy::CapStrategy,
                          registry_path::String)
    pkg_to_path,
        pkg_to_num_versions,
        pkg_to_latest_version,
        pkg_to_latest_zero_version = parse_registry(registry_path)
    add_caps(strategy,
             registry_path,
             pkg_to_path,
             pkg_to_num_versions,
             pkg_to_latest_version,
             pkg_to_latest_zero_version)
    return nothing
end

@inline function add_caps(strategy::CapStrategy,
                          registry_path::String,
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
                 registry_path,
                 pkg_to_latest_version,
                 pkg_to_latest_zero_version,
                 pkg,
                 pkg_path)
    end
    return nothing
end

@inline function add_caps(strategy::CapStrategy,
                          registry_path::String,
                          pkg_to_latest_version::AbstractDict{Package, VersionNumber},
                          pkg_to_latest_zero_version::AbstractDict{Package, <:Union{VersionNumber, Nothing}},
                          pkg::Package,
                          pkg_path::String)
    all_versions = get_all_versions(registry_path, pkg_path)
    latest_version = _get_latest_version(all_versions)
    compat_toml = joinpath(registry_path, pkg_path, "Compat.toml")
    deps_toml = joinpath(registry_path, pkg_path, "Deps.toml")
    if isfile(compat_toml) && isfile(deps_toml)
        compat = Compress.load(compat_toml)
        deps = Compress.load(deps_toml)
        m = length(all_versions)
        for j = 1:m
            version = all_versions[j]
            if version != latest_version
                add_caps!(compat,
                          deps,
                          strategy,
                          registry_path,
                          pkg_to_latest_version,
                          pkg_to_latest_zero_version,
                          pkg,
                          pkg_path,
                          version)
            end
        end
        Compress.save(compat_toml, compat)
    end
    return nothing
end

@inline function add_caps!(compat::AbstractDict{VersionNumber, <:Any},
                           deps::AbstractDict{VersionNumber, <:Any},
                           strategy::CapStrategy,
                           registry_path::String,
                           pkg_to_latest_version::AbstractDict{Package, VersionNumber},
                           pkg_to_latest_zero_version::AbstractDict{Package, <:Union{VersionNumber, Nothing}},
                           pkg::Package,
                           pkg_path::String,
                           version::VersionNumber)
    if haskey(deps, version)
        always_assert(haskey(compat, version))
        for dep in keys(deps[version])
            if !is_stdlib(dep) && !is_jll(dep)
                latest_dep_version = pkg_to_latest_version[Package(dep)]
                latest_dep_zero_version = pkg_to_latest_zero_version[Package(dep)]
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
