using SafeTestsets

@safetestset "Test model 2" begin include("Test_model2.jl") end

@safetestset "Test model 3" begin include("Test_model3.jl") end

@safetestset "Boehm against PyPesto" begin include("Boehm.jl") end

@safetestset "Log-likelihood values and gradients for published models" begin include("Test_ll.jl") end

@safetestset "PEtab test suite" begin include("PEtab_test_suite.jl") end
