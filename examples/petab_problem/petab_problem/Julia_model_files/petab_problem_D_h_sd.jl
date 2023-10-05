#u[1] = prey, u[2] = predator
#p_ode_problem[1] = α, p_ode_problem[2] = δ, p_ode_problem[3] = network1_layer_1__weight__1__1, p_ode_problem[4] = network1_layer_1__weight__1__2, p_ode_problem[5] = network1_layer_1__weight__1__3, p_ode_problem[6] = network1_layer_1__weight__1__4, p_ode_problem[7] = network1_layer_1__weight__1__5, p_ode_problem[8] = network1_layer_1__weight__2__1, p_ode_problem[9] = network1_layer_1__weight__2__2, p_ode_problem[10] = network1_layer_1__weight__2__3, p_ode_problem[11] = network1_layer_1__weight__2__4, p_ode_problem[12] = network1_layer_1__weight__2__5, p_ode_problem[13] = network1_layer_1__bias__1__1, p_ode_problem[14] = network1_layer_1__bias__1__2, p_ode_problem[15] = network1_layer_1__bias__1__3, p_ode_problem[16] = network1_layer_1__bias__1__4, p_ode_problem[17] = network1_layer_1__bias__1__5, p_ode_problem[18] = network1_layer_2__weight__1__1, p_ode_problem[19] = network1_layer_2__weight__1__2, p_ode_problem[20] = network1_layer_2__weight__1__3, p_ode_problem[21] = network1_layer_2__weight__1__4, p_ode_problem[22] = network1_layer_2__weight__1__5, p_ode_problem[23] = network1_layer_2__weight__2__1, p_ode_problem[24] = network1_layer_2__weight__2__2, p_ode_problem[25] = network1_layer_2__weight__2__3, p_ode_problem[26] = network1_layer_2__weight__2__4, p_ode_problem[27] = network1_layer_2__weight__2__5, p_ode_problem[28] = network1_layer_2__weight__3__1, p_ode_problem[29] = network1_layer_2__weight__3__2, p_ode_problem[30] = network1_layer_2__weight__3__3, p_ode_problem[31] = network1_layer_2__weight__3__4, p_ode_problem[32] = network1_layer_2__weight__3__5, p_ode_problem[33] = network1_layer_2__weight__4__1, p_ode_problem[34] = network1_layer_2__weight__4__2, p_ode_problem[35] = network1_layer_2__weight__4__3, p_ode_problem[36] = network1_layer_2__weight__4__4, p_ode_problem[37] = network1_layer_2__weight__4__5, p_ode_problem[38] = network1_layer_2__weight__5__1, p_ode_problem[39] = network1_layer_2__weight__5__2, p_ode_problem[40] = network1_layer_2__weight__5__3, p_ode_problem[41] = network1_layer_2__weight__5__4, p_ode_problem[42] = network1_layer_2__weight__5__5, p_ode_problem[43] = network1_layer_2__bias__1__1, p_ode_problem[44] = network1_layer_2__bias__1__2, p_ode_problem[45] = network1_layer_2__bias__1__3, p_ode_problem[46] = network1_layer_2__bias__1__4, p_ode_problem[47] = network1_layer_2__bias__1__5, p_ode_problem[48] = network1_layer_3__weight__1__1, p_ode_problem[49] = network1_layer_3__weight__1__2, p_ode_problem[50] = network1_layer_3__weight__2__1, p_ode_problem[51] = network1_layer_3__weight__2__2, p_ode_problem[52] = network1_layer_3__weight__3__1, p_ode_problem[53] = network1_layer_3__weight__3__2, p_ode_problem[54] = network1_layer_3__weight__4__1, p_ode_problem[55] = network1_layer_3__weight__4__2, p_ode_problem[56] = network1_layer_3__weight__5__1, p_ode_problem[57] = network1_layer_3__weight__5__2, p_ode_problem[58] = network1_layer_3__bias__1__1, p_ode_problem[59] = network1_layer_3__bias__1__2
#
function compute_∂h∂u!(u, t::Real, p_ode_problem::AbstractVector, θ_observable::AbstractVector,
                       θ_non_dynamic::AbstractVector, observableId::Symbol, parameter_map::θObsOrSdParameterMap, out) 
	if observableId == :observable_predator 
		out[2] = 1
		return nothing
	end

	if observableId == :observable_prey 
		out[1] = 1
		return nothing
	end

end

function compute_∂h∂p!(u, t::Real, p_ode_problem::AbstractVector, θ_observable::AbstractVector,
                       θ_non_dynamic::AbstractVector, observableId::Symbol, parameter_map::θObsOrSdParameterMap, out) 
	if observableId == :observable_predator 
		return nothing
	end

	if observableId == :observable_prey 
		return nothing
	end

end

function compute_∂σ∂σu!(u, t::Real, θ_sd::AbstractVector, p_ode_problem::AbstractVector,  θ_non_dynamic::AbstractVector,
                        parameter_info::ParametersInfo, observableId::Symbol, parameter_map::θObsOrSdParameterMap, out) 
	if observableId == :observable_predator 
		return nothing
	end

	if observableId == :observable_prey 
		return nothing
	end

end

function compute_∂σ∂σp!(u, t::Real, θ_sd::AbstractVector, p_ode_problem::AbstractVector,  θ_non_dynamic::AbstractVector,
                        parameter_info::ParametersInfo, observableId::Symbol, parameter_map::θObsOrSdParameterMap, out) 
	if observableId == :observable_predator 
		return nothing
	end

	if observableId == :observable_prey 
		return nothing
	end

end

