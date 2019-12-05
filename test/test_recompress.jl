using RetroCap
using Test

@testset "recompress function" begin
    RetroCap.with_temp_dir() do tmp_dir
        cd(tmp_dir)
        run(`git clone https://github.com/JuliaRegistries/General.git`)
        RetroCap.Compress.recompress(joinpath(tmp_dir, "General"))        
    end
end
