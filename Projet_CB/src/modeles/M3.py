import math
import json
import time
import sys
import copy
from os import listdir
from os.path import isfile, join
from operator import itemgetter

from modeles.modules import *

def interrupt(s):
    s.interrupt()

#----------------
# PRE-TRAITEMENT
#----------------
def pre_treatment(n, A, k):
    # création du distancier booleen
    M_dist = [[False for i in range(n)] for j in range(n)]
    for i in range(1,n+1):
        for j in range(1,n+1):
            if (min(abs(i-j), n - abs(i-j))) <= k:
                M_dist[i-1][j-1] = True
    
    # creation de la matrice booleenne des arretes
    M_edges = [[False for i in range(n)] for j in range(n)]
    for a in A:
        s1 = a[0]-1
        s2 = a[1]-1
        M_edges[s1][s2] = True
        M_edges[s2][s1] = True

    return M_edges, M_dist

#------------------------------------------------------------------------------------
# FONCTION DE VERIFICATION DE PRESENCE D'ARETE ET DE DISTANCE VALIDE ENTRE 2 SOMMETS
#------------------------------------------------------------------------------------
# a(litteral l1, litteral l2, nb de sommets n, graphe G) : Booleen  Retourne Vrai si la pair de sommet correspondant aux litteraux l1 et l2 sont relié par une arete dans M_edges
def a(i, j, n, M_edges):
    indice_sommet_i = math.floor(i/n)
    # On gere le cas des bouts de ligne
    if i%n==0:
        indice_sommet_i -= 1
    indice_sommet_j = math.floor(j/n)
    if j%n==0:
        indice_sommet_j -= 1
    return M_edges[indice_sommet_i][indice_sommet_j]

# a(litteral l1, litteral l2, nb de sommets n, matrice de distance M) : Booleen  Retourne Vrai si la pair d'etiquettage correspondant aux litteraux l1 et l2 est inferieur à k
def d(i, j, n, M_dist):
    if i%n==0:
        indice_etiquette_i = n-1
    else:
        indice_etiquette_i = (i % n) - 1
    if j%n==0:
        indice_etiquette_j = n-1
    else:
        indice_etiquette_j = (j % n) - 1
    return M_dist[indice_etiquette_i][indice_etiquette_j]

# Retourne le sommet correspondant au literal donné
def literals_to_sommet(lit, n):
    s = math.floor(lit/n)
    if (lit%n == 0):
        s -= 1
    return s

# Retourne l'étiquette correspondant au literal donné
def literals_to_etiq(lit, n):
    if (lit%n == 0):
        e = n
    else:
        e = lit%n
    return e

#-------------------------------------------------------------------------------------
# Modele M3: Retourne vraie s'il existe un étiquettage du graphe G de taille k donnée
#-------------------------------------------------------------------------------------
""" Exemple d'étiquettage possible pour l'instance étoile.json
    etiq[i][j] = true <=> le sommet i est etiquette par la valeur j
    Exemple: ('+' : True '-' : False)
        +1  -2  -3  -4  -5
        -6  -7  -8  +9 -10
        -11 +12 -13 -14 -15
        -16 -17 -18 -19 +20
        -21 -22 +23 -24 -25

    Affectation bijective: 1 sommet <=> 1 etiquette 
    -> si chaque sommet est de degré 2 : Methode hongroise? (LAP) """

# Ecriture des différentes clauses dans des csv pour les analyser, vérifier...
def trace_clauses(n,m,clause_AL,clauses_AM, clauses_dist, clauses_sym2):
    f = open("../res/clause_AL_"+str(n)+"_"+str(m)+"_M3.csv", "a")
    for c in clause_AL:
        f.write(str(c))
    f.close()
    f = open("../res/clauses_AM_"+str(n)+"_"+str(m)+"_M3.csv", "a")
    for j in range(len(clauses_AM)):
        f.write(str(clauses_AM[j]))
        f.write(";")
        if (j+1) % 10 == 0:
            f.write("\n")
    f.close()
    f = open("../res/clauses_dist_"+str(n)+"_"+str(m)+"_M3.csv", "a")
    for j in range(len(clauses_dist)):
        f.write(str(clauses_dist[j]))
        f.write(";")
        if (j+1) % 10 == 0:
            #print("saut de ligne i = ", i)
            f.write("\n")
    f.close()
    f = open("../res/clauses_sym2_"+str(n)+"_"+str(m)+"_M3.csv", "a")
    for j in range(len(clauses_sym2)):
        f.write(str(clauses_sym2[j]))
        f.write(";")
        if (j+1) % 10 == 0:
            f.write("\n")
    f.close()

# Retourne "SAT", "UNSAT" ou UNKNOWN si hors budget, les nombres de clauses AL, AM, dist et sym2 et leur temps de construction
def M3(n, m, A, k, budget, verbose):
    
    start_time = time.time()

    if verbose == "v":
        print("1) Pre-calcul des pairs d'etiquettages possibles...")
    s_t = time.time()
    M_edges, M_dist = pre_treatment(n, A, k)
    e_t = time.time() - s_t
    e_t = round(e_t, 4)
    if verbose == "v":
        print("temps :", e_t)
    
    if verbose == "v":
        print("2) Preparation du model...")

    # Creation du modele 
    m3 = Glucose3() #Clause 'glué' (Glucose)

    # At least: Chaque sommet est etiquetté par au moins un j <=> au moins un true par ligne i de la matrice etiq (<=> pas de sommet "vide")
    """ At least pour les graphes à n=5 sommets
               1 v  2 v  3 v  4 v  5
            ^  6 v  7 v  8 v  9 v 10
            ^ 11 v 12 v 13 v 14 v 15
            ^ 16 v 17 v 18 v 19 v 20
            ^ 21 v 22 v 23 v 24 v 25
    """
    if verbose == "v":
        print("- Ajout des clauses AtLeast...")
    s_t = time.time()
    nb_clause_AL = 0
    
    for i in range(n):
            m3.add_clause([i*n+j for j in range(1,n+1)]) # les conjonctions doivent correspondre aux lignes, et les disjonctions aux colonnes d'une matrice n x n
            #clause_AL.append([i*n+j for j in range(1,n+1)])
            nb_clause_AL += 1
    AL_time = time.time() - s_t
    AL_time = round(AL_time, 4)
    if verbose == "v":
        print("temps :", AL_time)

    """ Matrice carrée: (At least + At most 1 => At most 2 ...) """

    # At most: Au plus une affectation par étiquette (pas d'étiquette partagée)
    """ At most pour les graphes à n=5 sommets
            -1 v  -6 ^  -1 v -11 ^  -1 v -16 ^  -1 v -21
        ^             -6 v -11 ^  -6 v -16 ^  -6 v -21
        ^                        -11 v -16 ^ -11 v -21
        ^                                    -16 v -21 
        ^  -2 v  -7 ^  -2 v -12 ^  -2 v -17 ^  -2 v -22
        ^             -7 v -12 ^  -7 v -17 ^  -7 v -22
        ^                        -12 v -17 ^ -12 v -22
        ^                                    -17 v -22 
        ^  -3 v  -8 ^  -3 v -13 ^  -3 v -18 ^  -3 v -23
        ^             -8 v -13 ^  -8 v -18 ^  -8 v -23
        ^                        -13 v -18 ^ -13 v -23
        ^                                    -18 v -23 
        ^  -4 v  -9 ^  -4 v -14 ^  -4 v -19 ^  -4 v -24
        ^             -9 v -14 ^  -9 v -19 ^  -9 v -24
        ^                        -14 v -19 ^ -14 v -24
        ^                                    -19 v -24 
        ^  -5 v -10 ^  -5 v -15 ^  -5 v -20 ^  -5 v -25
        ^            -10 v -15 ^ -10 v -20 ^ -10 v -25
        ^                        -15 v -20 ^ -15 v -25
        ^                                    -20 v -25 
    """
    if verbose == "v":
        print("- Ajout des clauses AtMost...")
    nb_clauses_AM = 0
    #clauses_AM = []
    s_t = time.time()
    for l in range(1,n+1):
        for i in range(l,n*(n-1)+1,n):
            for j in range(n+i,n*n+1,n):
                m3.add_clause([-i,-j])
                #clauses_AM.append([-i,-j])
                nb_clauses_AM += 1
    AM_time = time.time() - s_t
    AM_time = round(AM_time, 4)
    if verbose == "v":
        print("temps :", AM_time)

    # On vérifie enfin que les sommets reliés par une arrete respectent des distances inférieures ou égales à k:
    """
        Exemple pour le graphe en étoile:
        
        Imaginons qu'un etiquettage qui convient soit:
        G_etiq
            Etiq
        Som  "1" "2" "3" "4" "5"
        1   +1  -2  -3  -4  -5
        2   -6  -7  -8  +9 -10
        3  -11 +12 -13 -14 -15
        4  -16 -17 -18 -19 +20
        5  -21 -22 +23 -24 -25

        -> Il faut vérifier que si les sommets 1 et 2 sont relié par une arête, alors la différence de leurs etiquettages (ici "1" et "4" resp.) est bien inférieur à k
        -> Il faut s'assurer que toutes les aretes (i,j) dans G_aret ne soit pas etiquettées par un couple (e_i, e_j) dont leur distance est > k (= (e_i,e_j) à False dans M_dist)

        Si une pair de sommets (i,j) est etiquette par (e_i, e_j) et si cette pair de sommet forme une arete, alors sa distance doit être inférieur à k:
        - Soit a(sommet a, sommet b) : Bool                 la fonction qui retourne Vrai si les sommets a et b sont reliés par une arete
            a(literal l1, literal l2) : Bool                                                          correspondants aux litteraux l1 et l2 sont reliés par une arete
        - Soit d(etiquette e_a, etiquette e_b) : Bool       la fonction qui retourne Vrai si les etiquettes e_a et e_b ont une distance inférieur à k
            d(literal l1, literal l2) : Bool                                                          correspondants aux litteraux l1 et l2 ont une distance inférieur à k

            (a^b) ^ a(s[a]],[s[b]) => d(e[a],e[b])
            (l1^l2) ^ a(l1,l2) => d(l1,l2)
            <=>      !(l1^l2) v !a(l1,l2) v d(l1,l2)
            <=>      !l1 v !l2 v !a(l1,l2) v d(l1,l2)

        Imaginons que le graphe des aretes soit:
        G_aret
            Som
        Som  1 2 3 4 5
        1   x   T T
        2     x   T T
        3       x   T
        4         x 
        5           x

        Et que le distancier soit: (k=1)
        M_dist
            Etiq
        Etiq "1" "2" "3" "4" "5"
        "1"  x   T           T
        "2"  T   x   T
        "3"      T   x   T
        "4"          T   x   T  
        "5"  T           T   x

        On voit donc ici que l'arete (1,3) ne peut pas etre etiquette ("2","4") par exemple 

    """

    new_line = True
    # Pour chaque pair d'étiquettage de sommet (dans notre exemple: i = l1, j = l2)
    if (verbose == "v"):
        print("- Ajout des clauses contraintes des distances...")
    nb_clauses_dist = 0
    #clauses_dist = []
    s_t = time.time()
    for i in range(1, (n*n)+1): # Il faut verifier chaque pair
        j = 1
        while j < ((n*n) + 1):
            # Si deux sommets sont etiquettes (ex: x1 ^ x12 pour le sommet 1 etiquetté par "1" et le sommet 3 étiquetté par "2" dans la matrice des etiquettages)
            # Alors ces deux sommets doivent etre relié par une arrete (on retrouve les numéros de sommet avec l'indice de ligne de la matrice des étiquettages)
            # Et doivent avoir une distance inférieur à k (on retrouve les numéros des étiquettes avec l'indice de colonne de la matrice des étiquettages)

            # (l1^l2) ^ a(l1,l2) => d(l1,l2)   <=>   !l1 v !l2 v !a(l1,l2) v d(l1,l2)
            
            # Pour économiser les clauses inutiles, on commence par regarder si les sommets correspondants à i et j (leurs numéros de ligne) sont reliés par une arete
            # Si ils ne sont pas relié par une arete, on passe à la ligne suivante pour j
            
            if  not a(i, j, n, M_edges) and new_line == True:
                #print("i:",i,"j:",j," pas d'arete: on passe a la ligne suivante")
                j += n
                new_line = True
            else:
                if new_line == True:
                    new_line = False

                if not d(i, j, n, M_dist):
                    m3.add_clause([-i, -j])
                    #clauses_dist.append([-i, -j])
                    nb_clauses_dist += 1
                    #print("i:",i,"j:",j," distance non respecte pour ces 2 sommets reliés: l'un ou l'autre (ou les 2) doit etre a faux")

                # Quand on arrive au bout de la ligne, on change de ligne donc nouvelle ligne à verifier (présence d'arete avec le nouveau sommet)
                if j%n == 0:
                    new_line = True
                    #print("On est arriver au bout d'une ligne, nouvelle ligne = nouveau sommet")
                
                j += 1
    dist_time = time.time() - s_t
    dist_time = round(dist_time, 4)
    if verbose == "v":
        print("temps :", dist_time)
    
    if (verbose == "v"):
        print("- Ajout des clauses brise symetrie 2...")
    nb_clauses_sym2 = 0
    #clauses_sym2 = []
    s_t = time.time()
    for i in range(n+3,2*n+1):
        k = [k for k in range(n*(n-1)+2,n*(n-1)+(i%n))]
        k = i%n
        if i%n == 0:
            k = n
        etiq_n = [-j for j in range(n*(n-1)+2,n*(n-1)+k)]  # avec n = 5, on vérifie par exemple qu'on ne peut pas avoir etiq(2) = "4" (9) ET etiq(5) = "2" (22) ou etiq(5) = "3" (23) et c'est tout.
        for j in etiq_n:
            nb_clauses_sym2 += 1
            m3.add_clause([-i,j])
            #clauses_sym2.append([-i,j])
    sym2_time = time.time() - s_t
    sym2_time = round(sym2_time, 4)
    if verbose == "v":
        print("temps :", sym2_time)
    

    total_times = AL_time + AM_time + dist_time + sym2_time
    total_times = round(total_times, 1)

    nb_clauses_total = int(nb_clause_AL + nb_clauses_AM + nb_clauses_dist + nb_clauses_sym2)
    clauses_lengths = [nb_clause_AL, nb_clauses_AM, nb_clauses_dist, nb_clauses_sym2, nb_clauses_total]

    if (verbose == "v"):
        print("len clauses AL = ", nb_clause_AL)
        print("len clauses AM = ", nb_clauses_AM)
        print("len clauses dist = ", nb_clauses_dist)
        print("len clauses sym2 = ", nb_clauses_sym2)
        print("len clauses total = ", nb_clauses_total)
        print("temps total = ", total_times)

    clauses_times = [AL_time, AM_time, dist_time, sym2_time, total_times]

    timer = Timer(budget, interrupt, [m3])
    timer.start()
    
    m3.clear_interrupt()
    # Symetrie 1: On brise la symétrie rotative en fixant le premier sommet à "1" par exemple
    assum_brise_symetrie_rotative = [1]
    
    if (verbose == "v"):
        print("- Solve pySAT en cours...")
    s_t = time.time()
    #assum_3bis = [1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16, -17, -18, -19, -20, -21, -22, -23, -24, -25, -26, -27, -28, -29, -30, -31, -32, -33, -34, -35, -36, -37, -38, -39, -40, -41, -42, -43, -44, -45, -46, -47, -48, -49, -50, -51, -52, -53, -54, -55, -56, -57, -58, -59, -60, -61, -62, 63, -64, -65, -66, -67, -68, -69, -70, -71, -72, -73, -74, -75, -76, -77, -78, -79, -80, -81, -82, -83, -84, -85, -86, -87, -88, -89, -90, -91, -92, -93, -94, 95, -96, -97, -98, -99, -100, -101, -102, -103, -104, -105, -106, -107, -108, -109, -110, -111, -112, -113, -114, -115, -116, -117, -118, -119, -120, -121, -122, -123, -124, -125, -126, -127, -128, -129, -130, -131, -132, -133, -134, -135, -136, -137, 138, -139, -140, -141, -142, -143, -144, -145, -146, -147, -148, -149, -150, -151, -152, -153, -154, -155, -156, -157, -158, -159, -160, -161, -162, -163, -164, -165, -166, -167, -168, -169, -170, -171, -172, -173, -174, -175, -176, -177, -178, -179, -180, -181, -182, -183, -184, -185, -186, -187, -188, -189, -190, 191, -192, -193, -194, -195, -196, -197, -198, -199, -200, -201, -202, -203, -204, -205, -206, -207, -208, -209, -210, -211, -212, -213, -214, -215, -216, -217, -218, -219, -220, -221, -222, -223, -224, -225, -226, -227, -228, -229, -230, -231, -232, -233, 234, -235, -236, -237, -238, -239, -240, -241, -242, -243, -244, -245, -246, -247, -248, -249, -250, -251, -252, -253, 254, -255, -256, -257, -258, -259, -260, -261, -262, -263, -264, -265, -266, -267, -268, -269, -270, -271, -272, -273, -274, -275, -276, -277, -278, -279, -280, -281, -282, -283, -284, -285, -286, -287, -288, -289, -290, -291, -292, -293, -294, -295, -296, -297, -298, -299, 300, -301, -302, -303, -304, -305, -306, -307, -308, -309, -310, -311, -312, -313, -314, -315, -316, -317, -318, -319, -320, -321, -322, -323, -324, -325, -326, -327, -328, -329, -330, 331, -332, -333, -334, -335, -336, -337, -338, -339, -340, -341, -342, -343, -344, -345, -346, -347, -348, -349, -350, -351, -352, -353, -354, -355, -356, -357, -358, -359, -360, 361, -362, -363, -364, -365, -366, -367, -368, -369, -370, -371, -372, -373, -374, -375, -376, -377, -378, -379, -380, -381, -382, -383, -384, -385, -386, -387, -388, -389, -390, -391, -392, -393, -394, -395, -396, -397, -398, -399, -400, -401, -402, -403, -404, -405, -406, -407, -408, -409, -410, -411, -412, -413, -414, -415, -416, -417, -418, -419, 420, -421, -422, -423, -424, -425, -426, -427, -428, -429, -430, -431, -432, -433, -434, -435, -436, -437, -438, -439, -440, -441, -442, -443, -444, -445, -446, -447, -448, -449, -450, -451, -452, -453, -454, -455, -456, -457, -458, -459, -460, -461, -462, -463, -464, -465, 466, -467, -468, -469, -470, -471, -472, -473, -474, -475, -476, -477, -478, -479, -480, -481, -482, -483, -484, -485, -486, -487, -488, -489, -490, -491, -492, -493, -494, -495, -496, -497, -498, -499, -500, -501, 502, -503, -504, -505, -506, -507, -508, -509, -510, -511, -512, -513, -514, -515, -516, -517, -518, -519, -520, -521, -522, -523, -524, 525, -526, -527, -528, -529, -530, -531, -532, -533, -534, -535, -536, -537, -538, -539, -540, -541, -542, -543, -544, -545, -546, -547, -548, -549, -550, -551, -552, -553, -554, -555, -556, -557, -558, -559, -560, -561, -562, -563, -564, -565, -566, -567, 568, -569, -570, -571, -572, -573, -574, -575, -576, -577, -578, -579, -580, -581, -582, -583, -584, -585, -586, -587, -588, -589, -590, -591, -592, -593, -594, -595, -596, -597, -598, -599, -600, -601, -602, -603, -604, -605, -606, -607, -608, -609, -610, -611, -612, -613, -614, -615, 616, -617, -618, -619, -620, -621, -622, -623, -624, -625, -626, -627, -628, -629, -630, -631, -632, -633, -634, -635, -636, -637, -638, -639, 640, -641, -642, -643, -644, -645, -646, -647, -648, -649, -650, -651, -652, -653, -654, -655, -656, -657, -658, -659, -660, -661, -662, -663, -664, -665, -666, -667, -668, -669, -670, -671, -672, -673, -674, -675, -676, -677, -678, -679, -680, -681, -682, -683, -684, -685, -686, -687, -688, -689, -690, -691, -692, -693, -694, 695, -696, -697, -698, -699, -700, -701, -702, -703, -704, -705, -706, -707, -708, -709, -710, -711, -712, -713, -714, -715, -716, -717, -718, -719, -720, -721, -722, -723, -724, -725, -726, -727, -728, -729, -730, 731, -732, -733, -734, -735, -736, -737, -738, -739, -740, -741, -742, -743, -744, -745, -746, -747, -748, -749, -750, -751, -752, -753, 754, -755, -756, -757, -758, -759, -760, -761, -762, -763, -764, -765, -766, -767, -768, -769, -770, -771, -772, -773, -774, -775, -776, -777, -778, -779, -780, -781, -782, -783, -784, -785, -786, -787, -788, -789, -790, -791, -792, -793, -794, 795, -796, -797, -798, -799, -800, -801, -802, -803, -804, -805, -806, -807, -808, -809, -810, -811, -812, -813, -814, -815, -816, -817, -818, -819, -820, -821, -822, -823, -824, -825, -826, -827, -828, -829, -830, -831, -832, 833, -834, -835, -836, -837, -838, -839, -840, -841, -842, -843, -844, -845, -846, -847, -848, -849, -850, -851, -852, -853, -854, -855, -856, -857, -858, -859, -860, -861, -862, -863, -864, -865, -866, -867, -868, -869, 870, -871, -872, -873, -874, -875, -876, -877, -878, -879, -880, -881, -882, -883, -884, -885, -886, -887, -888, -889, -890, -891, -892, -893, -894, -895, -896, -897, -898, -899, -900, -901, -902, -903, -904, -905, -906, -907, -908, -909, -910, -911, -912, -913, -914, -915, -916, -917, -918, -919, 920, -921, -922, -923, -924, -925, -926, -927, -928, -929, -930, -931, -932, -933, -934, -935, -936, -937, -938, -939, -940, -941, -942, -943, -944, -945, -946, -947, -948, -949, -950, -951, -952, -953, -954, -955, -956, -957, -958, -959, -960, -961, 962, -963, -964, -965, -966, -967, -968, -969, -970, -971, -972, -973, -974, -975, -976, -977, -978, -979, -980, -981, -982, -983, -984, -985, 986, -987, -988, -989, -990, -991, -992, -993, -994, -995, -996, -997, -998, -999, -1000, -1001, -1002, -1003, -1004, -1005, -1006, -1007, -1008, -1009, -1010, -1011, -1012, -1013, -1014, -1015, -1016, -1017, -1018, -1019, -1020, -1021, -1022, 1023, -1024, -1025, -1026, -1027, -1028, -1029, -1030, -1031, -1032, -1033, -1034, -1035, -1036, -1037, -1038, -1039, -1040, -1041, -1042, -1043, -1044, -1045, -1046, -1047, -1048, -1049, -1050, -1051, -1052, -1053, -1054, -1055, -1056, -1057, -1058, -1059, -1060, -1061, -1062, -1063, -1064, -1065, -1066, -1067, -1068, -1069, -1070, -1071, -1072, -1073, -1074, -1075, -1076, -1077, -1078, -1079, -1080, -1081, -1082, -1083, -1084, -1085, -1086, -1087, -1088, 1089, -1090, -1091, -1092, -1093, -1094, -1095, -1096, -1097, -1098, -1099, -1100, -1101, -1102, -1103, -1104, -1105, -1106, -1107, -1108, -1109, -1110, -1111, -1112, -1113, -1114, -1115, -1116, -1117, -1118, -1119, 1120, -1121, -1122, -1123, -1124, -1125, -1126, -1127, -1128, -1129, -1130, -1131, -1132, -1133, -1134, -1135, -1136, -1137, -1138, -1139, -1140, -1141, -1142, -1143, -1144, -1145, -1146, -1147, -1148, -1149, -1150, -1151, -1152, -1153, -1154, -1155, -1156, -1157, -1158, -1159, -1160, -1161, -1162, -1163, -1164, -1165, -1166, -1167, -1168, 1169, -1170, -1171, -1172, -1173, -1174, -1175, -1176, -1177, -1178, -1179, -1180, -1181, -1182, -1183, -1184, -1185, -1186, -1187, -1188, -1189, -1190, -1191, -1192, -1193, -1194, 1195, -1196, -1197, -1198, -1199, -1200, -1201, -1202, -1203, -1204, -1205, -1206, -1207, -1208, -1209, -1210, -1211, -1212, -1213, -1214, -1215, -1216, 1217, -1218, -1219, -1220, -1221, -1222, -1223, -1224, -1225, -1226, -1227, -1228, -1229, -1230, -1231, -1232, -1233, -1234, -1235, -1236, -1237, -1238, -1239, -1240, -1241, -1242, -1243, -1244, -1245, -1246, -1247, -1248, -1249, -1250, -1251, -1252, -1253, -1254, 1255, -1256, -1257, -1258, -1259, -1260, -1261, -1262, -1263, -1264, -1265, -1266, -1267, -1268, -1269, -1270, -1271, -1272, -1273, -1274, -1275, -1276, -1277, -1278, -1279, -1280, -1281, -1282, -1283, -1284, -1285, -1286, -1287, -1288, -1289, -1290, -1291, -1292, 1293, -1294, -1295, -1296, -1297, -1298, -1299, -1300, -1301, -1302, -1303, -1304, -1305, -1306, -1307, -1308, -1309, -1310, -1311, -1312, -1313, -1314, -1315, -1316, -1317, -1318, -1319, -1320, -1321, -1322, -1323, -1324, -1325, -1326, -1327, -1328, -1329, -1330, 1331, -1332, -1333, -1334, -1335, -1336, -1337, -1338, -1339, -1340, -1341, -1342, -1343, -1344, -1345, -1346, -1347, -1348, -1349, -1350, -1351, -1352, -1353, -1354, -1355, -1356, -1357, -1358, -1359, -1360, -1361, -1362, -1363, -1364, -1365, -1366, -1367, -1368, 1369, -1370, -1371, -1372, -1373, -1374, -1375, -1376, -1377, -1378, -1379, -1380, -1381, -1382, -1383, -1384, -1385, -1386, -1387, -1388, -1389, -1390, -1391, -1392, -1393, -1394, -1395, -1396, -1397, -1398, -1399, -1400, -1401, -1402, -1403, -1404, -1405, -1406, 1407, -1408, -1409, -1410, -1411, -1412, -1413, -1414, -1415, -1416, -1417, -1418, -1419, -1420, -1421, -1422, -1423, -1424, -1425, -1426, -1427, -1428, -1429, -1430, -1431, -1432, -1433, -1434, -1435, -1436, -1437, -1438, -1439, -1440, -1441, -1442, -1443, -1444, 1445, -1446, -1447, -1448, -1449, -1450, -1451, -1452, -1453, -1454, -1455, -1456, -1457, -1458, -1459, -1460, -1461, -1462, -1463, -1464, -1465, -1466, -1467, -1468, -1469, -1470, -1471, -1472, -1473, -1474, -1475, -1476, -1477, -1478, -1479, -1480, -1481, -1482, -1483, -1484, -1485, -1486, -1487, -1488, -1489, -1490, -1491, -1492, -1493, -1494, -1495, -1496, -1497, -1498, -1499, -1500, -1501, -1502, -1503, -1504, -1505, -1506, -1507, -1508, -1509, -1510, -1511, -1512, -1513, -1514, 1515, -1516, -1517, -1518, -1519, -1520, -1521]
    #sol_limit = m3.solve_limited(assumptions= assum_3bis, expect_interrupt=True)
    sol_limit = m3.solve_limited(assumptions= assum_brise_symetrie_rotative, expect_interrupt=True)
    e_t = time.time() - s_t
    e_t = round(e_t,4)
    
    if (verbose == "v"):
        print("\ntemps de pySAT = ", e_t)
    timer.cancel()
    t_elapsed = time.time() - start_time
    t_elapsed = round(t_elapsed,4)
    
    if(sol_limit == True):
        print("Probleme satisfiable (SAT,",t_elapsed,"s)")
        #print("sol: ",m3.get_model())
        dec = "SAT"
        
    elif (sol_limit == False):
        print("Probleme insatisfiable (UNSAT,",t_elapsed,"s)")

        """if verbose == "s":
            core = m3.get_core()
            etiqu = []
            for lit in core:
                s = literals_to_sommet(lit, n)
                e = literals_to_etiq(lit, n)
                etiqu.append([s,e])
            print("les sommets ", [etiqu[i][0] for i in range(len(etiqu))], " ne peuvent pas etre etiquette ", [etiqu[i][1] for i in range(len(etiqu))])
            trace_clauses(n,m,clause_AL,clauses_AM, clauses_dist, clauses_sym2)"""

        dec = "UNSAT"

    elif (sol_limit == None):
        print("Budget dépassé (UNKNOWN,",t_elapsed,"s)")
        dec = "UNKNOWN"
    m3.delete()
    return dec, clauses_lengths, e_t, clauses_times

"""
import json

nom_instance = "ibm32"
dossier = "ann"
fichier_json = json_file = open("../instances/"+dossier+"/"+nom_instance+".json")
variables = json.load(json_file)

# n : nb de sommets
# m : nb d'aretes
# A : matrice des arêtes
# k : CB recherché

n = variables["n"]
m = variables["m"]
A = variables["A"]

k = 6
budget = 60
verbose = True

M3(n, m, A, k, budget, verbose)"""