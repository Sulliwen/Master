Le Rapport pdf se trouve dans le dossier Doc.

-------------------------------
- Test des modèles SET et SAT -
-------------------------------
Les modèles SET et SAT se trouve dans le dossier Solveurs_Pro

- Test des modèles SET (avec bs ou sans bs)
	1) Positionnez vous dans le dossier Solveurs_Pro
	2) Selection des modèles:
		Pour selectionner les types de modèles que vous voulez tester, les copier ajouter dans le sous dossier "/Modeles_MZN_SET"
		Par exemple, si vous voulez tester les modèles sans brise symetrie (9_sbs.mzn) et brise symmetrie assumption fixer semaine 1 (0_bs_a1.mzn), copiez ceux-ci depuis le dossier "Solveurs_Pro/Modeles_MZN_SET/Liste_modeles" vers le dossier "Solveurs_Pro/Modeles_MZN_SET"
	3) Choix des instances:
		a) Instance Personnelle -> Entrez la commande:
			python3 Exp_SET.py s k p
			Par exemple pour lancer l'instance 2 semaines de 5 groupes de 4 joueurs: python3 Exp_SET.py 2 5 4
		b) Instance Cardinal -> Entrez la commande:
			python3 Exp_SET.py -t 0
		c) Instance Balayage -> Entrez la commande:
			python3 Exp_SET.py -t 1

- Test des modèles SAT (avec bs ou sans bs)
	1) Positionnez vous dans le dossier Solveurs_Pro
	
	/!\ Attention: Glucose ne semble pas réussir à résoudre le modèle bs_a2 de l'instance 4 6 5 (le processus s'arrête tout seul). Il peut etre judicieux de retirer l'instance 4 6 5 avant de lancer le test. Pour ce faire, rendez-vous ligne 110 du fichier Solveurs_Pro/Exp_SAT.py
	
	2) Selection des modèles:
		Pour selectionner les types de modèles que vous voulez tester, les copier ajouter dans le sous dossier "/Modeles_SAT"
		Par exemple, si vous voulez tester les modèles sans brise symetrie (9_sbs.mzn) et brise symmetrie assumption fixer semaine 1 (0_bs_a1.mzn), copiez ceux-ci depuis le dossier "Solveurs_Pro/Modeles_SAT/Liste_modeles" vers le dossier "Solveurs_Pro/Modeles_SAT"
	3) Choix des instances:
		a) Instance Personnelle -> Entrez la commande:
			python3 Exp_SAT.py s k p
			Par exemple pour lancer l'instance 2 semaines de 5 groupes de 4 joueurs: python3 Exp_SET.py 2 5 4
		b) Instance Cardinal -> Entrez la commande:
			python3 Exp_SAT.py -t 0
		c) Instance Balayage -> Entrez la commande:
			python3 Exp_SAT.py -t 1

--------------------------
- Utilisation du solveur -
--------------------------
Le solveur SET se trouve dans le dossier Solveur_Vanilla/src

Notation des brises symmétries (bs):
------------------------------------
a1: on fixe la premiere semaine
a2: on fixe le premier joueur des p premiers groupes à chaque semaine
o1: les groupes d'une semaine doivent être ordonnés par joueur d'indice minimum croissant
o2: les premiers groupes de chaque semaine doivent être ordonnés par joueur d'indice second minimum croissant

a12	: a1 + a2
a12_o1	: a1 + a2 + o1
etc...

- Test du solveur sur le problème du SGP (avec bs ou sans bs)
	1) Positionnez vous dans le dossier Solveur_Vanilla
	2) Choix des instances:
		Le choix de l'instance se fait en ligne de commande
		a) Instance de votre choix -> Entrez la commande:
			julia Exp_Vanilla.jl s k p
			Par exemple pour lancer l'instance 2 semaines de 5 groupes de 4 joueurs: julia Exp_Vanilla.jl 2 5 4
			Cette commande résolvera l'instance sans briser de symétrie
		b) Instance Cardinal -> Entrez la commande:
			julia Exp_Vanilla.jl -t 0
		c) Instance Balayage -> Entrez la commande:
			julia Exp_Vanilla.jl -t 1
			
	3) Choix des pack de bs: (permet de lancer une experience pour étudier (comparer) l'influence des brises symmetries sur la résolution) 
		Le choix des bs se fait également en ligne de commande
		a) Brise symmetries d'assertion, d'ordre et sans brise symmetrie
			julia Exp_Vanilla.jl -t 0 -b 0
			julia Exp_Vanilla.jl s k p -b 0
		b) Brise symmetries d'assertion
			julia Exp_Vanilla.jl -t 0 -b 1
			julia Exp_Vanilla.jl s k p -b 1
		b) Brise symmetries d'ordre
			julia Exp_Vanilla.jl -t 0 -b 2
			julia Exp_Vanilla.jl s k p -b 2	
		c) Choix des bs de votre choix:
			julia Exp_Vanilla.jl -t 0 -m [bs]
			julia Exp_Vanilla.jl s k p -m [bs]
			
			Avec [bs] = a1, a2, a12, a12_o1, a12_o2, a12_o12, o1, o2 ou o12
			Par exemple pour étudier la brise symmetrie qui fixe la semaine 1 avec la brise symmetrie qui ordonne les p premiers groupes sur l'instance 2 8 5:
			julia Exp_Vanilla.jl 2 8 5 -m a1 o1		
			
	4) Pour activer la verbose, ajoutez l'option -v. La verbose donne les différentes étapes du Branch and Prune (décommenter le readline() ligne 311 du fichier Solveur_Vanilla/src/Solveur_SET_Vanilla.jl permettra d'avoir le temps de lire chaque étape)
			julia Exp.jl 5 4 4 -m a12 -v
	
--------------------------------------------------------------------------------------------------------------------
		
- Test du solveur sur le problème du Sudoku
	1) Positionnez vous dans le dossier Solveur_Vanilla
	2) Choix des instances:
		Des instances sont déjà configurées mais pour faire la votre, rendez-vous dans le fichier Exp_Sudoku.jl et inspirez vous des instances grilles
	3) Lancement de l'experience:
		julia Exp_Sudoku.jl
	
--------------------------------------------------------------------------------------------------------------------
		
- Test du solveur sur le problème des n Reines
	1) Positionnez vous dans le dossier Solveur_Vanilla
	2) Choix des instances:
		Des instances sont déjà configurées mais pour faire la votre, rendez-vous dans le fichier Exp_nReines.jl et inspirez vous des instances
	3) Lancement de l'experience:
		julia Exp_nReines.jl
