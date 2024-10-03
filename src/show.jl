#=
    Functions for better printing of relevant PEtab-structs which are
    exported to the user.
=#
import Base.show

StyledStrings.addface!(:PURPLE => StyledStrings.Face(foreground = 0x8f4093))

function _get_solver_show(solver::ODESolver)::Tuple{String, String}
    @unpack abstol, reltol, maxiters = solver
    options = @sprintf("(abstol, reltol, maxiters) = (%.1e, %.1e, %.0e)", abstol, reltol,
                       maxiters)
    # First needed to handle expressions on the form OrdinaryDiffEq.Rodas5P...
    _solver = string(solver.solver)
    if length(_solver) ≥ 14 && _solver[1:14] == "OrdinaryDiffEq"
        _solver = split(string(solver.solver), ".")[2:end] |> prod
    end
    _solver = match(r"^[^({]+", _solver).match
    if length(_solver) ≥ 9 && _solver[1:9] == "Sundials."
        _solver = replace(_solver, "Sundials." => "")
    end
    return _solver, options
end

function _get_ss_solver_show(ss_solver::SteadyStateSolver; onlyheader::Bool = false)
    if ss_solver.method === :Simulate
        heading = styled"{emphasis:Simulate} ODE until du = f(u, p, t) ≈ 0"
        if ss_solver.termination_check === :wrms
            opt = styled"\nTerminates when {emphasis:wrms} = \
                        (∑((du ./ (reltol * u .+ abstol)).^2) / len(u)) < 1"
        else
            opt = styled"\nTerminates when {emphasis:Newton} step Δu = \
                         √(∑((Δu ./ (reltol * u .+ abstol)).^2) / len(u)) < 1"
        end
    else
        heading = styled"{emphasis:Rootfinding} to solve du = f(u, p, t) ≈ 0"
        alg = match(r"^[^({]+", ss_solver.rootfinding_alg |> string).match
        opt = styled"\n{emphasis:Algorithm:} $(alg) with NonlinearSolve.jl termination"
    end
    if onlyheader
        return heading
    else
        return styled"$(heading)$(opt)"
    end
end

function show(io::IO, solver::ODESolver)
    _solver, options = _get_solver_show(solver)
    str = styled"{PURPLE:{bold:ODESolver:}} {emphasis:$(_solver)} with options $options"
    print(io, str)
end
function show(io::IO, ss_solver::SteadyStateSolver)
    str = styled"{PURPLE:{bold:SteadyStateSolver:}} "
    options = _get_ss_solver_show(ss_solver)
    print(io, styled"$(str)$(options)")
end
function show(io::IO, parameter::PEtabParameter)
    header = styled"{PURPLE:{bold:PEtabParameter:}} {emphasis:$(parameter.parameter)} "
    @unpack scale, lb, ub, prior = parameter
    opt = @sprintf("estimated on %s-scale with bounds [%.1e, %.1e]", scale, lb, ub)
    if !isnothing(prior)
        prior_str = replace(prior |> string, r"\{[^}]+\}" => "")
        if length(prior_str) ≥ 14 && prior_str[1:14] == "Distributions."
            prior_str = replace(prior_str, "Distributions." => "")
        end
        opt *= @sprintf(" and prior %s", prior_str)
    end
    print(io, styled"$(header)$(opt)")
end
function show(io::IO, observable::PEtabObservable)
    @unpack obs, noise_formula, transformation = observable
    header = styled"{PURPLE:{bold:PEtabObservable:}} "
    opt1 = styled"{emphasis:h} = $(obs) and {emphasis:sd} = $(noise_formula)"
    if transformation in [:log, :log10]
        opt = styled"$opt1 with log-normal measurement noise"
    else
        opt = styled"$opt1 with normal measurement noise"
    end
    print(io, styled"$(header)$(opt)")
end
function show(io::IO, event::PEtabEvent)
    @unpack condition, target, affect = event
    header = styled"{PURPLE:{bold:PEtabEvent:}} "
    if is_number(string(condition))
        _cond = "t == " * string(condition)
    else
        _cond = condition |> string
    end
    if target isa Vector
        target_str = "["
        for tg in target
            target_str *= (tg |> string) * ", "
        end
        target_str = target_str[1:(end - 2)] * "]"
    else
        target_str = target |> string
    end
    if affect isa Vector
        affect_str = "["
        for af in affect
            affect_str *= (af |> string) * ", "
        end
        affect_str = affect_str[1:(end - 2)] * "]"
    else
        affect_str = affect |> string
    end
    effect_str = target_str * " = " * affect_str
    opt = styled"{emphasis:Condition} $_cond and {emphasis:affect} $effect_str"
    print(io, styled"$(header)$(opt)")
end
function show(io::IO, model::PEtabModel)
    nstates = @sprintf("%d", length(unknowns(model.sys_mutated)))
    nparameters = @sprintf("%d", length(parameters(model.sys_mutated)))
    header = styled"{PURPLE:{bold:PEtabModel:}} {emphasis:$(model.name)} with $nstates states \
                    and $nparameters parameters"
    if haskey(model.paths, :dirjulia) && !isempty(model.paths[:dirjulia])
        opt = @sprintf("\nGenerated Julia model files are at %s", model.paths[:dirjulia])
    else
        opt = ""
    end
    print(io, styled"$(header)$(opt)")
end
function show(io::IO, prob::PEtabODEProblem)
    @unpack probinfo, model_info, nparameters_estimate = prob
    name = model_info.model.name
    nstates = @sprintf("%d", length(unknowns(model_info.model.sys_mutated)))
    nest = @sprintf("%d", nparameters_estimate)

    header = styled"{PURPLE:{bold:PEtabODEProblem:}} {emphasis:$(name)} with ODE-states \
                    $nstates and $nest parameters to estimate"

    optheader = styled"\n---------------- {PURPLE:{bold:Problem options}} ---------------\n"
    opt1 = styled"Gradient method: {emphasis:$(probinfo.gradient_method)}\n"
    opt2 = styled"Hessian method: {emphasis:$(probinfo.hessian_method)}\n"
    solver1, options1 = _get_solver_show(probinfo.solver)
    solver2, options2 = _get_solver_show(probinfo.solver_gradient)
    opt3 = styled"ODE-solver nllh: {emphasis:$(solver1)}\n"
    opt4 = styled"ODE-solver gradient: {emphasis:$(solver2)}"
    if model_info.simulation_info.has_pre_equilibration == false
        print(io, styled"$(header)$(optheader)$(opt1)$(opt2)$(opt3)$(opt4)")
        return nothing
    end
    ss_solver1 = _get_ss_solver_show(probinfo.ss_solver; onlyheader = true)
    ss_solver2 = _get_ss_solver_show(probinfo.ss_solver_gradient, onlyheader = true)
    opt5 = styled"\nss-solver: $(ss_solver1)\n"
    opt6 = styled"ss-solver gradient: $(ss_solver2)"
    print(io, styled"$(header)$(optheader)$(opt1)$(opt2)$(opt3)$(opt4)$(opt5)$(opt6)")
end
function show(io::IO, res::PEtabOptimisationResult)
    header = styled"{PURPLE:{bold:PEtabOptimisationResult}}"
    optheader = styled"\n---------------- {PURPLE:{bold:Summary}} ---------------\n"
    opt1 = @sprintf("min(f)                = %.2e\n", res.fmin)
    opt2 = @sprintf("Parameters estimated  = %d\n", length(res.x0))
    opt3 = @sprintf("Optimiser iterations  = %d\n", res.niterations)
    opt4 = @sprintf("Runtime               = %.1es\n", res.runtime)
    opt5 = @sprintf("Optimiser algorithm   = %s\n", res.alg)
    print(io, styled"$(header)$(optheader)$(opt1)$(opt2)$(opt3)$(opt4)$(opt5)")
end
function show(io::IO, res::PEtabMultistartResult)
    header = styled"{PURPLE:{bold:PEtabMultistartResult}}"
    optheader = styled"\n---------------- {PURPLE:{bold:Summary}} ---------------\n"
    opt1 = @sprintf("min(f)                = %.2e\n", res.fmin)
    opt2 = @sprintf("Parameters estimated  = %d\n", length(res.xmin))
    opt3 = @sprintf("Number of multistarts = %d\n", res.nmultistarts)
    opt4 = @sprintf("Optimiser algorithm   = %s\n", res.alg)
    if !isnothing(res.dirsave)
        opt5 = @sprintf("Results saved at %s\n", res.dirsave)
    else
        opt5 = ""
    end
    print(io, styled"$(header)$(optheader)$(opt1)$(opt2)$(opt3)$(opt4)$(opt5)")
end
function show(io::IO, alg::Fides)
    print(io, "Fides(hessian_method = $(alg.hessian_method); verbose = $(alg.verbose))")
end
function show(io::IO, alg::IpoptOptimizer)
    print(io, "Ipopt(LBFGS = $(alg.LBFGS))")
end
function show(io::IO, target::PEtabLogDensity)
    out = styled"{PURPLE:{bold:PEtabLogDensity}} with $(target.dim) parameters to infer"
    print(io, out)
end
