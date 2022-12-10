




#=
#Essais
c::Matrix{Int64}
c = [[120,210,180,210,170] [180,10000,190,190,150] [100,150,110,150,110] [10000,240,195,180,150] [60,55,50,65,70] [10000,210,10000,120,195] [180,110,10000,160,200] [10000,165,195,120,10000]]
findmin(c)

findmin(c[1,:])

TempS = [45 15 70 80 0]

BoolI = [1, 1, 1, 1, 0, 1, 0, 0]
BoolI = [true, true, true, true, false, true, false, false]

		tabIplus = Array{Array{Bool,1},1}(undef,8)


=#

#MatBoolC = [1 1 1 0 1 1 1 1; 1 0 1 1 1 1 1 1; 1 1 1 1 1 0 0 1; 0 1 0 1 1 1 1 1; 1 1 1 1 0 1 1 0]

#MatBoolC = [1 1 1 0 1 0 1 0; 0 0 0 0 1 1 1 1; 1 1 1 1 1 0 0 1; 0 0 0 1 0 1 1 1; 1 1 1 1 0 1 0 0]

#	IstarJ = zeros([[Int64]],size(v)) #I*j

#########################################################################################################""




#=	u = init(c) # u est la matrice des ui
	col_augmentees = augmenteMax(c, f)=#


#=
function init(c)
	u = zeros(Int64,size(c,1),size(c,2))
end=#

#=
function augmenteMax(c,f)

	# Matrice des colonnes à modifier (liste des colonnes pour chaque ui)
	colonnes_a_augmenter = zeros(Bool,size(c,1),size(c,2))

	# vecteur des augmentations des ui commence à (0 0 0 0)
	col_augmentees = zeros(Int64, 1, size(c,2))
	col_saturees = zeros(Bool,1,size(c,2))

	lignes_saturees = zeros(Bool,1,size(c,1))

	isAugmentable = true
	nbIter = 0

	while isAugmentable
		nbIter += 1
		for i in 1:size(c,1)
			# Si la ligne n'est pas saturée (on regarde la ligne correspondante dans la matrice d'origine)
			if (lignes_saturees[i] == false)

				ligne_cour = c[i,:]

				# On récupère le minimum parmi les valeurs n'ayant jamais été minimums
				minim = minimum(ligne_cour[findall(x -> x == 0, colonnes_a_augmenter[i,:])])

				# On indique les positions des colonnes de ui à augmenter
				for j in 1:length(ligne_cour)
					if ligne_cour[j] == minim
						colonnes_a_augmenter[i,j] = 1
					end
				end

				col_a_augm = colonnes_a_augmenter[i,:]

				# Si le nombre de valeurs impactées par l'augmentation est > au numéro d'itération suivante, on ignore la ligne pour l'instant
				if ( length(findall(x -> x == 1, col_a_augm)) == nbIter)

					# indices des valeurs n'étant pas impacté par l'augmentation (contient le prochain min)
					mins_restants = ligne_cour[findall(x -> x == 0, col_a_augm)]
					# L'augmentation est de delta
					delta = minimum(mins_restants) - minim

					cols_satur = 0
					# Si avec cette augmentation on dépasse le coût d'installation d'un des f correspondant, on l'aligne sur ce dernier
					for j in 1:length(f)
						if col_a_augm[j] == true
							# Si augmenter la colonne de delta dépasse la contrainte f
							if (col_augmentees[j] + delta >= f[j])
								# On l'indique
								cols_satur = j
								# Et on aligne delta sur la valeur max que peut prendre la colonne
								delta = f[j] - col_augmentees[j]
							end
						end
					end

					# On récupère toutes les colonnes saturées par une augmentation de delta (si plusieurs colonnes sont saturées en même temps)
					for j in 1:length(f)
						if col_a_augm[j] == true

							# Si augmenter la colonne de delta dépasse la contrainte f
							if (col_augmentees[j] + delta >= f[j])
								col_saturees[j] = true
							end
						end
					end

					# On doit saturer tous les ui qui augmente l'une des colonnes saturées
					if (cols_satur != 0)
						# On met à jour lignes_saturees: les ui devant augmenter une contrainte serrée
						for j in 1:size(colonnes_a_augmenter,1)
							if lignes_saturees[j] == false # si la ligne n'est pas déjà indiqué comme saturée
								for k in 1:size(colonnes_a_augmenter,2)
									if colonnes_a_augmenter[j,k] == col_saturees[k] == true
										lignes_saturees[j] = true
										break # inutile de continuer cette ligne saturée, on regarde la suivante
									end
								end
							end
						end
					end

					#augm_serre = cont_f_serree(col_augmentees, f, delta)
					#if ( augm_serre != -1 )
					#	delta = augm_serre
					#	# et on indique que cette ligne n'est plus augmentable (saturée)
					#	lignes_saturees[i] = true
					#end

					# Augmentation des colonnes de u[i]
					for j in 1:length(col_a_augm)
						if (col_a_augm[j] == 1)
							u[i,j] = delta + col_augmentees[j]
							col_augmentees[j] = u[i,j]
						end
					end
				end
			end
		end
		isAugmentable = length(findall(x -> x == 1,lignes_saturees)) < size(c,1)
	end
	return col_augmentees
end
=#


