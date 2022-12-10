using JuMP, GLPK

struct solutionUFLP
    x::Matrix{Float64}
    y::Vector{Float64}
    z1::Float64
    z2::Float64
end

struct donneesUFLP
    n::Int64 # nombre de services potentiels
    m::Int64 # nombre de clients
    f1::Vector{Int64} # coûts d'ouverture des services (objectif 1)
    f2::Vector{Int64} # coûts d'ouverture des services (objectif 2)
    c1::Matrix{Int64} # coûts des affecations clients-services (objectif1)
    c2::Matrix{Int64} # coûts des affecations clients-services (objectif2)
end

# Résolution de la relaxation continue du problème UFLP par l'algorithme du simplexe
function minUFLPRC(m::Model,lambda1::Float64,lambda2::Float64,d::donneesUFLP)
    # Modification de la fonction objectif
    @objective(m, Min, sum((lambda1 * d.f1[i] + lambda2 * d.f2[i]) * m[:y][i] for i in 1:d.n)
                     + sum(sum((lambda1 * d.c1[i,j] + lambda2 * d.c2[i,j]) * m[:x][i,j] for j in 1:d.m) for i in 1:d.n)
              )
    # Résolution
    optimize!(m)

    # Récupération de la solution et retour
    ysol::Vector{Float64} = value.(m[:y])
    xsol::Matrix{Float64} = value.(m[:x])
    z1::Float64 = sum(d.f1[i] * ysol[i] for i in 1:d.n) + sum(sum(d.c1[i,j] * xsol[i,j] for j in 1:d.m) for i in 1:d.n)
    z2::Float64 = sum(d.f2[i] * ysol[i] for i in 1:d.n) + sum(sum(d.c2[i,j] * xsol[i,j] for j in 1:d.m) for i in 1:d.n)
    return solutionUFLP(xsol,ysol,z1,z2)
end

# Fonction récursive exécutant la méthode dichotomique
function dichoRec(m::Model,tabSol::Vector{solutionUFLP},z11::Float64,z12::Float64,z21::Float64,z22::Float64,d::donneesUFLP)
    # Définition du poids et résolution
    lambda1::Float64 = z12 - z22
    lambda2::Float64 = z21 - z11
    sol::solutionUFLP = minUFLPRC(m,lambda1,lambda2,d)

    # Test avant ajout et appels récurifs
    if (lambda1 * sol.z1 + lambda2 * sol.z2 < lambda1 * z11 + lambda2 * z12 - 1e-6)
        ajout::Bool = true
        if (isapprox(sol.z1,tabSol[1].z1,atol=1e-6))
            tabSol[1] = sol
            ajout = false
        else
            tabSol = dichoRec(m,tabSol,z11,z12,sol.z1,sol.z2,d)
        end
        if (isapprox(sol.z1,tabSol[2].z2,atol=1e-6))
            tabSol[2] = sol
            ajout = false
        else
            tabSol = dichoRec(m,tabSol,sol.z1,sol.z2,z21,z22,d)
        end
        if (ajout)
            push!(tabSol,sol)
        end
    end

    return tabSol
end


function dichotomy(d::donneesUFLP)
    # Modèle UFLPR (objectif 1)
    m::Model = Model(GLPK.Optimizer)
    @variable(m, x[1:d.n,1:d.m] >= 0)
    @variable(m, 0 <= y[1:d.n] <= 1)
    @objective(m, Min, sum(d.f1[i] * y[i] for i in 1:d.n)
                     + sum(sum(d.c1[i] * x[i,j] for j in 1:d.m) for i in 1:d.n))
    @constraint(m, AffClient[j in 1:d.m], sum(x[i,j] for i in 1:d.n) == 1)
    @constraint(m, AffPossible[i in 1:d.n,j in 1:d.m], x[i,j] <= y[i])

    # Initialisation du tableau de solutions
    tabSol::Vector{solutionUFLP} = Vector{solutionUFLP}(undef,0)

    # Résolution sur la première fonction objectif
    sol::solutionUFLP = minUFLPRC(m,1.0,0.0,d)
    push!(tabSol,sol)

    # Résolution sur la seconde fonction objectif
    sol = minUFLPRC(m,0.0,1.0,d)
    push!(tabSol,sol)

    # Lancement de la méthode dichotomique
    tabSol = dichoRec(m,tabSol,tabSol[1].z1,tabSol[1].z2,tabSol[2].z1,tabSol[2].z2,d)

    # Tri final
    sort!(tabSol, by = sol -> sol.z1)

    # Retour final
    return tabSol
end

function exemple()
    # Saisie des données du petit exemple utilisé par Sullivan dans le rapport
    f1::Vector{Int64} = [12,10]
    c1::Matrix{Int64} = [70 50 30;
                         40 10 70]
    f2::Vector{Int64} = [7,9]
    c2::Matrix{Int64} = [20 10 50;
                         40 90 100]
    d::donneesUFLP = donneesUFLP(2,3,f1,f2,c1,c2)

    # Résolution dichotomique
    return dichotomy(d)
end