include("../src/Solveur_SET_Vanilla.jl")

# ---------------------------------------------------------------------------------
# ------------
# -- Outils --
#-------------

# Cardinalité d'un ensemble
function card(ens::Set)
	return length(ens)
end

# Retourne l'indice de la variable correspondant à sa position
function indice_var(sem::Int64, grp::Int64, k::Int64)
    return k*(sem-1) + grp
end

# ---------------------------
# -- Fonctions de filtrage --
# ---------------------------

# Filtrage via l'intersection vide:
# - var1 != var2 (<=> card(var1 inter var2) == 0)
# -- aucune des valeurs du domaine min de l'une ne doit se retrouver dans le domaine max de l'autre
function filtre_intersection_vide!(vars::Vector{Variable})
	var1, var2 = vars
	filtrage_intersection_vide!(var1, var2)
end

# Filtrage sociabilité:
# - card(var1 inter var2) <= 1
# -- le groupe 1 et 2 ne doivent avoir qu'un seul joueur en commun au maximum
#=function filtre_sociabilite!(vars::Vector{Variable})
	var1, var2 = vars
	filtrage_max_card_intersect_n!(var1, var2, 1)
	return true
end=#

function filtre_sociabilite!(vars::Vector{Variable})
	var1, var2 = vars
	joueur_commun = intersect(var1.dom_min, var2.dom_min)
	if card(joueur_commun) > 1
		if VERBOSE
			println("Inconsistance detectée: Les variables ", var1, " et ", var2, "violent la contrainte de sociabilité")
		end
		return false
	else
		if card(joueur_commun) == 1
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

#=
# Filtrage sociabilité:
# - card(var1 inter var2) <= 1
# -- le groupe 1 et 2 ne doivent avoir qu'un seul joueur en commun au maximum
function filtre_sociabilite!(vars::Vector{Variable})
	var1, var2 = vars
	joueur_commun = intersect(var1.dom_min, var2.dom_min)
	if card(joueur_commun) > 1
		if VERBOSE
			println("Inconsistance detectée: Les variables ", var1, " et ", var2, "violent la contrainte de sociabilité")
		end
		return false
	else
		if card(joueur_commun) == 1
			# on retire les joueurs jouant avec le joueur en commun dans var1 des joueurs possibles pour var2 
			ens_a_retirer = setdiff(var1.dom_min, joueur_commun)
			setdiff!(var2.dom_max, ens_a_retirer)
			
			# et de même pour les joueurs jouant avec le joueur en commun dans var2 des joueurs possibles pour var1
			ens_a_retirer = setdiff(var2.dom_min, joueur_commun)
			setdiff!(var1.dom_max, ens_a_retirer)
		end
	end
	return true
end=#

# Filtrage ordre inter groupes:
# - min(var1) < min(var2)
# -- on enlève du domaine max de var2 les valeurs inférieur au minimum du domaine de var1
# /!\ les variables doivent être données dans l'ordre de leur numéro de groupe dans la semaine
function filtre_intergroupe!(vars::Vector{Variable})
	res = true
	# Soit var1 avant var2
	var1, var2 = vars
	
	# Si var1.dom_min est non vide
	if card(var1.dom_min) >= 1
		#=println("filtre intergroupe (avt)")
		println("var1 = ", var1)
		println("var2 = ", var2)=#
		
		# on retire de var2.dom_max les joueurs d'indice plus petit que le joueur d'indice minimum de var1.dom_min
		min_var1 = minimum(var1.dom_min)
		ens_a_retirer = Set([e for e in var2.dom_max if e <= min_var1])
		setdiff!(var2.dom_max, ens_a_retirer)
		
		#=println("filtre intergroupe (aps)")
		println("var1 = ", var1)
		println("var2 = ", var2)
		readline()=#
		
		# si card(min_var2) >= 1, on vérifie que l'ordre o1 est bien respecté: ie que la valeur minimum de var1.dom_min est < à la valeur minimum de var2.dom_min
		if (card(var2.dom_min) >= 1)
			min_var2 = minimum(var2.dom_min)
			if !(min_var1 < min_var2)
				res = false
			end
		end
		
		if VERBOSE && !res
			println("Inconsistance detectée: Les variables ", var1, " et ", var2, "violent la contrainte d'ordre inter groupes")
		end
	end
	
	return res
end

# Filtrage ordre inter semaines:
# - min(var1 \ min(var1)) < min(var2 \ min(var2))
# -- on enlève du domaine max de var2 les valeurs inférieur au second minimum du domaine de var1 sauf le minimum de var2.dom_max
# /!\ les variables doivent être données dans l'ordre de la semaine à laquelle elles appartiennent
function filtre_intersemaines!(vars::Vector{Variable})
	res = true
	# Soit var1 avant var2
	var1, var2 = vars
	
	# Si var1.dom_min et var2.dom_max contiennent au moins 2 valeurs
	if card(var1.dom_min) >= 2 && card(var2.dom_max) >= 2
		# on considère la deuxième valeur minimal de var1.dom_min
		min2_var1 = minimum(setdiff(var1.dom_min, minimum(var1.dom_min)))
		
		# on retire de var2.dom_max \ de son minimum les joueurs d'indice plus petit que le joueur de second indice minimum de var1.dom_min
		var2_rest = setdiff(var2.dom_max, minimum(var2.dom_max))
		ens_a_retirer = Set([e for e in var2_rest if e < min2_var1])
		setdiff!(var2.dom_max, ens_a_retirer)
		
		# si card(var2.dom_min) >= 2, on vérifie que l'ordre o2 est bien respecté: ie que la seconde valeur minimal de var1.dom_min est < à la seconde valeur minimal de var2.dom_min
		if card(var2.dom_min) >= 2
			min2_var2 = minimum(setdiff(var2.dom_min, minimum(var2.dom_min)))
			if !(min2_var1 < min2_var2)
				res = false
			end
		end
		
		if VERBOSE && !res
			println("Inconsistance detectée: Les variables ", var1, " et ", var2, "violent la contrainte d'ordre inter semaines")
		end
	end
	return res
end

function afficher_sol(modele, s, k, p)
	for sem in 1:s
		println("\t Semaine ",sem,":")
		for group in 1:k
			ind = k*(sem-1) + (group-1) + 1
			elems = [e for e in modele.variables[ind].dom_min]
			chaine = "{"
			for i in 1:length(elems)
				chaine = chaine * string(elems[i])
				if i < length(elems)
					chaine = chaine * ","
				end
			end
			chaine = chaine * "}"
			println("\t\t Groupe ", group, ": ", chaine)
		end
	end
	println()
end

# Contraintes d'affectations bijectives : pour chaque semaine, chaque joueur doit apparaitre dans exactement groupe
function affectations_bij(s, k)
	ctr_affectations_bijectives = Vector{Contrainte}() # contient toutes les contraintes d'affectations bijectives
	for sem in 1:s
		for g1 in 1:k-1
			for g2 in g1+1:k
				push!(ctr_affectations_bijectives, Contrainte([indice_var(sem, g1, k), indice_var(sem, g2, k)], filtre_intersection_vide!))
			end
		end
	end
	return ctr_affectations_bijectives
end

# Contraintes de sociabilités : d'une semaine à l'autre, la cardinalité de l'intersection de chaque pair de groupe doit etre <= 1
function contraintes_soc(s, k)
	ctr_sociabilites = Vector{Contrainte}() # contient toutes les contraintes de sociabilité
	for s1 in 1:s-1
		for g1 in 1:k
			for s2 in s1+1:s
				for g2 in 1:k
					push!(ctr_sociabilites, Contrainte([indice_var(s1, g1, k), indice_var(s2, g2, k)], filtre_sociabilite!))
				end
			end
		end
	end
	return ctr_sociabilites
end

# Assertions 1: on fixe la premiere semaine (a1)	
function assertion1(modele, s, k, p)
	n_groupes = length(modele.variables)
	for i in 1:k
		var = modele.variables[i]
		dom = Set(collect(p*(i-1)+1:p*i))
		fixer_var!(modele, i, dom, dom)
	end
end

# Assertions 2: On informe le premier joueur des p premiers groupes à chaque semaine (a2)
function assertion2(modele, s, k, p, a1)
	deb = 1
	if a1
		deb = 2
	end
	
	for sem in deb:s
		for group in 1:p
			ind = k*(sem-1) + (group-1) + 1
			ajouter_dom_min!(modele, ind, group)
		end
	end
end

# Contraintes d'ordre 1 : les groupes d'une semaine doivent être ordonnés par joueur d'indice minimum croissant (o1)
function ordre1(s, k)
	ctr_intergroupes = Vector{Contrainte}() # contient toutes les contraintes d'affectations bijectives
	for sem in 1:s
		for g1 in 1:k-1
			for g2 in g1+1:k
				push!(ctr_intergroupes, Contrainte([indice_var(sem, g1, k), indice_var(sem, g2, k)], filtre_intergroupe!))
			end
		end
	end
	return ctr_intergroupes
end


# Contraintes d'ordre 2 : les premiers groupes de chaque semaine doivent être ordonnés par joueur d'indice second minimum croissant (o2)
function ordre2(s, k)
	ctr_intersemaines = Vector{Contrainte}() # contient toutes les contraintes d'affectations bijectives
	for s1 in 1:s-1
		for s2 in s1+1:s
			push!(ctr_intersemaines, Contrainte([indice_var(s1, 1, k), indice_var(s2, 1, k)], filtre_intersemaines!))
		end
	end
	return ctr_intersemaines
end
# ----------------------------
# -- Modele SGP ensembliste --
# ----------------------------
function Modele_Vanilla(s::Int64, k::Int64, p::Int64, variante::Vector{String})

	g = k*p;  # nombre total de golfeurs
	n_groupes = s*k; # nombre total de groupes (ie de variables)

	# Donnée de départ (on fixe un maximum de variables pour aider le B&B)
	#= start = 	[ 	{1,2,3}	{4,5,6} {7,8,9};
					{1,4,7} {2,.,9} {3,.,9};
					{1,.,9} {2,.,9} {3,.,9};
					{1,.,9} {2,.,9} {3,.,9};
		    	]
	=#

	#=set of int: S = 1..sem;             % ensemble des semaines
	set of int: K = 1..group;           % ensemble des groupes dans une semaine
	set of int: G = 1..(joueurs*group); % ensemble des joueurs

	array[S,K] of var set of G: A; % matrice de groupes=#
	
	# ---------------
	# -- Variables --
	# ---------------
	univers = Set(collect(1:g))
	# On créer p variables de domaine min = {}, domaine max = univers, cardinalité requise = p, est_fixee = false
	variables = [Variable(Set{Int64}(), univers, p, false, i) for i in 1:n_groupes]
	
	nb_vars = length(variables)

	# ---------------------
	# -- Contraintes SGP --
	# ---------------------
	# On créer les contraintes impliquant les variables
	contraintes = Vector{Contrainte}()

	# Contraintes d'affectations bijectives : pour chaque semaine, chaque joueur doit apparaitre dans exactement 1 groupe
	ctr_affectations_bijectives = affectations_bij(s, k)
	append!(contraintes, ctr_affectations_bijectives)

	# Contraintes de sociabilités : d'une semaine à l'autre, la cardinalité de l'intersection de chaque pair de groupe doit etre <= 1
	ctr_sociabilites = contraintes_soc(s, k)
	append!(contraintes, ctr_sociabilites)
	
	# Récupération de la variante du modèle (quelles bs)
	a1 = "a1" in variante
	a2 = "a2" in variante
	o1 = "o1" in variante
	o2 = "o2" in variante
	
	# -----------------------------
	# -- Brise symmétrie d'ordre --
	#------------------------------
	# Contraintes d'ordre 1 : les groupes d'une semaine doivent être ordonnés par joueur d'indice minimum croissant (o1)
	if o1
		ctr_intergroupes = ordre1(s, k)
		append!(contraintes, ctr_intergroupes)
	end
	
	# Contraintes d'ordre 2 : les premiers groupes de chaque semaine doivent être ordonnés par joueur d'indice second minimum croissant (o2)
	if o2
		ctr_intersemaines = ordre2(s, k)
		append!(contraintes, ctr_intersemaines)
	end
	
	nb_ctrts = length(contraintes)
	# ------------
	# -- Modele --
	# ------------
	modele = Modele(variables, contraintes, nb_vars, nb_ctrts, Vector{Int64}(), [i for i in 1:nb_vars], falses(nb_vars,length(univers)))
	
	# On doit indiquer si on utilise l'assertion a1. Si on utilise a1, alors l'assertion a2 sera différente: on ne doit pas fixer les premiers joueurs des p premiers groupes en semaine 1
	# ----------------------------------
	# -- Brise symmétrie d'assertions --
	#-----------------------------------
	# Assertions 1: on fixe la premiere semaine (a1)
	if a1
		assertion1(modele,s,k,p)
		a1 = true
	end
	
	# Assertions 2: On informe le premier joueur des p premiers groupes à chaque semaine (a2)
	if a2
		assertion2(modele,s,k,p,a1)
	end
	
	return modele
end
