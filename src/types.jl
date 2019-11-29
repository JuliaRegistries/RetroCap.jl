import Pkg
import UUIDs

struct AlwaysAssertionError <: Exception
    msg::String
end

abstract type CapStrategy end

struct NoCompatEntry <: CapStrategy
end

struct NoUpperBound <: CapStrategy
end

struct Package
    name::String
end

struct Aggressive
end

struct NotAggressive
end
