using JuMP, SCIP

optimizer = SCIP.Optimizer(display_verblevel=0, limits_gap=0.05)

struct solutionUFLP
    x::Matrix{Float64}
    y::Vector{Float64}
    z::Float64
end

struct donneesUFLP
    n::Int64 # nombre de services potentiels
    m::Int64 # nombre de clients
    f::Vector{Int64} # coûts d'ouverture des services
    c::Matrix{Int64} # coûts des affecations clients-services
end

function solveUFLP(d::donneesUFLP)
    # Modèle UFLP
    m::Model = Model(SCIP.Optimizer)
    @variable(m, x[1:d.n,1:d.m], Bin)
    @variable(m, y[1:d.n], Bin)
    @objective(m, Min, sum(d.f[i] * y[i] for i in 1:d.n)
                     + sum(sum(d.c[i,j] * x[i,j] for j in 1:d.m) for i in 1:d.n))
    @constraint(m, AffClient[j in 1:d.m], sum(x[i,j] for i in 1:d.n) == 1)
    @constraint(m, AffPossible[i in 1:d.n,j in 1:d.m], x[i,j] <= y[i])

    #--------------------------------------
    # contraintes spécifiques à l'exercice
    #--------------------------------------
    
    # On veut ouvrir 2 dépots
    @constraint(m, minDepot2, sum(y[i] for i in 1:d.n) == 2)

    # Les entrepots 2 et 3 ne peuvent etre ouverts simultanément
    @constraint(m, dis23, y[3] <= 1 - y[2])

    # Ouvrir l'entrepot 2 => ouvrir l'entrepot 4
    @constraint(m, link24, y[2] <= y[4])

    # Si l'entrepot 1 est ouvert, ni le 2 ni le 3 ne peuvent être ouverts
    @constraint(m, dis12, y[2] <= 1 - y[1])
    @constraint(m, dis13, y[3] <= 1 - y[1])

    print(m)
    # Résolution
    optimize!(m)

    #println();
    #println(JuMP.value.(y))
    #println(JuMP.value.(x))
    #println(objective_value(m))
    
end

function exemple()
    # Saisie des données du petit exemple utilisé par Sullivan dans le rapport
    #=f::Vector{Int64} = [12,10]
    c::Matrix{Int64} = [70 50 30;
                         40 10 70]=#

    #=
    f::Vector{Int64} = [7020,4030,3400,1700]
    c::Matrix{Int64} = [220 550 820 360 900;
                        150 260 220 400 520;
                        440 780 320 210 190;
                        990 320 80 170 180]=#

    #=c::Matrix{Int64} = [220 550 820 360 900;
    0 0 0 0 0;
    440 780 320 210 0;
    990 320 80 170 180]=#

    f::Vector{Int64} = [7020,4030,3400,1700]
    
    c::Matrix{Int64} = [220 550 820 360 900;
                         150 260 220 400 520;
                         440 780 320 210 190;
                         990 320 80 170 180]

    d::donneesUFLP = donneesUFLP(4,5,f,c)

    # Résolution dichotomique
    return solveUFLP(d)
end