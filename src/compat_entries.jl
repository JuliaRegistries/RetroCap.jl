import Pkg
import UUIDs

@inline function new_compat_entry(current_compat_entry::Vector,
                                  upper_version::VersionNumber)::String
    return new_compat_entry(upper_version)
end

@inline function new_compat_entry(latest_dep_version::VersionNumber)::String
    lower_bound = v"0"
    return new_compat_entry(lower_bound, latest_dep_version)
end

@inline function _extract_lower_bound(current_compat_entry::String)::VersionNumber
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
        return v"0"
    end
end

@inline function new_compat_entry(current_compat_entry::String,
                                  upper_version::VersionNumber)::String
    lower_bound = _extract_lower_bound(current_compat_entry)
    return new_compat_entry(lower_bound, upper_version)
end

@inline function _compute_cap_upper_bound(upper_version::VersionNumber)::String
    x = upper_version.major
    y = upper_version.minor
    z = upper_version.patch
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

@inline function new_compat_entry(lower_bound::VersionNumber,
                                  upper_version::VersionNumber)::String
    a = lower_bound.major
    b = lower_bound.minor
    c = lower_bound.patch
    upper_bound = _compute_cap_upper_bound(upper_version)
    compat = "$(a).$(b).$(c) - $(upper_bound)"
    @assert Pkg.Types.VersionRange(compat) isa Pkg.Types.VersionRange
    return compat
end

@inline function generate_compat_entry(pkg::Package,
                                       dep::Package,
                                       strategy::CapStrategy,
                                       current_compat_entry::Union{Vector, String},
                                       latest_dep_version::VersionNumber,
                                       latest_dep_zero_version::Union{VersionNumber, Nothing})
    if length(current_compat_entry) == 0
        return new_compat_entry(current_compat_entry,
                                latest_dep_version)
    else
        spec = _entry_to_spec(current_compat_entry)
        return generate_compat_entry(pkg,
                                     dep,
                                     strategy,
                                     current_compat_entry,
                                     spec,
                                     latest_dep_version,
                                     latest_dep_zero_version)
    end
end

@inline function _entry_to_spec(current_compat_entry::String)::Pkg.Types.VersionSpec
    try
        return Pkg.Types.semver_spec(current_compat_entry)
    catch
    end
    r = Pkg.Types.VersionRange(current_compat_entry)
    ranges = Pkg.Types.VersionRange[r]
    spec = Pkg.Types.VersionSpec(ranges)
    return spec
end

@inline function _entry_to_spec(current_compat_entry::Vector{String})::Pkg.Types.VersionSpec
    n = length(current_compat_entry)
    ranges = Vector{Pkg.Types.VersionRange}(undef, n)
    for i = 1:n
        ranges[i] = Pkg.Types.VersionRange(current_compat_entry[i])
    end
    spec = Pkg.Types.VersionSpec(ranges)
end

@inline function generate_compat_entry(pkg::Package,
                                       dep::Package,
                                       strategy::UpperBound,
                                       current_compat_entry::Union{Vector, String},
                                       spec::Pkg.Types.VersionSpec,
                                       latest_dep_version::VersionNumber,
                                       latest_dep_zero_version::Union{VersionNumber, Nothing})
    always_assert( length(current_compat_entry) > 0 )
    if is_unbounded_infinity(spec)
        return new_compat_entry(current_compat_entry, latest_dep_version)
    elseif is_unbounded_bad_zero(spec)
        if latest_dep_zero_version isa Nothing
            return new_compat_entry(current_compat_entry, latest_dep_version)
        else
            return new_compat_entry(current_compat_entry, latest_dep_zero_version)
        end
    else
        # if (next_breaking_release(latest_dep_version) in spec) | (next_breaking_release(latest_dep_zero_version) in spec)
        #     msg = string("This is a bad compat entry because ",
        #                  "it includes future (not-yet-released) ",
        #                  "breaking releases. ",
        #                  "Unfortunately, I am not smart enough to fix this ",
        #                  "compat entry, so I am leaving it unmodified. ",
        #                  "Please manually modify this compat entry.")
        #     @warn(msg,
        #           pkg,
        #           dep,
        #           strategy,
        #           spec,
        #           latest_dep_version,
        #           latest_dep_zero_version,
        #           next_breaking_release(latest_dep_version),
        #           next_breaking_release(latest_dep_zero_version))
        # end
        # if too_many_breaking_zero_versions(spec)
        #     msg = string("This is a bad compat entry because ",
        #                  "it includes an infinite number of breaking ",
        #                  "releases of the form `0.x`.",
        #                  "Unfortunately, I am not smart enough to fix this ",
        #                  "compat entry, so I am leaving it unmodified. ",
        #                  "Please manually modify this compat entry.")
        #     @warn(msg,
        #           pkg,
        #           dep,
        #           strategy,
        #           spec,
        #           latest_dep_version,
        #           latest_dep_zero_version,
        #           next_breaking_release(latest_dep_version),
        #           next_breaking_release(latest_dep_zero_version))
        # end
        return current_compat_entry
    end
end

function too_many_breaking_nonzero_versions(spec::Pkg.Types.VersionSpec, cutoff::Integer = 50)::Bool
    num = 0
    a = typemin(Base.VInt) : Base.VInt(1)       : Base.VInt(200_000)
    b = typemin(Base.VInt) : Base.VInt(100_000) : typemax(Base.VInt)
    for major in Iterators.flatten([a, b])
        if VersionNumber(major, 0, 0) in spec
            num += 1
        end
    end
    if num >= cutoff
        return true
    else
        return false
    end
end

function too_many_breaking_zero_versions(spec::Pkg.Types.VersionSpec, cutoff::Integer = 50)::Bool
    num = 0
    a = typemin(Base.VInt) : Base.VInt(1)       : Base.VInt(200_000)
    b = typemin(Base.VInt) : Base.VInt(100_000) : typemax(Base.VInt)
    for minor in Iterators.flatten([a, b])
        if VersionNumber(0, minor, 0) in spec
            num += 1
        end
    end
    if num >= cutoff
        return true
    else
        return false
    end
end

@inline function includes_infinity(spec::Pkg.Types.VersionSpec)::Bool
    max_component = typemax(Base.VInt)
    x = typemax(VersionNumber)
    y = VersionNumber(max_component, max_component, max_component)
    result = (x in spec) | (y in spec)
    return result
end

@inline function includes_bad_zero(spec::Pkg.Types.VersionSpec)::Bool
    max_component = typemax(Base.VInt)
    a = VersionNumber(0, max_component, 0)
    b = VersionNumber(0, max_component, max_component)
    c = VersionNumber(1, 0, 0)
    has_a_or_b = (a in spec) | (b in spec)
    doesnt_have_c = !(c in spec)
    result = has_a_or_b & doesnt_have_c
    return result
end

@inline function is_unbounded_infinity(spec::Pkg.Types.VersionSpec)::Bool
    # return includes_infinity(spec) | too_many_breaking_nonzero_versions(spec)
    return includes_infinity(spec)
end

@inline function is_unbounded_bad_zero(spec::Pkg.Types.VersionSpec)::Bool
    # return includes_bad_zero(spec) | too_many_breaking_zero_versions(spec)
    return includes_bad_zero(spec)
end

@inline function next_breaking_release(latest_version::VersionNumber)::VersionNumber
    if latest_version < v"1"
        major = 0
        minor = latest_version.minor + 1
    else
        major = latest_version.major + 1
        minor = 0
    end
    return VersionNumber(major, minor, 0)
end

@inline next_breaking_release(::Nothing) = v"0.0.0"

function monotonize!(pkgbounds, compat)
    for (dep, bnd) in compat
        pkgdep = Package(dep)
        if haskey(pkgbounds, pkgdep)
            spec = _entry_to_spec(bnd)
            upper = VersionNumber(spec.ranges[end].upper.t)
            upper == v"0.0.0" && continue
            current_upper = pkgbounds[pkgdep]
            if current_upper === nothing || current_upper == v"0.0.0" || upper < current_upper
                pkgbounds[pkgdep] = upper
            end
        end
    end
    return pkgbounds
end
