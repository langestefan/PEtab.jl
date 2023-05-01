#u[1] = B, u[2] = A
#pODEProblemNames[1] = compartment, pODEProblemNames[2] = b0, pODEProblemNames[3] = k1, pODEProblemNames[4] = a0, pODEProblemNames[5] = k2, pODEProblemNames[6] = __init__B__, pODEProblemNames[7] = __init__A__
#

function compute_h(u::AbstractVector, t::Real, pODEProblem::AbstractVector, θ_observable::AbstractVector,
                   θ_nonDynamic::AbstractVector, parameterInfo::ParametersInfo, observableId::Symbol,
                      parameterMap::θObsOrSdParameterMap)::Real 
	if observableId === :obs_a 
		return u[2] 
	end

end

function compute_u0!(u0::AbstractVector, pODEProblem::AbstractVector) 

	#pODEProblem[1] = compartment, pODEProblem[2] = b0, pODEProblem[3] = k1, pODEProblem[4] = a0, pODEProblem[5] = k2, pODEProblem[6] = __init__B__, pODEProblem[7] = __init__A__

	B = pODEProblem[6] 
	A = pODEProblem[7] 

	u0 .= B, A
end

function compute_u0(pODEProblem::AbstractVector)::AbstractVector 

	#pODEProblem[1] = compartment, pODEProblem[2] = b0, pODEProblem[3] = k1, pODEProblem[4] = a0, pODEProblem[5] = k2, pODEProblem[6] = __init__B__, pODEProblem[7] = __init__A__

	B = pODEProblem[6] 
	A = pODEProblem[7] 

	 return [B, A]
end

function compute_σ(u::AbstractVector, t::Real, θ_sd::AbstractVector, pODEProblem::AbstractVector, θ_nonDynamic::AbstractVector,
                   parameterInfo::ParametersInfo, observableId::Symbol, parameterMap::θObsOrSdParameterMap)::Real 
	if observableId === :obs_a 
		return 0.5 
	end

end