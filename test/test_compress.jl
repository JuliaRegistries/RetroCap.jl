using Pkg
using RetroCap
using Test

const Compress = RetroCap.Compress

@testset "compress_versions()" begin
    # Test exact version matching
    vs = [v"1.1.0", v"1.1.1", v"1.1.2"]
    @test Compress.compress_versions(vs, [vs[2]]) == Pkg.Types.VersionSpec("1.1.1")

    # Test holes
    vs = [v"1.1.0", v"1.1.1", v"1.1.4"]
    @test Compress.compress_versions(vs, [vs[2]]) == Pkg.Types.VersionSpec("1.1.1")

    # Test patch variation with length(subset) > 1
    vs = [v"1.1.0", v"1.1.1", v"1.1.2", v"1.1.3", v"1.2.0"]
    @test Compress.compress_versions(vs, [vs[2], vs[3]]) == Pkg.Types.VersionSpec("1.1.1-1.1.2")

    # Test minor variation
    vs = [v"1.1.0", v"1.1.1", v"1.2.0"]
    @test Compress.compress_versions(vs, [vs[2]]) == Pkg.Types.VersionSpec("1.1.1-1.1")

    # Test major variation
    vs = [v"1.1.0", v"1.1.1", v"1.2.0", v"2.0.0"]
    @test Compress.compress_versions(vs, [vs[2], vs[3]]) == Pkg.Types.VersionSpec("1.1.1-1")

    # Test build numbers and prerelease values are ignored
    vs = [v"1.1.0-alpha", v"1.1.0+0", v"1.1.0+1"]
    @test Compress.compress_versions(vs, [vs[2]]) == Pkg.Types.VersionSpec("1")
end

@testset "_my_string()" begin
    @test Compress._my_string("foo") == "foo"
    @test Compress._my_string(v"1.2.3") == "1.2.3"
    @test Compress._my_string(VersionNumber(1, 2, 3)) == "1.2.3"
end

@testset "_make_keys_strings" begin
    a = Dict{Any, Any}()
    a[v"1.2.3"] = "foo"
    @test eltype([collect(keys(a))...]) <: VersionNumber
    b = Compress._make_keys_strings(a)
    @test eltype([collect(keys(b))...]) <: AbstractString
end

@testset "_save_uncompressed" begin
    RetroCap.with_temp_dir() do tmp_dir
        cd(tmp_dir)
        run(`git clone https://github.com/JuliaRegistries/General.git`)
        cd(joinpath(tmp_dir, "General", "P", "PredictMD"))
        compat = Compress.load("Compat.toml")
        rm("Compat.toml"; force = true, recursive = true)
        Compress._save_uncompressed("Compat.toml", compat)
        deps = Compress.load("Deps.toml")
        rm("Deps.toml"; force = true, recursive = true)
        Compress._save_uncompressed("Deps.toml", deps)
        compat = Compress.load("Compat.toml")
        rm("Compat.toml"; force = true, recursive = true)
        Compress.save("Compat.toml", compat)
        deps = Compress.load("Deps.toml")
        rm("Deps.toml"; force = true, recursive = true)
        Compress.save("Deps.toml", deps)
    end
end

@testset "_save_uncompressed" begin
    this_file = @__FILE__
    test_directory = dirname(this_file)
    package_root = dirname(test_directory)
    bin_directory = joinpath(package_root, "bin")
    recompress_script = joinpath(bin_directory, "recompress.jl")
    RetroCap.with_temp_dir() do tmp_dir
        original_depot_path = deepcopy(Base.DEPOT_PATH)
        depot = tmp_dir
        mkpath(joinpath(depot, "registries"))
        cd(joinpath(depot, "registries"))
        run(`git clone https://github.com/JuliaRegistries/General.git`)
        empty!(Base.DEPOT_PATH)
        pushfirst!(Base.DEPOT_PATH, depot)
        cd(tmp_dir)
        include(recompress_script)
        empty!(Base.DEPOT_PATH)
        for x in original_depot_path
            push!(Base.DEPOT_PATH, x)
        end
    end
end
