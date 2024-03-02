module PEtab

using ModelingToolkit
using CSV
using SciMLBase
using OrdinaryDiffEq
using Catalyst
using DiffEqCallbacks
using DataFrames
using SteadyStateDiffEq
using ForwardDiff
using ReverseDiff
import ChainRulesCore
using SBMLImporter
using StatsBase
using Sundials
using Random
using LinearAlgebra
using Distributions
using Printf
using YAML
using RuntimeGeneratedFunctions
using PreallocationTools
using NonlinearSolve
using PrecompileTools
using QuasiMonteCarlo

RuntimeGeneratedFunctions.init(@__MODULE__)

include("Structs.jl")
include(joinpath("PEtabModel", "Table_input.jl"))
include(joinpath("PEtabModel", "Julia_input.jl"))

include("Common.jl")

# Files related to computing the cost (likelihood)
include(joinpath("Objective", "Priors.jl"))
include(joinpath("Objective", "Objective.jl"))

# Files related to computing derivatives
include(joinpath("Derivatives", "Hessian.jl"))
include(joinpath("Derivatives", "Gradient.jl"))
include(joinpath("Derivatives", "Forward_sensitivity_equations.jl"))
include(joinpath("Derivatives", "Gauss_newton.jl"))
include(joinpath("Derivatives", "Common.jl"))
include(joinpath("Derivatives", "ForwardDiff_chunks.jl"))

# Files related to solving the ODE-system
include(joinpath("Solve_ODE", "Switch_condition.jl"))
include(joinpath("Solve_ODE", "Common.jl"))
include(joinpath("Solve_ODE", "Solve.jl"))
include(joinpath("Solve_ODE", "Steady_state.jl"))

# Files related to processing user input
include(joinpath("Process_input", "Table_input", "Measurements.jl"))
include(joinpath("Process_input", "Table_input", "Parameters.jl"))
include(joinpath("Process_input", "Table_input", "Read_tables.jl"))
include(joinpath("Process_input", "Julia_input.jl"))
include(joinpath("Process_input", "Common.jl"))
include(joinpath("Process_input", "Simulation_info.jl"))
include(joinpath("Process_input", "Parameter_indices.jl"))
include(joinpath("Process_input", "Callbacks.jl"))
include(joinpath("Process_input", "Observables", "Common.jl"))
include(joinpath("Process_input", "Observables", "h_sigma_derivatives.jl"))
include(joinpath("Process_input", "Observables", "u0_h_sigma.jl"))

# For creating a PEtab ODE problem
include(joinpath("PEtabODEProblem", "Defaults.jl"))
include(joinpath("PEtabODEProblem", "Remake.jl"))
include(joinpath("PEtabODEProblem", "Cache.jl"))
include(joinpath("PEtabODEProblem", "Create.jl"))

# Nice util functions
include(joinpath("Utility.jl"))

# For correct struct printing
include(joinpath("Show.jl"))

# Reduce time for reading a PEtabModel and for building a PEtabODEProblem
@setup_workload begin
    path_yaml = joinpath(@__DIR__, "..", "test", "Test_model3", "Test_model3.yaml")
    @compile_workload begin
        petab_model = PEtabModel(path_yaml, verbose = false, build_julia_files = true,
                                 write_to_file = false)
        petab_problem = PEtabODEProblem(petab_model, verbose = false)
        petab_problem.compute_cost(petab_problem.θ_nominalT)
    end
end

export PEtabModel, PEtabODEProblem, ODESolver, SteadyStateSolver, PEtabModel,
       PEtabODEProblem, remake_PEtab_problem, Fides, PEtabOptimisationResult, IpoptOptions,
       IpoptOptimiser, PEtabParameter, PEtabObservable, PEtabMultistartOptimisationResult,
       generate_startguesses, get_ps, get_u0, get_odeproblem, get_odesol, PEtabEvent,
       PEtabLogDensity

# These are given as extensions, but their docstrings are availble in the
# general documentation
include(joinpath("Calibrate", "Common.jl"))
export calibrate_model, calibrate_model_multistart, run_PEtab_select

if !isdefined(Base, :get_extension)
    include(joinpath(@__DIR__, "..", "ext", "PEtabIpoptExtension.jl"))
    include(joinpath(@__DIR__, "..", "ext", "PEtabOptimExtension.jl"))
    include(joinpath(@__DIR__, "..", "ext", "PEtabPyCallExtension.jl"))
    include(joinpath(@__DIR__, "..", "ext", "PEtabOptimizationExtension.jl"))
    include(joinpath(@__DIR__, "..", "ext", "PEtabSciMLSensitivityExtension.jl"))
    include(joinpath(@__DIR__, "..", "ext", "PEtabLogDensityProblemsExtension.jl"))
    include(joinpath(@__DIR__, "..", "ext", "PEtabPlotsExtension.jl"))
end

function get_obs_comparison_plots end
export get_obs_comparison_plots

function compute_llh end
function correct_gradient! end

end
