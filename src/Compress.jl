module Compress

import Pkg
import UUIDs

import Pkg.TOML
import Pkg.Types: VersionSpec, VersionRange, VersionBound

"""
    compress_versions(pool::Vector{VersionNumber}, subset::Vector{VersionNumber})

Given `pool` as the pool of available versions (of some package) and `subset` as some
subset of the pool of available versions, this function computes a `VersionSpec` which
includes all versions in `subset` and none of the versions in its complement.
"""
@inline function compress_versions(pool::Vector{VersionNumber},
                                   subset::Vector{VersionNumber})
    # Explicitly drop prerelease/build numbers, as those can confuse this.
    # TODO: Rewrite all this to use VersionNumbers instead of VersionBounds
    drop_build_prerelease(v::VersionNumber) = VersionNumber(v.major, v.minor, v.patch)
    pool = drop_build_prerelease.(pool)
    subset = sort!(drop_build_prerelease.(subset))

    complement = sort!(setdiff(pool, subset))
    ranges = VersionRange[]
    @label again
    isempty(subset) && return VersionSpec(ranges)
    a = first(subset)
    for b in reverse(subset)
        a.major == b.major || continue
        for m = 1:3
            lo = VersionBound((a.major, a.minor, a.patch)[1:m]...)
            for n = 1:3
                hi = VersionBound((b.major, b.minor, b.patch)[1:n]...)
                r = VersionRange(lo, hi)
                if !any(v in r for v in complement)
                    filter!(!in(r), subset)
                    push!(ranges, r)
                    @goto again
                end
            end
        end
    end
end

# @inline function compress_versions(pool::Vector{VersionNumber}, subset)
#     compress_versions(pool, filter(in(subset), pool))
# end

@inline function load_versions(path::String)
    versions_file = joinpath(dirname(path), "Versions.toml")
    versions_dict = TOML.parsefile(versions_file)
    sort!([VersionNumber(v) for v in keys(versions_dict)])
end

@inline function load(path::String,
                      versions::Vector{VersionNumber} = load_versions(path))
    compressed = TOML.parsefile(path)
    uncompressed = Dict{VersionNumber,Dict{Any,Any}}()
    for (vers, data) in compressed
        vs = VersionSpec(vers)
        for v in versions
            v in vs || continue
            merge!(get!(uncompressed, v, Dict()), deepcopy(data))
        end
    end
    return uncompressed
end

@inline function compress(path::String,
                          uncompressed::Dict,
                          versions::Vector{VersionNumber} = load_versions(path))
    inverted = Dict()
    for (ver, data) in uncompressed, (key, val) in data
        val isa TOML.TYPE || (val = string(val))
        push!(get!(inverted, key => val, VersionNumber[]), ver)
    end
    compressed = Dict()
    for ((k, v), vers) in inverted
        for r in compress_versions(versions, sort!(vers)).ranges
            get!(compressed, string(r), Dict{String,Any}())[k] = v
        end
    end
    return compressed
end

@inline function save(path::String,
                      uncompressed::Dict,
                      versions::Vector{VersionNumber} = load_versions(path))
    compressed = compress(path, uncompressed)
    open(path, write=true) do io
        TOML.print(io, compressed, sorted=true)
    end
end

end # module
