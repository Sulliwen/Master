from minizinc import Instance, Model, Solver

import time
import datetime
import random
import string

import sys

from os import listdir
from os.path import isfile, join

import matplotlib.pyplot as plt

def Afficher_res(A):
	i = 0
	chaine = "Solution:\n"
	for s in A:
		i += 1
		for g in s:
			chaine += "{"
			for j in g:
				chaine += str(j) + ", "
			chaine = chaine[:len(chaine)-2]
			chaine += "}, "
		chaine = chaine[:len(chaine)-2]
		chaine += "\n"
	print(chaine)

def randstring(length):
	characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPRSTUVWXYZ0123456789'

	random_string = ''
	for i in range(length):
		random_char = random.choice(characters)
		random_string += random_char
	return random_string

#----------------------------------
#- Initialisation de l'experiment -
#----------------------------------
# Récupère les instances et les modules de l'experience
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
	modules_all = ["a1", "a2", "a12", "a12_o1", "a12_o2", "a12_o12", "o1", "o2", "o12", "sbs"]
	modules_bs_a = ["a1", "a2", "a12"]
	modules_bs_o = ["o1", "o2", "o12"]

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

def Experiment(args) :

	# Récupération des instances et des modules
	instances, nom_instance, bss_modele  = Init_Experiment(args)

	###############
	# Paramétrage #
	###############
		
	# Sélection du solveur
	gecode = Solver.lookup("gecode")
	
	# Sélection du modèle
	SGP_modele = Model("./Modeles_MZN_SET/Modele_SGP_SET.mzn")
	
	f = open("res/SET/Res_"+ID_EXP+".txt", "w")
	chaine = "---------------\n"
	chaine += "-- Resultats --\n"
	chaine += "---------------\n\n"
	f.write(chaine)
	print(chaine)
	f.close()

	f = open("res/SET/Latex_"+ID_EXP+".txt", "w")
	f.write("Tableau des res format latex\n\n")
	f.close()
	
	chaine = "////////////////////////\n"
	chaine += "// Instances " + nom_instance + " //\n"
	chaine += "////////////////////////\n\n"
	
	f = open("res/SET/Res_"+ID_EXP+".txt", "a")
	f.write(chaine)
	print(chaine)
	f.close()
	
	t_exec_par_modele_par_instance = []
	
	# Pour chaque instance s,k,p
	for ins in instances:
	
		[s,k,p] = ins
		
		chaine = "Instance: " + str(s) + " " + str(k) + " " + str(p) + "\n"
		f = open("res/SET/Res_"+ID_EXP+".txt", "a")
		f.write(chaine)
		print("ins =",ins)
		print(chaine)
		f.close()
		
		# Génération des résultats sous forme de tableau au format latex
		str_latex = "\\begin{table}[H]\n"
		str_latex += "\centering\n"
		str_latex += "\\begin{tabular}{|c|c|c|c|} \hline\n"
		str_latex += "\\textbf{Instance} & \\textbf{Modèle} & \\textbf{temps exec} \\\\ \hline\n"
		str_latex += "\\multirow{" + str(len(bss_modele)) + "}{4em}{\centering{" + str(s) + " " + str(k) + " " + str(p) + "}}"
		
		f = open("res/SET/Latex_"+ID_EXP+".txt", "a")
		f.write(str_latex)
		f.close()
		
		t_exec_par_modele = []
		
		# Pour chaque modèle
		for bss in bss_modele:

			nom_modele_fic = "bs_" + bss
			
			chaine = "-----------------------------------\n"
			chaine += "Modele " + nom_modele_fic + "\n"
			chaine += "-----------------------------------\n\n"
			f = open("res/SET/Res_"+ID_EXP+".txt", "a")
			f.write(chaine)
			print("bss =",bss)
			print(chaine)
			print("\t(instance "+str(s) + " " + str(k) + " " + str(p)+")")
			f.close()
			
			# Création d'une instance du modele SGP pour Gecode
			instance = Instance(gecode, SGP_modele)
			
			var = [bss]
			
			if bss == "a12":
				var = ["a1","a2"]
			if bss == "a12_o1":
				var = ["a1","a2","o1"]
			if bss == "a12_o2":
				var = ["a1","a2","o2"]
			if bss == "a12_o12":
				var = ["a1","a2","o1","o2"]
			if bss == "o12":
				var = ["o1","o2"]
			
			# Definition des paramètre s,k,p
			instance["s"] = s
			instance["k"] = k
			instance["p"] = p
			
			# Definition des brises symmetries
			a1 = "a1" in var
			a2 = "a2" in var
			o1 = "o1" in var
			o2 = "o2" in var
			instance["a1"] = a1
			instance["a2"] = a2
			instance["o1"] = o1
			instance["o2"] = o2

			start = time.time()
			
			print("Résolution en cours...")
			result = instance.solve(timeout=BUDGET)
			
			end = time.time()
			t_exec = round(end - start, 3)
			
			if result:
				# Logs
				i = 1
				chaine = ""
				for sem in result["A"]:
					for g in sem:
						chaine += "{"
						for j in g:
							chaine += str(j) + ","
						chaine = chaine[:len(chaine)-1]
						chaine += "}, "
					chaine = chaine[:len(chaine)-2]
					chaine += "\n"
					i += 1
				chaine += "\ntemps exec:" + str(t_exec) + "\n\n"
				
				# Affichage dans la console
				print("\033[32mSAT\n \033[0m")
				print("temps exec:" + str(t_exec) + "\n")
				Afficher_res(result["A"])
				
			else:
				print("resultat = ", result)
				# Logs
				if t_exec >= BUDGET.seconds:
					chaine += "TIME OUT\n"
					print("\033[35mTIMEOUT\n \033[0m")
				else:
					chaine += "UNSAT\n"
					print("\033[31mUNSAT\n \033[0m")
					
				chaine += "\ntemps exec:" + str(t_exec) + "\n\n"
				
				# Affichage dans la console
				print("temps exec:" + str(t_exec) + "\n")
				
			
			f = open("res/SET/Res_"+ID_EXP+".txt", "a")
			f.write(chaine)
			f.close()
			
			# Génération des résultats sous forme de tableau au format latex
			str_latex = " & " + nom_modele_fic.replace("_", "\_") + " & " + str(t_exec) + " \\\\ \n"
			f = open("res/SET/Latex_"+ID_EXP+".txt", "a")
			f.write(str_latex)
			f.close()
			
			# Sauvegarde des résultats pour plot
			t_exec_par_modele.append(t_exec)
		
		# Génération des résultats sous forme de tableau au format latex
		str_latex = "\\hline\n"
		str_latex += "\\end{tabular}\n"
		str_latex += "\\caption{Influence des brise-symmétries sur les temps de résolution sous Gecode}\n"
		str_latex += "\\end{table}\n\n"
		
		f = open("res/SET/Latex_"+ID_EXP+".txt", "a")
		f.write(str_latex)
		f.close()
		
		# Sauvegarde des temps d'exec par instance pour plot
		str_plot = "Données plots\n\n"
		
		t_exec_par_modele_par_instance.append(t_exec_par_modele)
		str_plot += str(t_exec_par_modele_par_instance) + " "
		
		f = open("res/graph/Plots_SET_"+nom_instance+"_"+ID_EXP+".txt", "w")
		f.write(str_plot)
		f.close()
	
	#------------------------------
	#- Plots de l'experimentation -
	#------------------------------
	fig, ax = plt.subplots()

	# On doit dessiner le canvas, sinon les labels ne seront pas positionné et n'auront pas de valeur 
	fig.canvas.draw()

	nb_instances = len(instances)
	nb_bss_modele = len(bss_modele)

	# On récupère les temps d'execution par instance pour chacun des bss_modele
	t_exec_par_instance_par_modele = []
	for i in range(nb_bss_modele):
		t_exec_par_modele = []
		for j in range(nb_instances):
			t_exec_par_modele.append(t_exec_par_modele_par_instance[j][i])
		t_exec_par_instance_par_modele.append(t_exec_par_modele)
	
	# On plot les temps pour chaque modele
		
	x = range(nb_instances)
	for i in range(nb_bss_modele):
		y = t_exec_par_instance_par_modele[i]
		plt.plot(x, y, label='bs_'+bss_modele[i])
	plt.legend()

	# Labels
	labels = []
	for i in range(nb_instances):
		labels.append(str(instances[i]))
	print("labels = ", labels)
	for i in range(nb_instances):
		nom_ins = str(instances[i])
		labels[i] = nom_ins
	# Labels
	# On labellise les instances en diagonale
	plt.xticks(x, labels, rotation=45)
	# Margin par rapport aux axes
	plt.margins(0.2)
	# Espacement
	plt.subplots_adjust(bottom=0.15)
	plt.xlabel('Instances Cardinal')
	plt.ylabel('T exec (s)')
	plt.title('Influence des bs sur le modèle SET')
	
	# Sauvegarde de la figure dans res/graph/
	plt.savefig("res/graph/SET_"+nom_instance+"_"+ID_EXP+".svg")
	
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

'''
# Find and print all possible solutions
result = instance.solve(all_solutions=True)
for i in range(len(result)):
	print(result[i, "q"])


for i in range(4,6):
	# Create an Instance of the n-Queens model for Gecode
	instance = Instance(gecode, nqueens)

	# Assign i to n
	instance["n"] = i
	print("instance", i)

	#result = instance.solve()
	# Output the array q
	#print(result["q"])

	# Find and print all possible solutions
	result = instance.solve(all_solutions=True)
	for i in range(len(result)):
		print(result[i, "q"])'''
