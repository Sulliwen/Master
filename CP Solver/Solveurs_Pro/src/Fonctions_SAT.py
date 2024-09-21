# Exemple avec un modèle résolu avec Glucose3
from pysat.solvers import Solver, Glucose3

# Pour itérerer sur les clauses AM (fonction Inter_semaine_constraints)
from itertools import product

import sys
import time
import datetime
import os
import copy

from os import listdir
from os.path import isfile, join

#------------------------------------------------------------------------------------------------
# Formattage : Les fonctions qui suivent ne sert que pour améliorer la lisibilité de la solution
#------------------------------------------------------------------------------------------------
# retourne le groupe associé à une position
def getGroupe(pos, nb_golfeurs_par_groupe):
    #print("pos = " + str(pos) + " nb_golfeurs_par_groupe = " + str(nb_golfeurs_par_groupe) + " nb_g % pos = " + str(nb_golfeurs_par_groupe % pos))
    if pos % nb_golfeurs_par_groupe == 0:
        ret = pos // nb_golfeurs_par_groupe
    else:
        ret = (pos // nb_golfeurs_par_groupe) + 1
    return ret

def Matrice_To_Verbose1(matrice, nb_golfeurs_par_groupe, nb_golfeurs, nb_semaines) :
    for s in range(1, nb_semaines+1):
        print("\nsemaine " + str(s))
        for i in range(1, nb_golfeurs+1):
            chaine = " golfeur " + str(i) + " dans groupe "
            for pos in range(1, nb_golfeurs+1):
                #print("golfeur i = " + str(i) + " pos = " + str(pos))
                if matrice[s-1][i-1][pos-1] == 1:
                    chaine += str(getGroupe(pos, nb_golfeurs_par_groupe))
            print(chaine)

def Matrice_to_HumanR(matrice, nb_golfeurs_par_groupe, nb_golfeurs, nb_semaines):
	nb_groupes = nb_golfeurs//nb_golfeurs_par_groupe

	sol = []
	semaine = []
	groupe = []
	for s in range(1, nb_semaines+1):
		semaine = []
		for m in range(1, nb_groupes+1):
			pos_deb_groupe = (m-1)*nb_golfeurs_par_groupe
			groupe = []
			for i in range(1, nb_golfeurs+1):
				if 1 in matrice[s-1][i-1][pos_deb_groupe : (pos_deb_groupe + nb_golfeurs_par_groupe)]:
					groupe.append(i)
			#print("on ajoute le groupe", groupe)
			semaine.append(groupe)
		#print("on ajoute la semaine", semaine)
		sol.append(semaine)
	
	return sol

def Matrice_To_Verbose2(matrice, nb_golfeurs_par_groupe, nb_golfeurs, nb_semaines) :
	print("nb_golfeurs = ",nb_golfeurs, "nb_golfeurs_par_groupe = ",nb_golfeurs_par_groupe)
	nb_groupes = nb_golfeurs//nb_golfeurs_par_groupe
	for s in range(1, nb_semaines+1):
		print("\nsemaine " + str(s))
		for m in range(1, nb_groupes+1):
		    chaine = " groupe " + str(m) + " : {"
		    pos_deb_groupe = (m-1)*nb_golfeurs_par_groupe
		    cpt = 0
		    for i in range(1, nb_golfeurs+1):
		        #print("golfeur i = " + str(i) + " pos_deb_groupe = " + str(pos_deb_groupe))
		        #input("continuer")
		        if 1 in matrice[s-1][i-1][pos_deb_groupe : (pos_deb_groupe + nb_golfeurs_par_groupe)]:
		            chaine += str(i)
		            cpt += 1
		            if cpt != nb_golfeurs_par_groupe:
		                chaine += ", "
		    chaine += "}"
		    print(chaine)

def Formattage_Matrice(m):
    chaine = "[\n"
    for semaine in range(len(m)) : #len(m) renvoie le nombre de ligne de la matrice m
        #chaine += "  [\n"
        chaine += "  semaine " + str(semaine+1) + " : [\n"
        for golfeur in range(len(m[semaine])): 
            #chaine += "   " + str(m[semaine][golfeur]) + "\n"
            chaine += "   golfeur " + str(golfeur+1) + " : " + str(m[semaine][golfeur]) + "\n"
        chaine += "  ]\n"
    chaine += " ]"
    return chaine

def DIMACS_to_Matrice(dimacs, nb_golfeurs, nb_semaines) :
    s = -1 # numero de la semaine
    k = -1 # numero du golfeur-1
    a = [[[0 for i in range(nb_golfeurs)] for i in range(nb_golfeurs)] for i in range(nb_semaines)]
    print("len(dimacs) = " + str(len(dimacs)))
    for i in range(len(dimacs)):
    	# changement de semaine
        if i % (nb_golfeurs*nb_golfeurs) == 0 :
            s = s + 1
            k = -1
        # changement de golfeur
        if i % nb_golfeurs == 0:
            k = k + 1
            j = 0
        if dimacs[i] > 0:
            a[s][k][j] = 1
        j = j+1
    return a
# Fin Formattage

#--------------------------------------------------------------------------------------------------------
# Contraintes : fonctions qui s'occupent de rajouter les contraintes AtLeast, AtMost et Social au modele
#--------------------------------------------------------------------------------------------------------

#------------------------
# -- Fonction At Least --
#------------------------
# Entrées
# - mSAT: modèle
# - s	: nombre de semaines
# - g	: nombre de golfeurs
# Sortie
# - Modélisation des contraintes At Least : Un golfeur doit être attribué à au moins une position
#-------------------------------------------------------------------------------------------------
def AtLeast_constraints(mSAT, s, g):
	nb_clause_AL = 0
	for i in range(s):
		for j in range(g):
		    mSAT.add_clause([i*(g*g) + j*g+k for k in range(1,g+1)]) # les conjonctions doivent correspondre aux lignes, et les disjonctions aux colonnes d'une matrice n x n
		    nb_clause_AL += 1
	return nb_clause_AL

#------------------------
# -- Fonction At Most --
#------------------------
# Entrées
# - mSAT: modèle
# - s	: nombre de semaines
# - g	: nombre de golfeurs
# Sortie
# - Modélisation des contraintes At Most : Un golfeur ne peut être positionné qu'à une position au plus
# ------------------------------------------------------------------------------------------------------
# Vu qu'on force d'avoir au moins un golfeur à 1 position (At least ci-dessus), un seul des 2 Atmost est suffisant pour obtenir une affectation bijective.
''' At most pour g=16 golfeurs
       -1 v -17 ^  -1 v -33 ^  -1 v -49 ^  -1 v -65 ^  -1 v -81 ^  -1 v -97 ^  -1 v -113 ^  -1 v -129 ^  -1 v -145 ^  -1 v -161 ^  -1 v -177 ^  -1 v -193 ^  -1 v -209 ^  -1 v -225 ^  -1 v -241
    ^             -17 v -33 ^ -17 v -49 ^ -17 v -65 ^ -17 v -81 ^ -17 v -97 ^ -17 v -113 ^ -17 v -129 ^ -17 v -145 ^ -17 v -161 ^ -17 v -177 ^ -17 v -193 ^ -17 v -209 ^ -17 v -225 ^ -17 v -241
    ^                         -33 v -49 ^ -33 v -65 ^ ...
    ^                                    ...
    ...                                    
    ^  -2 v -18 ^  -2 v -34 ^  -2 v -50 ^  -2 v -66 ...
    ^             -18 v -34 ^ -18 v -50 ^ -18 v -66 ...
                               ...
    ...
    ^ -16 v -32 ^ -16 v -64 ^ -16 v -80 ^ -16 v -96 ...
    ...
                                                    ... -240 v -246
'''
def AtMost_constraints(mSAT, s, g):
	nb_clauses_AM = 0
	# range(start, stop, step)
	for w in range(s):
		for l in range(1,g+1):
		    #print("----------------------------------------")
		    #print("(w = " + str(w) + ") i va de " + str(l + w*(g*g)) + " à " + str(g*(g-1)+1 + w*(g*g)) + " par pas de " + str(g))
		    for i in range(l + w*(g*g), g*(g-1)+1 + w*(g*g), g):
		        for j in range(g+i, g*g+1 + w*(g*g), g):
		            mSAT.add_clause([-i,-j])
		            #if w == 1:
		                #clauses_AM.append([-i,-j])
		                #print("clause AM : " + str(clauses_AM))
		            nb_clauses_AM += 1
	return nb_clauses_AM
                    
#------------------------
# -- Fonction d'affectation --
#------------------------
# Entrées
# - mSAT: modèle
# - s	: nombre de semaines
# - g	: nombre de golfeurs
# Sortie
# - Pour chaque semaine, on veut exactement 1 golfeur à chaque position (donc au moins 1 par position et au plus 1 par position), par ex pour une semaine:
'''
Semaine 1:
		[
		[0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] # Le golfeur 1 est positionné en pos 5 (groupe 2)
		[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
		[0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
		[0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
		[0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
		[0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
		[0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]
		[0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0]
		[0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]
		[0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]
		[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]
		[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0]
		[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0] # Le golfeur 13 est positionné en pos 13
		[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]
		[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0]
		[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]
		]
'''
def Affectation_constraints(mSAT, s, g):
	
	start = time.time()
	# Création des clauses AL
	nb_clauses_AL = AtLeast_constraints(mSAT, s, g)
	
	end = time.time()
	t_exec = round(end - start, 3)
	
	f = open("res/SAT/Clauses.txt", "a")
	chaine = "nb clauses AL: " + str(nb_clauses_AL) + "\n"
	chaine += "t_exec: " + str(t_exec) + "\n\n"
	f.write(chaine)
	f.close()
	
	start = time.time()
	# Création des clauses AM
	nb_clauses_AM = AtMost_constraints(mSAT, s, g)
	
	end = time.time()
	t_exec = round(end - start, 3)
	
	f = open("res/SAT/Clauses.txt", "a")
	chaine = "nb clauses AM: " + str(nb_clauses_AM) + "\n"
	chaine += "t_exec: " + str(t_exec) + "\n\n"
	f.write(chaine)
	f.close()
	
	
	return nb_clauses_AL, nb_clauses_AM

def calcul_lit(g, p, si, gi, ji, i):
	return (si-1)*g*g + (ji-1)*g + (gi-1)*p + i

# -----------------------------------------------------------------------------------------------------------------------------------------------
# Modélisation des contraintes de sociabilité : Un golfeur ne peut pas jouer une deuxième fois avec un même joueur (dans 2 semaines différentes)
# -----------------------------------------------------------------------------------------------------------------------------------------------
# Si, en semaine 1, le golfeur 1 joue dans le groupe 1 (1 v 2 v 3 v 4) et que le golfeur 2 joue aussi dans le groupe 1 (17 v 18 v 19 v 20),
# Alors il ne pourront pas jouer ensemble en semaine 2: (-257 ^ -258 ^ -259 ^ -260) v (-273 ^ -274 ^ -275 ^ -276)
#       (1 v 2 v 3 v 4) ^ (17 v 18 v 19 v 20) => (-257 ^ -258 ^ -259 ^ -260) v (-273 ^ -274 ^ -275 ^ -276)
# CNF : 

# On créer une table qui regroupe tous de teamup interdit sur 2 semaines GI = [(i,j),(k,l)] avec i = j et k = l.
#  Ainsi [(1,2),(1,2)] n'est pas interdit car le joueur 1 et 2 sont dans 2 groupes différent d'une semaine à l'autre.
#  Par contreExemple [(1,1),(6,6)] est interdit car les joueurs jouent ensemble (dans le groupe 1) en semaine 1 et encore (dans le groupe 6) en semaine 2.

def Social_constraints(mSAT, s, g, k):
	nb_clauses = 0
	p = g//k

	#print("nombre de semaine: ", s)
	#print("nombre de total de golfeurs: ", g)
	#print("nombre de groupes: ", k)
	#print("nombre de joueurs par groupe: ", p)
	# pairs de joueur
	pairs = [(j1,j2) for j1 in range(1,g) for j2 in range(j1+1,g+1) if j1!=j2]
	
	# positions possible pour une pair de joueurs dans un groupe
	poses = [(i,j) for i in range(1,p+1) for j in range(1,p+1) if i!=j]
	
	start = time.time()
	# Pour chaque pair de joueur
	for (j1,j2) in pairs:
		# Pour chaque semaine s1 où j1,j2 vont jouer
		for s1 in range(1,s):
			# Pour chaque groupe g1 où j1,j2 vont jouer
			for g1 in range(1,k+1):
				# Pour chaque position que peuvent prendre j1 et j2 dans g1
				for (s1p1,s1p2) in poses:
					id_s1j1 = calcul_lit(g, p, s1, g1, j1, s1p1) # on calcul l'id du literal correspondant pour j1 dans le groupe g1 position i en s1
					id_s1j2 = calcul_lit(g, p, s1, g1, j2, s1p2) # on calcul l'id du literal correspondant pour j2 dans le groupe g1 position j en s1
					# Pour chaque semaine s2
					for s2 in range(s1+1,s+1):
						# Pour chaque groupe g2
						for g2 in range(1,k+1):
							# Pour chaque position que peut prendre j1,j2 dans g2
							for (s2p1,s2p2) in poses:

								#print(" j", j1, "s", s1, "groupe", g1, " pos : ", s1p1)
								#print(" j", j2, "s", s1, "groupe", g1, " pos : ", s1p2,"\n")
								
								#print(" j", j1, "s", s2, "groupe", g2, " pos : ", s2p1)
								#print(" j", j2, "s", s2, "groupe", g2, " pos : ", s2p2,"\n")
								
								id_s2j1 = calcul_lit(g, p, s2, g2, j1, s2p1) # on calcul l'id du literal correspondant pour j1 dans le groupe g1 position i en s1
								id_s2j2 = calcul_lit(g, p, s2, g2, j2, s2p2) # on calcul l'id du literal correspondant pour j2 dans le groupe g1 position j en s1
								#print("s2: couple litteraux associé -> (", (id_s1j1,id_s1j2))
								#print("s2: couple litteraux associé -> (", (id_s2j1,id_s2j2))
								#input("continuer")
								#print("\n\n")
								mSAT.add_clause([-id_s1j1,-id_s1j2,-id_s2j1,-id_s2j2])

								nb_clauses += 1
	
	end = time.time()
	t_exec = round(end - start, 3)
	
	f = open("res/SAT/Clauses.txt", "a")
	chaine = "nb clauses sociabilite: " + str(nb_clauses) + "\n"
	chaine += "t_exec: " + str(t_exec) + "\n\n\n"
	f.write(chaine)
	f.close()
	
	return nb_clauses

# Brise symmetrie o0: ordre entre les joueurs à l'intérieur d'un groupe
# -- Si j1 est en position p1 dans g1, alors aucun joueur d'indice plus petit ne doit apparaître dans une position postérieur dans g1, et aucun joueur d'indice plus grand ne doit apparaître dans une position antérieur dans g1
def Intra_groupe_constraints(mSAT, s, k, p):
	g = k*p
	nb_clauses = 0
	# Pour chaque semaine
	for sem in range(1,s+1):
		# Pour chaque joueur j1
		for j1 in range(1,g+1):
			# Pour chaque groupe auquel j1 peut appartenir
			for g1 in range(1,k+1):
				# Pour chaque position que peut prendre j1 dans g1
				for p1 in range(1,p+1):
					id_j1 = calcul_lit(g, p, sem, g1, j1, p1)
					# Pour chaque joueur d'indice plus petit
					for j2 in range(1,j1):
						# Pour chaque position postérieur à j1 dans g1
						for p2 in range(p1+1,p+1):
							id_j2 = calcul_lit(g, p, sem, g1, j2, p2)
							#print("-", id_j1, "v", "-", id_j2)
							nb_clauses += 1
							mSAT.add_clause([-id_j1,-id_j2])
	return nb_clauses

# Brise symmetrie o1: ordre entre les groupes
# -- Si j1 est le plus petit de son groupe, alors aucun joueur d'indice plus petit ne doit apparaître dans les groupes suivants
def Inter_groupes_constraints(mSAT, s, k, p):
	g = k*p
	nb_clauses = 0
	# Pour chaque semaine
	for sem in range(1,s+1):
		# Pour chaque joueur j1
		for j1 in range(1,g+1):
			# Pour chaque groupe auquel j1 peut appartenir
			for g1 in range(1,k+1):
				# Pour chaque position que peut prendre j1 dans g1
				for p1 in range(1,p+1):
					id_j1 = calcul_lit(g, p, sem, g1, j1, p1)
					# Pour chaque joueur d'indice plus petit que j1
					# On récupère l'indice DIMACS de chaque position que peuvent prendre les joueurs d'indice plus petit que j1
					ppj1 = [0 for i in range(1,j1)]
					for j3 in range(1,j1):
						pj3 = [0 for i in range(1,p+1)]
						# Pour chaque position que peut prendre j3 dans g1
						for p3 in range(1,p+1):
							id_j3 = calcul_lit(g, p, sem, g1, j3, p3)
							pj3[p3-1] = id_j3
						#print("pj3 = ",pj3)
						ppj1[j3-1] = pj3
					liste_ppj1 = []
					for i in ppj1:
						liste_ppj1 = liste_ppj1 + i
					#print("liste_ppj1 = ",liste_ppj1)
							
					# Pour chaque joueur d'indice plus petit
					for j2 in range(1,j1):
						# Pour chaque groupe suivant g1
						for g2 in range(g1+1,k+1):
							# Pour chaque position que peut prendre j2
							for p2 in range(1,p+1):
								id_j2 = calcul_lit(g, p, sem, g2, j2, p2)
								liste_lit = [-id_j1] + liste_ppj1 + [-id_j2]
								#print("liste_lit = ", liste_lit)
								nb_clauses += 1
								mSAT.add_clause(liste_lit)
	return nb_clauses

# Fonction dédiée à la contrainte de brise-symmetrie inter-semaines qui prend en entrée:
# - le nombre de golfeurs g
# - le nombre de joueur par groupe p 
# - le numéro de la semaine sem
# - le numéro du joueur j1
# et retourne la liste de littéraux associés à la contrainte qui assure qu'au moins un joueur d'indice plus petit se trouve dans le groupe 1, semaine sem (là où se trouve le joueur j)   
def getAL(g, p, sem, j1):
	# At Least
	lit_AL = []
	# Pour chaque joueur d'indice plus petit: exactement un joueur doit lui etre inférieur
	for j3 in range(1,j1):
		# Pour chaque position dans le groupe 1 (différent de la position de j1)
		for p3 in range(1,p+1):
			# Au moins un joueur j3 doit se trouver dans le même groupe 1 que j1
			id_j3 = calcul_lit(g, p, sem, 1, j3, p3)
			lit_AL.append(id_j3)
	return lit_AL
			
# Fonction dédiée à la contrainte de brise-symmetrie inter-semaines qui prend en entrée:
# - le nombre de golfeurs g
# - le nombre de joueur par groupe p 
# - le numéro de la semaine sem
# - le numéro du joueur j1
# et retourne la liste de liste de littéraux associés à la contrainte qui assure qu'au plus un joueur d'indice plus petit se trouve dans le groupe 1, semaine sem (là où se trouve le joueur j)
def getAM(g, p, sem, j1):
	lit_AM = []
	# Pour chaque paire de joueur d'indice plus petit
	pairs = [(j2,j3) for j2 in range(1,j1-1) for j3 in range(j2+1,j1) if j1!=j2]
	
	for (j2,j3) in pairs:
		# Pour chaque position que peut prendre j2 dans le groupe 1 (différent de la position de j1)
		for p2 in range(1,p+1):
			#if p2!=p1:
			id_j2 = calcul_lit(g, p, sem, 1, j2, p2)
			# Pour chaque position que peut prendre j3 dans le groupe 1 (différent de la position de j1)
			for p3 in range(1,p+1):

				#if p3!=p1:
				id_j3 = calcul_lit(g, p, sem, 1, j3, p3)
				lit_AM.append([-id_j2,-id_j3])
	return lit_AM

# Brise symmetrie o2: ordre entre les semaines (Trop de clauses générée: à revoir?)
# -- Si en semaine s1, j1 est le deuxieme plus petit de son groupe, alors en semaine s2, aucun joueur d'indice plus petit ne doit apparaître dans les groupes suivants, et aucun joueur d'indice plus grand ne doit apparaître dans les groupes précédents
# -- <=> Si exactement un joueur est plus petit que j1 dans g1 en s1, alors exactement 1 joueur doit etre plus petit que j1 dans g1 en s2 (les contraintes d'affectation + sociabilité font le reste)
# -- (2ème minimum <=> exactement 1 joueur j2 d'indice plus petit que j1 doit être présent dans le groupe g1 (AL + AM) )
def Inter_semaines_constraints(mSAT, s, k, p):
	g = k*p
	# Pour chaque pair de semaine
	pairs = [(s1,s2) for s1 in range(1,s) for s2 in range(s1+1,s+1) if s1!=s2]
	for (s1,s2) in pairs:
		# Pour chaque joueur j1
		for j1 in range(1,g+1):
			# Pour chaque position que peut prendre j1 dans le groupe 1
			pos_j1 = [0 for i in range(1,p+1)]
			for p1 in range(1,p+1):
				id_j1 = calcul_lit(g, p, s1, 1, j1, p1)
				# Pose j1
				pos_j1[p1-1] = id_j1
				
				# At Least
				lit_AL_s1 = getAL(g, p, s1, j1)
				lit_AL_s2 = getAL(g, p, s2, j1)
				
				# At most
				lit_AM_s1 = getAM(g, p, s1, j1)
				lit_AM_s2 = getAM(g, p, s2, j1)
				
				lit_implique = [lit_AL_s2] + lit_AM_s2

				#pos_j1 ^ lit_AL_s1 ^ lit_AM_s1 => lit_AL_s2 ^ lit_AM_s2
				for pos in pos_j1:
					for al in lit_AL_s1:	
						for n_tuple in product(*lit_AM_s1):
							for e in lit_implique:
								liste_lit = [-pos] + [-al] + list(n_tuple) + e
								# On supprime tous les doublons
								liste_lit = list(set(liste_lit))
								#print(liste_lit)
								#input("press")
'''
for pos in pos_j1:
	for al in lit_AL_s1:		
		for n_tuple in product(*lit_AM_s1):
			for e in lit_implique:
				print("e =",e)
				liste_lit = [-pos] + [-al] + list(n_tuple) + e
				liste_lit = list(set(liste_lit))
				print(liste_lit)
				input("press")
								'''
