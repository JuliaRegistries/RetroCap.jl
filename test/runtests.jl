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
    end
    Test.@testset "Run on the General registry" begin
        # RetroCap.with_temp_dir() do tmp_dir
        #     cd(tmp_dir)
        #     run(`git clone https://github.com/JuliaRegistries/General.git`)
        #     cd("General")
            # RetroCap.add_caps(RetroCap.NoCompatEntry(),
            #                   strip(pwd()))
        # end
        RetroCap.with_temp_dir() do tmp_dir
            cd(tmp_dir)
            run(`git clone https://github.com/JuliaRegistries/General.git`)
            cd("General")
            RetroCap.add_caps(RetroCap.NoCompatEntry(),
                              strip(pwd());
                              aggressive = false)
        end
        RetroCap.with_temp_dir() do tmp_dir
            cd(tmp_dir)
            run(`git clone https://github.com/JuliaRegistries/General.git`)
            cd("General")
            RetroCap.add_caps(RetroCap.NoCompatEntry(),
                              strip(pwd());
                              aggressive = true)
        end

        # RetroCap.with_temp_dir() do tmp_dir
        #     cd(tmp_dir)
        #     run(`git clone https://github.com/JuliaRegistries/General.git`)
        #     cd("General")
            # RetroCap.add_caps(RetroCap.NoUpperBound(),
                              # strip(pwd()))
        # end
        RetroCap.with_temp_dir() do tmp_dir
            cd(tmp_dir)
            run(`git clone https://github.com/JuliaRegistries/General.git`)
            cd("General")
            RetroCap.add_caps(RetroCap.NoUpperBound(),
                              strip(pwd());
                              aggressive = false)
        end
        RetroCap.with_temp_dir() do tmp_dir
            cd(tmp_dir)
            run(`git clone https://github.com/JuliaRegistries/General.git`)
            cd("General")
            RetroCap.add_caps(RetroCap.NoUpperBound(),
                              strip(pwd());
                              aggressive = true)
        end
    end
end
