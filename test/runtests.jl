using Pkg
using RetroCap
using Test

@testset "RetroCap.jl" begin
    @testset "Compress.jl" begin
        include("test_Compress.jl")
    end
    @testset "Run on the General registry" begin
        RetroCap.with_temp_dir() do tmp_dir
            cd(tmp_dir)
            run(`git clone https://github.com/JuliaRegistries/General.git`)
            cd("General")
            add_caps(NoCompatEntry(), pwd())
        end
        RetroCap.with_temp_dir() do tmp_dir
            cd(tmp_dir)
            run(`git clone https://github.com/JuliaRegistries/General.git`)
            cd("General")
            add_caps(NoUpperBound(), pwd())
        end
    end

end
