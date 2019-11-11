module RetroCap

export CapStrategy
export NoCompatEntry
export NoUpperBound
export add_caps

include("types.jl")

include("Compress.jl")

include("add_caps.jl")
include("assert.jl")
include("compat_entries.jl")
include("parse_registry.jl")
include("utils.jl")

end # module
