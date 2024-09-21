import matplotlib.pyplot as plt

instances = [[2,5,4],[2,6,4],[2,7,4],[2,8,5],[3,5,4],[3,6,4],[3,7,4],[4,5,4],[4,6,5],[4,7,4],[4,9,4],[5,4,3],[5,5,4],[5,7,4],[5,8,3],[6,4,3],[6,5,3],[6,6,3],[7,5,3],[7,5,5]]

t_SAT_total_bbs = [[0.772], [1.563], [3.16], [27.123], [2.408], [5.011], [11.301], [5.073], [200.006], [21.881], [56.57], [11.643], [11.003], [55.92], [7.838], [11.873], [1.824], [3.769], [52.208], [80.978]] 

t_SET_bbs = [[0.186], [0.29], [0.369], [59.258], [0.319], [0.361], [0.519], [0.334], [0.871], [0.467], [0.694], [31.935], [0.597], [0.771], [0.505], [0.332], [1.115], [0.53], [200.304], [0.466]] 

nb_instances = 20
	
plt.clf()

# On plot les temps pour chaque modele
x = range(nb_instances)

t_SAT_total_bbs = [a[0] for a in t_SAT_total_bbs]
t_SET_bbs = [a[0] for a in t_SET_bbs]

y = t_SET_bbs
plt.plot(x, y, label="SET a12_o12")

y = t_SAT_total_bbs
plt.plot(x, y, label="SAT a12_o0")
	
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
plt.title('Comparaison meilleure bs SAT vs SET')

# Sauvegarde de la figure dans res/graph/
plt.savefig("Plots_rapport_SAT_solve.svg")

plt.show()
