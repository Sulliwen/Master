# Exemple avec un modèle résolu avec Glucose3
from pysat.solvers import Solver, Glucose3
from threading import Timer

# Pour itérerer sur les clauses AM (fonction Inter_semaine_constraints)
from itertools import product

import sys
import time
import datetime
import os
import random
import string

import matplotlib.pyplot as plt

from os import listdir
from os.path import isfile, join

sys.path.append(os.path.join(os.getcwd(), 'src'))

from Fonctions_SAT import *

sys.path.append(os.path.join(os.getcwd(), 'Modeles_SAT'))

from SGP_modele_SAT import *

def randstring(length):
	characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPRSTUVWXYZ0123456789'

	random_string = ''
	for i in range(length):
		random_char = random.choice(characters)
		random_string += random_char
	return random_string
    
# -----------
# Résolution
# -----------
def interrupt(s):
	s.interrupt()

	
def Solve(mSAT, bs, s, k, p, timeout) :
	res = False
	g = k*p
	# Cas infaisables
	# - Si s > 1, on doit avoir plus de groupes que de joueurs par groupe
	# - On doit s'assurer qu'il y a assez de joueurs pour que, à chaque semaine, un joueur rencontre p-1 nouveaux joueurs
	# + d'autres ?
	infaisable = (s > 1 and p > k) or (s*(p-1) > g)
	# desactiver pour la comparaison avec les instances Cardinal
	#if infaisable:
	if False:
		chaine = "\nL'instance est structurellement infaisable\n"
		chaine += "UNSAT\n"
		chaine += "\nt exec = 0\n\n"
		t_exec = 0
		print(chaine)
	else:
		# Retourne True si la formule est SATisfiable, False sinon
		start = time.time()

		# On configure le budget de temps
		mSAT.clear_interrupt()
		#timeout = 1
		timer = Timer(timeout, interrupt, [mSAT])
		timer.start()

		res = mSAT.solve_limited(expect_interrupt=True, assumptions=bs)
		end = time.time()
		t_exec = end - start
		#res = mSAT.solve(assumptions=bs)
		#res = mSAT.solve(assumptions=[1]) : # on force le golfeur 1 a etre en position 1 (groupe 1)
		#res = mSAT.solve()
		
		timer.cancel()
		mSAT.clear_interrupt()
		
		# Logs res/Res_"+ID_EXP+".txt
		if res :
			print("\n\033[32mSAT\n \033[0m")
			print("\ntemps exec:" + str(t_exec) + "\n")
			matrice_sol = DIMACS_to_Matrice(mSAT.get_model(), g, s)
			matrice_sol_h = Matrice_to_HumanR(matrice_sol, p, g, s)
			
			i = 1
			chaine = ""
			for sem in matrice_sol_h:
				for g in sem:
					chaine += "{"
					for j in g:
						chaine += str(j) + ","
					chaine = chaine[:len(chaine)-1]
					chaine += "}, "
				chaine = chaine[:len(chaine)-2]
				chaine += "\n"
				#print("chaine =",chaine)
				i += 1
			chaine += "\ntemps de résolution (Glucose3):" + str(round(t_exec, 3)) + "\n\n"
		else :
			if t_exec >= timeout:
				chaine = "TIME OUT\n"
				chaine += "\ntimeout (Glucose3):" + str(round(t_exec, 3)) + "\n\n"
				print("\033[35mTIME OUT\n \033[0m")
			else:
				chaine = "UNSAT\n"
				chaine += "\nt solve (Glucose3):" + str(round(t_exec, 3)) + "\n\n"
				print("\033[31mUNSAT\n \033[0m")
				print("t exec : " + str(round(t_exec, 3)))
			
		f = open("res/SAT/Res_"+ID_EXP+".txt", "a")
		f.write(chaine)
		f.close()
		
		# Affichage console
		g = k*p
		if res:
			Matrice_To_Verbose2(matrice_sol, p, g, s)
			print("\ntemps de résolution (Glucose3):" + str(round(t_exec, 3)) + "\n\n")
	return t_exec

#----------------------------------
#- Initialisation de l'experiment -
#----------------------------------
# Récupère les instances de l'experience
def Init_Experiment(args):
	# id de l'exp:
	global ID_EXP
	ID_EXP = randstring(5)

	# Définition des packs d'instances
	instances_cardinal = [[2,5,4],[2,6,4],[2,7,4],[2,8,5],[3,5,4],[3,6,4],[3,7,4],[4,5,4],[4,6,5],[4,7,4],[4,9,4],[5,4,3],[5,5,4],[5,7,4],[5,8,3],[6,4,3],[6,5,3],[6,6,3],[7,5,3],[7,5,5]]
	#instances_cardinal = [[2,5,4],[2,6,4],[2,7,4]]
	instances_balayage = [[]]
	instances_challenge = [[5,4,3]]
	for s in range(1,8):
		for k in range(2,8):
		    for p in range(2,8):
		        instances_balayage.append([s,k,p])

	instances_balayage = instances_balayage[2:]

	packs_instances = [instances_cardinal, instances_balayage, instances_challenge]
	nom_packs_ins = ["Cardinal", "Balayage", "Challenge"]

	# Définition des packs de modules
	modules_all = ["a1", "a2", "a12", "a12_o0", "a12_o1", "a12_o01", "o0", "o1", "o01", "sbs"]
	modules_bs_a = ["a1", "a2", "a12"]
	modules_bs_o = ["o0", "o1", "o01"]

	packs_modules = [modules_all, modules_bs_a, modules_bs_o]

	instances_select = []
	bss_modele_select = []
	nb_args = len(args)

	# Instance perso (modèle sbs par defaut)
	if nb_args == 4 and all([a.isdigit() for a in args[1:]]) :
		print("Instance perso (modèle sbs par defaut)")
		s = int(args[1])
		k = int(args[2])
		p = int(args[3])
		instances_select = [[s,k,p]]
		nom_instance = "Perso"

		bss_modele_select = ["sbs"]
	else :
		# Instance perso et modèles perso
		if nb_args >= 6 and all([a.isdigit() for a in args[1:4]]) and args[4] == "-m" :
			print("Instance perso et modèles perso")
			s = int(args[1])
			k = int(args[2])
			p = int(args[3])
			instances_select = [[s,k,p]]
			nom_instance = "Perso"
			
			bss_modele_select = args[5:]
		else :
			# Instance perso et modèles pack
			if nb_args == 6 and all([a.isdigit() for a in args[1:4]]) and args[4] == "-b" and args[5].isdigit() :
				print("Instance perso et modèles pack")
				s = int(args[1])
				k = int(args[2])
				p = int(args[3])
				instances_select = [[s,k,p]]
				nom_instance = "Perso"
				
				ind_pack_module = int(args[5])
				bss_modele_select = packs_modules[ind_pack_module]
			else :
				# Instance pack (modèle sbs par defaut)
				if nb_args == 3 and args[1] == "-t" :
					print("Instance pack (modèle sbs par defaut)")
					ind_pack_instance = int(args[2])
					instances_select = packs_instances[ind_pack_instance]
					nom_instance = nom_packs_ins[ind_pack_instance]
					
					bss_modele_select = ["sbs"]
				else :
					# Instance pack et modèles perso
					if nb_args >= 5 and args[1] == "-t" and args[2].isdigit() and args[3] == "-m" :
						print("Instance pack et modèles perso")
						ind_pack_instance = int(args[2])
						instances_select = packs_instances[ind_pack_instance]
						nom_instance = nom_packs_ins[ind_pack_instance]
						
						bss_modele_select = args[4:]
					else :
						# Instance pack et modèles pack
						if nb_args == 5 and args[1] == "-t" and args[2].isdigit() and args[3] == "-b" and args[4].isdigit() :
							print("Instance pack et modèles pack")
							ind_pack_instance = int(args[2])
							instances_select = packs_instances[ind_pack_instance]
							nom_instance = nom_packs_ins[ind_pack_instance]
							
							ind_pack_module = int(args[4])
							bss_modele_select = packs_modules[ind_pack_module]
						else :
							print("Commande inconnue. Voir la liste des commandes dans le fichier Readme.txt.")
							exit()

	# On récupère le param global verbose
	#global VERBOSE = args[len(args)-1] == "-v"

	return [instances_select, nom_instance, bss_modele_select]

# Lance l'experiment
def Experiment(args):

	# Récupération des instances et des modules
	instances, nom_instance, bss_modele  = Init_Experiment(args)

	f = open("res/SAT/Res_"+ID_EXP+".txt", "w")
	chaine = "---------------\n"
	chaine += "-- Resultats --\n"
	chaine += "---------------\n\n"
	f.write(chaine)
	print(chaine)
	f.close()

	f = open("res/SAT/Latex_"+ID_EXP+".txt", "w")
	f.write("-- Tableau des res format latex --\n\n")
	f.close()
	
	f = open("res/SAT/Clauses_"+ID_EXP+".txt", "w")
	chaine = "---------------------------------------------\n"
	chaine += "-- Nombre et temps de création des clauses --\n"
	chaine += "---------------------------------------------\n\n"
	f.write(chaine)
	f.close()

	chaine = "////////////////////////\n"
	chaine += "// Instances " + nom_instance + " //\n"
	chaine += "////////////////////////\n\n"
	
	f = open("res/SAT/Res_"+ID_EXP+".txt", "a")
	f.write(chaine)
	print(chaine)
	f.close()
	
	print(" instances = ", instances)
	
	t_exec_par_modele_par_instance = []
	t_solve_par_modele_par_instance = []
	
	# Pour chaque instance s,k,p
	for ins in instances:

		# On récupère l'instance
		[s,k,p] = ins
		
		chaine = "-------------------\n"
		chaine += "| Instance: " + str(s) + " " + str(k) + " " + str(p) + " |\n"
		chaine += "-------------------\n"
		f = open("res/SAT/Res_"+ID_EXP+".txt", "a")
		f.write(chaine)
		print(chaine)
		f.close()
	
		# Génération des résultats des clauses sous forme de tableau au format latex
		str_latex = "\\begin{table}[H]\n"
		str_latex += "\centering\n"
		str_latex += "\\begin{tabular}{|c|c|c|c|c|c|} \hline\n"
		str_latex += "\\textbf{Instance} & \\textbf{Modèle} & \\textbf{nb clauses} & \\textbf{\\% t clauses} & \\textbf{\\% t solve} & \\textbf{t total (s)} \\\\ \hline\n"
		str_latex += "\\multirow{" + str(len(bss_modele)) + "}{4em}{\centering{" + str(s) + " " + str(k) + " " + str(p) + "}}"
		
		f = open("res/SAT/Latex_"+str(s)+str(k)+str(p)+".txt", "w")
		f.write(str_latex)
		f.close()
		
		info_clauses_renseignees = False
		
		t_exec_par_modele = []
		t_solve_par_modele = []
		
		# Pour chaque modèle
		for bss in bss_modele:
			
			nom_modele_fic = "bs_" + bss
			
			chaine = "-----------------------------------\n"
			chaine += "Modele " + nom_modele_fic + "\n"
			chaine += "-----------------------------------\n\n"
			f = open("res/SAT/Res_"+ID_EXP+".txt", "a")
			f.write(chaine)
			print("bss =",bss)
			print(chaine)
			print("\t(instance "+str(s) + " " + str(k) + " " + str(p)+")")
			f.close()
			
			var = [bss]
			
			if bss == "a12":
				var = ["a1","a2"]
			if bss == "a12_o0":
				var = ["a1","a2","o0"]
			if bss == "a12_o1":
				var = ["a1","a2","o1"]
			if bss == "a12_o01":
				var = ["a1","a2","o0","o1"]
			if bss == "o01":
				var = ["o0","o1"]
			
			timeout = BUDGET.seconds
			#timeout = 1
			mSAT = Glucose3()
			
			start_clauses = time.time()
			t_solve = 0
			bs, nb_clauses, t_clauses = SGP_modele_SAT(mSAT, s, k, p, var, timeout)
			#print("fin: nb_clauses = ", nb_clauses)
			#print("t_clauses = ", t_clauses)
			#print("bs =", bs)
			# On met a jour le timeout restant
			end_clauses = time.time()
			t_clauses = end_clauses - start_clauses
			timeout -= t_clauses
			
			# Si le budget a été dépassé lors de la création de clauses, alors on l'indique dans le rapport et on passe à l'instance suivante
			if timeout <= 0:
				print("\033[35mTIMEOUT\n \033[0m ("+str(round(timeout,3))+"s)")
				nb_clauses = "-"
				t_exec_total = t_clauses
				t_solve = -10
				prctg_clauses = "-"
				prctg_solve = "-"
			# Sinon on continue l'analyse de l'instance (résolution)
			else :
				print("Résolution en cours...")
				#print("on lance la résolution avec un timeout de ", timeout)
				t_solve = Solve(mSAT, bs, s, k, p, timeout)
				# Si le budget a été dépassé lors de la résolution, alors on l'indique dans le rapport et on passe à l'instance suivante
				timeout -= t_solve
				t_exec_total = t_clauses + t_solve
				t_exec_total = round(t_exec_total, 3)
				if timeout <= 0:
					prctg_clauses = "-"
					prctg_solve = "-"
				else:
					prctg_clauses = round(round(t_clauses/t_exec_total, 2)*100,2)
					prctg_solve = round(round(t_solve/t_exec_total, 2)*100,2)

			# On supprime le modele
			mSAT.clear_interrupt()
			mSAT.delete()
			
			# Génération des résultats sous forme de tableau au format latex (res/Latex.txt)
			str_latex = " & " + bss.replace("_", "\_") +  " & " + str(nb_clauses) + " & " + str(prctg_clauses) + " & " + str(prctg_solve) + " & " + str(t_exec_total) + " \\\\ \n"
			f = open("res/SAT/Latex_"+str(s)+str(k)+str(p)+".txt", "a")
			f.write(str_latex)
			f.close()
			
			# Sauvegarde des résultats pour plot
			t_exec_par_modele.append(t_exec_total)
			t_solve_par_modele.append(t_solve)
		
		# Génération des résultats sous forme de tableau au format latex
		str_latex = "\\hline\n"
		str_latex += "\\end{tabular}\n"
		str_latex += "\\caption{Instance "+str(s)+" "+str(k)+" "+str(p)+": influence des bs sur les temps de résolution de Glucose3}\n"
		str_latex += "\\end{table}\n\n"
		
		f = open("res/SAT/Latex_"+str(s)+str(k)+str(p)+".txt", "a")
		f.write(str_latex)
		f.close()
		
		# Sauvegarde des temps d'exec par instance pour plot
		str_plot = "Données plots (total)\n\n"
		
		t_exec_par_modele_par_instance.append(t_exec_par_modele)
		str_plot += str(t_exec_par_modele_par_instance) + " "
		
		f = open("res/graph/Plots_SAT_total_"+nom_instance+"_"+str(ID_EXP)+".txt", "w")
		f.write(str_plot)
		f.close()
		
		str_plot_solve = "Données plots (solve)\n\n"
		
		t_solve_par_modele_par_instance.append(t_solve_par_modele)
		str_plot_solve += str(t_solve_par_modele_par_instance) + " "
		
		f = open("res/graph/Plots_SAT_solve_"+nom_instance+"_"+str(ID_EXP)+".txt", "w")
		f.write(str_plot_solve)
		f.close()
	
	#----------------------------------------
	#- Plots de l'experimentation (t total) -
	#----------------------------------------
	fig, ax = plt.subplots()

	# On doit dessiner le canvas, sinon les labels ne seront pas positionné et n'auront pas de valeur 
	fig.canvas.draw()

	nb_instances = len(instances)
	nb_modeles = len(bss_modele)
	
	# On récupère les temps d'execution par instance pour chacun des modeles
	t_exec_par_instance_par_modele = []
	for i in range(nb_modeles):
		t_exec_par_modele = []
		for j in range(nb_instances):
			t_exec_par_modele.append(t_exec_par_modele_par_instance[j][i])
		t_exec_par_instance_par_modele.append(t_exec_par_modele)
	
	# On plot les temps pour chaque modele
	x = range(nb_instances)
	for i in range(nb_modeles):
		y = t_exec_par_instance_par_modele[i]
		plt.plot(x, y, label='bs_'+bss_modele[i])
	plt.legend()

	# Labels
	#labels = []
	#for i in range(nb_instances):
	#	labels.append(str(instances[i]))
	
	labels = []
	for i in range(nb_instances):
		nom_ins = str(instances[i])
		labels.append(nom_ins)
	print("labels = ", labels)
	
	# Labels
	# On labellise les instances en diagonale
	plt.xticks(x, labels, rotation=45)
	# Margin par rapport aux axes
	plt.margins(0.2)
	# Espacement
	plt.subplots_adjust(bottom=0.15)
	plt.xlabel('Instances Cardinal')
	plt.ylabel('T exec (s)')
	plt.title('Influence des bs sur le modèle SAT (total)')
	
	# Sauvegarde de la figure dans res/graph/
	plt.savefig("res/graph/SAT_total_"+nom_instance+"_"+str(ID_EXP)+".svg")
	
	plt.show()
	
	#----------------------------------------
	#- Plots de l'experimentation (t solve) -
	#----------------------------------------
	plt.clf()
	
	# On récupère les temps d'execution par instance pour chacun des modeles
	t_solve_par_instance_par_modele = []
	for i in range(nb_modeles):
		t_solve_par_modele = []
		for j in range(nb_instances):
			t_solve_par_modele.append(t_solve_par_modele_par_instance[j][i])
		t_solve_par_instance_par_modele.append(t_solve_par_modele)
	
	# On plot les temps pour chaque modele
	x = range(nb_instances)
	for i in range(nb_modeles):
		y = t_solve_par_instance_par_modele[i]
		bss = bss_modele[i][2:]
		bss = bss[:len(bss)-4]
		print("bss = ", bss)
		plt.plot(x, y, label=bss)
	plt.legend()

	labels = []

	for i in range(nb_instances):
		nom_ins = str(instances[i])
		labels.append(nom_ins)
	print("labels = ", labels)
	
	# Labels
	# On labellise les instances en diagonale
	plt.xticks(x, labels, rotation=45)
	# Margin par rapport aux axes
	plt.margins(0.2)
	# Espacement
	plt.subplots_adjust(bottom=0.15)
	plt.xlabel('Instances Cardinal')
	plt.ylabel('T exec (s)')
	plt.title('Influence des bs sur le modèle SAT (solve)')
	
	# Sauvegarde de la figure dans res/graph/
	plt.savefig("res/graph/SAT_solve_"+nom_instance+"_"+ID_EXP+".svg")
	
	plt.show()

#---------------
#- Paramétrage -
#---------------
VERBOSE = False
BUDGET = datetime.timedelta(seconds=200)
T_START = 0
T_TIC = 0
ID_EXP = ""

print("Chargement des arguments (ARGS)...")
Experiment(sys.argv)
