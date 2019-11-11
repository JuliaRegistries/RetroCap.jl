import Pkg
import UUIDs

function generate_compat_entry(latest_dep_version::VersionNumber)::String
    major = latest_dep_version.major
    minor = latest_dep_version.minor
    patch = latest_dep_version.patch
    compat = "< $(major).$(minor).$(patch + 1)"
    @assert Pkg.Types.semver_spec(compat) isa Pkg.Types.VersionSpec
    return compat
end



function generate_compat_entry(strategy::CapStrategy, current_compat_entry, latest_dep_version::VersionNumber)
    if length(current_compat_entry) == 0
        return generate_compat_entry(latest_dep_version)
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

function generate_compat_entry(::NoCompatEntry, current_compat_entry, spec::Pkg.Types.VersionSpec, latest_dep_version::VersionNumber)
    if length(current_compat_entry) == 0
        return generate_compat_entry(latest_dep_version)
    else
        return current_compat_entry
    end
end

function generate_compat_entry(::NoUpperBound, current_compat_entry, spec::Pkg.Types.VersionSpec, latest_dep_version::VersionNumber)
    if length(current_compat_entry) == 0
        return generate_compat_entry(latest_dep_version)
    else
        if has_upper_bound(spec)
            return current_compat_entry
        else
            return generate_compat_entry(latest_dep_version)
        end
    end
end

function has_upper_bound(spec::Pkg.Types.VersionSpec)::Bool
    return !(typemax(VersionNumber) in spec)
end
