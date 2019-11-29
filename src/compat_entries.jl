import Pkg
import UUIDs

function new_compat_entry(current_compat_entry::Vector,
                          latest_dep_version::VersionNumber)::String
    return new_compat_entry(latest_dep_version)
end

function _extract_lower_bound(current_compat_entry::String)
    myregex1 = r"([\d]*)\.([\d]*)\.([\d]*)[\s]*-[\s]*"
    myregex2 = r"([\d]*)\.([\d]*)[\s]*-[\s]*"
    myregex3 = r"(\d[\d]*)[\s]*-[\s]*"
    if occursin(myregex1, current_compat_entry)
        m1 = match(myregex1, current_compat_entry)
        return VersionNumber("$(m1[1]).$(m1[2]).$(m1[3])")
    elseif occursin(myregex2, current_compat_entry)
        m2 = match(myregex2, current_compat_entry)
        return VersionNumber("$(m2[1]).$(m2[2])")
    elseif occursin(myregex3, current_compat_entry)
        m3 = match(myregex3, current_compat_entry)
        return VersionNumber("$(m3[1])")
    else
        return nothing
    end
end

function new_compat_entry(current_compat_entry::String,
                          latest_dep_version::VersionNumber)::String
    lower_bound = _extract_lower_bound(current_compat_entry)
    if lower_bound isa Nothing
        return new_compat_entry(latest_dep_version)
    else
        return new_compat_entry(lower_bound, latest_dep_version)
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
                               latest_dep_version::VersionNumber;
                               aggressive::Bool)
    if length(current_compat_entry) == 0
        return new_compat_entry(current_compat_entry, latest_dep_version)
    else
        spec = _entry_to_spec(current_compat_entry)
        return generate_compat_entry(strategy,
                                     current_compat_entry,
                                     spec,
                                     latest_dep_version;
                                     aggressive = aggressive)
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
                               latest_dep_version::VersionNumber;
                               aggressive::Bool)
    always_assert( length(current_compat_entry) > 0 )
    return current_compat_entry
end

function generate_compat_entry(::NoUpperBound,
                               current_compat_entry::Union{Vector, String},
                               spec::Pkg.Types.VersionSpec,
                               latest_dep_version::VersionNumber;
                               aggressive::Bool)
    always_assert( length(current_compat_entry) > 0 )
    if has_upper_bound(spec; aggressive = aggressive)
        return current_compat_entry
    else
        return new_compat_entry(current_compat_entry, latest_dep_version)
    end
end

function has_upper_bound(spec::Pkg.Types.VersionSpec; aggressive::Bool)::Bool
    if aggressive
        return has_upper_bound(spec, Aggressive())
    else
        return has_upper_bound(spec, NotAggressive())
    end
end

function _includes_infinity(spec::Pkg.Types.VersionSpec)::Bool
    max_component = typemax(Base.VInt)
    infinity_A = typemax(VersionNumber)
    infinity_B = VersionNumber(max_component, max_component, max_component)
    return (infinity_A in spec) || (infinity_B in spec)
end

function _does_not_include_infinity(spec::Pkg.Types.VersionSpec)::Bool
    return !_includes_infinity(spec)
end

function _is_zero(spec::Pkg.Types.VersionSpec)::Bool
    max_component = typemax(Base.VInt)
    _zero_max = VersionNumber(0, max_component, max_component)
    _one = v"1"
    return (_zero_max in spec) && !(_one in spec)
end

function _is_not_zero(spec::Pkg.Types.VersionSpec)::Bool
    return !_is_zero(spec)
end

function has_upper_bound(spec::Pkg.Types.VersionSpec, ::NotAggressive)::Bool
    return _does_not_include_infinity(spec)
end

function has_upper_bound(spec::Pkg.Types.VersionSpec, ::Aggressive)::Bool
    return _does_not_include_infinity(spec) && _is_not_zero(spec)
end
