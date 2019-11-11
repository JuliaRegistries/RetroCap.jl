import Pkg
import RetroCap
import Test

Test.@testset "RetroCap.jl" begin
    Test.@testset "Compress.jl" begin
        include("test_Compress.jl")
    end
    Test.@testset "assert.jl" begin
        Test.@test_nowarn RetroCap.always_assert(true)
        Test.@test RetroCap.always_assert(true) isa Nothing
        Test.@test RetroCap.always_assert(true) == nothing
        Test.@test Test.@test_nowarn RetroCap.always_assert(true) isa Nothing
        Test.@test Test.@test_nowarn RetroCap.always_assert(true) == nothing
        Test.@test_throws RetroCap.AlwaysAssertionError RetroCap.always_assert(false)
    end
    Test.@testset "Run on the General registry" begin
        RetroCap.with_temp_dir() do tmp_dir
            cd(tmp_dir)
            run(`git clone https://github.com/JuliaRegistries/General.git`)
            cd("General")
            RetroCap.add_caps(RetroCap.NoCompatEntry(), strip(pwd()))
        end
        RetroCap.with_temp_dir() do tmp_dir
            cd(tmp_dir)
            run(`git clone https://github.com/JuliaRegistries/General.git`)
            cd("General")
            RetroCap.add_caps(RetroCap.NoUpperBound(), strip(pwd()))
        end
    end
end
