#u[1] = prey, u[2] = predator
#p_ode_problem_names[1] = α, p_ode_problem_names[2] = δ, p_ode_problem_names[3] = network1_layer_1__weight__1__1, p_ode_problem_names[4] = network1_layer_1__weight__1__2, p_ode_problem_names[5] = network1_layer_1__weight__1__3, p_ode_problem_names[6] = network1_layer_1__weight__1__4, p_ode_problem_names[7] = network1_layer_1__weight__1__5, p_ode_problem_names[8] = network1_layer_1__weight__2__1, p_ode_problem_names[9] = network1_layer_1__weight__2__2, p_ode_problem_names[10] = network1_layer_1__weight__2__3, p_ode_problem_names[11] = network1_layer_1__weight__2__4, p_ode_problem_names[12] = network1_layer_1__weight__2__5, p_ode_problem_names[13] = network1_layer_1__bias__1__1, p_ode_problem_names[14] = network1_layer_1__bias__1__2, p_ode_problem_names[15] = network1_layer_1__bias__1__3, p_ode_problem_names[16] = network1_layer_1__bias__1__4, p_ode_problem_names[17] = network1_layer_1__bias__1__5, p_ode_problem_names[18] = network1_layer_2__weight__1__1, p_ode_problem_names[19] = network1_layer_2__weight__1__2, p_ode_problem_names[20] = network1_layer_2__weight__1__3, p_ode_problem_names[21] = network1_layer_2__weight__1__4, p_ode_problem_names[22] = network1_layer_2__weight__1__5, p_ode_problem_names[23] = network1_layer_2__weight__2__1, p_ode_problem_names[24] = network1_layer_2__weight__2__2, p_ode_problem_names[25] = network1_layer_2__weight__2__3, p_ode_problem_names[26] = network1_layer_2__weight__2__4, p_ode_problem_names[27] = network1_layer_2__weight__2__5, p_ode_problem_names[28] = network1_layer_2__weight__3__1, p_ode_problem_names[29] = network1_layer_2__weight__3__2, p_ode_problem_names[30] = network1_layer_2__weight__3__3, p_ode_problem_names[31] = network1_layer_2__weight__3__4, p_ode_problem_names[32] = network1_layer_2__weight__3__5, p_ode_problem_names[33] = network1_layer_2__weight__4__1, p_ode_problem_names[34] = network1_layer_2__weight__4__2, p_ode_problem_names[35] = network1_layer_2__weight__4__3, p_ode_problem_names[36] = network1_layer_2__weight__4__4, p_ode_problem_names[37] = network1_layer_2__weight__4__5, p_ode_problem_names[38] = network1_layer_2__weight__5__1, p_ode_problem_names[39] = network1_layer_2__weight__5__2, p_ode_problem_names[40] = network1_layer_2__weight__5__3, p_ode_problem_names[41] = network1_layer_2__weight__5__4, p_ode_problem_names[42] = network1_layer_2__weight__5__5, p_ode_problem_names[43] = network1_layer_2__bias__1__1, p_ode_problem_names[44] = network1_layer_2__bias__1__2, p_ode_problem_names[45] = network1_layer_2__bias__1__3, p_ode_problem_names[46] = network1_layer_2__bias__1__4, p_ode_problem_names[47] = network1_layer_2__bias__1__5, p_ode_problem_names[48] = network1_layer_3__weight__1__1, p_ode_problem_names[49] = network1_layer_3__weight__1__2, p_ode_problem_names[50] = network1_layer_3__weight__2__1, p_ode_problem_names[51] = network1_layer_3__weight__2__2, p_ode_problem_names[52] = network1_layer_3__weight__3__1, p_ode_problem_names[53] = network1_layer_3__weight__3__2, p_ode_problem_names[54] = network1_layer_3__weight__4__1, p_ode_problem_names[55] = network1_layer_3__weight__4__2, p_ode_problem_names[56] = network1_layer_3__weight__5__1, p_ode_problem_names[57] = network1_layer_3__weight__5__2, p_ode_problem_names[58] = network1_layer_3__bias__1__1, p_ode_problem_names[59] = network1_layer_3__bias__1__2
##parameter_info.nominalValue[2] = beta_C 
#parameter_info.nominalValue[3] = gamma_C 


function compute_h(u::AbstractVector, t::Real, p_ode_problem::AbstractVector, θ_observable::AbstractVector,
                   θ_non_dynamic::AbstractVector, parameter_info::ParametersInfo, observableId::Symbol,
                      parameter_map::θObsOrSdParameterMap)::Real 
	if observableId === :observable_predator 
		return u[2] 
	end

	if observableId === :observable_prey 
		return u[1] 
	end

end

function compute_u0!(u0::AbstractVector, p_ode_problem::AbstractVector) 

	#p_ode_problem[1] = α, p_ode_problem[2] = δ, p_ode_problem[3] = network1_layer_1__weight__1__1, p_ode_problem[4] = network1_layer_1__weight__1__2, p_ode_problem[5] = network1_layer_1__weight__1__3, p_ode_problem[6] = network1_layer_1__weight__1__4, p_ode_problem[7] = network1_layer_1__weight__1__5, p_ode_problem[8] = network1_layer_1__weight__2__1, p_ode_problem[9] = network1_layer_1__weight__2__2, p_ode_problem[10] = network1_layer_1__weight__2__3, p_ode_problem[11] = network1_layer_1__weight__2__4, p_ode_problem[12] = network1_layer_1__weight__2__5, p_ode_problem[13] = network1_layer_1__bias__1__1, p_ode_problem[14] = network1_layer_1__bias__1__2, p_ode_problem[15] = network1_layer_1__bias__1__3, p_ode_problem[16] = network1_layer_1__bias__1__4, p_ode_problem[17] = network1_layer_1__bias__1__5, p_ode_problem[18] = network1_layer_2__weight__1__1, p_ode_problem[19] = network1_layer_2__weight__1__2, p_ode_problem[20] = network1_layer_2__weight__1__3, p_ode_problem[21] = network1_layer_2__weight__1__4, p_ode_problem[22] = network1_layer_2__weight__1__5, p_ode_problem[23] = network1_layer_2__weight__2__1, p_ode_problem[24] = network1_layer_2__weight__2__2, p_ode_problem[25] = network1_layer_2__weight__2__3, p_ode_problem[26] = network1_layer_2__weight__2__4, p_ode_problem[27] = network1_layer_2__weight__2__5, p_ode_problem[28] = network1_layer_2__weight__3__1, p_ode_problem[29] = network1_layer_2__weight__3__2, p_ode_problem[30] = network1_layer_2__weight__3__3, p_ode_problem[31] = network1_layer_2__weight__3__4, p_ode_problem[32] = network1_layer_2__weight__3__5, p_ode_problem[33] = network1_layer_2__weight__4__1, p_ode_problem[34] = network1_layer_2__weight__4__2, p_ode_problem[35] = network1_layer_2__weight__4__3, p_ode_problem[36] = network1_layer_2__weight__4__4, p_ode_problem[37] = network1_layer_2__weight__4__5, p_ode_problem[38] = network1_layer_2__weight__5__1, p_ode_problem[39] = network1_layer_2__weight__5__2, p_ode_problem[40] = network1_layer_2__weight__5__3, p_ode_problem[41] = network1_layer_2__weight__5__4, p_ode_problem[42] = network1_layer_2__weight__5__5, p_ode_problem[43] = network1_layer_2__bias__1__1, p_ode_problem[44] = network1_layer_2__bias__1__2, p_ode_problem[45] = network1_layer_2__bias__1__3, p_ode_problem[46] = network1_layer_2__bias__1__4, p_ode_problem[47] = network1_layer_2__bias__1__5, p_ode_problem[48] = network1_layer_3__weight__1__1, p_ode_problem[49] = network1_layer_3__weight__1__2, p_ode_problem[50] = network1_layer_3__weight__2__1, p_ode_problem[51] = network1_layer_3__weight__2__2, p_ode_problem[52] = network1_layer_3__weight__3__1, p_ode_problem[53] = network1_layer_3__weight__3__2, p_ode_problem[54] = network1_layer_3__weight__4__1, p_ode_problem[55] = network1_layer_3__weight__4__2, p_ode_problem[56] = network1_layer_3__weight__5__1, p_ode_problem[57] = network1_layer_3__weight__5__2, p_ode_problem[58] = network1_layer_3__bias__1__1, p_ode_problem[59] = network1_layer_3__bias__1__2

	t = 0.0 # u at time zero

	prey = 0.44249296 
	predator = 4.6280594 

	u0 .= prey, predator
end

function compute_u0(p_ode_problem::AbstractVector)::AbstractVector 

	#p_ode_problem[1] = α, p_ode_problem[2] = δ, p_ode_problem[3] = network1_layer_1__weight__1__1, p_ode_problem[4] = network1_layer_1__weight__1__2, p_ode_problem[5] = network1_layer_1__weight__1__3, p_ode_problem[6] = network1_layer_1__weight__1__4, p_ode_problem[7] = network1_layer_1__weight__1__5, p_ode_problem[8] = network1_layer_1__weight__2__1, p_ode_problem[9] = network1_layer_1__weight__2__2, p_ode_problem[10] = network1_layer_1__weight__2__3, p_ode_problem[11] = network1_layer_1__weight__2__4, p_ode_problem[12] = network1_layer_1__weight__2__5, p_ode_problem[13] = network1_layer_1__bias__1__1, p_ode_problem[14] = network1_layer_1__bias__1__2, p_ode_problem[15] = network1_layer_1__bias__1__3, p_ode_problem[16] = network1_layer_1__bias__1__4, p_ode_problem[17] = network1_layer_1__bias__1__5, p_ode_problem[18] = network1_layer_2__weight__1__1, p_ode_problem[19] = network1_layer_2__weight__1__2, p_ode_problem[20] = network1_layer_2__weight__1__3, p_ode_problem[21] = network1_layer_2__weight__1__4, p_ode_problem[22] = network1_layer_2__weight__1__5, p_ode_problem[23] = network1_layer_2__weight__2__1, p_ode_problem[24] = network1_layer_2__weight__2__2, p_ode_problem[25] = network1_layer_2__weight__2__3, p_ode_problem[26] = network1_layer_2__weight__2__4, p_ode_problem[27] = network1_layer_2__weight__2__5, p_ode_problem[28] = network1_layer_2__weight__3__1, p_ode_problem[29] = network1_layer_2__weight__3__2, p_ode_problem[30] = network1_layer_2__weight__3__3, p_ode_problem[31] = network1_layer_2__weight__3__4, p_ode_problem[32] = network1_layer_2__weight__3__5, p_ode_problem[33] = network1_layer_2__weight__4__1, p_ode_problem[34] = network1_layer_2__weight__4__2, p_ode_problem[35] = network1_layer_2__weight__4__3, p_ode_problem[36] = network1_layer_2__weight__4__4, p_ode_problem[37] = network1_layer_2__weight__4__5, p_ode_problem[38] = network1_layer_2__weight__5__1, p_ode_problem[39] = network1_layer_2__weight__5__2, p_ode_problem[40] = network1_layer_2__weight__5__3, p_ode_problem[41] = network1_layer_2__weight__5__4, p_ode_problem[42] = network1_layer_2__weight__5__5, p_ode_problem[43] = network1_layer_2__bias__1__1, p_ode_problem[44] = network1_layer_2__bias__1__2, p_ode_problem[45] = network1_layer_2__bias__1__3, p_ode_problem[46] = network1_layer_2__bias__1__4, p_ode_problem[47] = network1_layer_2__bias__1__5, p_ode_problem[48] = network1_layer_3__weight__1__1, p_ode_problem[49] = network1_layer_3__weight__1__2, p_ode_problem[50] = network1_layer_3__weight__2__1, p_ode_problem[51] = network1_layer_3__weight__2__2, p_ode_problem[52] = network1_layer_3__weight__3__1, p_ode_problem[53] = network1_layer_3__weight__3__2, p_ode_problem[54] = network1_layer_3__weight__4__1, p_ode_problem[55] = network1_layer_3__weight__4__2, p_ode_problem[56] = network1_layer_3__weight__5__1, p_ode_problem[57] = network1_layer_3__weight__5__2, p_ode_problem[58] = network1_layer_3__bias__1__1, p_ode_problem[59] = network1_layer_3__bias__1__2

	t = 0.0 # u at time zero

	prey = 0.44249296 
	predator = 4.6280594 

	 return [prey, predator]
end

function compute_σ(u::AbstractVector, t::Real, θ_sd::AbstractVector, p_ode_problem::AbstractVector,  θ_non_dynamic::AbstractVector,
                   parameter_info::ParametersInfo, observableId::Symbol, parameter_map::θObsOrSdParameterMap)::Real 
	if observableId === :observable_predator 
		return 1.0 
	end

	if observableId === :observable_prey 
		return 1.0 
	end


end

