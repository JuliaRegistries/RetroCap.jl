import Pkg
import UUIDs

function _strip(s::AbstractString)::String
    result::String = convert(String, strip(s))::String
    return result
end

function _strip(v::AbstractVector{<:AbstractString})::Vector{String}
    result::Vector{String} = Vector{String}(undef, 0)
    for i = 1:length(v)
        v_i_stripped = _strip(v[i])::String
        if length(v_i_stripped) > 0
            push!(result, v_i_stripped)
        end
    end
    return result
end

function is_stdlib(name::AbstractString)::Bool
    _stdlibs = Pkg.Types.stdlibs()
    return strip(name) in values(_stdlibs)
end

function is_jll(name::AbstractString)::Bool
    return endswith(lowercase(strip(name)), "_jll")
end

function with_temp_dir(f::Function)
    original_dir = pwd()
    tmp_dir = mktempdir()
    atexit(() -> rm(tmp_dir; force = true, recursive = true))
    cd(tmp_dir)

    result = f(tmp_dir)

    cd(original_dir)
    rm(tmp_dir; force = true, recursive = true)
    return result
end
