import math
import json
import time
import sys
import copy
from os import listdir
from os.path import isfile, join
from operator import itemgetter

from modeles.modules import *

# n : nb de sommets
# m : nb d'aretes
# A : matrice des arêtes

def M1_bis(n, m, A, k, budget, verbose):
	clear()
	# x est un vecteur. Il est de taille n. Chaque élément de x peut prendre une valeur dans le domaine [1,...,n].
	# x[i] est l'étiquette du sommet i. Exemple d'étiquetage possible: x = [2,4,3,1,5]
	x = VarArray(size=n, dom=range(1,n+1))

	if verbose == "v":
		print("Satisfy...")
	satisfy (
		AllDifferent(x),
		x[0] == 1, # brise symétries rotation
		x[2] < x[n-1] # brise symétrie miroir
	)

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

nom_instance = "lns__131"
dossier = "ann"
fichier_json = json_file = open("../instances/"+dossier+"/"+nom_instance+".json")
variables = json.load(json_file)

# n : nb de sommets
# m : nb d'aretes
# A : matrice des arêtes
# k : CB recherché

n = variables["n"]
m = variables["m"]
A = variables["A"]

#M3(n, m, A, k, budget)"""