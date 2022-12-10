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
# k : CB recherché

""" Etoile """
"""n = 5
m = 5
A = [[1,3],[3,5],[5,2],[2,4],[4,1]]
k = 1
"""

def calcul_borne_inf(A):
	deg_max = 0
	for s in range(1,n):
		cpt = 0
		for a in A:
			if s in a:
				print(s, " dans ", a)
				cpt += 1
				print(s, ":", cpt)
		if cpt > deg_max:
			deg_max = cpt
	print("deg max =", deg_max)
	return math.ceil(deg_max/2)

# Retourne True si sat, False si non sat et None si hors budget
def M2(n, m, A, k, budget, verbose):
	clear()
	start_time = time.time()
	# x est un vecteur. Il est de taille n. Chaque élément de f peut prendre une valeur dans le domaine [1,...,n].
	# x[i] est l'étiquette du sommet i. Exemple d'étiquetage possible: x = [2,4,3,1,5]
	x = VarArray(size=n, dom=range(1,n+1))

	# initialisation du distancier
	d = [[0 for i in range(n)] for j in range(n)]

	# création du distancier et des arretes correspondants à n sommet
	edges = []
	for i in range(n):
		for j in range(n):
			d[i][j] = min(abs(i-j), n - abs(i-j))
			if (i!=j):
				edges.append((i+1,j+1))

	# création des contraintes en extension
	table = {(i,j) for (i,j) in edges if d[i-1][j-1] <= k}

	# Chaque sommet doit etre etiquette differemment (AllDifferent)
	# et chaque arete doit etre etiquette selon les couples possibles contenue dans la table (contraintes en extension)

	#print("A : ", A)
	#print("### ", [(i,j) for (i,j) in A])
	satisfy (
		AllDifferent(x),
		x[0] == 1, # symétries (rotation)
		x[1] < x[n-1], # symétries (mirroir)
		[(x[i-1],x[j-1]) in table or (x[j-1],x[i-1]) in table for (i,j) in A]
	)

	str_budg = "-t="+str(budget)+"s"
	sol_limit = solve(solver=ACE,verbose=-1,options=str_budg)
	t_elapsed = time.time() - start_time
	t_elapsed = round(t_elapsed,4)

	if (sol_limit is SAT):
		print("Probleme satisfiable ("+str(sol_limit)+",",t_elapsed,"s)")
	elif (sol_limit is UNSAT):
		print("Probleme insatisfiable ("+str(sol_limit)+",",t_elapsed,"s)")
	elif (sol_limit is UNKNOWN):
		print("Budget dépassé ("+str(sol_limit)+",",t_elapsed,"s)")
	print("str(sol_limit) : " + str(sol_limit))
	return str(sol_limit), [], t_elapsed, []

"""
import json

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
