@inline function always_assert(cond::Bool, msg::String)
    cond || throw(AlwaysAssertionError(msg))
    return nothing
end
