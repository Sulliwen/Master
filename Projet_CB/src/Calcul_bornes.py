import math

def calcul_borne_inf_th(A, n):
    # Pour l'instant borne inf = ceil(deg_max/2) (Yixun Lin 1995..)
    deg_max = 0
    for i in range(1,n+1):
        cpt = 0
        for edge in A:
            if edge[0] == i or edge[1] == i:
                cpt += 1
        if cpt > deg_max:
            deg_max = cpt
    return math.ceil(deg_max/2)

def calcul_borne_sup_th(n):
    # Pour l'instant borne sup = floor(n/2)
    return math.floor(n/2)