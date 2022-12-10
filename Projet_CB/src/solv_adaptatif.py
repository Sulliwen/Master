from imports import *

# ----------------------------
#  Recuperation des arguments
# ----------------------------
modeles = [M1_bis, M2, M3]
nom_instance_groupe = "ann"
budget = 200
verbose = True

args = sys.argv

# Nom du dossier où se trouve les instances à exécuter
if len(args) >= 2:
    nom_instance_groupe = str(sys.argv[1])

# Verbose
if len(args) >= 3:
    verbose = str(sys.argv[2])

# Budget
if len(args) >= 4:
    budget = int(sys.argv[3])


# Récupération des instances
path = "../instances/" + nom_instance_groupe
instances = [f for f in listdir(path) if isfile(join(path, f))]

# Commande: python3 solv_adaptatif.py ann v 200
def solv_adaptatif(path, instances, budget, verbose):
    num_instance = 0
    for nom_instance in instances:
        fichier_json = open(path + "/" + nom_instance)
        variables = json.load(fichier_json)

        # n : nb de sommets
        # m : nb d'aretes
        # A : matrice des arêtes
        # k : CB recherché

        n = variables["n"]
        m = variables["m"]
        A = variables["A"]

        BUDGET_MAX = budget
        num_instance += 1
        print("\n------------------------------------------")
        print("--- INSTANCE : " + nom_instance + " (" + str(n) + " x " + str(m) + ") ---")
        # Un graphe de moins de 50 aretes se résout plus rapidement sur M3 et M3_bis (empirique)
        if m <= 50:
            modele = M3_bis
        else:
            modele = M2
        print("--- Modele : " + modele.__name__)

        dichoSAT(modele, n, m, A, BUDGET_MAX, num_instance, nom_instance, verbose)

        # On sauvegarde la figure du compte rendu de l'execution de l'instance
        plt.figure(num_instance) # on selectionne la figure i
        plt.savefig("../res/graphs/solved/"+nom_instance+".png")

solv_adaptatif(path, instances, budget, verbose)