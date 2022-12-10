#TODO:
#		Fonctionalités
#			- traiter les cas de doublons de minimums (sur chaque ligne, triplets sur 2 lignes et quadruplé sur 4 etc)
#		Code cleaning
#			- répétitions à éviter dans la mise à jour des lignes saturées déjà indiquée comme saturée
#			- séparer le code en fonctions élémentaires
#			- factoriser les variables (enlever les variables inutiles)

#=
#--------------------------Instance Erlenkotter-------------------------
c = [[120,210,180,210,170] [180,10000,190,190,150] [100,150,110,150,110] [10000,240,195,180,150] [60,55,50,65,70] [10000,210,10000,120,195] [180,110,10000,160,200] [10000,165,195,120,10000]]
f = [200 200 200 400 300]

---------------------------Instance Teghem---------------------------
c=[  5  3   4   7  10  10  5   3;
  2  0   1   4   7  13  8   6;
 10  8  10  13  10   5  0   2;
 11  9   7   4   2   3  8  11]

f = [8 15 7 6]

-----------------------Instance Verter----------------------

c = [[120,210,180,210,170] [180,10000,190,190,150] [100,150,110,150,110] [10000,240,195,180,150] [60,55,50,65,70] [10000,210,10000,120,195] [180,110,10000,160,200] [10000,165,195,120,10000]]
f = [200 200 200 400 300]

c = [[120,210,180,210,170] [180,10000,190,190,150] [100,150,110,150,110] [10000,240,195,180,150] [60,55,50,65,70] [10000,210,10000,120,195] [180,110,10000,160,200] [10000,165,195,120,10000]]
 f = [100 70 60 110 80]
=#


c = [[120,210,180,210,170] [180,10000,190,190,150] [100,150,110,150,110] [10000,240,195,180,150] [60,55,50,65,70] [10000,210,10000,120,195] [180,110,10000,160,200] [10000,165,195,120,10000]]
f = [200 200 200 400 300]



function DUALOC(c, f) # cij matrice des couts, fi couts d'installation

	# Variables
		#MatriceCout::Array{Int64}
		#v::Array{Int64,2}  # Coût v attribuer au client i
		#s::Array{Int64,2}  # Coût s des entrepôt j après le dual ascent
		#f::Array{Int64,2}  # Coût f des entrepôt j

		MatriceCout = deepcopy(c)
		v,s, MatBoolC, VecteurDernierCout, BoolI = dualAscentClassique(MatriceCout, f)
		#dualAdjustment(c, v, s, MatBoolC, VecteurDernierCout, BoolI)
		#v,s,MatBoolC, VecteurDernierCout, BoolI  = dualAscentPourAdjustment(MatriceCout, f, TempMatBoolC, TempVecteurDernierCout, TempBoolI)

end









function dualAscentClassique(c,f)
    #Variables
	#v::Array{Int64,2}  # Coût v attribuer au client j
	#s::Array{Int64,2}  # Coût s des entrepôt i
	tempV = zeros(Int64,1,size(c,2)) # variable comportant les valeur Vj temporaire pour chaque itération
	tempS = deepcopy(f) #variable comportant les valeur Si temporaire pour chaque itération
	MatBoolC = zeros(Bool,size(c,1),size(c,2)) #Matrice des coût ayant déjà été utilisé
	VecteurDernierCout = zeros(Int64,1,size(c,2)) # Vecteur comportant la dernère valeur du coût utilisé pour chaque colonnes
	BoolI = zeros(Bool,size(c,2)) # Vecteur de booléen indiquant si le client peux être augmenté


	# Initialisation
	# On cherche le coût minimum pour chaque colonnes
    for i in 1:size(c,2)
		minInit = findmin(c[:,i])
		MatBoolC[minInit[2],i] = true
		VecteurDernierCout[i] = minInit[1]
		tempV[i]=minInit[1]
    end
	#Fin Initialisation
#=
	println("MatBoolC:", MatBoolC)
=#


	while(all(BoolI)!=true && tempS != zeros(Int64,size(c,1)))
		indice = 1
		println("indice : ", indice)
        while (all(BoolI)!=true && tempS != zeros(Int64,size(c,1)) && indice <= size(c,2))
			if (BoolI[indice] == 0)
				find = findmin([(MatBoolC[x,indice] == false) ? c[x,indice] : 110000 for x in 1:size(c,1)])
				min = find[1]
				minIndice = find[2]
#=				for i in 1:size(c,1)
					if (MatBoolC[i,indice] == false && c[i,indice] < min)
    					min = c[i,indice]
						minIndice = i
    				end
				end =#

				#Trouver le minimum de S
				minS = findmax(tempS)[1]    #TODO Optim grande valeur de base
				for i in 1:size(c,1)
					if(MatBoolC[i,indice] == true && minS > tempS[i])
						minS = tempS[i]
					end
				end

				delta = min - VecteurDernierCout[indice]
				ChangementEtat = true
				if (delta > minS)
    				ChangementEtat = false
    				delta = minS
				end

				cptBool = 0
    			for i in 1:size(c,1)
                   	if (MatBoolC[i,indice]==true)
    					cptBool += 1
    					tempS[i] -= delta
                        if (tempS[i]==0)
    									#Verification des clients non saturés
							for j in 1:size(c,2)
								if (MatBoolC[i,j]==true)   #Possible optim
    								BoolI[j] = true
								end
							end
                        end
                   	end
                end
				if (cptBool == size(c,1))
    				BoolI[indice] = true
				end
				MatBoolC[minIndice,indice] = ChangementEtat
				if ChangementEtat
						VecteurDernierCout[indice] = min  #erreur!!!!!!!!!!!!!!!
				end
				tempV[indice]+=delta
			end
			println("----------------------------")
			println("indice : ", indice)
			println("MatBoolC:", MatBoolC)
			println("BoolI : ", BoolI)
			println("TempS : ", tempS)
			println("TempV : ", tempV)
			println("VectDernierCout : ", VecteurDernierCout)

			indice += 1
        end

	end
	return tempV, tempS, MatBoolC, VecteurDernierCout, BoolI
end

#--------------------------------------------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------------------------------#

function dualAscentPourAdjustment(c,s,v, MatBoolC, VecteurDernierCout, BoolI , Jplus)

    #Variables
	#v::Array{Int64,2}  # Coût v attribuer au client j
	#s::Array{Int64,2}  # Coût s des entrepôt i
	# v : variable comportant les valeur Vj temporaire pour chaque itération
	# s : variable comportant les valeur Si temporaire pour chaque itération
	# MatBoolC : Matrice des coût ayant déjà été utilisé
	# VecteurDernierCout : Vecteur comportant la dernère valeur du coût utilisé pour chaque colonnes
	# BoolI : Vecteur de booléen indiquant si le client peux être augmenté

	v, s, MatBoolC, VecteurDernierCout, BoolI

	println(" ")
	println("Debut ascent pour adjustment")
	println(" ")


	while(all(BoolI)!=true && s != zeros(Int64,size(c,1)))
		indice = 1

        while (all(BoolI)!=true && s != zeros(Int64,size(c,1)) && indice <= size(c,2))
			if (BoolI[indice] == 0)
				#println("Jplus : ", Jplus)
				#println("BoolI : ",BoolI)
				BoolJplus = all([BoolI[x] for x in Jplus])==true
				if(indice in Jplus || BoolJplus)
    				#println("MatBoolC : ", MatBoolC[1,indice])
					find = findmin([(MatBoolC[x,indice] == false) ? c[x,indice] : 110000 for x in 1:length(s)])
					#println("find", find)
					min = find[1]
					minIndice = find[2]#=
					for i in 1:size(c,1)
						if (MatBoolC[i,indice] == false && c[i,indice] < min)
	    					min = c[i,indice]
							minIndice = i
	    				end
					end=#
					#println("minindice : ",minIndice)
					#Trouver le minimum de S
					minS = findmax(s)[1]    #TODO Optim grande valeur de base
					for i in 1:size(c,1)
						if(MatBoolC[i,indice] == true && minS > s[i])
							minS = s[i]
						end
					end
					#println("vecteur dernier cout", VecteurDernierCout[indice] )
					delta = min - VecteurDernierCout[indice]

					ChangementEtat = true
					if (delta > minS)
    					ChangementEtat = false
	    				delta = minS
					end
#=					println("s ASCENT : ",s)
					println("MatBoolC : ",MatBoolC)
					println("delta : ", delta)=#
					cptBool = 0
	    			for i in 1:size(c,1)
	                   	if (MatBoolC[i,indice]==true)
    						cptBool+=1
	    					s[i] -= delta
	                        if (s[i]==0)
	    									#Verification des clients non saturés
								for j in 1:size(c,2)
									if (MatBoolC[i,j]==true)   #Possible optim
	    								BoolI[j] = true
									end
								end
	                        end
	                   	end
	                end
                    if (cptBool == size(c,1))
						BoolI[indice] = true
                    end
					MatBoolC[minIndice,indice] = ChangementEtat
                    if ChangementEtat
						VecteurDernierCout[indice] = min  #erreur!!!!!!!!!!!!!!!
                    end
					v[indice]+=delta
				end
			end
#=			println("----------------------------")
			println("indice : ", indice)
			println("MatBoolC:", MatBoolC)
			println("BoolI : ", BoolI)
			println("s : ", s)
			println("v : ", v)
			println("VectDernierCout : ", VecteurDernierCout)=#

			indice += 1
        end
		#println("BoolI : ",BoolI)

	end

	println(" ")
	println("Fin ascent pour adjustment")
	println(" ")

	return v, s, MatBoolC, VecteurDernierCout, BoolI
end

