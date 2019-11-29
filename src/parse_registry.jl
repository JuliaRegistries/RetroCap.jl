import Pkg
import UUIDs

function get_all_versions(registry_path::String, pkg_path::String)::Vector{VersionNumber}
    versions_toml = Pkg.TOML.parsefile(joinpath(registry_path, pkg_path, "Versions.toml"))
    all_versions = VersionNumber.(collect(keys(versions_toml)))
    unique!(all_versions)
    sort!(all_versions)
    return all_versions
end

function parse_registry(registry_path::String)
    pkg_to_path = Dict{Package, String}()
    pkg_to_num_versions = Dict{Package, Int}()
    pkg_to_latest_version = Dict{Package, VersionNumber}()
    parse_registry!(pkg_to_path,
                    pkg_to_num_versions,
                    pkg_to_latest_version,
                    registry_path)
    return pkg_to_path, pkg_to_num_versions, pkg_to_latest_version
end

function parse_registry!(pkg_to_path::AbstractDict{Package, String},
                         pkg_to_num_versions::AbstractDict{Package, Int},
                         pkg_to_latest_version::AbstractDict{Package, VersionNumber},
                         registry_path::String)
    registry = Pkg.TOML.parsefile(joinpath(registry_path, "Registry.toml"))
    packages = registry["packages"]
    for p in packages
        name = p[2]["name"]
        pkg_path = p[2]["path"]
        if !is_jll(name)
            all_versions = get_all_versions(registry_path, pkg_path)
            num_versions = length(all_versions)
            latest_version = maximum(all_versions)
            pkg = Package(name)
            pkg_to_path[pkg] = pkg_path
            pkg_to_num_versions[pkg] = num_versions
            pkg_to_latest_version[pkg] = latest_version
        end
    end
    return nothing
end
