import Pkg
import RetroCap
import Test

Test.@testset "RetroCap.jl" begin
    Test.@testset "Compress submodule" begin
        Test.@testset "compress_main.jl" begin
            include("test_compress_main.jl")
        end
        Test.@testset "recompress.jl" begin
            include("test_recompress.jl")
        end
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
                                                                     RetroCap.UpperBound(),
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
    Test.@testset "Run RetroCap on the General registry" begin
        RetroCap.with_temp_dir() do tmp_dir
            cd(tmp_dir)
            
            run(`git clone https://github.com/JuliaRegistries/General.git General`)
            run(`git clone https://github.com/BioJulia/BioJuliaRegistry.git BioJuliaRegistry`)
            
            RetroCap.add_caps(RetroCap.UpperBound(), RetroCap.ExcludeLatestVersion(), "General")
            RetroCap.add_caps(RetroCap.UpperBound(), RetroCap.ExcludeLatestVersion(), Any["General", "BioJuliaRegistry"])

            RetroCap.add_caps(RetroCap.UpperBound(), RetroCap.CapLatestVersion(), "General")
            RetroCap.add_caps(RetroCap.UpperBound(), RetroCap.CapLatestVersion(), Any["General", "BioJuliaRegistry"])
        end
    end
end
