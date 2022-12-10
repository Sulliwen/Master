from imports import *

# Lance les modeles passé en entrée sur les instances en entrée pour k = floor((borne inf + borne sup)/2)
# Commande pour lancer sur les instances Adrien Nicolas Nicolas (ann) avec verbose ON sur les modèles [M1,M1_bis,M2,M3,M3_bis] avec un budget de 200:
#           python3 Run_M_ann.py ann
# sur les modèles M3 et M3_bis avec verbose:
#           python3 Run_M_ann.py ann v [M3,M3_bis] 200
# sur les modèles M3 et M3_bis sans verbose:
#           python3 Run_M_ann.py ann n [M3,M3_bis] 200
def Run_M_ann(modeles, path, dossier, instances, budget, verbose):
    print("Resolution sur les (instance_i, k_i) d'Adrien Nicolas Nicolas")
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

    modeles_comp = modeles[0].__name__
    for i in range(1,len(modeles)):
        modeles_comp += "_"+modeles[i].__name__

    for instance in instances_ord_som:

        n = instance[0]
        m = instance[1]
        A = instance[2]
        nom_instance = instance[3]

        borne_inf_th = calcul_borne_inf_th(A, n)
        borne_sup_th = calcul_borne_sup_th(n)
        k_ann = math.floor((borne_inf_th + borne_sup_th)/2)

        times = {}
        lengths = {}
        pySAT_times = {}
        clauses_times = {}

        nb_lengths = 5
        nb_type_clauses = 5

        nom_inst = copy.deepcopy(nom_instance)
        nom_instance = nom_instance.replace("_", "\_")

        for modele in modeles:
            print("\n------------------------------------------")
            print("--- INSTANCE : " + nom_inst + " (" + str(n) + " x " + str(m) + ") ---")
            print("--- Modele : " + modele.__name__)
            print("--- Bornes : [" + str(borne_inf_th) + " ; " + str(borne_sup_th) + "]")
            print("--- k : " + str(k_ann))
            print("--- Budget : " + str(budget))

            if modele.__name__ == "M1" or modele.__name__ == "M1_bis" or modele.__name__ == "M2":
                start_time = time.time()
                best_borne_inf, l_c, t_e, t_c = modele(n, m, A, k_ann, budget, verbose)
                t_elapsed = time.time() - start_time
                t_elapsed = round(t_elapsed, 4)

                times[modele.__name__] = t_elapsed
            else:
                start_time = time.time()
                prct_T = 0
                res, lengths[modele.__name__], pySAT_times[modele.__name__], clauses_times[modele.__name__] = modele(n, m, A, k_ann, budget, verbose)

                t_elapsed = time.time() - start_time
                t_elapsed = round(t_elapsed, 4)

                times[modele.__name__] = t_elapsed
                if modele.__name__ == "M3" or modele.__name__ == "M3_bis":
                    f = open("../res/csv/nb_clauses_"+dossier+"_"+modeles_comp+".txt", "a")

                    if len(lengths[modele.__name__]) == nb_lengths:

                        total_c = lengths[modele.__name__][nb_lengths-1]
                        if total_c != 0:
                            prct_T = (lengths[modele.__name__][0]*100)/total_c
                            prct_T = round(prct_T, 1)

                        str_lengths = str(prct_T) + "\%"
                        for i in range(1,nb_lengths-1):
                            if total_c != 0:
                                prct_T = (lengths[modele.__name__][i]*100)/total_c
                                prct_T = round(prct_T, 1)
                            str_lengths += " & " + str(prct_T) + "\%"
                        
                        str_lengths += " & " + str(total_c)

                    else:
                        str_lengths = "None"
                        for i in range(1,nb_lengths-1):
                            str_lengths += " & None"
                    
                    str_pySAT_times = str(pySAT_times[modele.__name__])
                
                    f.write(nom_instance + " & " + str_lengths + " & " + str_pySAT_times + " \\\\ \hline\n")
                    f.close()

                if modele.__name__ == "M3" or modele.__name__ == "M3_bis":
                    f = open("../res/csv/t_clauses_"+dossier+"_"+modeles_comp+".txt", "a")

                    if len(clauses_times[modele.__name__]) == nb_type_clauses:

                        total_t = clauses_times[modele.__name__][nb_type_clauses-1]
                        if total_t != 0:
                            prct_T = (clauses_times[modele.__name__][0]*100)/total_t
                            prct_T = round(prct_T, 1)

                        str_clauses_times = str(prct_T) + "\%"
                        for i in range(1,nb_type_clauses-1):
                            if total_t != 0:
                                prct_T = (clauses_times[modele.__name__][i]*100)/total_t
                                prct_T = round(prct_T, 1)
                            str_clauses_times += " & " + str(prct_T) + "\%"
                        
                        str_clauses_times += " & " + str(total_t)

                    else:
                        str_clauses_times = "None"
                        for i in range(1,nb_type_clauses-1):
                            str_clauses_times += " & None"

                    str_mod_t = str(times[modele.__name__])
                
                    f.write(nom_instance + " & " + str_clauses_times + " \\\\ \hline\n")
                    f.close()

        fichier_json.close()

        f = open("../res/csv/res_"+dossier+"_"+modeles_comp+".txt", "a")
        str_mod_t = str(times[modeles[0].__name__])
        for i in range(1,len(modeles)):
            str_mod_t += " & " + str(times[modeles[i].__name__])
        
        f.write(nom_instance + " & " + str(n) + " & " + str(m) + " & " + str(k_ann) + " & " + str_mod_t + " \\\\ \hline\n")
        f.close()

modeles = [M1, M1_bis, M2, M3, M3_bis]
dossier = "ann"
verbose = "v"
budget = 200

# Recuperation des arguments
args = sys.argv

if len(args) >= 2:
    dossier = str(args[1])

if len(args) >= 3:
    verbose = str(sys.argv[2])

if len(args) >= 4:
    modeles_str = args[3]
    # Recuperation des modeles a comparer
    modeles_str = modeles_str.replace('[', '')
    modeles_str = modeles_str.replace(']', '')
    modeles_str = modeles_str.split(",")
    modeles = []

    for m in modeles_str:
        #print("m = " + m)
        if m == "M1":
            modeles.append(0)
        elif m == "M1_bis":
            modeles.append(1)
        elif m == "M3_bis":
            modeles.append(4)
        else:
            modeles.append(int(m.replace('M', '')))
    
    print("modeles = ", modeles)
    ms = [M1, M1_bis, M2, M3, M3_bis]
    modeles = [ms[i] for i in modeles]

if len(args) >= 5:
    budget = int(args[4])

path = "../instances/"+dossier

instances = [f for f in listdir(path) if isfile(join(path, f))]

Run_M_ann(modeles, path, dossier, instances, budget, verbose)