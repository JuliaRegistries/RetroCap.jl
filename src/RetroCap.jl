module RetroCap

import Pkg
import RegistryTools
import UUIDs

export CapStrategy, UpperBound, MonotonicUpperBound
export LatestVersionOption, CapLatestVersion, ExcludeLatestVersion
export add_caps

include("types.jl")

include("add_caps.jl")
include("assert.jl")
include("compat_entries.jl")
include("parse_registry.jl")
include("utils.jl")

end # end module RetroCap
