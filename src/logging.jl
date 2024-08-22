function _logging(whatlog::Symbol, verbose::Bool; time=nothing, name::String="", buildfiles::Bool=false, exist::Bool=false)::Nothing
    verbose == false && return nothing

    if !isnothing(time)
        str = @sprintf("done. Time = %.1es\n", time)
        print(str)
        return nothing
    end

    if whatlog == :Build_PEtabModel
        str = styled"{blue:{bold:Info:}} Building {magenta:PEtabModel} for model $(name)\n"
    end
    if whatlog == :Build_SBML
        if buildfiles == true && exist == true
            str = styled"{blue:{bold:Info:}} By user option reimports {magenta:SBML} model ... "
        end
        if exist == false
            str = styled"{blue:{bold:Info:}} Imports {magenta:SBML} model ... "
        end
        if buildfiles == false && exist == true
            str = styled"{blue:{bold:Info:}} {magenta:SBML} model already imported\n"
        end
    end
    if whatlog == :Build_ODESystem
        str = styled"{blue:{bold:Info:}} Parses the SBML model into an {magenta:ODESystem} ... "
    end
    if whatlog == :Build_u0_h_σ
        if buildfiles == true && exist == true
            str = styled"{blue:{bold:Info:}} By user option rebuilds {magenta:u0}, " *
                  styled"{magenta:h} and {magenta:σ} functions ... "
        end
        if exist == false
            str = styled"{blue:{bold:Info:}} Builds {magenta:u0}, {magenta:h} and " *
                  styled"{magenta:σ} functions ... "
        end
        if buildfiles == false && exist == true
            str = styled"{blue:{bold:Info:}} {magenta:u0}, {magenta:h} and {magenta:σ} " *
                  styled"functions already exist\n"
        end
    end
    if whatlog == :Build_∂_h_σ
        if buildfiles == true && exist == true
            str = styled"{blue:{bold:Info:}} By user option rebuilds {magenta:∂h∂p}, " *
                  styled"{magenta:∂h∂u}, {magenta:∂σ∂p} and {magenta:∂σ∂u} functions ... "
        end
        if exist == false
            str = styled"{blue:{bold:Info:}} Builds {magenta:∂h∂p}, {magenta:∂h∂u}, " *
                  styled"{magenta:∂σ∂p} and {magenta:∂σ∂u} functions ... "
        end
        if buildfiles == false && exist == true
            str = styled"{blue:{bold:Info:}} {magenta:∂h∂p}, {magenta:∂h∂u}, " *
                  styled"{magenta:∂σ∂p} and {magenta:∂σ∂u} functions already exist\n"
        end
    end
    if whatlog == :Build_callbacks
        str = styled"{blue:{bold:Info:}} Builds {magenta:callback} functions ... "
    end
    print(str)
    return nothing
end
