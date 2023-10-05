# This is quite a simple problem, I still get a linear vector, I just need to map the parameter
# vector correctly for this. Then it should just work. Would be best if I could set the parameter
# names to start with, and then match them with what I have in the file.
function PEtab.PEtabModel(path_yaml::String, ode_problem::ODEProblem; write_to_file=true)

    path_parameters, path_conditions, path_observables, path_measurements, dir_julia, dir_model, model_name = PEtab.read_petab_yaml(path_yaml; skip_SBML=true)

    # Setup the ODESystem via ModelingToolkit
    ode_system = modelingtoolkitize(ode_problem)

    # Extract parameter names from the p (correct names when p later is elongated to a Vector),
    # as when we applied modelingtoolkitize parameters just gets named α1, ..., α_n, this is
    # not helpful when building parameter maps, so manually maps these parameters. Flexible
    # for handling several networks of Lux-structure
    parameter_names = Vector{String}(undef, length(ode_problem.p))
    network_index, k = "1", 1
    for p_name in keys(ode_problem.p)
        # In case p is a model parameter like α
        if ode_problem.p[p_name] isa Real
            parameter_names[k] = String(p_name)
            k += 1
            continue
        end

        # If we get here it is assumed that p_name corresponds to a Neural Network
        # (can be modified later to handle more general structures)
        _parameter_names = get_parameter_names_neural_network(ode_problem.p[p_name], network_index)
        parameter_names[k:(k+length(_parameter_names)-1)] .= _parameter_names
        k += length(_parameter_names) + 1
        network_index = string(parse(Int64, network_index) + 1)
    end
    # Extract correct state-names
    state_names = string.(first.(ode_problem.u0))

    # Build parameter map, then change θ_indices building function to accept only state and parameter names
    parameters_data = CSV.read(path_parameters, DataFrame)
    _parameter_map = [Symbol(p) => 0.0 for p in parameter_names]
    for (i, _p) in pairs(parameter_names)
        ix = findfirst(x -> string(x) == _p, parameters_data[!, :parameterId])
        if !isnothing(ix)
            _parameter_map[i] = Pair(_parameter_map[i].first, parameters_data[ix, :nominalValue])
        end
    end

    # Build initial value-file and observable file
    path_u0_h_sigma = joinpath(dir_julia, model_name * "_h_sd_u0.jl")
    h_str, u0!_str, u0_str, σ_str = PEtab.create_σ_h_u0_file(model_name, path_yaml, dir_julia, parameter_names,
                                                            state_names, _parameter_map, ode_problem.u0, write_to_file)

    compute_h = @RuntimeGeneratedFunction(Meta.parse(h_str))
    compute_u0! = @RuntimeGeneratedFunction(Meta.parse(u0!_str))
    compute_u0 = @RuntimeGeneratedFunction(Meta.parse(u0_str))
    compute_σ = @RuntimeGeneratedFunction(Meta.parse(σ_str))

    path_D_h_sd = joinpath(dir_julia, model_name * "_D_h_sd.jl")
    ∂h∂u_str, ∂h∂p_str, ∂σ∂u_str, ∂σ∂p_str = PEtab.create_derivative_σ_h_file(model_name, path_yaml,
                                                                            dir_julia, parameter_names, state_names,
                                                                            _parameter_map, ode_problem.u0, write_to_file)
    compute_∂h∂u! = @RuntimeGeneratedFunction(Meta.parse(∂h∂u_str))
    compute_∂h∂p! = @RuntimeGeneratedFunction(Meta.parse(∂h∂p_str))
    compute_∂σ∂σu! = @RuntimeGeneratedFunction(Meta.parse(∂σ∂u_str))
    compute_∂σ∂σp! = @RuntimeGeneratedFunction(Meta.parse(∂σ∂p_str))

    # Until PEtabDose format is supported not callbacks allowed
    write_callbacks_str = "function getCallbacks_" * model_name * "(foo)\n"
    write_tstops_str = "\nfunction compute_tstops(u::AbstractVector, p::AbstractVector)\n"
    write_tstops_str *= "\t return Float64[]\nend\n"
    write_callbacks_str *= "\treturn CallbackSet(), Function[], false\nend"
    get_callback_function = @RuntimeGeneratedFunction(Meta.parse(write_callbacks_str))
    cbset, check_cb_active, convert_tspan = get_callback_function("https://xkcd.com/2694/") # Argument needed by @RuntimeGeneratedFunction
    compute_tstops = @RuntimeGeneratedFunction(Meta.parse(write_tstops_str))

    petab_model = PEtabModel(model_name,
                            compute_h,
                            compute_u0!,
                            compute_u0,
                            compute_σ,
                            compute_∂h∂u!,
                            compute_∂σ∂σu!,
                            compute_∂h∂p!,
                            compute_∂σ∂σp!,
                            compute_tstops,
                            convert_tspan,
                            ode_system,
                            _parameter_map,
                            ode_problem.u0,
                            parameter_names,
                            state_names,
                            dir_model,
                            dir_julia,
                            CSV.File(path_measurements, stringtype=String),
                            CSV.File(path_conditions, stringtype=String),
                            CSV.File(path_observables, stringtype=String),
                            CSV.File(path_parameters, stringtype=String),
                            "",
                            path_yaml,
                            cbset,
                            check_cb_active,
                            false,
                            true)
    return petab_model
end


# Function for extracting parameter names from a Neural Network
function get_parameter_names_neural_network(p::ComponentVector{T}, network_index)::Vector{String} where T

    out = Vector{String}(undef, length(p))
    k = 1
    for layer in keys(p)
        for component in keys(p[layer])
            for i in 1:size(p[layer][component])[2] # Column major
                for j in 1:size(p[layer][component])[1]
                    out[k] = "network" * network_index * "_" * string(layer) * "__" * string(component) * "__" * string(i) * "__" * string(j)
                    k += 1
                end
            end
        end
    end
    return out
end