include("../src/Solveur_SET_Vanilla.jl")

using BenchmarkTools

# ---------------------------------------------------------------------------------
# ------------
# -- Outils --
#-------------

# Cardinalité d'un ensemble
function card(ens::Set)
	return length(ens)
end

# Retourne l'indice de la variable correspondant à sa position
function indice_var(l::Int64, c::Int64)
	return (l-1) * 9 + c
end

# ---------------------------
# -- Fonctions de filtrage --
# ---------------------------

# Filtrage via l'intersection vide:
# - aucune des valeurs du domaine min de l'une ne doit se retrouver dans le domaine max de l'autre
function filtre_intersection_vide!(vars::Vector{Variable})
	var1, var2 = vars
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

function fixer_vars_init!(modele::Modele, grille::Matrix{Int64})
	for l in 1:9
		for c in 1:9
			if grille[l, c] != 0
				set = Set([grille[l, c]])
				fixer_var!(modele, indice_var(l,c), set, set)
			end
		end
	end
end

function afficher_sol(modele::Modele, grille::Matrix{Int64})
	print("┏━━━┯━━━┯━━━┳━━━┯━━━┯━━━┳━━━┯━━━┯━━━┓\n")
	for l in 1:9
		print("┃")
		for c in 1:9
			if grille[l,c] != 0
				elem = string(grille[l,c])
				printstyled(" " * elem * " "; bold = true)
			else
				ind = (l-1) * 9 + c
				elem = modele.variables[ind].dom_min
				if length(elem) == 0
					print("   ")
				else
					print(" " * string(collect(elem)[1]) * " ")
				end
			end
			if c % 3 == 0
				print("┃")
			else
				print("│")
			end
		end
		if l != 9
			if l % 3 == 0
				print("\n┣━━━┿━━━┿━━━╋━━━┿━━━┿━━━╋━━━┿━━━┿━━━┫\n")
			else
				print("\n┠───┼───┼───╂───┼───┼───╂───┼───┼───┨\n")
			end
		end
	end
	print("\n┗━━━┷━━━┷━━━┻━━━┷━━━┷━━━┻━━━┷━━━┷━━━┛\n")
end

# -------------------------------
# -- Modele Susoku ensembliste --
# -------------------------------
function modele_Sudoku(grille::Matrix{Int64})

	# ---------------
	# -- Variables --
	# ---------------

	univers = Set(collect(1:9))
	# On créer p variables de domaine min = {}, domaine max = univers, cardinalité requise = p, est_fixee = false
	variables = [Variable(Set{Int64}(), univers, 1, false, i) for i in 1:81]
	
	nb_vars = length(variables)

	# -----------------
	# -- Contraintes --
	# -----------------
	# On créer les contraintes impliquant les variables
	contraintes = Vector{Contrainte}()

	# contraintes lignes
	for l in 1:9
		for c1 in 1:8
			for c2 in c1+1:9
				push!(contraintes, Contrainte([indice_var(l,c1),indice_var(l,c2)], filtre_intersection_vide!))
			end
		end
	end

	# contraintes colonnes
	for c in 1:9
		for l1 in 1:8
			for l2 in l1+1:9
				push!(contraintes, Contrainte([indice_var(l1,c),indice_var(l2,c)], filtre_intersection_vide!))
			end
		end
	end

	# contraintes blocs
	for b in 1:9
		for l in 1:9
			for c1 in 1:8
				for c2 in c1+1:9
					push!(contraintes, Contrainte([indice_var(l,c1),indice_var(l,c2)], filtre_intersection_vide!))
				end
			end
		end
	end

	for b in 1:9
		l = floor(Int, (b-1)/3) * 3 + 1
		c = (b-1)%3 * 3 + 1
		for i in 1:8
			l1 = l + floor(Int, (i-1)/3)
			c1 = c + (i-1)%3
			for j in i+1:9
				l2 = l + floor(Int, (j-1)/3)
				c2 = c + (j-1)%3
				push!(contraintes, Contrainte([indice_var(l1,c1),indice_var(l2,c2)], filtre_intersection_vide!))
			end
		end
	end
	nb_ctrts = length(contraintes)

	# ------------
	# -- Modele --
	# ------------
	modele = Modele(variables, contraintes, nb_vars, nb_ctrts, Vector{Int64}(), [i for i in 1:nb_vars], falses(nb_vars,length(univers)))

	# ------------------
	# -- Pre filtrage --
	# ------------------
	# On fixe un maximum de groupes selon l'état de l'art spécifique au sudoku

	fixer_vars_init!(modele, grille)

	return modele
end
