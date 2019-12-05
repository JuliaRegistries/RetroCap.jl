import Pkg
import UUIDs

function recompress(registry_path::AbstractString)
    registry_file = joinpath(registry_path, "Registry.toml")
    packages = Pkg.TOML.parsefile(registry_file)["packages"]
    version_map = Dict{String,Vector{VersionNumber}}()
    
    for (uuid, info) in packages
        name = info["name"]
        if !Compress.is_jll_name(name)
            path = joinpath(registry_path, info["path"])
            versions_file = joinpath(path, "Versions.toml")
            versions = Compress.load(versions_file)
            version_map[uuid] = sort!(collect(keys(versions)))
        end
    end
    
    for (_, info) in packages
        path = joinpath(registry_path, info["path"])
        # load and normalize Deps.toml
        deps_file = joinpath(path, "Deps.toml")
        isfile(deps_file) || continue
        deps = Compress.load(deps_file)
        Compress.save(deps_file, deps)
        # load and normalize Compat.toml
        compat_file = joinpath(path, "Compat.toml")
        isfile(compat_file) || continue
        compat = Compress.load(compat_file)
        for (ver, data) in compat
            for (dep, spec) in data
                ranges = Pkg.Types.VersionSpec(spec).ranges
                compat[ver][dep] =
                    length(ranges) == 1 ? string(ranges[1]) : map(string, ranges)
            end
        end
        Compress.save(compat_file, compat)
    end
    
    return nothing
end

