import Pkg
import UUIDs

@inline function get_all_versions(pkg_path::String)::Vector{VersionNumber}
    versions_toml = Pkg.TOML.parsefile(joinpath(pkg_path, "Versions.toml"))
    all_versions = VersionNumber.(collect(keys(versions_toml)))
    unique!(all_versions)
    sort!(all_versions)
    return all_versions
end

@inline function _get_latest_version(versions::AbstractVector{VersionNumber})
    return maximum(versions)
end

@inline function _get_latest_zero_version(versions::AbstractVector{VersionNumber})
    all_zero_versions = filter((x) -> (x < v"1"), versions)
    if isempty(all_zero_versions)
        return nothing
    else
        latest_zero_version = maximum(all_zero_versions)
        always_assert(latest_zero_version < v"1", "latest_zero_version < v\"1\"")
        return latest_zero_version
    end
end

@inline function parse_registry(registry_paths::Vector{String})
    pkg_to_path = Dict{Package, String}()
    pkg_to_num_versions = Dict{Package, Int}()
    pkg_to_latest_version = Dict{Package, VersionNumber}()
    pkg_to_latest_zero_version = Dict{Package, Union{VersionNumber, Nothing}}()
    parse_registry!(pkg_to_path,
                    pkg_to_num_versions,
                    pkg_to_latest_version,
                    pkg_to_latest_zero_version,
                    registry_paths)
    return pkg_to_path,
           pkg_to_num_versions,
           pkg_to_latest_version,
           pkg_to_latest_zero_version
end

@inline function parse_registry!(pkg_to_path::AbstractDict{Package, String},
                                 pkg_to_num_versions::AbstractDict{Package, Int},
                                 pkg_to_latest_version::AbstractDict{Package, VersionNumber},
                                 pkg_to_latest_zero_version::AbstractDict{Package, <:Union{VersionNumber, Nothing}},
                                 registry_paths::Vector{String})
    for path in registry_paths
        parse_registry!(pkg_to_path,
                        pkg_to_num_versions,
                        pkg_to_latest_version,
                        pkg_to_latest_zero_version,
                        path)
    end
    return pkg_to_path,
           pkg_to_num_versions,
           pkg_to_latest_version,
           pkg_to_latest_zero_version
end

@inline function parse_registry!(pkg_to_path::AbstractDict{Package, String},
                                 pkg_to_num_versions::AbstractDict{Package, Int},
                                 pkg_to_latest_version::AbstractDict{Package, VersionNumber},
                                 pkg_to_latest_zero_version::AbstractDict{Package, <:Union{VersionNumber, Nothing}},
                                 registry_path::String)
    registry = Pkg.TOML.parsefile(joinpath(registry_path, "Registry.toml"))
    packages = registry["packages"]
    for p in packages
        name = p[2]["name"]
        pkg_path = joinpath(registry_path, p[2]["path"])
        if !is_jll(name)
            all_versions = get_all_versions(pkg_path)
            num_versions = length(all_versions)
            latest_version = _get_latest_version(all_versions)
            latest_zero_version = _get_latest_zero_version(all_versions)
            pkg = Package(name)
            pkg_to_path[pkg] = pkg_path
            pkg_to_num_versions[pkg] = num_versions
            pkg_to_latest_version[pkg] = latest_version
            pkg_to_latest_zero_version[pkg] = latest_zero_version
        end
    end
    return nothing
end
