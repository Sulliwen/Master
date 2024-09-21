include("src/Solveur_SET_Vanilla.jl")
include("Modeles/Modele_Sudoku_SET.jl")

function Sudoku(grille::Matrix{Int64}, verbose)
	modele = modele_Sudoku(grille)
	afficher_sol(modele, grille)
	# On lance la résolution après ce pré filtrage
	println("\t Résolution en cours...")
	global T_START = time()
	temps_exec1 = @elapsed sat1 = Solve(modele)

	if temps_exec1 > BUDGET
		printstyled("\t Budget dépassé\n\n"; color = :magenta)
	else
		if !sat1
			printstyled("\t UNSAT\n\n"; color = :red)
		else
			printstyled("\t SAT"; color = :green)
			println(" (temps exec: ", temps_exec1, " sec)\n")
			println("\t Solution trouvée:\n")
			afficher_sol(modele, grille)
		end
	end
end

grille1 = [ 5 3 0  0 7 0  0 0 0;
			6 0 0  1 9 5  0 0 0;
			0 9 8  0 0 0  0 6 0;

			8 0 0  0 6 0  0 0 3;
			4 0 0  8 0 3  0 0 1;
			7 0 0  0 2 0  0 0 6;

			0 6 0  0 0 0  2 8 0;
			0 0 0  4 1 9  0 0 5;
			0 0 0  0 8 0  0 7 9;
		]
grille2 = [ 6 1 0  0 4 0  7 0 0;
			0 0 0  0 5 0  9 0 0;
			2 0 0  0 0 6  5 0 8;

			4 0 0  9 0 0  0 6 0;
			0 0 0  0 0 0  0 0 0;
			0 7 0  0 0 5  0 0 3;

			1 0 8  7 0 0  0 0 9;
			0 0 6  0 2 0  0 0 0;
			0 0 3  0 9 0  0 8 1;
		]

#---------------
#- Paramétrage -
#---------------
VERBOSE = false
BUDGET = 200
T_START = 0
T_TIC = 0
ID_EXP = ""

Sudoku(grille1, false)
