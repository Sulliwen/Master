from imports import *
from Calcul_bornes import *

def dichoSAT(sat, n, m, A, BUDGET_MAX, num_instance, nom_instance, verbose):
    # Calcul d'une borne inf (propriété de base: ceil(deg_max/2))
    borne_inf = calcul_borne_inf_th(A, n)
    # Calcul d'une borne sup (propriété de base: floor(n/2))
    borne_sup = calcul_borne_sup_th(n)
    print("Borne inf initiale: ", borne_inf)
    print("Borne sup initiale: ", borne_sup)
    k_traites = []
    
    budget = BUDGET_MAX

    # Approche dichotomique (on prend k au milieu des bornes trouves, récursivement)
    k = math.ceil((borne_inf + borne_sup) / 2) # on prend la partie entiere superieure car le temps de calcul est beaucoup plus long quand la réponse est non.. (on a plus de chance d'avoir une réponse positive avec un plus grand k)
    print("Existe-t-il un CB <=", k, "?")

    start_dec_time = time.time()
    decision, taille_clauses, temps_exec, temps_clauses = sat(n, m, A, k, budget, verbose)
    prec_dec_time = time.time() - start_dec_time
    prec_dec_time = round(prec_dec_time,4)

    temps_k = []
    temps_k.append(prec_dec_time)
    k_traites.append(k)

    if (decision == "SAT"):
        borne_sup = k
    else:
        borne_inf = k
    
    print("borne inf: ", borne_inf)
    print("borne sup: ", borne_sup)
    dernier_k = k
    dernier_t = prec_dec_time
    unknowns = []
    unsats = []

    continuer = borne_sup != borne_inf
    while continuer:
        # si les bornes sont adjacentes (on a forcément l'une des deux déjà traité grace au premier traitement avant le while)
        if (borne_sup == borne_inf + 1):
            # et qu'elles ont toutes les deux déjà été vérifié, on break
            if (borne_sup in k_traites) and (borne_inf in k_traites):
                break
            # sinon on traite celle qui n'a pas été vérifiée
            if (k == borne_sup) and (borne_sup in k_traites) and (borne_inf not in k_traites):
                k = borne_inf
            else:
                if (k == borne_inf) and (borne_inf in k_traites) and (borne_sup not in k_traites):
                    k = borne_sup
            continuer = False
        else:
            k = math.ceil((borne_inf + borne_sup) / 2) # on prend la partie entiere superieure car le temps de calcul est beaucoup plus long quand la réponse est non.. (on a plus de chance d'avoir une réponse positive avec un plus grand k)
        print("\nMeilleure borne inf jusque là: ", borne_inf)
        print("Meilleure borne sup jusque là: ", borne_sup)
        print("Existe-t-il un CB <=", k, "?")

        # Si le temps de calcul d'un nouveau k dépasse de beaucoup le temps de calcul de k+1 satisfiable, alors on peut raisonnablement penser que ce nouveau k n'est pas satisfiable

        start_dec_time = time.time()

        decision, taille_clauses, temps_exec, temps_clauses  = sat(n, m, A, k, budget, verbose)
        
        prec_dec_time = time.time() - start_dec_time
        prec_dec_time = round(prec_dec_time,4)

        temps_k.append(prec_dec_time)
        k_traites.append(k)
        
        if (decision == "SAT"):
            borne_sup = k
        else:
            borne_inf = k
            if decision == "UNKNOWN":
                unknowns.append([str(k),prec_dec_time])
            elif decision == "UNSAT":
                unsats.append([str(k),prec_dec_time])

        dernier_k = k
        dernier_t = prec_dec_time

    if (decision == "SAT"):
        k_best = k
    else:
        k_best = borne_sup

    # Creation ou selection du graphe numéro num_ins
    k_traites_str = [str(x) for x in k_traites]
    colors = {}
    #colors["M2"] = 'b' ; colors["M3"] = 'r' ; colors["M1"] = 'g' ; colors["M1_bis"] = 'y'
    plt.figure(num_instance)
    plt.xlabel('valeur de k') ; plt.ylabel('T exec')
    plt.title('Evolution des temps d\'exec selon la valeur de k ('+nom_instance+')')
    plt.plot(k_traites_str, temps_k, label=sat.__name__)
    plt.legend(loc='upper left')
    # On indique les k unknowns (en noir)
    for u in unknowns:
        plt.plot(u[0], u[1], 'k*')
    # et le k unsats (en cyan)
    for f in unsats:
        plt.plot(f[0], f[1], 'r*')
    # on incruste la valeur CB_best
    nom_m = sat.__name__
    if "_bis" in nom_m:
        nom_m = nom_m.replace("_bis", "b")
    plt.text(str(dernier_k), dernier_t, nom_m + " : "+str(k_best), ha='left')
    return k_best