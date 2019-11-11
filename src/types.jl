import Pkg
import UUIDs

abstract type CapStrategy end

struct NoCompatEntry <: CapStrategy
end

struct NoUpperBound <: CapStrategy
end

struct Package
    name::String
end
