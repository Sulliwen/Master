Données plots (solve)

t_solve_par_instance_par_modele = [[0.08478856086730957], [0.03326821327209473], [0.057212114334106445], [0.4200584888458252], [0.1742398738861084], [0.07562422752380371], [0.1026010513305664], [0.3442392349243164], [7.57983660697937], [0.4311952590942383], [9.994904518127441], [199.58173751831055], [12.152306318283081], [0.3457348346710205], [0.04735136032104492], [199.33582472801208], [2.2739171981811523], [0.17522454261779785], [66.39081478118896], [124.67402482032776]] 


import matplotlib.pyplot as plt

instances = [[2,5,4],[2,6,4],[2,7,4],[2,8,5],[3,5,4],[3,6,4],[3,7,4],[4,5,4],[4,6,5],[4,7,4],[4,9,4],[5,4,3],[5,5,4],[5,7,4],[5,8,3],[6,4,3],[6,5,3],[6,6,3],[7,5,3],[7,5,5]]
t_solve_par_modele_par_instance = [[0.832], [1.678], [2.815], [22.078], [2.289], [4.657], [8.598], [4.58], [45.977], [16.682], [55.383], [-10], [19.895], [31.585], [6.772], [-10], [4.008], [3.553], [68.67], [-10]] 

nb_instances = 20
nb_modeles = 1
	
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

bss_modele = ["sbs"]

for i in range(nb_modeles):
	y = t_solve_par_instance_par_modele[i]
	bss = bss_modele[i][2:]
	bss = bss[:len(bss)-4]
	print("bss = ", bss)
	plt.plot(x, y, label=bss)
	
plt.legend()

# Labels
labels = []

print("labels = ", labels)
for i in range(nb_instances):
	nom_ins = str(instances[i])
	labels.append(nom_ins)

# Labels
# On labellise les instances en diagonale
plt.xticks(x, labels, rotation=45)
# Margin par rapport aux axes
plt.margins(0.2)
# Espacement
plt.subplots_adjust(bottom=0.15)
plt.xlabel('Instances Cardinal')
plt.ylabel('T exec (s)')
plt.title('Résolution du modèle SAT (Glucose3)')

# Sauvegarde de la figure dans res/graph/
plt.savefig("Plots_rapport_SAT_solve.svg")

plt.show()
