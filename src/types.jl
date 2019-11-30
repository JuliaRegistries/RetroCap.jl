import Pkg
import UUIDs

struct AlwaysAssertionError <: Exception
    msg::String
end

abstract type CapStrategy end

struct NoUpperBound <: CapStrategy
end

struct Package
    name::String
end
