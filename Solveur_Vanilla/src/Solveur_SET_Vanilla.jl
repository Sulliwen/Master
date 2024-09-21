# TODO:
#=
	- Tester Sudoku
	- Valeur dans min apres Branchement
		(-> Si SGP SAT: normalement mieux de choisir la valeur min de chaque groupe pour aller le plus vite vers la sol SAT)
	- Symmetries:
		- min inter groupes
		- min inter semaines
	- Contraintes d'affectation: un seul gro inter pour toute une semaine? (mieux que par pair de groupe?)
	- 
=#

# -------------------------------
# -- Définition d'une Variable --
# -------------------------------

# Une variable est définit par:
# - un domaine min et un domaine max
# - un cardinal requis pour être fixé
# - est fixé ou non
# Rappelle: le but est de fixer toute les variables du problèmes, ie réduire le domaine max et/ou augmenter le domaine mine jusqu'à ce que la variable soit fixée
mutable struct Variable
    dom_min::Set{Int64} # domaine minimum
    dom_max::Set{Int64} # domaine maximum
    card_requis::Int64  # cardinal de l'ensemble minimal requis par la variable (exemple pour SGP: un groupe doit etre exactement de taille 3 donc card_requis = 3)
	
    est_fixee::Bool	# si dom_min = card_requis, alors la variable est fixée (exemple pour SGP: si card_requis = 3 et que dom_min = {1,2} alors est_fixee = false)
    id::Int64

    Variable(min::Set{Int64},
    		 max::Set{Int64},
    		 card_requis::Int64,
    		 est_fixee::Bool,
    		 id::Int64) = new(
					Set{Int64}(min),
					Set{Int64}(max),
					card_requis,
					est_fixee,
					id)
end

# ---------------------------------
# -- Définition d'une Contrainte --
# ---------------------------------

struct Contrainte
	# Indices des variables impliquées dans la contrainte
    vars::Vector{Int64}
    # Fonction de filtrage associée à la contrainte
    fonction_filtrage!::Function
end

# -------------------------------------------
# -- Définition des opérateurs élémentaires --
# -------------------------------------------
# Cardinalité d'un ensemble
function card(ens::Set{Int64})
	return length(ens)
end

# Intersection de 2 variables
function inter(var1::Variable, var2::Variable)
	dom_min = intersect(var1.dom_min,var2.dom_min)
	dom_max = intersect(var1.dom_max,var2.dom_max)
	var = Variable(dom_min, dom_max, var1.card_requis, false, -1)
end

# -------------------------------------------
# -- Définition des filtrages élémentaires --
# -------------------------------------------

# Intersection vide entre 2 variables
# - card(var1, var2) == 0
function filtrage_intersection_vide!(var1::Variable, var2::Variable)
	# var1.max \ var2.min
	setdiff!(var1.dom_max, var2.dom_min)
	# var2.max \ var1.min
	setdiff!(var2.dom_max, var1.dom_min)

	if !(card(var1.dom_max) > 0 && card(var1.dom_max) > 0)
		if VERBOSE
			println("Inconsistance detectée: Les variables ", var1, " et ", var2, "violent la contrainte d'intersection vide.")
		end
		return false
	else
		return true
	end
end

# Cardinalité maximal de l'intersection de 2 variables
# - card(var1, var2) <= n
# -- on ne filtre que quand la cardinalité de l'intersection a atteint la valeur max n
function filtrage_max_card_intersect_n!(var1::Variable, var2::Variable, n)
	joueur_commun = intersect(var1.dom_min, var2.dom_min)
	if card(joueur_commun) > n
		if VERBOSE
			println("Inconsistance detectée: Les variables ", var1, " et ", var2, "violent la contrainte de cardinalité d'intersection max")
		end
		return false
	else
		if card(joueur_commun) == n
			# on retire les joueurs jouant avec le joueur en commun dans var1 des joueurs possibles pour var2 
			ens_a_retirer = setdiff(var1.dom_min, joueur_commun)
			setdiff!(var2.dom_max, ens_a_retirer)
			
			# et de même pour les joueurs jouant avec le joueur en commun dans var2 des joueurs possibles pour var1
			ens_a_retirer = setdiff(var2.dom_min, joueur_commun)
			setdiff!(var1.dom_max, ens_a_retirer)
		end
	end
	return true
end


# -----------------------------
# -- Définition d'un Modele --
# -----------------------------
mutable struct Modele
	# Liste des variables du modele
	variables::Vector{Variable}
	# Liste des contraintes du modele
	contraintes::Vector{Contrainte}
	
	# Nombre de variables
	nb_vars::Int64
	# Nombre de contraintes
	nb_ctrts::Int64
	
	# Indices des variables fixées du modèle
	vars_fixees::Vector{Int64}
	# Indices des variables non fixées du modèle
	vars_non_fixees::Vector{Int64}
	
	#quel valeurs sont présentes dans quel domaine min de variables
	vals_informed::BitMatrix
	
	# Status du modèle ("UNSAT" tant que vars_non_fixées est non vide, "SAT" sinon)
	status::String
	
	Modele(vars::Vector{Variable},
    		ctrts::Vector{Contrainte},
    		nb_v::Int64,
    		nb_c::Int64,
    		 vars_f::Vector{Int64},
    		 vars_non_f::Vector{Int64},
    		 val_inf::BitMatrix) = new(
					vars,
					ctrts,
					nb_v,
					nb_c,
					vars_f,
					vars_non_f,
					val_inf,
					"UNSAT")
	Modele() = new()
end

# ---------------------------------------------
# -- Fonctions de mise à jour d'une variable --
# ---------------------------------------------

# Fixe une variable à une valeur.
function fixer_var!(modele::Modele, ind_var::Int64, dom_min::Set{Int64}, dom_max::Set{Int64})
    modele.variables[ind_var].dom_min = dom_min
    modele.variables[ind_var].dom_max = dom_max
    modele.variables[ind_var].est_fixee = true
    
    # On met à jour vals_informed
    for val in dom_min
    	modele.vals_informed[ind_var, val] = true
    end
    
    # On ajoute l'indice de la variable fixee à la liste des variables fixées
	if !(ind_var in modele.vars_fixees)
		push!(modele.vars_fixees, ind_var)
	end
	# On enleve l'indice de la variable fixees de la liste des variables non fixées
	if (ind_var in modele.vars_non_fixees)
		deleteat!(modele.vars_non_fixees, findfirst(x->x==ind_var,modele.vars_non_fixees))
	end
end

# Ajoute une valeur au domaine minimum d'une variable
function ajouter_dom_min!(modele, ind::Int64, val::Int64)
	push!(modele.variables[ind].dom_min, val)
	# On met à jour vals_informed
	modele.vals_informed[ind, val] = true
end

# Retirer une valeur au domaine minimum d'une variable
function retirer_dom_max!(var::Variable, val::Int64)
	delete!(var.dom_max, val)
end

# ------------
# -- Outils --
#-------------
# Edition du print de Julia pour l'affichage de la structure Variable
function Base.show(io::IO, var::Variable)
    compact = get(io, :compact, false)
    sep = ", "
    if !compact
        println(io, "Variable ():")
        println(io, "\tdom_min : ", var.dom_min)
        println(io, "\tdom_max : ", var.dom_max)
        println(io, "\tid: ", var.id)
    else
        print(io, "Variable(")
        print(io, "dom_min:")
        show(io, var.dom_min)
        print(io, sep)
        print(io, "dom_max:")
        show(io, var.dom_max)
        print(io, sep)
        print(io, "card_min_requis:")
        show(io, var.card_min_requis)
        print(sep)
        print(io, "card_max_requis:")
        show(io, var.card_max_requis)
        print(sep)
        print(io, "id:")
        show(io, var.id)
        print(io, ")")
    end
end

# Récupère la valeur présente dans le plus de domaine min 
function get_val_informatrice(vals_informed, parmi_vals)
	val_informatrice = collect(parmi_vals)[1]
	nb_info_val_informatrice = 0
	
	nb_vars = size(vals_informed,1)
	nb_vals = size(vals_informed,2)
	
	# Si le nombre de fois où val est dans un dom min surpasse le nombre max trouvé jusque là, alors elle devient la variable informatrice
	for val in parmi_vals
		nb_info_val = sum(vals_informed[:,val])
		if nb_info_val > nb_info_val_informatrice
			val_informatrice = val
			nb_info_val_informatrice = nb_info_val
		end
	end
	return val_informatrice
end

# ----------------
# -- Résolution --
# ----------------

# -- Filtrage -- 
function Filtrage!(modele::Modele, ind_ctr::Int64)
	#println("###############")
	#println("avant filtrage (",modele.contraintes[ind_ctr].fonction_filtrage!,"):")
	#println("###############")
	#println(modele.variables[modele.contraintes[ind_ctr].vars])
	ctr = modele.contraintes[ind_ctr]
	variables = modele.variables
	
	if !ctr.fonction_filtrage!(variables[ctr.vars])
		if VERBOSE
			println("Le filtrage induit par la contrainte amène à une inconsistance")
		end
		return false
	end
	
	# On met à jour les variables filtrées (tout en vérifiant si le filtrage ne rend pas les variables non viables)
	for var in variables[ctr.vars]
		# Si la mise à jour entraine des problèmes de cohérence, la résolution doit s'arreter
		if !maj_var(modele, var)
			if VERBOSE
				println("la mise à jour de la variable x", var.id, " est inconsistante:")
				println(var)
			end
			return false
		end
	end
	#println("---------------")
	#println("après filtrage (",modele.contraintes[ind_ctr].fonction_filtrage!,"):")
	#println("---------------")
	#println(modele.variables[modele.contraintes[ind_ctr].vars])
	return true
end

# --------------------------
# -- Fonctions garde-fous --
# --------------------------
function maj_var(modele::Modele, var::Variable)
	if !check_viabilite(var)
		return false
	else
		maj_var_fixee(modele, var)
	end
	return true
end

function maj_var_fixee(modele::Modele, var::Variable)
	# On vérifie si la variable a un cardinal = cardinal requis, auquel cas
	#  - on met à jour son ensemble max = min
	#  - on met à jour son statut est_fixee à true
	if !var.est_fixee
		if card(var.dom_min) == var.card_requis
			fixer_var!(modele, var.id, var.dom_min, var.dom_min)
		end
		if card(var.dom_max) == var.card_requis
			fixer_var!(modele, var.id, var.dom_max, var.dom_max)
		end
	end
end

function check_viabilite(var::Variable)
	# On vérifie:
	# 1) max inter min = min
	# 2) card(min) <= card(max)
	viable = (intersect(var.dom_min, var.dom_max) == var.dom_min) &&
			 (card(var.dom_min) <= card(var.dom_max)) &&
			 (card(var.dom_max) >= var.card_requis) &&
			 (card(var.dom_min) <= var.card_requis)
	return viable
end


# -- Propagator --
# --- Propage les informations déduites des filtrages
function Propagate!(modele::Modele)
	variables = modele.variables
	contraintes = modele.contraintes
	nb_vars = modele.nb_vars
	
	# On récupère toutes les contraintes où la variable var est impliquées
	# parcours toutes les contraintes et renvoie l'indice de la contrainte où 1 est dans contrainte.var
	# findall(contrainte -> 1 in contrainte.vars, contraintes)
	variables_impliques_ctr = [
        	findall(contrainte -> id_var in contrainte.vars, contraintes)
        	for id_var in 1:length(variables)
    	]
	# Pour chaque variable
	for id_var in 1:nb_vars 
	    	# Pour toutes les contraintes où elle est impliquée
	    	for id_ctr in variables_impliques_ctr[id_var]
	    		# On applique le filtrage associé à la contrainte
	    		#println("Filtrage de la contraintes ", id_ctr)
	    		if !Filtrage!(modele, id_ctr)
	    			if VERBOSE
	    				println("La mise à jour suite au filtrage de la contrainte ", id_ctr, " a posé problème. Interruption de l'exploration de la branche")
	    			end
	    			return false
	    		end
	    		#println("Ok")
	    	end
	end
    return true
end

function differences_vars(vars_m1, vars_m2)
	for i in 1:length(vars_m1)
		if (vars_m1[i].dom_min != vars_m2[i].dom_min) || (vars_m1[i].dom_max != vars_m2[i].dom_max)
			return true
		end
	end
	return false
end

# -- Propagator --
# --- Appelle de Propagate! tant qu'un point fixe n'a pas été atteint
function Propagator!(modele::Modele)
	vars = deepcopy(modele.variables)
	propager = true
	# Tant que la propagation apporte de nouvelles informations sur le domaine d'au moins une variable, on re propage
	while propager == true
		if !Propagate!(modele)
			return false
		end
		#if (vars != modele.variables)
		if (differences_vars(vars, modele.variables))
			vars = modele.variables
			propager = true
		else
			propager = false
		end
	end
	
	# Si toutes les variables ont été fixées tout en respectant les contraintes, alors une solution a été trouvée
	if isempty(modele.vars_non_fixees)
		if VERBOSE
			println("Toutes les variables ont été fixées tout en respectant les contraintes: une solution a été trouvée!")
			println(modele.vars_non_fixees)
			println(modele.vars_fixees)
			println(modele.variables)
		end
		modele.status = "SAT"
	end
	
	return true
end

function Branch_and_Prune!(modele::Modele, lvl::Int64)
	sat = false
	# Propagation: on propage toutes les informations connues jusque là (filtrage via les contraintes)
	if VERBOSE
		println("-- Niveau ", lvl, " --")
		#readline()
	end
	
	if !Propagator!(modele)
		#print("FALSE")
		#readline()
		return false
	end
	
	#println("APRES Propagator:")
	#println(modele.variables)
	#readline()
	
	# Si la propagation a fixée toutes les variables, la résolution est finie avec status = "SAT"
	if modele.status == "SAT"
		return true
	end
	
	if VERBOSE
		println("Apres propagation:")
		println(modele.variables)
		println("Variables fixées:")
		println(modele.vars_fixees)
	end
	
	# Branchement: différentes stratégies de branchement possibles
	# 1) On branche sur la variable impliquées dans le plus de contraintes
	# 2) On branche sur la variable la plus proche d'être fixée
	
	# on récupère la liste des variables non fixées
	if !isempty(modele.vars_non_fixees) # condition d'arret
		# Il est probable que la propagation ait fixé des variables et réduit des domaines, et en particulier la variable de branchement du niveau supérieur. On va donc recalculer à chaque fois la variable non fixée la plus susceptible de fail
		# on trie la liste des variables non closes par l'ordre lexicographique sur la cardinalité de leurs ensembles max/min définit
		#sort!(modele.vars_non_fixees, by = e -> card(modele.variables[e].dom_max) - card(modele.variables[e].dom_min)) # <- très lent
		sort!(modele.vars_non_fixees, by = e -> card(modele.variables[e].dom_max)) # tester d'autres heur de branchement
		# on branche sur la variable la plus "petite" au sens de l'ordre définit
		ind_var_branche = modele.vars_non_fixees[1]
		
		# on récupère la variable associée
		var = modele.variables[ind_var_branche]
		
		#println("--- On branche sur x",var.id)
		
		if VERBOSE
			println("--- On branche sur x",var.id)
		end
		# Enumération (ajout d'information artificielle valide dans l'ensemble min de la variable branchée): différentes stratégies d'énumération possibles
		# 1) On choisi la valeur qui apparaît dans le plus de variable fixée (car information forte -> on pourra filtrer plus de valeurs dans l'ensemble max)
		# 2) 
		# Pour chaque candidat à ajouter à l'ensemble min, tant qu'on n'a pas trouvé d'ajout faisable pour l'ensemble min de la variable branchée, on continue l'enumeration des valeurs candidates possibles
		
		# les candidats à ajouter sont ceux qui sont dans l'ensemble max mais pas dans l'ensemble min
		vals_candidats = setdiff(var.dom_max, var.dom_min)
		n = length(vals_candidats)
		
		modele_copie = Modele()
		
		# On énumère toutes les valeurs candidates pour l'ensemble min de la variable branchée
		while !isempty(vals_candidats) && !sat
			# On copie l'état du modele
		    vars_copie = deepcopy(modele.variables)
		    modele_copie = Modele(vars_copie, deepcopy(modele.contraintes), deepcopy(modele.nb_vars), deepcopy(modele.nb_ctrts), deepcopy(modele.vars_fixees), deepcopy(modele.vars_non_fixees), deepcopy(modele.vals_informed))
		    
		    # On choisit le candidat récoltant le plus d'information (présent dans le plus de variables fixées)
		    #val_enum = vals_candidats[ind_val_candidat]	# à modifier
			
			val_enum = get_val_informatrice(modele.vals_informed, vals_candidats)
			# On retire le candidat de la liste
			#println("(avt) vals candidats = ", vals_candidats)
			setdiff!(vals_candidats, val_enum)
			#=println("val informatrice = ", val_enum)
			println("(aps) vals candidats = ", vals_candidats)
			readline()=#
			
			#=println(modele.variables)
			println("val informed:")
			println(string(modele.vals_informed))
			println("val informatrice = ", val_informatrice)
			readline()=#
		    
		    #=if lvl == 1
				println("--- Variable branchée: x",var.id)
				println(var)
				println("--- Valeur ajoutée à x",var.id,".dom_min: ",val_enum)
				#readline()
		    end=#
		    
		    #println("valeur enum: ", val_enum)
		
		    if VERBOSE
				println("x",var.id,".dom_min = ", var.dom_min)
				println("x",var.id,".dom_max = ", var.dom_max)
				println("On ajoute ", val_enum, " à x",var.id,".dom_min")
			end
		    # On ajoute la valeur enumérée (information créé) à l'ensemble min de la variable branchée
		    ajouter_dom_min!(modele_copie, ind_var_branche, val_enum)
		    if VERBOSE
				println("x",var.id,".dom_min = ", modele_copie.variables[ind_var_branche].dom_min)
				println("On rappelle le branch and prune sur une copie du modele")
				#readline()
				println("vars fixees modele lvl", lvl," (avant B&P):")
				println(modele.vars_fixees)
				#readline()
			end
			
		    # On rappelle le branch and prune avec la copie de l'état des variables
		    global T_TIC = time()
		    t_exec = T_TIC - T_START
		    if t_exec > BUDGET
		    	return false
		    else
		    	#println("temps exec = ", t_exec)
		    	global t = @elapsed sat = Branch_and_Prune!(modele_copie, lvl+1)
		    end
		    
		    if VERBOSE
				println("\n## Retour au Niveau ", lvl,"\n")
				
				println("vars fixees modele lvl", lvl," (apres B&P):")
				println(modele.vars_fixees)
				println("vars fixees modele_copie:")
				println(modele_copie.vars_fixees)
		    end
		    
		    # Si la branche est infaisable avec la valeur qu'on vient d'ajouter à l'ensemble min, alors on retire cette derniere à la variable en cours de branchement.
		    if !sat
		    	if VERBOSE
		    		println("Problème infaisable quand on ajoute ", val_enum, " à l'ensemble min de x", ind_var_branche, ": on la retire des candidats")
		    	end
		        setdiff!(vals_candidats, val_enum)
		        
		        # On propage cette nouvelle information
		        #=println("Et on repropage cette nouvelle info")
		        if !Propagator!(modele::Modele)
					return false
				end
				if modele.status == "SAT"
					sat = true
				end
				println("Apres propagation:")
				println(modele.variables)=#
			# Sinon le modèle est SAT: on remonte le modele
		    else
		    	if VERBOSE
					println("L'exploration a produit une solution faisable, on met à jour les variables du modele")
					println(modele_copie.variables)
				end
		    	# On remonte le modele
		    	#=for i in 1:modele.nb_vars
		    		modele.variables[i] = modele_copie.variables[i]
		    	end=#
		    	modele.variables = deepcopy(modele_copie.variables)
		    	modele.vars_fixees = deepcopy(modele_copie.vars_fixees)
		    	modele.vars_non_fixees = deepcopy(modele_copie.vars_non_fixees)
		    	modele.status = modele_copie.status
		    	
		    	#=println("\n\nApres recopie:")
		    	println(modele.variables)
		    	println(modele.vars_fixees)
		    	println(modele.vars_non_fixees)
		    	println(modele.status)=#
		    end
		
		end
		# Si l'ajout de la valeur génère une solution sat
		if VERBOSE
			if sat
				println("L'exploration a produit une solution faisable, on remonte la solution trouvée")
			else
				println("Aucune valeur disponible dans l'ensemble max produit une solution faisable, on backtrack")
			end
		end
	end
    # Si non faisable, on BT
    return sat
end

#--------------
# -- Solveur --
#--------------
function Solve(modele::Modele)
	# En fait on ne fait qu'appeler le B&P en effet, comme l'a dit le prof pendant la présentation
	if VERBOSE
		println("Appelle du Branch and Prune")
	end
	# On crée la matrice renseignant dans quel variable.dom_min chaque valeur est présente
	
	sat = Branch_and_Prune!(modele, 1)
	if VERBOSE
		println("## Retour au Niveau 0. (fonction solve)")
	end
	return sat
end

#=
function Branch_and_Prune(modele::Modele)
	# on récupère la liste des variables non fixées
	if !isempty(modele.vars_non_fixees) # condition d'arret
		# on trie la liste des variables non closes par l'ordre lexicographique sur la cardinalité de leurs ensembles max/min définit
		sort!(modele.vars_non_fixees, by = e -> card(modele.variables[e].dom_max)) # a modifier
		# on branche sur la variable la plus "petite" au sens de l'ordre définit
		ind_var_branche = modele.vars_non_fixees[1]
		# on récupère la variable associée
		var = modele.variables[ind_var_branche]
		# les candidats à ajouter sont ceux qui sont dans l'ensemble max mais pas dans l'ensemble min
		vals_candidats = collect(setdiff(var.max, var.min))
		n = length(vals_candidats)
		# On choisit le candidat récoltant le plus d'information (présent dans le plus de variables fixées)
		ind_val_candidat = 1 # à modifier
		faisable_temp = false
		vars_tmp = []
		# Pour chaque candidat à ajouter à l'ensemble min, tant qu'on n'a pas trouvé d'ajout faisable pour l'ensemble min de la variable branchée, on continue l'enumeration des valeurs candidates possibles
		while ind_val_candidat <= n && !faisable_temp
			# On copie l'état du modele
		    vars_copie = deepcopy(modele.variables)
		    modele_copie = Modele(vars_copie, modele.contraintes, modele.nb_vars, modele.nb_ctrts, modele.vars_fixees, modele.vars_non_fixees)
		    
		    # On choisit le candidat récoltant le plus d'information (présent dans le plus de variables fixées)
		    val_enum = vals_candidats[ind_val_candidat]	# à modifier
		    # On ajoute la valeur enumérée (information créé) à l'ensemble min de la variable branchée
		    ajouter_dom_min!(vars_copie[ind_var_branche], val_enum)
		    # On rappelle le branch and prune avec la copie de l'état des variables 
		    faisable_temp = Branch_and_Prune!(modele_copie)
		    ind_val_candidat += 1	# à modifier
		    # Si le problème est infaisable avec la valeur qu'on vient d'ajouter à l'ensemble min, alors on retire cette derniere à la variable en cours de branchement.
		    if !faisable_temp
		        setdiff!(modele.variables[ind_var_branche].dom_max, val_enum)
		    end
		end
		# Si l'ajout de la valeur est faisable, alors on affecte la variable a la valeur filtrée par le branch and prune
		if faisable_temp
		    for i in 1:modele.nb_vars
		        modele.variables[i] = vars_copie[i]
		    end
		else
			# Sinon, si on a épuisé toutes les valeurs de l'ensemble min sans trouver de déduction viables, on relance le branch and prune ?? 
		    faisable_temp = Branch_and_Prune!(modele)
		    faisable = faisable_temp # pas faisable
		end
	end
    # Si non faisable, on BT
    return faisable
end=#


###################################################################################################################

#=
function solver_generique!(liste_variables::Array{Variable, 1}, liste_contraintes::Array{Contrainte, 1})
    # On commence par récupérer toutes les contraintes où chaque variable est impliquée
    # tableau qui associe toutes les contraintes d'une variable à l'indice de cette dernière dans liste_variables
    # array_contrainte_variable[1] = indices de toutes les contraintes où la variable 1 est impliquée 
    # array_contrainte_variable[81] = indices de toutes les contraintes où la variable 81 est impliquée 
    array_contrainte_variable = [
        findall(ctr -> indice in ctr.liste_indice_arguments, liste_contraintes)
        for indice in 1:length(liste_variables)
    ]

    liste_filtrage_restant = collect(length(liste_contraintes):-1:1)
    infaisable = false
    # Pour chaque contrainte du modele
    while !isempty(liste_filtrage_restant) && !infaisable
        # On récupère la description de la contrainte et son indice (indice de liste_filtrage_restant) 
        indice_ctr = pop!(liste_filtrage_restant)
        ctr = liste_contraintes[indice_ctr]
        # on récupère les variables impliquées dans la contrainte
        arguments = [deepcopy(liste_variables[i]) for i in ctr.liste_indice_arguments]
        # on filtre la contrainte avec le domaine de toutes les autres variables
        filtrer!(ctr, liste_variables)
        # Pour chaque variables impliquées dans la contraintes
        for indice_var in ctr.liste_indice_arguments
            # On récupère la variable
            var = liste_variables[indice_var]
            # Si la variable est "valide" (pas un var.min > var.max etc..)
            if verifie_validite(var)
            	# Si la variable a évolué (s'est ressérée) après le filtrage
                if !(var in arguments)
                    # Pour chaque contrainte où la variable apprarait
                    for indice in array_contrainte_variable[indice_var]
                        #Ne pas mettre plusieurs fois la même contrainte en attente.
                        # Si la contrainte n'est pas dans la liste des contraintes a filtrer, on la rajoute
                        if !(indice in liste_filtrage_restant)
                            push!(liste_filtrage_restant, indice)
                        end
                    end
                end
            else
                infaisable = true
            end
        end
    end
    return !infaisable # retourne true si le solver a trouvé le problème faisable.
end

# Stratégie de branchement pour le B&B:
# - On branche sur la variable non fixé qui a l'ensemble max le plus petit
# - et on ajoute dans son ensemble min la valeur qui est contenue dans le plus de variables fixe
# Ex: var1: min = {1,2} max = {1,2,3,4} a un ensemble max petit, on branche sur elle. On ajoute 4 a son ensemble min car cette valeur apparait dans bcp de variables fixée
function Branch_and_Bound!(liste_variables::Array{Variable, 1}, liste_contraintes::Array{Contrainte, 1})
    faisable = solver_generique!(liste_variables, liste_contraintes)
    if faisable
    	# on récupère la liste des variables non closes
        liste_non_clot = findall(var -> !verifie_clot(var), liste_variables)
        if !isempty(liste_non_clot) # condition d'arret
        	# on trie la liste des variables non closes par à quel point elles sont proche d'etre closes
            sort!(liste_non_clot, by = e -> liste_variables[e].card_max - length(liste_variables[e].min) )
            # l'indice de branchement est l'indice de la premiere variable de la liste triée
            indice_branchement = liste_non_clot[1]
            # on récupère la variable associée
            var = liste_variables[indice_branchement]
            # les candidats à ajouter sont ceux qui sont dans l'ensemble max mais pas dans l'ensemble min
            candidat_ajout = collect(setdiff(var.max, var.min))
            n = length(candidat_ajout)
            indice_valeur = 1
            faisable_temp = false
            liste_variables_temp = []
            # Pour chaque candidat à ajouter à l'ensemble min, tant qu'on n'a pas trouver d'ajout faisable pour l'ensemble min de la variable branchée
            while indice_valeur <= n && !faisable_temp
            	# On copie l'état des variables
                liste_variables_temp = deepcopy(liste_variables)
                valeur_ajout = candidat_ajout[indice_valeur]
                ajouter!(liste_variables_temp[indice_branchement], valeur_ajout)
                # On rappelle le branch and prune avec la copie de l'état des variables 
                faisable_temp = branch_and_bound!(liste_variables_temp, liste_contraintes)
                indice_valeur += 1
                # Si le problème est infaisable avec la valeur qu'on vient d'ajouter à l'ensemble min, alors on retire cette derniere à la variable en cours de branchement.
                if !faisable_temp
                    setdiff!(liste_variables[indice_branchement].max, valeur_ajout)
                end
            end
            # Si l'ajout de la valeur est faisable, alors on affecte la variable a la valeur filtré par le branch and prune
            if faisable_temp
                for i in 1:length(liste_variables) # assignation
                    liste_variables[i] = liste_variables_temp[i]
                end
            else
            	# Sinon, si on a épuisé toutes les valeurs de l'ensemble min sans trouver de déduction viables, on relance le branch and prune ?? 
                faisable_temp = branch_and_bound!(liste_variables, liste_contraintes)
                faisable = faisable_temp # pas faisable
            end
        end
    end
    # Si non faisable, on BT
    return faisable
end=#
