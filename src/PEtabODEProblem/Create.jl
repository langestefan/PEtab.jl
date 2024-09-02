function PEtabODEProblem(model::PEtabModel;
                         odesolver::Union{Nothing, ODESolver} = nothing,
                         odesolver_gradient::Union{Nothing, ODESolver} = nothing,
                         ss_solver::Union{Nothing, SteadyStateSolver} = nothing,
                         ss_solver_gradient::Union{Nothing, SteadyStateSolver} = nothing,
                         gradient_method::Union{Nothing, Symbol} = nothing,
                         hessian_method::Union{Nothing, Symbol} = nothing,
                         FIM_method::Union{Nothing, Symbol} = nothing,
                         sparse_jacobian::Union{Nothing, Bool} = nothing,
                         specialize_level = SciMLBase.FullSpecialize,
                         sensealg = nothing,
                         sensealg_ss = nothing,
                         chunksize::Union{Nothing, Int64} = nothing,
                         split_over_conditions::Bool = false,
                         reuse_sensitivities::Bool = false,
                         verbose::Bool = true,
                         custom_values::Union{Nothing, Dict} = nothing)::PEtabODEProblem
    _logging(:Build_PEtabODEProblem, verbose; name = model.modelname)

    # To bookeep parameters, measurements, etc...
    model_info = ModelInfo(model, sensealg, custom_values)
    # All ODE-relevent info for the problem, e.g. solvers, gradient method ...
    probleminfo = PEtabODEProblemInfo(model, model_info, odesolver, odesolver_gradient,
                                      ss_solver, ss_solver_gradient, gradient_method,
                                      hessian_method, FIM_method, sensealg, sensealg_ss,
                                      reuse_sensitivities, sparse_jacobian, specialize_level,
                                      chunksize, split_over_conditions, verbose)

    # The prior enters into the nllh, grad, and hessian functions and is evaluated by
    # default (keyword user can toggle). Grad and hess are not inplace, in order to
    # to not overwrite the nllh hess/grad when evaluating total grad/hess
    prior, grad_prior, hess_prior = _get_prior_f(model_info)

    _logging(:Build_nllh, verbose)
    btime = @elapsed begin
        nllh = _get_nllh_f(probleminfo, model_info, prior, false)
    end
    _logging(:Build_nllh, verbose; time = btime)

    _logging(:Build_gradient, verbose; method = probleminfo.gradient_method)
    btime = @elapsed begin
        method = probleminfo.gradient_method
        grad!, grad = _get_grad_f(Val(method), probleminfo, model_info, grad_prior)
        nllh_grad = _get_nllh_grad_f(method, grad, prior, probleminfo, model_info)
    end
    _logging(:Build_gradient, verbose; time = btime)

    _logging(:Build_hessian, verbose; method = probleminfo.hessian_method)
    btime = @elapsed begin
        hess!, hess = _get_hess_f(probleminfo, model_info, hess_prior)
        FIM!, FIM = _get_hess_f(probleminfo, model_info, hess_prior; FIM = true)
    end
    _logging(:Build_hessian, verbose; time = btime)

    # TODO: Must refactor later
    compute_chi2 = (θ; as_array = false) -> begin
        _ = nllh(θ)
        if as_array == false
            return sum(measurement_info.chi2_values)
        else
            return measurement_info.chi2_values
        end
    end
    compute_residuals = (θ; as_array = false) -> begin
        _ = nllh(θ)
        if as_array == false
            return sum(measurement_info.residuals)
        else
            return measurement_info.residuals
        end
    end
    compute_simulated_values = (θ) -> begin
        _ = nllh(θ)
        return measurement_info.simulated_values
    end

    # Relevant parameter information for the parameter estimation problem
    xnames = model_info.θ_indices.xids[:estimate]
    nestimate = length(xnames)
    lb = _get_bounds(model_info, xnames, :lower)
    ub = _get_bounds(model_info, xnames, :upper)
    xnominal = _get_xnominal(model_info, xnames, false)
    xnominal_transformed = _get_xnominal(model_info, xnames, true)

    return PEtabODEProblem(nllh, compute_chi2, grad!, grad, hess!, hess, FIM!, FIM,
                           nllh_grad, prior, grad_prior, hess_prior,
                           compute_simulated_values, compute_residuals, probleminfo,
                           model_info, nestimate, xnames, xnominal, xnominal_transformed,
                           lb, ub)
end

function PEtabODEProblemInfo(model::PEtabModel, model_info::ModelInfo, odesolver,
                             odesolver_gradient, ss_solver, ss_solver_gradient,
                             gradient_method, hessian_method, FIM_method, sensealg,
                             sensealg_ss, reuse_sensitivities::Bool, sparse_jacobian,
                             specialize_level, chunksize, split_over_conditions::Bool,
                             verbose::Bool)::PEtabODEProblemInfo
    model_size = _get_model_size(model.sys_mutated, model_info)
    gradient_method_use = _get_gradient_method(gradient_method, model_size,
                                               reuse_sensitivities)
    hessian_method_use = _get_hessian_method(hessian_method, model_size)
    FIM_method_use = _get_hessian_method(FIM_method, model_size)
    sensealg_use = _get_sensealg(sensealg, Val(gradient_method_use))
    sensealg_ss_use = _get_sensealg_ss(sensealg_ss, sensealg_use, model_info,
                                       Val(gradient_method_use))

    _check_method(gradient_method_use, :gradient)
    _check_method(hessian_method_use, :Hessian)
    _check_method(FIM_method_use, :FIM)

    odesolver_use = _get_odesolver(odesolver, model_size, gradient_method_use)
    odesolver_gradient_use = _get_odesolver(odesolver_gradient, model_size,
                                            gradient_method_use;
                                            default_solver = odesolver_use)
    _ss_solver = _get_ss_solver(ss_solver, odesolver_use)
    _ss_solver_gradient = _get_ss_solver(ss_solver_gradient, odesolver_gradient_use)
    sparse_jacobian_use = _get_sparse_jacobian(sparse_jacobian, model_size)
    chunksize_use = isnothing(chunksize) ? 0 : chunksize

    # Cache to avoid allocations to as large degree as possible. TODO: Refactor into single
    cache = PEtabODEProblemCache(gradient_method_use, hessian_method_use, FIM_method_use,
                                 sensealg_use, model_info)

    _logging(:Build_ODEProblem, verbose)
    btime = @elapsed begin
        _set_constant_ode_parameters!(model, model_info.parameter_info)
        @unpack sys_mutated, statemap, parametermap, defined_in_julia = model
        if sys_mutated isa ODESystem && defined_in_julia == false
            SL = specialize_level
            _oprob = ODEProblem{true, SL}(sys_mutated, statemap, [0.0, 5e3], parametermap;
                                          jac = true, sparse = sparse_jacobian_use)
        else
            # For ReactionSystem there is bug if I try to set specialize_level. Also,
            # statemap must somehow be a vector. TODO: Test with MTKv9
            u0map_tmp = zeros(Float64, length(model.statemap))
            _oprob = ODEProblem(sys_mutated, u0map_tmp, [0.0, 5e3], parametermap;
                                jac = true, sparse = sparse_jacobian_use)
        end
        # Ensure correct types for further computations
        oprob = remake(_oprob, p = Float64.(_oprob.p), u0 = Float64.(_oprob.u0))
        oprob_gradient = _get_odeproblem_gradient(oprob, gradient_method_use, sensealg_use)
    end
    _logging(:Build_ODEProblem, verbose; time = btime)

    # To build the steady-state solvers the ODEProblem (specifically its Jacobian)
    # is needed (which is the same for oprob and oprob_gradient)
    ss_solver_use = _get_steady_state_solver(_ss_solver, oprob)
    ss_solver_gradient_use = _get_steady_state_solver(_ss_solver_gradient, oprob)

    return PEtabODEProblemInfo(oprob, oprob_gradient, odesolver_use, odesolver_gradient_use,
                               ss_solver_use, ss_solver_gradient_use, gradient_method_use,
                               hessian_method_use, FIM_method_use, reuse_sensitivities,
                               sparse_jacobian_use, sensealg_use, sensealg_ss_use,
                               cache, split_over_conditions, chunksize_use)
end

function _get_nllh_f(probleminfo::PEtabODEProblemInfo, model_info::ModelInfo,
                     prior::Function, residuals::Bool)::Function
    _nllh = let pinfo = probleminfo, minfo = model_info, res = residuals, _prior = prior
        (x; prior = true) -> begin
            nllh_val = nllh(x, pinfo, minfo, [:all], false, res)
            if prior == true && res == false
                # nllh -> negative prior
                return nllh_val - _prior(x)
            else
                return nllh_val
            end
        end
    end
    return _nllh
end

function _get_grad_f(method, probleminfo::PEtabODEProblemInfo, model_info::ModelInfo,
                     grad_prior::Function)::Tuple{Function, Function}
    if probleminfo.gradient_method == :ForwardDiff
        _grad_nllh! = _get_grad_forward_AD(probleminfo, model_info)
    end
    if probleminfo.gradient_method == :ForwardEquations
        _grad_nllh! = _get_grad_forward_eqs(probleminfo, model_info)
    end

    _grad! = let _grad_nllh! = _grad_nllh!, grad_prior = grad_prior
        (g, x; prior = true) -> begin
            _grad_nllh!(g, x)
            if prior
                # nllh -> negative prior
                g .+= grad_prior(x) .* -1
            end
        end
    end
    _grad = let _grad! = _grad!
        (x; prior = true) -> begin
            gradient = zeros(Float64, length(x))
            _grad!(gradient, x; prior = prior)
            return gradient
        end
    end
    return _grad!, _grad
end

function _get_hess_f(probleminfo::PEtabODEProblemInfo, model_info::ModelInfo,
                     hess_prior::Function; ret_jacobian::Bool = false,
                     FIM::Bool = false)::Tuple{Function, Function}
    @unpack hessian_method, split_over_conditions, chunksize, cache = probleminfo
    @unpack xdynamic = cache
    if FIM == true
        hessian_method = probleminfo.FIM_method
    end

    if hessian_method === :ForwardDiff
        if split_over_conditions == false
            _nllh = let pinfo = probleminfo, minfo = model_info
                (x) -> nllh(x, pinfo, minfo, [:all], true, false)
            end

            nestimate = length(model_info.θ_indices.xids[:estimate])
            chunksize_use = _get_chunksize(chunksize, zeros(nestimate))
            cfg = ForwardDiff.HessianConfig(_nllh, zeros(nestimate), chunksize_use)
            _hess_nllh! = let _nllh = _nllh, cfg = cfg, minfo = model_info
                (H, x) -> hess!(H, x, _nllh, minfo, cfg)
            end
        end

        if split_over_conditions == true
            _nllh = let pinfo = probleminfo, minfo = model_info
                (x, cid) -> nllh(x, pinfo, minfo, cid, true, false)
            end

            _hess_nllh! = let _nllh = _nllh, minfo = model_info
                (H, x) -> hess_split!(H, x, _nllh, minfo)
            end
        end
    end

    if hessian_method === :BlockForwardDiff
        _nllh_not_solveode = _get_nllh_not_solveode(probleminfo, model_info; grad_forward_AD = true)

        if split_over_conditions == false
            _nllh_solveode = let pinfo = probleminfo, minfo = model_info
                @unpack xnoise, xobservable, xnondynamic = pinfo.cache
                (x) -> nllh_solveode(x, xnoise, xobservable, xnondynamic, pinfo, minfo;
                                     grad_xdynamic = true, cids = [:all])
            end

            chunksize_use = _get_chunksize(chunksize, xdynamic)
            cfg = ForwardDiff.HessianConfig(_nllh_solveode, xdynamic, chunksize_use)
            _hess_nllh! = let _nllh_solveode = _nllh_solveode,
                _nllh_not_solveode = _nllh_not_solveode, pinfo = probleminfo, minfo = model_info,
                cfg = cfg

                (H, x) -> hess_block!(H, x, _nllh_not_solveode, _nllh_solveode, pinfo,
                                      minfo, cfg; cids = [:all])
            end
        end

        if split_over_conditions == true
            _nllh_solveode = let pinfo = probleminfo, minfo = model_info
                @unpack xnoise, xobservable, xnondynamic = pinfo.cache
                (x, cid) -> nllh_solveode(x, xnoise, xobservable, xnondynamic,
                                                   pinfo, minfo,
                                                   grad_xdynamic = true,
                                                   cids = cid)
            end

            _hess_nllh! = let _nllh_solveode = _nllh_solveode,
                _nllh_not_solveode = _nllh_not_solveode, pinfo = probleminfo, minfo = model_info
                (H, x) -> hess_block_split!(H, x, _nllh_not_solveode, _nllh_solveode,
                                            pinfo, minfo; cids = [:all])
            end
        end
    end

    if hessian_method == :GaussNewton
        if split_over_conditions == false
            _solve_conditions! = let pinfo = probleminfo, minfo = model_info
                (sols, x) -> solve_conditions!(sols, x, pinfo, minfo; cids = [:all],
                                               sensitivites_AD = true)
            end
        end
        if split_over_conditions == true
            _solve_conditions! = let pinfo = probleminfo, minfo = model_info
                (sols, x, cid) -> solve_conditions!(sols, x, pinfo, minfo; cids = cid,
                                                    sensitivites_AD = true)
            end
        end
        chunksize_use = _get_chunksize(chunksize, xdynamic)
        cfg = cfg = ForwardDiff.JacobianConfig(_solve_conditions!,
                                               cache.odesols,
                                               cache.xdynamic, chunksize_use)

        _residuals_not_solveode = let pinfo = probleminfo, minfo = model_info
            ixnoise = minfo.θ_indices.xindices_notsys[:noise]
            ixobservable = minfo.θ_indices.xindices_notsys[:observable]
            ixnondynamic = minfo.θ_indices.xindices_notsys[:nondynamic]
            (residuals, x) -> begin
                residuals_not_solveode(residuals, x[ixnoise], x[ixobservable],
                                       x[ixnondynamic], pinfo, minfo; cids = [:all])
            end
        end

        xnot_ode = zeros(Float64, length(model_info.θ_indices.xids[:not_system]))
        cfg_notsolve = ForwardDiff.JacobianConfig(_residuals_not_solveode,
                                                  cache.residuals_gn, xnot_ode,
                                                  ForwardDiff.Chunk(xnot_ode))
        _hess_nllh! = let _residuals_not_solveode = _residuals_not_solveode,
            pinfo = probleminfo, minfo = model_info, cfg = cfg, cfg_notsolve = cfg_notsolve,
            ret_jacobian = ret_jacobian, _solve_conditions! = _solve_conditions!

            (H, x; isremade = false) -> hess_GN!(H, x, _residuals_not_solveode,
                                                 _solve_conditions!, pinfo, minfo, cfg,
                                                 cfg_notsolve; cids = [:all],
                                                 isremade = isremade,
                                                 ret_jacobian = ret_jacobian)
        end
    end

    _hess! = let _hess_nllh! = _hess_nllh!, hess_prior = hess_prior
        (H, x; prior = true) -> begin
            _hess_nllh!(H, x)
            if prior
                # nllh -> negative prior
                H .+= hess_prior(x) .* -1
            end
        end
    end
    _hess = (x; prior = true) -> begin
        H = zeros(eltype(x), length(x), length(x))
        _hess!(H, x; prior = prior)
        return H
    end
    return _hess!, _hess
end

function _get_prior_f(model_info::ModelInfo)::Tuple{Function, Function, Function}
    _prior = let minfo = model_info
        @unpack θ_indices, prior_info = minfo
        (x) -> begin
            xnames = θ_indices.xids[:estimate]
            return prior(x, xnames, prior_info, θ_indices)
        end
    end
    _grad_prior = let p = _prior
        x -> ForwardDiff.gradient(p, x)
    end
    _hess_prior = let p = _prior
        x -> ForwardDiff.hessian(p, x)
    end
    return _prior, _grad_prior, _hess_prior
end

function _get_nllh_grad_f(gradient_method::Symbol, grad::Function, _prior::Function,
                          probleminfo::PEtabODEProblemInfo, model_info::ModelInfo)::Function
    grad_forward_AD = gradient_method == :ForwardDiff
    grad_forward_eqs = gradient_method == :ForwardEquations
    grad_adjoint = gradient_method == :Adjoint

    _nllh_not_solveode = _get_nllh_not_solveode(probleminfo, model_info;
                                                grad_forward_AD = grad_forward_AD,
                                                grad_forward_eqs = grad_forward_eqs,
                                                grad_adjoint = grad_adjoint)
    _compute_nllh_grad = (x; prior = true) -> begin
        g = grad(x; prior = prior)
        nllh = _nllh_not_solveode(x)
        if prior
            nllh += _prior(x)
        end
        return nllh, g
    end
    return _compute_nllh_grad
end

function _get_nllh_not_solveode(probleminfo::PEtabODEProblemInfo, model_info::ModelInfo;
                                grad_forward_AD::Bool = false, grad_adjoint::Bool = false,
                                grad_forward_eqs::Bool = false)::Function
    _nllh_not_solveode = let pinfo = probleminfo, minfo = model_info
        ixnoise = minfo.θ_indices.xindices_notsys[:noise]
        ixobservable = minfo.θ_indices.xindices_notsys[:observable]
        ixnondynamic = minfo.θ_indices.xindices_notsys[:nondynamic]
        (x) -> nllh_not_solveode(x[ixnoise], x[ixobservable], x[ixnondynamic], pinfo, minfo;
                                 cids = [:all], grad_forward_AD = grad_forward_AD,
                                 grad_forward_eqs = grad_forward_eqs,
                                 grad_adjoint = grad_adjoint)
    end
    return _nllh_not_solveode
end

function _get_nllh_solveode(probleminfo::PEtabODEProblemInfo, model_info::ModelInfo;
                            grad_xdynamic::Bool = false, cid::Bool = false)
    if cid == false
        _nllh_solveode = let pinfo = probleminfo, minfo = model_info
            @unpack xnoise, xobservable, xnondynamic = pinfo.cache
            (x) -> nllh_solveode(x, xnoise, xobservable, xnondynamic, pinfo, minfo; grad_xdynamic = grad_xdynamic, cids = [:all])
        end
    else
        _nllh_solveode = let pinfo = probleminfo, minfo = model_info
            @unpack xnoise, xobservable, xnondynamic = pinfo.cache
            (x, _cid) -> nllh_solveode(x, xnoise, xobservable, xnondynamic, pinfo, minfo; grad_xdynamic = grad_xdynamic, cids = _cid)
        end
    end
    return _nllh_solveode
end

function _get_grad_forward_AD(probleminfo::PEtabODEProblemInfo, model_info::ModelInfo)::Function
    @unpack split_over_conditions, gradient_method, chunksize = probleminfo
    @unpack sensealg, cache = probleminfo
    _nllh_not_solveode = _get_nllh_not_solveode(probleminfo, model_info; grad_forward_AD = true)

    if split_over_conditions == false
        _nllh_solveode = _get_nllh_solveode(probleminfo, model_info; grad_xdynamic = true)

        @unpack xdynamic = cache
        chunksize_use = _get_chunksize(chunksize, xdynamic)
        cfg = ForwardDiff.GradientConfig(_nllh_solveode, xdynamic, chunksize_use)
        _grad! = let _nllh_not_solveode = _nllh_not_solveode, _nllh_solveode = _nllh_solveode, cfg = cfg, minfo = model_info, pinfo = probleminfo
            (grad, x; isremade = false) -> grad_forward_AD!(grad, x, _nllh_not_solveode, _nllh_solveode, cfg, pinfo, minfo; isremade = isremade)
        end
    end

    if split_over_conditions == true
        _nllh_solveode = _get_nllh_solveode(probleminfo, model_info; cid = true, grad_xdynamic = true)

        _grad! = let _nllh_not_solveode = _nllh_not_solveode, _nllh_solveode = _nllh_solveode, minfo = model_info, pinfo = probleminfo
            (g, θ) -> grad_forward_AD_split!(g, θ, _nllh_not_solveode, _nllh_solveode, pinfo, minfo)
        end
    end
    return _grad!
end

function _get_grad_forward_eqs(probleminfo::PEtabODEProblemInfo, model_info::ModelInfo)::Function
    @unpack split_over_conditions, gradient_method, chunksize = probleminfo
    @unpack sensealg, cache = probleminfo
    @unpack xdynamic, odesols = cache
    chunksize_use = _get_chunksize(chunksize, xdynamic)

    if sensealg == :ForwardDiff && split_over_conditions == false
        _solve_conditions! = let pinfo = probleminfo, minfo = model_info
            (sols, x) -> solve_conditions!(sols, x, pinfo, minfo;  sensitivites_AD = true)
        end
        cfg = ForwardDiff.JacobianConfig(_solve_conditions!, odesols, xdynamic, chunksize_use)
    end

    if sensealg == :ForwardDiff && split_over_conditions == true
        _solve_conditions! = let pinfo = probleminfo, minfo = model_info
            (sols, x, cid) -> solve_conditions!(sols, x, pinfo, minfo; cids = cid, sensitivites_AD = true)
        end
        cfg = ForwardDiff.JacobianConfig(_solve_conditions!, odesols, xdynamic, chunksize_use)
    end

    if sensealg != :ForwardDiff
        _solve_conditions! = let pinfo = probleminfo, minfo = model_info
            (x, cid) -> solve_conditions!(minfo, x, pinfo; cids = cid, sensitivites = true)
        end
        cfg = nothing
    end

    _nllh_not_solveode = _get_nllh_not_solveode(probleminfo, model_info; grad_forward_eqs = true)

    _grad! = let _nllh_not_solveode = _nllh_not_solveode, _solve_conditions! = _solve_conditions!, minfo = model_info, pinfo = probleminfo, cfg = cfg
            (g, x; isremade = false) -> grad_forward_eqs!(g, x, _nllh_not_solveode,
                                                          _solve_conditions!, pinfo, minfo,
                                                          cfg; cids = [:all], isremade = isremade)
    end
    return _grad!
end

function _get_bounds(model_info::ModelInfo, xnames::Vector{Symbol},
                     which::Symbol)::Vector{Float64}
    @unpack parameter_info, θ_indices = model_info
    ix = [findfirst(x -> x == id, parameter_info.parameter_id) for id in xnames]
    if which == :lower
        bounds = parameter_info.lower_bounds[ix]
    else
        bounds = parameter_info.upper_bounds[ix]
    end
    transform_x!(bounds, xnames, θ_indices, reverse_transform = true)
    return bounds
end

function _get_xnominal(model_info::ModelInfo, xnames::Vector{Symbol},
                       transform::Bool)::Vector{Float64}
    @unpack parameter_info, θ_indices = model_info
    ix = [findfirst(x -> x == id, parameter_info.parameter_id) for id in xnames]
    xnominal = parameter_info.nominal_value[ix]
    if transform == true
        transform_x!(xnominal, xnames, θ_indices, reverse_transform = true)
    end
    return xnominal
end
