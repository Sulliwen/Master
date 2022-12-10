from imports import *
from Calcul_bornes import *

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

# Recuperation des modeles a comparer
if len(args) >= 4:
    modeles_str = str(sys.argv[3])

    modeles_str = modeles_str.replace('[', '')
    modeles_str = modeles_str.replace(']', '')
    modeles_str = modeles_str.split(",")
    modeles = []

    for m in modeles_str:
        if m == "M1":
            modeles.append(0)
        elif m == "M1_bis":
            modeles.append(1)
        elif m == "M3_bis":
            modeles.append(4)
        else:
            modeles.append(int(m.replace('M', '')))

    ms = [M1, M1_bis, M2, M3, M3_bis]

    modeles = [ms[i] for i in modeles]

# Budget
if len(args) >= 5:
    budget = int(sys.argv[4])


# Récupération des instances
path = "../instances/" + nom_instance_groupe
instances = [f for f in listdir(path) if isfile(join(path, f))]

# Copie de fonction
def copy_func(f):
    """Based on http://stackoverflow.com/a/6528148/190597 (Glenn Maynard)"""
    g = types.FunctionType(f.__code__, f.__globals__, name=f.__name__,
                        argdefs=f.__defaults__,
                        closure=f.__closure__)
    g = functools.update_wrapper(g, f)
    g.__kwdefaults__ = f.__kwdefaults__
    return g

# Commande: python3 compare.py [MODELES_A_COMPARER] NOM_DOSSIER_INSTANCES BUDGET VERBOSE
# Exemple 1: pour comparer M1_bis, M2 et M3,
#   sur les instances du dossier 'ann'
#   avec un budget de 60 secondes
#   avec l'option verbose pour l'affichage,
#   écrire (attention, pas d'espace dans la liste des modèles): 
#           $python3 compare.py ann v [M1_bis,M2,M3] 200
# Exemple 2: pour comparer M3 et M3_bis avec verbose (affichage des temps d'execution, nombre de clauses...):
#           $python3 compare.py ann v [M3,M3_bis] 200
# Exemple 3: verbose special: affichage des core unsat pour M3: (lancer compare_s.py)
#           $python3 compare.py ann s [M3] 200
# Exemple 4: sans verbose
#           $python3 compare.py ann n [M3,M3_bis] 200
def compare(modeles, path, instances, budget, verbose):

    nbInstance = len(instances)

    instances_ord_som = []
    for instance in instances:
        fichier_json = open(path + "/" + instance)
        variables = json.load(fichier_json)

        nom_instance = instance.replace(".json", '')

        n = variables["n"]
        m = variables["m"]
        A = variables["A"]

        instances_ord_som.append([n, m, A, nom_instance])

    instances_ord_som = sorted(instances_ord_som, key=itemgetter(0))

    print("Comparaison des modeles " + str([str(modeles[i].__name__) for i in range(len(modeles))]))
    nbInstance = len(instances)
    time_solves = {}

    modeles_comp = modeles[0].__name__
    for i in range(1,len(modeles)):
        modeles_comp += "_"+modeles[i].__name__

    perfs = {}
    for modele in modeles:
        time_solves[modele.__name__] = []
        perfs[modele.__name__] = []
        i = 0
        for instance in instances_ord_som:
            
            n = instance[0]
            m = instance[1]
            A = instance[2]
            nom_instance = instance[3]

            nom_inst = nom_instance.replace("_", "\_")
        
            k = 0 #inu

            i += 1
            print("\n------------------------------------------")
            print("--- INSTANCE : " + nom_instance + " (" + str(n) + " x " + str(m) + ") ---")
            print("--- Modele : " + modele.__name__)

            if (modele == M1 or modele == M1_bis):
                if modele == M1:
                    print("--- Résolution par optimisation: symetries non brisées (ACE)")
                elif (modele == M1_bis):
                    print("--- Résolution par optimisation: symetries brisées (ACE)")
                print("------------------------------------------\n")
                start_time = time.time()
                CB_opt = modele(n, m, A, k, budget, verbose)
                end_time = time.time() - start_time
                end_time = round(end_time,4)

                if CB_opt != -1:
                    print("\nCB optimale: ", CB_opt, "(--- temps d'exec: ", end_time," secondes ---)\n")
                else:
                    print("\nCB optimale non trouvée (--- temps d'exec: ", end_time," secondes ---)\n")


            else:

                if modele == M2:
                    solveur_str = "ACE"
                elif modele == M3 or modele == M3_bis:
                    solveur_str = "pySAT"

                print("--- Décisions successives ("+ solveur_str + ")")
                print("--- Méthode dichotomique: Calcul de la CB optimale en posant les meilleures questions (CB <= k?) à " + modele.__name__ + " ---")
                print("------------------------------------------\n")
                
                s_t = time.time()
                CB_best = dichoSAT(modele, n, m, A, budget, i, nom_instance, verbose)
                end_time = time.time() - s_t
                end_time = round(end_time, 4)
                
                print("\nMeilleure borne inf trouvée: ",CB_best, "(--- trouvée en ",end_time," secondes ---)\n")

            # Enregistrement des performance du modele sur l'instance
            if (modele == M1 or modele == M1_bis):
                CB = CB_opt
            else:
                CB = CB_best
            perfs[modele.__name__].append([str(nom_inst), str(CB),str(end_time)])


            # On ajoute le temps pour l'instance i pour le modele m
            time_solves[modele.__name__].append(end_time)

            fichier_json.close()

            # On sauvegarde la figure du compte rendu de l'execution de l'instance
            plt.figure(i) # on selectionne la figure i
                
            plt.savefig("../res/graphs/compare/"+nom_instance+"_"+modeles_comp+".png")

    # On exporte le nom de l'instance, le Modele utilisé, la meilleure borne trouvé, et le temps d'execution au format latex dans un fichier texte
    f = open("../res/csv/comp_"+modeles_comp+"_cr.txt", "a")
    for i in range(nbInstance):
        ligne_str = str(instances_ord_som[i][3])
        for modele in modeles:
            CB = perfs[modele.__name__][i][1]
            if CB == -1 or CB == "-1":
                CB = "inconnue"
            end_time = perfs[modele.__name__][i][2]
            end_time = str(round(float(end_time),1))
            ligne_str += " & " + CB + " & " + end_time
        #print("ligne_str = ", ligne_str)
        f.write(ligne_str + " \\\\ \hline\n")
    f.close()

    # Plot des temps d'execution par modele et par instance

    # Creation d'une nouvelle figure avec un nouvel ID (dernier ID: nbInstance)
    plt.figure(nbInstance+1) # prochain numéro de figure libre (il y a nbInstance figure déjà créées)
    plt.xlabel('Instances') ; plt.ylabel('T exec')
    plt.title('Evolution des temps d\'excec par instance')
    for m in modeles:
        plt.plot(instances, time_solves[m.__name__], label=m.__name__)
        plt.legend(loc='upper left')

    # Enregistrement des figures

    plt.savefig("../res/graphs/compare/"+modeles_comp+".png")

compare(modeles, path, instances, budget, verbose)
