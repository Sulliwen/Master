import os
import sys
sys.path.append(os.path.join(os.getcwd(), '..'))
sys.path.append(os.path.join(os.getcwd(), 'src'))

import signal
import time

from Fonctions_SAT import *
	
def handler(signum, frame):
	raise Exception("end of time")

#----------------
# Modèle SGP SAT
#----------------
def SGP_modele_SAT(mSAT, s, k, p, var, timeout) :
	g = k*p
	bs = []
	nb_clauses = 0
	
	# Definition des brises symmetries
	a1 = "a1" in var
	a2 = "a2" in var
	o0 = "o0" in var
	o1 = "o1" in var
	o2 = "o2" in var
	
	# On start un chrono
	start = time.time()
	
	# On ne calcul que les temps de génération des clauses a
	t_aff = 0
	
	# Contraintes d'affectation (très rapide comparé aux clause de sociabilités)
	print("Création des clauses d'affectation en cours...")
	
	tic = time.time()
	nb_clauses_AL, nb_clauses_AM = Affectation_constraints(mSAT, s, g)
	tac = time.time()
	t_aff += tac - tic
	
	tic = time.time()
	nb_clauses = nb_clauses_AL + nb_clauses_AM
	tac = time.time()
	t_aff += tac - tic
	
	# Toc chrono
	toc = time.time()
	t_elapsed = toc - start
	print("done (t_elapsed : "+str(round(t_elapsed,3))+ "s | t gen clauses : " + str(round(t_aff,3))+"s)")
	
	# Enregistrement du gestionnaire de fonction de signal
	signal.signal(signal.SIGALRM, handler)

	# On définit un timeout pour la fonction qui ajoute les clauses de sociabilité (car particulièrement couteuse)
	#print("temps de départ :",timeout)
	timeout -= t_elapsed
	#print("temps restant :",timeout)
	signal.alarm(int(timeout)+1)
	
	nb_clauses_Soc = 0
	# On essaye de lancer la fonction Social_constraints
	# - Si elle dépasse le budget, alors l'instance est ignoré car trop gourmande en temps
	try:
		print("Création des clauses de sociabilité en cours...")
		
		# On ne calcul que les temps de génération des clauses a
		t_soc = 0
	
		tic = time.time()
		nb_clauses_Soc = Social_constraints(mSAT, s, g, k)
		tac = time.time()
		t_soc = tac - tic
		
	except Exception as exc:
		print(exc)
		end = time.time()
		t_exec = round(end - start, 3)
		print("t_exec :", t_exec)
		return bs, nb_clauses, t_exec # on ignore en retournant à la fonction appelante
	
	# On désactive l'alarme
	signal.alarm(0)
	
	nb_clauses += nb_clauses_Soc
	
	# Toc chrono
	toc = time.time()
	t_elapsed = round(toc - start, 3)
	print("done (t_elapsed : "+str(round(t_elapsed,3))+ "s | t gen clauses : " + str(round(t_soc,3))+"s)")

	# ----------------------------
	# Brise symmétrie: Assertions
	# ----------------------------
	# On fixe la premiere semaine (a1)
	if a1:
		bs_a1 = [g*(i-1) + i for i in range(1,g+1)]
		bs += bs_a1
	# On fixe le premier joueur du groupe i à i pour i allant de 1 à p (a2)
	if a2:
		# Si on a fixé la semaine 1, alors on ne fixe le premier joueur des p premiers groupes qu'à partir de la deuxième semaine
		if a1:
			bs_a2 = [g*g*i + g*(j-1) + p*(j-1) + 1 for i in range(1,s) for j in range(1,p+1)]
		else :
			bs_a2 = [g*g*i + g*(j-1) + p*(j-1) + 1 for i in range(s) for j in range(1,p+1)]
			
		bs += bs_a2
	
	# ----------------------------
	# Brise symmétrie: Ordre
	# ----------------------------
	# On ordonne chaque groupe (ordre intra groupe) (o0)
	if o0:
		nb_clauses += Intra_groupe_constraints(mSAT, s, k, p)
	# On ordonne les groupes entre eux (ordre inter groupes) (o1)
	if o1:
		nb_clauses += Inter_groupes_constraints(mSAT, s, k, p)
	# On ordonne les semaines entre elles (ordre inter semaines) (o2) 
	if o2:
		Inter_semaines_constraints
	
	#-----------------
	# Sur contraintes
	#-----------------
	# On fixe le premier groupe de la semaine 2 (sur contraintes 1)
	#sc1 = [g*g + g*p*(i-1) + i for i in range(1,p+1)]
	# On fixe les premiers joueurs de chaque groupe (sur contraintes 2)
	#sc2 = [g*g*i + g*(j-1) + p*(j-1) + 1 for i in range(1,s) for j in range(1,k)]
	
	# Fin chrono
	end = time.time()
	t_exec = round(end - start, 3)
	
	return bs, nb_clauses, t_exec
