from modeles.modules import *

# n : nb de sommets
# m : nb d'aretes
# A : matrice des arêtes

def M1(n, m, A, k, budget, verbose):
	clear()
	# x est un vecteur. Il est de taille n. Chaque élément de x peut prendre une valeur dans le domaine [1,...,n].
	# x[i] est l'étiquette du sommet i. Exemple d'étiquetage possible: x = [2,4,3,1,5]
	x = VarArray(size=n, dom=range(1,n+1))

	if verbose == "v":
		print("Satisfy...")
	satisfy (
		AllDifferent(x)
	)

	# Minimize est chere (temps de calcul deraisonnable pour m > 300)
	if verbose == "v":
		print("Minimize...")
	minimize (
		Maximum( Minimum( (abs(x[i]-x[j])), (n - abs(x[i]-x[j])) ) for i in range(m) for j in range(m) if [i+1,j+1] in A )
	)

	str_budg = "-t="+str(budget)+"s"
	if verbose == "v":
		print("Solve...\n")
	sol_limit = solve(solver=ACE,options=str_budg)
	if (sol_limit is OPTIMUM):
		print("Probleme résolue à l'optimalité")
		return sol_limit.value
	elif (sol_limit is UNSAT):
		print("Probleme insatisfiable")
		return -1
	else:
		print("Budget dépassé")
		return -1

"""import json
fichier_json = open("instances/HB113/bcspwr03.mtx.rnd.json")
variables = json.load(fichier_json)

# n : nb de sommets
# m : nb d'aretes
# A : matrice des arêtes
# k : CB recherché

n = variables["n"]
m = variables["m"]
A = variables["A"]

M1(n, m, A, 10, 10)"""