using Lux
using ComponentArrays
using Random
using PEtab
using OrdinaryDiffEq
using Plots
using PyCall
using ModelingToolkit
using Ipopt


# Define the neural network
hidden_layers = 2
first_layer = Dense(2, 5, Lux.tanh)
intermediate_layers = [Dense(5, 5, Lux.tanh) for _ in 1:hidden_layers-1]
last_layer = Dense(5, 2)
nn = Lux.Chain(first_layer, intermediate_layers..., last_layer)
rng = Random.default_rng()
Random.seed!(rng, 1)
p_nn, st = Lux.setup(rng, nn)

# Defines initial value maps and parameter
@variables prey, predator
p_mechanistic = (α = 1.3, δ = 1.8)
u0_map = [prey => 0.44249296, predator => 4.6280594]
p_combined = ComponentArray(merge(p_mechanistic, (p_nn=p_nn,)))

# Dynamics
function lv!(du, u, p, t)
    prey, predator = u
    @unpack α, δ, p_nn = p

    du_nn = nn([prey, predator], p_nn, st)[1]

    du[1] = dprey =  α*prey + du_nn[1]
    du[2] = dpredator = du_nn[2] - δ*predator
    return nothing
end

lv_problem = ODEProblem(lv!, u0_map, (0.0, 500), p_combined)
path_yaml = joinpath(@__DIR__, "petab_problem", "petab_problem", "petab_problem.yaml")
petab_model = PEtabModel(path_yaml, lv_problem, write_to_file=true)

petab_problem = PEtabODEProblem(petab_model,
                                ode_solver=ODESolver(Vern7(), abstol=1e-8, reltol=1e-8), 
                                gradient_method=:ForwardEquations, 
                                hessian_method=:GaussNewton,
                                sensealg=:ForwardDiff,
                                reuse_sensitivities=true)

# Getting the gradient and objective function, in this case also the Hessian 
# is now easy                                 
p0 = zeros(length(petab_problem.θ_nominalT))
f = petab_problem.compute_cost(p0)
∇f = petab_problem.compute_gradient(p0)
H = petab_problem.compute_hessian(p0)

# A good parameter Vector from training
#  p0 = [0.11753319620828563, 0.2534687584628469, -1.681432507324037, 0.32499151893081296, 0.36914119110141047, 0.050983215410473424, -2.2899272133243, -0.5835703303333487, 0.3833751283738198, -1.593909484316206, 0.4445738185701283, 5.045708632939731, 4.105623325645565, -4.45614380906301, -3.460630382408623, -0.69046931123274, 8.037701925042986, -0.3539866309028288, -2.3031594205870136, -3.594783044128806, -3.864628928761406, 2.003383319966077, 5.4632255243501655, 6.08593910735619, -0.24169351993501445, 1.7724396725892908, 1.9294948705637167, 3.306480256535746, 2.6170036689227136, 3.9881969393180574, 1.6824144346035175, -0.5316005332769452, 1.00200883131416, 0.8730186809895223, 0.4710358410045214, -1.7667191460237879, -0.19589228389519667, 4.1696234012253495, -0.6328667586099389, 2.660393959432052, -7.191306943859559, 1.2884478129986003, 3.013721362259555, 4.435340563440399, -9.556192412905016, -9.878317375651857, 6.485477021070721, -5.387670729732423, 4.724608630907724, -8.60317910366224, 7.676772587610731, 4.589969368229043, -2.0236144646563794, 4.475602341842053, -0.23074168072766651, 0.8621991084021459, 5.791175619766056, -5.807734508945664, 4.364505511305734]
dir_save = joinpath(petab_model.dir_model, "Opt_results")
res = calibrate_model_multistart(petab_problem, alg, 200, dir_save; seed=1)

# Plot results 
p0 = [0.11753319620828563, 0.2534687584628469, -1.681432507324037, 0.32499151893081296, 0.36914119110141047, 0.050983215410473424, -2.2899272133243, -0.5835703303333487, 0.3833751283738198, -1.593909484316206, 0.4445738185701283, 5.045708632939731, 4.105623325645565, -4.45614380906301, -3.460630382408623, -0.69046931123274, 8.037701925042986, -0.3539866309028288, -2.3031594205870136, -3.594783044128806, -3.864628928761406, 2.003383319966077, 5.4632255243501655, 6.08593910735619, -0.24169351993501445, 1.7724396725892908, 1.9294948705637167, 3.306480256535746, 2.6170036689227136, 3.9881969393180574, 1.6824144346035175, -0.5316005332769452, 1.00200883131416, 0.8730186809895223, 0.4710358410045214, -1.7667191460237879, -0.19589228389519667, 4.1696234012253495, -0.6328667586099389, 2.660393959432052, -7.191306943859559, 1.2884478129986003, 3.013721362259555, 4.435340563440399, -9.556192412905016, -9.878317375651857, 6.485477021070721, -5.387670729732423, 4.724608630907724, -8.60317910366224, 7.676772587610731, 4.589969368229043, -2.0236144646563794, 4.475602341842053, -0.23074168072766651, 0.8621991084021459, 5.791175619766056, -5.807734508945664, 4.364505511305734]
measurement_info = petab_problem.compute_cost.measurement_info
color = [obs_id == :observable_predator ? "blue" : "orange" for obs_id in measurement_info.observable_id]
ode_sol = get_odesol(p0, petab_problem)
p = plot(ode_sol)
p = plot!(measurement_info.time, measurement_info.measurement, seriestype=:scatter, color=color)
savefig(p, "Fig_happy.png")
