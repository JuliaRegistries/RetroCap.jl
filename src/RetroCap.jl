module RetroCap

export CapStrategy, UpperBound, MonotonicUpperBound
export LatestVersionOption, CapLatestVersion, ExcludeLatestVersion
export add_caps

include("types.jl")

include("Compress/Compress.jl")

include("add_caps.jl")
include("assert.jl")
include("compat_entries.jl")
include("parse_registry.jl")
include("utils.jl")

end # module
