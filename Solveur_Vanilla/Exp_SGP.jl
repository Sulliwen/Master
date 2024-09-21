include("src/Solveur_SET_Vanilla.jl")
include("Modeles/Modele_SGP_SET.jl")

println("Chargement du module Plots...")
using Plots

function is_digit(str)
    return tryparse(Float64, str) !== nothing
end

using Random


#----------------------------------
#- Initialisation de l'experiment -
#----------------------------------
# Récupère les instances et les modules de l'experience
function Init_Experiment(args)
	nb_args = length(args)
	
	# ID de l'exp:
	global ID_EXP = randstring(12)
	
	# On récupère le param global verbose
    	global VERBOSE = args[nb_args] == "-v"
	
	# Définition des packs d'instances
	instances_cardinal = [[2,5,4],[2,6,4],[2,7,4],[2,8,5],[3,5,4],[3,6,4],[3,7,4],[4,5,4],[4,6,5],[4,7,4],[4,9,4],[5,4,3],[5,5,4],[5,7,4],[5,8,3],[6,4,3],[6,5,3],[6,6,3],[7,5,3],[7,5,5]]
	#instances_cardinal = [[5,4,3],[5,5,4],[5,7,4],[5,8,3],[6,4,3],[6,5,3],[6,6,3],[7,5,3],[7,5,5]]
    #instances_cardinal = [[2,5,4],[2,6,4],[2,7,4]]
    instances_balayage = [[]]
    instances_challenge = [[5,4,3]]
    for s in range(1,8)
        for k in range(2,8)
            for p in range(2,8)
                push!(instances_balayage, [s,k,p])
            end
        end
    end
    instances_balayage = instances_balayage[2:end]
    
    packs_instances = [instances_cardinal, instances_balayage, instances_challenge]
    nom_packs_ins = ["Cardinal", "Balayage", "Challenge"]
	
	# Définition des packs de modules
	modules_all = ["a1", "a2", "a12", "a12_o1", "a12_o2", "a12_o12", "o1", "o2", "o12", "sbs"]
	modules_bs_a = ["a1", "a2", "a12"]
	modules_bs_o = ["o1", "o2", "o12"]
	
	packs_modules = [modules_all, modules_bs_a, modules_bs_o]
	
	instances_select = []
	modeles_select = []
	
	# Instance perso (modèle sbs par defaut)
	if nb_args == 3 && all([is_digit(a) for a in args])
		println("Instance perso (modèle sbs par defaut)")
		s = parse(Int, args[1])
        k = parse(Int, args[2])
        p = parse(Int, args[3])
		instances_select = [[s,k,p]]
		nom_instance = "Perso"
		
		modeles_select = ["sbs"]
	else
		# Instance perso et modèles perso
		if nb_args >= 5 && all([is_digit(a) for a in args[1:3]]) && args[4] == "-m"
			println("Instance perso et modèles perso")
			s = parse(Int, args[1])
		    k = parse(Int, args[2])
		    p = parse(Int, args[3])
			instances_select = [[s,k,p]]
			nom_instance = "Perso"
			
			# On retire -v de la liste des args pour n'avoir que les modèles
			deleteat!(args, findall(x->x=="-v",args))
			nb_args = length(args)
			
			modeles_select = args[5:nb_args]
		else
			# Instance perso et modèles pack
			if nb_args == 5 && all([is_digit(a) for a in args[1:3]]) && args[4] == "-b" && is_digit(args[5])
				println("Instance perso et modèles pack")
				s = parse(Int, args[1])
				k = parse(Int, args[2])
				p = parse(Int, args[3])
				instances_select = [[s,k,p]]
				nom_instance = "Perso"
				
				ind_pack_module = parse(Int,args[5]) + 1
				modeles_select = packs_modules[ind_pack_module]
			else
				# Instance pack (modèle sbs par defaut)
				if nb_args == 2 && args[1] == "-t"
					println("Instance pack (modèle sbs par defaut)")
					ind_pack_instance = parse(Int,args[2]) + 1
					instances_select = packs_instances[ind_pack_instance]
					nom_instance = nom_packs_ins[ind_pack_instance]
					
					modeles_select = ["sbs"]
				else
					# Instance pack et modèles perso
					if nb_args >= 4 && args[1] == "-t" && is_digit(args[2]) && args[3] == "-m"
						println("Instance pack et modèles perso")
						ind_pack_instance = parse(Int,args[2]) + 1
						instances_select = packs_instances[ind_pack_instance]
						nom_instance = nom_packs_ins[ind_pack_instance]
						
						# On retire -v de la liste des args pour n'avoir que les modèles
						deleteat!(args, findall(x->x=="-v",args))
						nb_args = length(args)
						
						modeles_select = args[4:nb_args]
					else
						# Instance pack et modèles pack
						if nb_args == 4 && args[1] == "-t" && is_digit(args[2]) && args[3] == "-b"
							println("Instance pack et modèles pack")
							ind_pack_instance = parse(Int,args[2]) + 1
							instances_select = packs_instances[ind_pack_instance]
							nom_instance = nom_packs_ins[ind_pack_instance]
							
							ind_pack_module = parse(Int,args[4]) + 1
							modeles_select = packs_modules[ind_pack_module]
						else
							println("Commande inconnue. Voir la liste des commandes dans le fichier Readme.txt.")
		            		exit()
		            	end
		            end
                end
            end
        end
    end
    
    return [instances_select, nom_instance, modeles_select]
end

function Experiment(args)
	
	# Récupération des instances et des modules
	instances, nom_instance, modeles_select  = Init_Experiment(args)
	
	println("instances = ", instances)
	println("nom_instance = ", nom_instance)
	println("modeles_select = ", modeles_select)
	
	open("res/Res.txt", "w") do io	
		chaine = "---------------\n"
		chaine *= "-- Resultats --\n"
		chaine *= "---------------\n\n"
		write(io, chaine)
		println(chaine)
	end
	
	open("res/Latex"*ID_EXP*".txt", "w") do io
		write(io, "-- Tableau des res format latex --\n\n")
	end
	

	chaine = "////////////////////////\n"
	chaine *= "// Instances " * nom_instance * " //\n"
	chaine *= "////////////////////////\n\n"
	
	open("res/Res.txt", "a") do io
		write(io, chaine)
		println(chaine)
	end
	
	println(" instances = ", instances)
	
	t_total_par_instance_par_modele = []
	t_solve_par_instance_par_modele = []
	
	# Pour chaque instance s,k,p de instances_select
	for ins in instances

		# On récupère l'instance
		s,k,p = ins
		
		chaine = "-------------------\n"
		chaine *= "| Instance: " * string(s) * " " * string(k) * " " * string(p) * " |\n"
		chaine *= "-------------------\n"
		
		open("res/Res.txt", "a") do io
       		write(io, chaine)
			println(chaine)
		end
	
		# Génération des résultats des temps sous forme de tableau au format latex
		str_latex = "\\begin{table}[H]\n"
		str_latex *= "\\centering\n"
		str_latex *= "\\begin{tabular}{|c|c|c|} \\hline\n"
		str_latex *= "\\textbf{Instance} & \\textbf{Modèle} & \\textbf{t total (s)} \\\\ \\hline\n"
		str_latex *= "\\multirow{" * string(length(modeles_select)) * "}{4em}{\\centering{" * string(s) * " " * string(k) * " " * string(p) * "}}"
		
		open("res/Latex_"*string(s)*string(k)*string(p)*".txt", "w") do io
       		write(io, str_latex)
		end
		
		t_total_par_modele = []
		t_solve_par_modele = []
		
		# Pour chaque modèle
		for nom_modele in modeles_select
			
			nom_modele_fic = "bs_" * nom_modele
			
			chaine =  "\t--------------------\n"
			chaine *= "\t| Modele " * nom_modele_fic * "\n"
			chaine *= "\t--------------------\n"
			
			open("res/Res.txt", "a") do io
	       		write(io, chaine)
			end
			
			println(chaine)
       		println("(instance "*string(s) * " " * string(k) * " " * string(p)*")")
			
			timeout = BUDGET
			
			# On créer le modèle pour Vanilla
			variante = [nom_modele]
			
			if nom_modele == "a12"
				variante = ["a1","a2"]
			end
			if nom_modele == "a12_o1"
				variante = ["a1","a2","o1"]
			end
			if nom_modele == "a12_o2"
				variante = ["a1","a2","o2"]
			end
			if nom_modele == "a12_o12"
				variante = ["a1","a2","o1","o2"]
			end
			if nom_modele == "o12"
				variante = ["o1","o2"]
			end
			
			t_modele = @elapsed modele = Modele_Vanilla(s, k, p, variante)
			timeout -= t_modele
			
			# Si le budget a été dépassé lors de la création du modèle, alors on l'indique dans le rapport et on passe à l'instance suivante
			if timeout <= 0
				println("Budget dépassé ("*string(round(timeout,3))*"s)")
				t_solve = -10
			# Sinon on continue l'analyse de l'instance (résolution)
			else
				println("\t Résolution en cours...")
				global T_START = time()
				t_solve = @elapsed sat = Solve(modele)
				timeout -= t_solve
				
				if timeout <= 0
					printstyled("\t Budget dépassé\n\n"; color = :magenta)
					t_total = t_modele + t_solve
				else
					if !sat
						printstyled("\t UNSAT\n\n"; color = :red)
						t_total = t_modele + t_solve
					else
						t_total = t_modele + t_solve
						printstyled("\t SAT"; color = :green)
						println(" (temps solve: ", round(t_solve; digits = 3), " sec)\n")
						println(" (temps total: ", round(t_total; digits = 3), " sec)\n")
						println("\t Solution trouvée:\n")
						afficher_sol(modele, s, k, p)
					end
				end
			end
			
			nom_m = replace(nom_modele_fic, "_" => "\\_")
			# Génération des résultats sous forme de tableau au format latex (res/Latex.txt)
			str_latex = " & " * nom_m * " & " * string(round(t_total; digits = 3)) * " \\\\ \n"
			
			open("res/Latex_"*string(s)*string(k)*string(p)*".txt", "a") do io
	       		write(io, str_latex)
			end
			
			# Sauvegarde des résultats pour plot
			t_solve = round(t_solve; digits = 3)
			t_total = round(t_total; digits = 3)
			push!(t_total_par_modele, t_total)
			push!(t_solve_par_modele, t_solve)
		end
		
		# Génération des résultats sous forme de tableau au format latex
		str_latex = "\\hline\n"
		str_latex *= "\\end{tabular}\n"
		str_latex *= "\\caption{Instance "*string(s)*" "*string(k)*" "*string(p)*": influence des bs sur les temps de résolution de Vanilla}\n"
		str_latex *= "\\end{table}\n\n"
		
		open("res/Latex_"*string(s)*string(k)*string(p)*".txt", "a") do io
       		write(io, str_latex)
		end
		
		# Sauvegarde des temps d'exec par instance pour plot
		str_plot = "Données plots (total)\n\n"
		
		push!(t_total_par_instance_par_modele, t_total_par_modele)
		str_plot *= replace(string(t_total_par_instance_par_modele) * " ", "Any" => "")
		
		str_exp = "exp_" * string(ID_EXP)
		
		open("res/Plots_total_"*str_exp*".txt", "w") do io
       		write(io, str_plot)
		end
		
		str_plot_solve = "Données plots (solve)\n\n"
		
		t_solve_par_instance_par_modele = push!(t_solve_par_instance_par_modele, t_solve_par_modele)
		str_plot_solve *= replace(string(t_solve_par_instance_par_modele) * " ", "Any" => "")
		
		open("res/Plots_solve_"*str_exp*".txt", "w") do io
       		write(io, str_plot_solve)
		end
	end
	
	nb_instances = length(instances)
	nb_modeles = length(modeles_select)

	# On récupère les temps d'execution par instance pour chacun des modeles
	t_total_par_modele_par_instance = []
	for i in 1:nb_modeles
		t_total_par_modele = []
		for j in 1:nb_instances
			push!(t_total_par_modele, t_total_par_instance_par_modele[j][i])
		end
		push!(t_total_par_modele_par_instance, t_total_par_modele)
	end			
	x = 1:nb_instances
	y = t_total_par_modele_par_instance
	
	bss = reshape(modeles_select, 1, length(modeles_select))
	# Les plots et savefig ci-dessous prennent 3 à 4 secondes..
	plot(x, y, label = bss)
	labels_ins = [replace(string(a), "Any" => "" ) for a in instances]
	plot!(xticks = ([1:nb_instances;], labels_ins), ylabel = "t exec", xlabel = "Instances " * nom_instance, xrotation = 45)
	savefig("res/graph/Vanilla_t_exec_"*ID_EXP*".svg")

end
	

#---------------
#- Paramétrage -
#---------------
VERBOSE = false
BUDGET = 200
T_START = 0
T_TIC = 0
ID_EXP = ""

println("Chargement des arguments (ARGS)...")
Experiment(ARGS)

#= SAT
[6, 6, 3]
=#

#= UNSAT
[5, 4, 3], [6, 4, 3], [6, 5, 3], [7, 5, 3], [7, 5, 5], [6, 4, 4]
=#

		#----------------------------------------
		#- Plots de l'experimentation (t total) -
		#----------------------------------------
		#=fig, ax = plt.subplots()

		# On doit dessiner le canvas, sinon les labels ne seront pas positionné et n'auront pas de valeur 
		fig.canvas.draw()

		nb_instances = len(instances)
		nb_modeles = len(SGP_modeles)
		
		# On récupère les temps d'execution par instance pour chacun des modeles
		t_exec_par_instance_par_modele = []
		for i in range(nb_modeles):
			t_total_par_modele = []
			for j in range(nb_instances):
				t_total_par_modele.append(t_total_par_instance_par_modele[j][i])
			t_exec_par_instance_par_modele.append(t_total_par_modele)
		
		# On plot les temps pour chaque modele
		x = range(nb_instances)
		for i in range(nb_modeles):
			y = t_exec_par_instance_par_modele[i]
			nom_modele = SGP_modeles[i][2:]
			nom_modele = nom_modele[:len(nom_modele)-4]
			plt.plot(x, y, label=nom_modele)
		plt.legend()

		# Labels
		labels = []
		for i in range(nb_instances):
			labels.append(string(instances[i]))

		println("labels = ", labels)
		for i in range(nb_instances):
			nom_instance = string(instances[i])
			labels[i] = nom_instance
		
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
		plt.savefig("res/graph/SAT_total_"+string(instances)+".png")
		
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
				t_solve_par_modele.append(t_solve_par_instance_par_modele[j][i])
			t_solve_par_instance_par_modele.append(t_solve_par_modele)
		
		# On plot les temps pour chaque modele
		x = range(nb_instances)
		for i in range(nb_modeles):
			y = t_solve_par_instance_par_modele[i]
			nom_modele = SGP_modeles[i][2:]
			nom_modele = nom_modele[:len(nom_modele)-4]
			plt.plot(x, y, label=nom_modele)
		plt.legend()

		# Labels
		labels = []
		for i in range(nb_instances):
			labels.append(string(instances[i]))

		println("labels = ", labels)
		for i in range(nb_instances):
			nom_instance = string(instances[i])
			labels[i] = nom_instance
			
		
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
		plt.savefig("res/graph/SAT_solve_"+string(instances)+".png")
		
		plt.show()=#
