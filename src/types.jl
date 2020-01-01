import Pkg
import UUIDs

struct AlwaysAssertionError <: Exception
    msg::String
end

abstract type CapStrategy end

struct UpperBound <: CapStrategy
end

struct MonotonicUpperBound <: CapStrategy
end

abstract type LatestVersionOption end

struct ExcludeLatestVersion <: LatestVersionOption
end

struct CapLatestVersion <: LatestVersionOption
end

struct Package
    name::String
end
