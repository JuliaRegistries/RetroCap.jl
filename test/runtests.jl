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
    Test.@testset "compat_entries.jl" begin
        Test.@testset "_compute_cap_upper_bound" begin
            Test.@test RetroCap._compute_cap_upper_bound(v"1.2.3") == "1"
            Test.@test RetroCap._compute_cap_upper_bound(v"1.2.0") == "1"
            Test.@test RetroCap._compute_cap_upper_bound(v"1.0.3") == "1"
            Test.@test RetroCap._compute_cap_upper_bound(v"1.0.0") == "1"
            Test.@test RetroCap._compute_cap_upper_bound(v"0.2.3") == "0.2"
            Test.@test RetroCap._compute_cap_upper_bound(v"0.2.0") == "0.2"
            Test.@test RetroCap._compute_cap_upper_bound(v"0.0.3") == "0.0.3"
            Test.@test RetroCap._compute_cap_upper_bound(v"0.0.0") == "0.0.0"
        end
        Test.@testset "_extract_lower_bound" begin
            Test.@test RetroCap._extract_lower_bound("1.2.3 - foo") == v"1.2.3"
            Test.@test RetroCap._extract_lower_bound("1.2 - foo") == v"1.2"
            Test.@test RetroCap._extract_lower_bound("1 - foo") == v"1"
            Test.@test RetroCap._extract_lower_bound(" - foo") == v"0"
        end
        Test.@testset "generate_compat_entry" begin
            Test.@test "0.0.0 - 1" == RetroCap.generate_compat_entry(RetroCap.Package("PkgA"),
                                                                     RetroCap.Package("PkgB"),
                                                                     RetroCap.NoUpperBound(),
                                                                     "0",
                                                                     Pkg.Types.semver_spec("0"),
                                                                     v"1.2.3",
                                                                     nothing)
        end
        Test.@testset "too_many_breaking_nonzero_versions" begin
            Test.@test !RetroCap.too_many_breaking_nonzero_versions(Pkg.Types.semver_spec("0"))
            Test.@test RetroCap.too_many_breaking_nonzero_versions(Pkg.Types.semver_spec(">=1.2.3"))
        end
        Test.@testset "too_many_breaking_zero_versions" begin
            Test.@test RetroCap.too_many_breaking_zero_versions(Pkg.Types.semver_spec("0"))
            Test.@test !RetroCap.too_many_breaking_zero_versions(Pkg.Types.semver_spec(">=1.2.3"))
        end
        Test.@testset "next_breaking_release" begin
            Test.@test v"0.0.0" == RetroCap.next_breaking_release(nothing)
            Test.@test v"0.2.0" == RetroCap.next_breaking_release(v"0.1.0")
            Test.@test v"2.0.0" == RetroCap.next_breaking_release(v"1.0.0")
        end
    end
    Test.@testset "Run on the General registry" begin
        RetroCap.with_temp_dir() do tmp_dir
            cd(tmp_dir)
            run(`git clone https://github.com/JuliaRegistries/General.git`)
            cd("General")
            a = joinpath("D", "DiffEqPhysics", "Compat.toml")
            rm(a)
            open(a, "w") do io
                s = """
[2]
OrdinaryDiffEq = "3-5"
julia = "0.7-1"

["2-3.1"]
DiffEqBase = "3-5"
DiffEqCallbacks = "0-2"
ForwardDiff = "0.5.0 - 0.10"
RecipesBase = "0.0.0 - 0.7"
RecursiveArrayTools = "0.0.0 - 0.20"
Reexport = "0.0.0 - 0.2"
StaticArrays = "0.0.0 - 0.12"

["3.0"]
julia = "0.7-1"

["3.1-3"]
julia = "1"

["3.3-3"]
DiffEqBase = "6.5.0-6"
DiffEqCallbacks = "2.9.0-2"
ForwardDiff = "0.10"
RecipesBase = "0.7"
RecursiveArrayTools = "1"
Reexport = "0.2"
StaticArrays = "0.10-0.12"
                """
                println(io, strip(s))
                println(io)
            end
            RetroCap.add_caps(RetroCap.NoUpperBound(), strip(pwd()))
        end
    end
end
