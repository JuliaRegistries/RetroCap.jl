using Pkg
using RetroCap
using Test

@testset "compress_versions()" begin
    # Test exact version matching
    vs = [v"1.1.0", v"1.1.1", v"1.1.2"]
    @test RetroCap.Compress.compress_versions(vs, [vs[2]]) == Pkg.Types.VersionSpec("1.1.1")

    # Test holes
    vs = [v"1.1.0", v"1.1.1", v"1.1.4"]
    @test RetroCap.Compress.compress_versions(vs, [vs[2]]) == Pkg.Types.VersionSpec("1.1.1")

    # Test patch variation with length(subset) > 1
    vs = [v"1.1.0", v"1.1.1", v"1.1.2", v"1.1.3", v"1.2.0"]
    @test RetroCap.Compress.compress_versions(vs, [vs[2], vs[3]]) == Pkg.Types.VersionSpec("1.1.1-1.1.2")

    # Test minor variation
    vs = [v"1.1.0", v"1.1.1", v"1.2.0"]
    @test RetroCap.Compress.compress_versions(vs, [vs[2]]) == Pkg.Types.VersionSpec("1.1.1-1.1")

    # Test major variation
    vs = [v"1.1.0", v"1.1.1", v"1.2.0", v"2.0.0"]
    @test RetroCap.Compress.compress_versions(vs, [vs[2], vs[3]]) == Pkg.Types.VersionSpec("1.1.1-1")

    # Test build numbers and prerelease values are ignored
    vs = [v"1.1.0-alpha", v"1.1.0+0", v"1.1.0+1"]
    @test RetroCap.Compress.compress_versions(vs, [vs[2]]) == Pkg.Types.VersionSpec("1")
end

@testset "_my_string()" begin
    @test RetroCap.Compress._my_string("foo") == "foo"
    @test RetroCap.Compress._my_string(v"1.2.3") == "1.2.3"
    @test RetroCap.Compress._my_string(VersionNumber(1, 2, 3)) == "1.2.3"
end

@testset "_make_keys_strings" begin
    a = Dict{Any, Any}()
    a[v"1.2.3"] = "foo"
    @test eltype([collect(keys(a))...]) <: VersionNumber
    b = RetroCap.Compress._make_keys_strings(a)
    @test eltype([collect(keys(b))...]) <: AbstractString
end

@testset "_save_uncompressed" begin
    RetroCap.with_temp_dir() do tmp_dir
        cd(tmp_dir)
        run(`git clone https://github.com/JuliaRegistries/General.git`)
        cd(joinpath(tmp_dir, "General", "P", "PredictMD"))
        compat = RetroCap.Compress.load("Compat.toml")
        rm("Compat.toml"; force = true, recursive = true)
        RetroCap.Compress._save_uncompressed("Compat.toml", compat)
        deps = RetroCap.Compress.load("Deps.toml")
        rm("Deps.toml"; force = true, recursive = true)
        RetroCap.Compress._save_uncompressed("Deps.toml", deps)
        compat = RetroCap.Compress.load("Compat.toml")
        rm("Compat.toml"; force = true, recursive = true)
        RetroCap.Compress.save("Compat.toml", compat)
        deps = RetroCap.Compress.load("Deps.toml")
        rm("Deps.toml"; force = true, recursive = true)
        RetroCap.Compress.save("Deps.toml", deps)
    end
end
