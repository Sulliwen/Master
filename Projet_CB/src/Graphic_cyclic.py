import json
import sys
import time
import matplotlib.pyplot as plt
import matplotlib.pyplot as plt
import networkx as nx

from pycsp3 import *

# Exemple commande pour afficher le graph cyclic correspondant à une CB de 4 pour l'instance bcspwr01:
#       python3 Graphic_cyclic.py bcspwr01.json 4
def Graph_cyclic(A, x, k, nom_instance):
    #---------------------- afficher le graphique de la cyclic bandwidth ----------------------#
    # on créé d'abord la liste des index car on veut ajouter les sommets dans l'ordre de leur étiquetage
    li=[] # liste des index
    for i in range(len(x)):
        li.append([value(x[i]),i])
    li.sort()
    sort_index = []

    for l in li:
        sort_index.append(l[1])

    # print(sort_index)

    G = nx.Graph()
    # ajout des noeuds avec un attribut type qui correspond à l'etiquetage
    for i in range(n):
        G.add_node(sort_index[i]+1,type="\'"+str(i+1)+"\'")

    G.add_edges_from(A) # ajout des aretes

    pos_nodes = nx.circular_layout(G) # permet d'avoir une disposition en cercle
    nx.draw_networkx(G, pos_nodes)
    attrs = nx.get_node_attributes(G, 'type')
    for p in pos_nodes:  # permet de decaler un peu l'etiquetage
        pos_nodes[p][1] += 0.1
    nx.draw_networkx_labels(G, pos_nodes, labels=attrs)

    ax = plt.gca()
    ax.margins(0.20)
    plt.axis("off")
    #plt.show() # commenter la ligne ou non pour afficher le graphique lors de l'execution (met le programme en pause)
    plt.savefig("../res/graphs/graphs_cyclic/"+nom_instance+"_"+str(k)+".png")

# Retourne True si sat, False si non sat et None si hors budget
def M2_g(n, m, A, k):
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
    
    print("solve M2 en cours...")
    solve(solver=ACE,verbose=-1)
    
    return x

args = sys.argv

nom_instance = "bcspwr01.json"

# Nom du dossier où se trouve les instances à exécuter
if len(args) >= 2:
    nom_instance = str(sys.argv[1])

if len(args) >= 3:
    k = int(sys.argv[2])

path = "../instances/graphics"

print("nom_instance = ", nom_instance)
fichier_json = open(path + "/" + nom_instance)
variables = json.load(fichier_json)

n = variables["n"]
m = variables["m"]
A = variables["A"]

x = M2_g(n, m, A, k)
Graph_cyclic(A, x, k, nom_instance)