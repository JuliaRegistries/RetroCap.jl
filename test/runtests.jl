import Pkg
import RetroCap
import Test
using UUIDs

Test.@testset "RetroCap.jl" begin
    Test.@testset "assert.jl" begin
        Test.@test_nowarn RetroCap.always_assert(true, "")
        Test.@test RetroCap.always_assert(true, "") isa Nothing
        Test.@test RetroCap.always_assert(true, "") == nothing
        Test.@test Test.@test_nowarn RetroCap.always_assert(true, "") isa Nothing
        Test.@test Test.@test_nowarn RetroCap.always_assert(true, "") == nothing
        Test.@test_throws RetroCap.AlwaysAssertionError RetroCap.always_assert(false, "")
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
            Test.@test "0.0.0 - 1" == RetroCap.generate_compat_entry(RetroCap.Package("PkgA"),
                                                                     RetroCap.Package("PkgB"),
                                                                     RetroCap.UpperBound(),
                                                                     [],
                                                                     v"1.2.3",
                                                                     nothing)
            Test.@test "0.0.0 - 1" == RetroCap.generate_compat_entry(RetroCap.Package("PkgA"),
                                                                     RetroCap.Package("PkgB"),
                                                                     RetroCap.MonotonicUpperBound(),
                                                                     [],
                                                                     v"1.2.3",
                                                                     nothing)
        end
        Test.@testset "next_breaking_release" begin
            Test.@test v"0.0.0" == RetroCap.next_breaking_release(nothing)
            Test.@test v"0.2.0" == RetroCap.next_breaking_release(v"0.1.0")
            Test.@test v"2.0.0" == RetroCap.next_breaking_release(v"1.0.0")
        end
        Test.@testset "new_compat_entry" begin
        end
        Test.@testset "too_many_breaking_nonzero_versions" begin
            Test.@test !RetroCap.too_many_breaking_nonzero_versions(Pkg.Types.semver_spec("0"))
            Test.@test RetroCap.too_many_breaking_nonzero_versions(Pkg.Types.semver_spec(">=1.2.3"))
        end
        Test.@testset "too_many_breaking_zero_versions" begin
            Test.@test RetroCap.too_many_breaking_zero_versions(Pkg.Types.semver_spec("0"))
            Test.@test !RetroCap.too_many_breaking_zero_versions(Pkg.Types.semver_spec(">=1.2.3"))
        end
    end
    Test.@testset "Monotonic" begin
        RetroCap.with_temp_dir() do tmp_dir
            cd(tmp_dir) do
                # Create a fake registry
                mkdir("Fake")
                pkga = joinpath("Fake", "A", "APkg")
                pkgb = joinpath("Fake", "B", "BPkg")
                pkgc = joinpath("Fake", "C", "CPkg")
                uuida, uuidb, uuidc = uuid4(), uuid4(), uuid4()
                uuidr = uuid4()
                open(joinpath("Fake", "Registry.toml"), "w") do io
                    println(io, """
                    name = "Fake"
                    uuid = "$uuidr"
                    repo = "fake"

                    [packages]
                    $uuida = { name = "APkg", path = "A/APkg" }
                    $uuidb = { name = "BPkg", path = "B/BPkg" }
                    $uuidc = { name = "CPkg", path = "C/CPkg" }
                    """)
                end
                foreach(mkpath, [pkga, pkgb, pkgc])
                open(joinpath(pkga, "Versions.toml"), "w") do io
                    println(io, """
                    ["1.0.0"]
                    git-tree-sha1 = "aa"

                    ["2.0.0"]
                    git-tree-sha1 = "bb"

                    ["3.0.0"]
                    git-tree-sha1 = "cc"
                    """)
                end
                open(joinpath(pkgb, "Versions.toml"), "w") do io
                    println(io, """
                    ["0.1.0"]
                    git-tree-sha1 = "aa"

                    ["0.2.0"]
                    git-tree-sha1 = "bb"
                    """)
                end
                open(joinpath(pkgc, "Deps.toml"), "w") do io
                    println(io, """
                    [0]
                    APkg = "$uuida"

                    ["0.1-0.2"]
                    BPkg = "$uuidb"
                    """)
                end
                open(joinpath(pkgc, "Versions.toml"), "w") do io
                    println(io, """
                    ["0.1.0"]
                    git-tree-sha1 = "aa"

                    ["0.2.0"]
                    git-tree-sha1 = "bb"

                    ["0.3.0"]
                    git-tree-sha1 = "cc"
                    """)
                end
                open(joinpath(pkgc, "Compat.toml"), "w") do io
                    println(io, """
                    ["0.1.0"]
                    APkg = "1-*"
                    BPkg = "0.1-0"

                    ["0.2.0"]
                    APkg = "2"
                    BPkg = "0.1-0.2"

                    ["0.3.0"]
                    APkg = "3"
                    """)
                end
                RetroCap.add_caps(RetroCap.MonotonicUpperBound(), RetroCap.CapLatestVersion(), "Fake")
                str = read(joinpath(pkgc, "Compat.toml"), String)
                Test.@test str == """
                ["0-0.1"]
                APkg = "1.0.0 - 2"
                BPkg = "0.1.0 - 0.2"

                ["0.2"]
                APkg = "2"
                BPkg = "0.1-0.2"

                ["0.3-0"]
                APkg = "3"
                """
            end
        end
        # Monotonic, single package
        RetroCap.with_temp_dir() do tmp_dir
            cd(tmp_dir) do
                # Create a fake registry
                mkdir("Fake")
                pkga = joinpath("Fake", "A", "APkg")
                pkgb = joinpath("Fake", "B", "BPkg")
                pkgc = joinpath("Fake", "C", "CPkg")
                uuida, uuidb, uuidc = uuid4(), uuid4(), uuid4()
                uuidr = uuid4()
                open(joinpath("Fake", "Registry.toml"), "w") do io
                    println(io, """
                    name = "Fake"
                    uuid = "$uuidr"
                    repo = "fake"

                    [packages]
                    $uuida = { name = "APkg", path = "A/APkg" }
                    $uuidb = { name = "BPkg", path = "B/BPkg" }
                    $uuidc = { name = "CPkg", path = "C/CPkg" }
                    """)
                end
                foreach(mkpath, [pkga, pkgb, pkgc])
                open(joinpath(pkga, "Versions.toml"), "w") do io
                    println(io, """
                    ["1.0.0"]
                    git-tree-sha1 = "aa"

                    ["2.0.0"]
                    git-tree-sha1 = "bb"

                    ["2.0.1"]
                    git-tree-sha1 = "cc"
                    """)
                end
                compatstr = """
                ["1.0.0"]
                APkg = "1-*"

                ["1.1.0"]
                APkg = "2"

                ["1.1.1"]
                APkg = "2.0.1"
                """
                for pkgo in (pkgb, pkgc)
                    open(joinpath(pkgo, "Deps.toml"), "w") do io
                        println(io, """
                        [1-2]
                        APkg = "$uuida"
                        """)
                    end
                    open(joinpath(pkgo, "Versions.toml"), "w") do io
                        println(io, """
                        ["1.0.0"]
                        git-tree-sha1 = "aa"

                        ["1.1.0"]
                        git-tree-sha1 = "bb"

                        ["1.1.1"]
                        git-tree-sha1 = "cc"
                        """)
                    end
                    open(joinpath(pkgo, "Compat.toml"), "w") do io
                        println(io, compatstr)
                    end
                end
                RetroCap.add_caps(RetroCap.MonotonicUpperBound(), RetroCap.CapLatestVersion(), "Fake", RetroCap.Package("BPkg"))
                str = read(joinpath(pkgb, "Compat.toml"), String)
                targetstr = """
                ["1.0"]
                APkg = "1.0.0 - 2"

                ["1.1.0"]
                APkg = "2"

                ["1.1.1-1"]
                APkg = "2.0.1"
                """
                Test.@test str == targetstr
                str = read(joinpath(pkgc, "Compat.toml"), String)
                Test.@test strip(str) == strip(compatstr)
            end
        end
    end
    Test.@testset "Run RetroCap on the General registry" begin
        RetroCap.with_temp_dir() do tmp_dir
            cd(tmp_dir)

            run(`git clone https://github.com/JuliaRegistries/General.git General`)

            RetroCap.add_caps(RetroCap.UpperBound(), RetroCap.ExcludeLatestVersion(), "General")
            RetroCap.add_caps(RetroCap.UpperBound(), RetroCap.ExcludeLatestVersion(), Any["General", "General"])

            RetroCap.add_caps(RetroCap.UpperBound(), RetroCap.CapLatestVersion(), "General")
            RetroCap.add_caps(RetroCap.UpperBound(), RetroCap.CapLatestVersion(), Any["General", "General"])

            RetroCap.add_caps(RetroCap.MonotonicUpperBound(), RetroCap.CapLatestVersion(), "General")
            RetroCap.add_caps(RetroCap.MonotonicUpperBound(), RetroCap.CapLatestVersion(), Any["General", "General"])
        end
    end
end
