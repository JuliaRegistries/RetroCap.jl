import Pkg
import UUIDs

function new_compat_entry(current_compat_entry::Vector,
                          latest_dep_version::VersionNumber)::String
    return new_compat_entry(latest_dep_version)
end

function new_compat_entry(current_compat_entry::String,
                          latest_dep_version::VersionNumber)::String
    myregex_1 = r"([\d]*)\.([\d]*)\.([\d]*)[\s]*-[\s]*\*"
    if occursin(myregex_1, current_compat_entry)
        m = match(myregex_1, current_compat_entry)
        lower_bound = VersionNumber("$(m[1]).$(m[2]).$(m[3])")
        return new_compat_entry(lower_bound, latest_dep_version)
    else
        return new_compat_entry(latest_dep_version)
    end
end

function new_compat_entry(latest_dep_version::VersionNumber)::String
    lower_bound = v"0"
    return new_compat_entry(lower_bound, latest_dep_version)
end

function _compute_cap_upper_bound(latest_dep_version::VersionNumber)::String
    x = latest_dep_version.major
    y = latest_dep_version.minor
    z = latest_dep_version.patch
    if x == 0
        if y == 0 # x is 0 and y is 0
            return "0.0.$(z)"
        else # x is 0 and y is nonzero
            return "0.$(y)"
        end
    else # x is nonzero
        return "$(x)"
    end
end

function new_compat_entry(lower_bound::VersionNumber,
                          latest_dep_version::VersionNumber)::String
    a = lower_bound.major
    b = lower_bound.minor
    c = lower_bound.patch
    upper_bound = _compute_cap_upper_bound(latest_dep_version)    
    compat = "$(a).$(b).$(c) - $(upper_bound)"
    @assert Pkg.Types.VersionRange(compat) isa Pkg.Types.VersionRange
    return compat
end

function generate_compat_entry(strategy::CapStrategy,
                               current_compat_entry::Union{Vector, String},
                               latest_dep_version::VersionNumber)
    if length(current_compat_entry) == 0
        return new_compat_entry(current_compat_entry, latest_dep_version)
    else
        spec = _entry_to_spec(current_compat_entry)
        return generate_compat_entry(strategy, current_compat_entry, spec, latest_dep_version)
    end
end

function _entry_to_spec(current_compat_entry::String)::Pkg.Types.VersionSpec
    try
        return Pkg.Types.semver_spec(current_compat_entry)
    catch
    end
    r = Pkg.Types.VersionRange(current_compat_entry)
    ranges = Pkg.Types.VersionRange[r]
    spec = Pkg.Types.VersionSpec(ranges)
    return spec
end

function _entry_to_spec(current_compat_entry::Vector{String})::Pkg.Types.VersionSpec
    n = length(current_compat_entry)
    ranges = Vector{Pkg.Types.VersionRange}(undef, n)
    for i = 1:n
        ranges[i] = Pkg.Types.VersionRange(current_compat_entry[i])
    end
    spec = Pkg.Types.VersionSpec(ranges)
end

function generate_compat_entry(::NoCompatEntry,
                               current_compat_entry::Union{Vector, String},
                               spec::Pkg.Types.VersionSpec,
                               latest_dep_version::VersionNumber)
    always_assert( length(current_compat_entry) > 0 )
    return current_compat_entry
end

function generate_compat_entry(::NoUpperBound,
                               current_compat_entry::Union{Vector, String},
                               spec::Pkg.Types.VersionSpec,
                               latest_dep_version::VersionNumber)
    always_assert( length(current_compat_entry) > 0 )
    if has_upper_bound(spec)
        return current_compat_entry
    else
        return new_compat_entry(current_compat_entry, latest_dep_version)
    end
end

function has_upper_bound(spec::Pkg.Types.VersionSpec)::Bool
    return !(typemax(VersionNumber) in spec)
end
