Liste des modules python à installer:
- sudo pip install pycsp3
- sudo pip install pySAT
- sudo pip install networkx 

 -------------------------
| Comparaison des modèles |
 -------------------------
	- compare.py

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

 ---------------------------------------------------------------------------------------
| Comparaison des modèles SAT sur k_ann (comparaisons du groupe Adrien Nicolas Nicolas) |
 ---------------------------------------------------------------------------------------
	- Run_M_ann.py
# Lance les modeles passé en entrée sur les instances en entrée pour k = floor((borne inf + borne sup)/2)
# Commande pour lancer sur les instances Adrien Nicolas Nicolas (ann) avec verbose ON sur les modèles [M1,M1_bis,M2,M3,M3_bis] avec un budget de 200:
#           python3 Run_M_ann.py ann
# sur les modèles M3 et M3_bis avec verbose:
#           python3 Run_M_ann.py ann v [M3,M3_bis] 200
# sur les modèles M3 et M3_bis sans verbose:
#           python3 Run_M_ann.py ann n [M3,M3_bis] 200

 -----------------------
| Résolution adaptative |
 -----------------------
	- solv_adaptatif.py

 -------------------------
| Résolution personalisée |
 -------------------------
	- M1.py ... M3_bis.py
Pour lancer l'un des modèles de manière isolé avec les paramètres désirés, décommenter le code en bas des fichiers.

 ---------------------------------------------------------------
| Affichage graphique d'une instance sous forme de graph cyclic |
 ---------------------------------------------------------------
	- graphic/graph_cycle.py

# Exemple pour afficher le graph cyclic de bcspwr01 avec k = 4:
# Toujours depuis src/
#	python3 Graphic_cyclic.py bcspwr01.json 4

# Les graphiques sont générés dans res/graphs/graphs_cyclic

# Avant de générer un nouveau graphique, s'assurer qu'il est ajouté dans graphiques a afficher dans instances/graphics/