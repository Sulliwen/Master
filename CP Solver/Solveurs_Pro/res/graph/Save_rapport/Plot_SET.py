import matplotlib.pyplot as plt

t_solve_par_modele_par_instance = [[0.181, 0.24, 0.239, 0.259, 0.255, 0.266, 0.257, 0.3, 0.265, 0.288], [0.554, 0.245, 0.245, 0.273, 0.266, 0.285, 0.272, 0.559, 0.28, 0.534], [0.358, 0.244, 0.281, 0.322, 0.299, 0.346, 0.294, 0.376, 0.301, 0.356], [200.188, 0.78, 50.057, 54.657, 33.241, 55.359, 0.333, 200.203, 1.095, 200.189], [0.4, 0.248, 0.247, 0.277, 0.268, 0.293, 0.278, 0.39, 0.314, 0.361], [0.94, 0.271, 0.325, 0.335, 0.336, 0.36, 0.303, 1.074, 0.333, 0.933], [0.648, 0.461, 0.561, 0.445, 0.732, 0.469, 0.355, 0.63, 0.362, 0.67], [0.854, 0.326, 0.268, 0.318, 0.289, 0.341, 0.317, 5.391, 0.414, 0.778], [200.201, 1.939, 2.283, 2.733, 0.689, 0.842, 0.834, 200.221, 27.607, 200.215], [3.538, 0.61, 1.398, 0.605, 0.559, 0.464, 0.386, 1.5, 0.452, 3.535], [1.256, 0.496, 0.488, 0.603, 0.691, 0.67, 0.486, 5.342, 0.524, 1.195], [200.192, 2.419, 200.194, 200.214, 18.709, 28.934, 200.214, 200.223, 200.224, 200.207], [200.218, 1.736, 3.081, 3.996, 0.434, 0.477, 0.478, 0.523, 29.025, 200.221], [93.953, 3.37, 5.066, 0.815, 2.096, 0.73, 0.537, 2.087, 0.622, 110.585], [12.499, 200.244, 0.437, 0.458, 77.484, 0.485, 0.459, 7.172, 0.551, 17.06], [200.219, 3.405, 1.643, 1.886, 0.301, 0.332, 200.218, 200.233, 200.248, 200.205], [200.216, 0.46, 200.223, 200.251, 16.08, 1.023, 31.533, 85.245, 17.298, 200.221], [200.233, 54.901, 1.791, 0.677, 23.771, 0.471, 0.467, 66.551, 1.938, 200.234], [200.25, 200.257, 200.24, 200.28, 200.264, 200.285, 200.271, 200.282, 53.81, 200.287], [0.266, 0.245, 0.261, 0.257, 0.26, 0.244, 0.252, 0.26, 0.253, 0.26]] 

instances = [[2,5,4],[2,6,4],[2,7,4],[2,8,5],[3,5,4],[3,6,4],[3,7,4],[4,5,4],[4,6,5],[4,7,4],[4,9,4],[5,4,3],[5,5,4],[5,7,4],[5,8,3],[6,4,3],[6,5,3],[6,6,3],[7,5,3],[7,5,5]]

nb_instances = len(t_solve_par_modele_par_instance)
nb_modeles = 10
	
plt.clf()
	
# On récupère les temps d'execution par instance pour chacun des modeles
t_total_par_instance_par_modele = []
for i in range(nb_modeles):
	t_solve_par_modele = []
	for j in range(nb_instances):
		t_solve_par_modele.append(t_solve_par_modele_par_instance[j][i])
	t_total_par_instance_par_modele.append(t_solve_par_modele)

# On plot les temps pour chaque modele
x = range(nb_instances)

bss_modele = ["a1", "a2", "a12", "a12_o1", "a12_o2", "a12_o12", "o1", "o2", "o12", "sbs"]

for i in range(nb_modeles):
	y = t_total_par_instance_par_modele[i]
	bss = bss_modele[i]
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
plt.title('Résolution du modèle SET (Gecode)')

# Sauvegarde de la figure dans res/graph/
plt.savefig("Plots_rapport_SET.svg")

plt.show()
