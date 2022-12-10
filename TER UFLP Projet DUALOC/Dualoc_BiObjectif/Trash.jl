































#=

#=
préconditions : tableau de matrice de cout c et tableau de vecteur de cout f
=#
function InitialisationDualAscentMultiObjectif(c,f)
	# Variables
	dims = lsize
	#v::Array{Int64,2}  # Coût v attribuer au client j
	#s::Array{Int64,2}  # Coût s des entrepôt i
	n = size(c) # nombre d'objectifs
	tempV = Array{Array{Int64,2},1} # tableau comportant les valeur Vj temporaire pour chaque itération
	tempS = Array{Array{Int64,2},1} # tableau comportant les valeur Si temporaire pour chaque itération
	MatBoolC = Array{Array{Bool,2},1} #tableau de matrices des coûts ayant déjà été utilisés
	VecteurDernierCout = Array{Array{Int64,2},1} # tableau de vecteurs comportant les dernière valeurs de coût utilisés pour chaque colonnes

    for i in 1:n
		tempV[i] = zeros(Int64,1,size(c[1],2))
		tempS[i] = deepcopy(f[i])
		MatBoolC [i] = zeros(Bool,size(c[1],1),size(c[1],2))
		VecteurDernierCout [i] = zeros(Int64,1,size(c[1],2))
    end
	BoolI = zeros(Bool,size(c[1],2)) # Vecteur de booléen indiquant si le client peux être augmenté
	return n, tempV, tempS, MatBoolC, VecteurDernierCout, BoolI
end



function DualAcentMultiObjectifRec(c, n, tempV, tempS, MatBoolC, VecteurDernierCout, BoolI, indice, BoolInitialisation)

	#while(all(BoolI)!=true )    # && tempS != zeros(Int64,size(c,1))
		while (all(BoolI)!=true && indice <= size(c[1],2)) #&& tempS != zeros(Int64,size(c,1))
            if BoolI[i] = false
				vecIndice, intervalle = calculMin(c, MatBoolC, indice)
				for i in vecIndice
				DualAcentMultiObjectif(c, n, tempV, tempS, MatBoolC, VecteurDernierCout, BoolI, indice, i, BoolInitialisation)
				end
			end
			indice += 1
			if (indice > size(c[1],2))
				BoolInitialisation = true
			end
		end
	#end


	# Faire un print du résultat
	return n, tempV, tempS, MatBoolC, VecteurDernierCout, BoolI, indice #retour de tous les récursifs
end
=#

#=
# On cherche le coût minimum pour un indice de colonne en somme pondéré
function calculMinimum()

end



# Faire une matrice de pondération
function DualAcentMultiObjectif(c, n, tempV, tempS, MatBoolC, VecteurDernierCout, BoolI, indice, i, BoolInitialisation)

	if (BoolInitialisation) # initialisation des premiers Cij
		for j in 1:n
			MatBoolC[j][i,indice] = true
			tempV[j][indice] = c[j][i,indice]
		end
	else
		min = Array{Int64,1}
		for j in 1:n
			min[j] = c[j][i,indice]
			minIndice = i
			# trouver le s minimum entre les s des différents objectifs en fonction
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
#=			println("----------------------------")
			println("indice : ", indice)
			println("MatBoolC:", MatBoolC)
			println("BoolI : ", BoolI)
			println("TempS : ", tempS)
			println("TempV : ", tempV)
			println("VectDernierCout : ", VecteurDernierCout)=#

			indice += 1
        end

	end
	return tempV, tempS, MatBoolC, VecteurDernierCout, BoolI



	end


	DualAcentMultiObjectifRec(n, tempV, tempS, MatBoolC, VecteurDernierCout, BoolI, indice+1)
	return 0;
end





function main()
    c1 = [[10,50,40,70,20] [20,10,60,30,20] [10,10,30,90,90] [40,10000,10,60,20] [80,30,20,70,80] [30,40,10000,10,40]]
	c2 = [[30,80,60,10,50] [60,80,30,20,30] [10000,10,20,70,60] [40,20,10000,10,50] [30,40,80,30,10] [80,50,20,10,80]]
	f1 = [200 200 200 400 300]
	f2 = [200 200 200 400 300]
	c = [c1, c2]
	f = [f1, f2]
	BoolInitialisation = false #Booléen permettant de savoir si l'initialisation est terminée
	n, tempV, tempS, MatBoolC, VecteurDernierCout, BoolI = InitialisationDualAscentMultiObjectif(c,f)
	DualAcentMultiObjectifRec(c, n, tempV, tempS, MatBoolC, VecteurDernierCout, BoolI, 1, BoolInitialisation)
end








	# Initialisation
	# On cherche le coût minimum pour chaque colonnes en somme pondéré
    for i in 1:size(c[1],2)
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
				end=#

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

=#




#SAuvegarde ancienne fonction rec

#=
function recResolutionBiObjectif(c::Array{Droite,2},f::Array{Droite,1},MatBoolC::Array{Bool,2},v,VecteurDernierCout::Array{Droite,1},indiceColonne::Int64,deb::Rational{Int64},fin::Rational{Int64},BoolI::Array{Bool,1},noeud::Arbre)
        if (all(BoolI)!=true && f != zeros(Int64,size(c,1))) #Condition d'arret si tous les client sont saturé ou si tous les coût associés au service sont saturés
            if (BoolI[i]==false)
				# recherche de l'ensemble des services minimum

				droiteSansInf = [i for i in [VecteurDroiteSansInf(c[:,indiceColonne])] if MatBoolC[i.ind,indiceColonne] == false]
				if(size(droiteSansInf)[1]>0)
					vecDroite = lowerHull(droiteSansInf,deb,fin,1//10) # 1 argument correspond au droites != inf et pas

					vecDroiteMoinsDelta = Array{Droite,1}(undef,size(vecDroite)[1])

					for i in 1:size(vecDroite)[1]
						tempMatBoolC = deepcopy(MatBoolC)
						tempMatBoolC[vecDroite[i].ind,indiceColonne]= 1

						delta = SoustractionDroite(diophentiennesToAffine(vecDroite[i]),diophentiennesToAffine(VecteurDernierCout[indiceColonne]))

						for j in 1:size(vecDroite)[1]
							vecFMoinsDelta[j] = SoustractionDroite(diophentiennesToAffine(f[vecDroite[j].ind]),delta) # possible de faire que sur les F
						end

						#Calcul des intervalles en fonction des droites
						tempDeb,tempFin = calculIntervalle(vecDroite,deb,fin,i)

						#= 	Décomposition des différents cas sur l'intervalle [tempdeb,tempFin]
						Cas 1 : fonction f-delta > 0
						Cas 2 : fonction f-delta coupe l'abscisse
						Cas 3 : fonction < 0
						=#
						casUn=Array{Droite,1}(undef,0)
						casDeux=Array{Droite,1}(undef,0)
						casTrois=Array{Droite,1}(undef,0)

						for f in vecFMoinsDelta
							if (f.a > 0 && f.b > 0) # Cas 1
    							push!(casUn, affineToDiophentiennes(f))
							elseif ((f.a > 0 && f.b < 0)||(f.a < 0 && f.b > 0))# Cas 1, 2 ou 3
    							if ((f.a*tempFin+f.b)>0 && (f.a*tempDeb+f.b)>0)
    								push!(casUn,affineToDiophentiennes(f))
								elseif((f.a*tempFin+f.b)<0 && (f.a*tempDeb+f.b)<0)
    								push!(casTrois,affineToDiophentiennes(f))
								else
    								push!(casDeux,affineToDiophentiennes(f))
								end
							else
    							push!(casTrois,affineToDiophentiennes(f))
    						end
						end
						#Fin de décomposition des différents cas
						#Voir le cas = 0

						tempVecteurDernierCout = deepcopy(VecteurDernierCout) # Même variable que pour V à l'initialisation
						tempVecteurDernierCout[indiceColonne] = vecDroite[i]

						tempCas = Array{Droite,1}(undef,0)
						tempDebCas = tempDeb
						tempFinCas = tempFin

						#Consequences en fonction des différents Cas
						if (size(casTrois)[1]>0)
							tempCas = lowerHull(vcat(casDeux, casTrois),tempDeb,tempFin,1//10)
							for j in 1:size(tempCas)[1]
								tempDebCas,tempFinCas = calculIntervalle(tempCas,tempDeb,tempFin,j)
								tempDelta = f[tempCas[j].ind]
								tempBoolI = deepcopy(BoolI)
								tempF = deepcopy(f)
								for k in 1:size(tempF)
									if (MatBoolC[k,indiceColonne] == 1)
										fMoinsDelta = affineToDiophentiennes(SoustractionDroite(diophentiennesToAffine(tempF[k]),tempDelta))
										tempF[k] = fMoinsDelta
									end
								end

								tempBoolI = deepcopy(BoolI)

								for l in 1:size(c,2)
									if (MatBoolC[tempCas[j],l]==true)   #Possible optim
    									TempBoolI[l] = true
									end
								end

								tempV = deepcopy(v)
								tempV[indiceColonne] = AdditionDroiteDiophentienne(tempV[indiceColonne] + delta)
								noeudAct = Arbre(tempDebCas,tempFinCas,tempVecteurDernierCout,tempMatBoolC[:,indiceColonne],[])
								push!(noeud.fils,noeudAct)
								recResolutionBiObjectif(c,tempF,tempMatBoolC,tempV,tempVecteurDernierCout,mod(indiceColonne,8)+1, tempDeb, tempFin,BoolI,noeudAct)
							end






						elseif (size(casDeux)[1]>0)

    						tempCas = lowerHull(casDeux,tempDeb,tempFin,1//10)
							for j in 1:size(tempCas)[1]
								tempDebCas,tempFinCas = calculIntervalle(tempCas,tempDeb,tempFin,j)
								tempDelta = diophentiennesToAffine(tempCas[j])
								tempF = deepcopy(f)
								for k in 1:size(tempF)
									if (MatBoolC[k,indiceColonne] == 1)
										fMoinsDelta = affineToDiophentiennes(SoustractionDroite(diophentiennesToAffine(tempF[k]),tempDelta))
										tempF[k] = fMoinsDelta
									end
								end

								tempVecteurDernierCout[indiceColonne] = vecDroite[i]
								tempV = deepcopy(v)
								tempV[indiceColonne] = tempV[indiceColonne] + # TODO!!!!!! Calcul du V        +delta
								noeudAct = Arbre(tempDebCas,tempFinCas,tempVecteurDernierCout,tempMatBoolC[:,indiceColonne],[])
								push!(noeud.fils,noeudAct)
								recResolutionBiObjectif(c,tempF,tempMatBoolC,tempV,tempVecteurDernierCout,mod(indiceColonne,8)+1, tempDeb, tempFin,BoolI,noeudAct)
							end

						else
    						for f in vecFMoinsDelta
								tempF[f.ind] = affineToDiophentiennes(f)
							end
							noeudAct = Arbre(tempDeb,tempFin,tempVecteurDernierCout,tempMatBoolC[:,indiceColonne],[])
							push!(noeud.fils,noeudAct)
							tempVecteurDernierCout = deepcopy(VecteurDernierCout) # Même variable que pour V à l'initialisation
							tempVecteurDernierCout[indiceColonne] = vecDroite[i]
							tempV = deepcopy(v)
							tempV[indicecolonne] = vecDroite[i]
							recResolutionBiObjectif(c,f,tempMatBoolC,tempV,tempVecteurDernierCout,mod(indiceColonne,8)+1, tempDeb, tempFin,BoolI,noeudAct)#modifier le f
    					end





						#=println(" ")
						println("indicecolonne : ", indiceColonne)
						println("deb = ", tempDeb)
						println("fin = ", tempFin)
						println("vecDroite = ", vecDroite)=#
						noeudAct = Arbre(tempDeb,tempFin,tempVecteurDernierCout,tempMatBoolC[:,indiceColonne],[])
						println(" ")
						println("Deb : ",noeudAct.deb)
						println("Fin : ",noeudAct.fin)
						push!(noeud.fils,noeudAct)
						if(indiceColonne != size(c)[2])
							recResolutionBiObjectif(c,f,tempMatBoolC,tempVecteurDernierCout,mod(indiceColonne,8)+1, tempDeb, tempFin,BoolI,noeudAct) #modifier le f
						end
					end



				else	# étape correspondant au dernier coût possible +inf



				end
			else
				recResolutionBiObjectif(c,f,tempMatBoolC,tempVecteurDernierCout,mod(indiceColonne,8)+1, tempDeb, tempFin,BoolI,noeudAct)
			end
		end
	end=#











#Fin de décomposition des différents cas
						#Voir le cas = 0
						#=else



    						for f in vecFMoinsDelta
								tempF[f.ind] = affineToDiophentiennes(f)
							end
							noeudAct = Arbre(tempDeb,tempFin,tempVecteurDernierCout,tempMatBoolC[:,indiceColonne],[])
							push!(noeud.fils,noeudAct)

							tempVecteurDernierCout = deepcopy(VecteurDernierCout) # Même variable que pour V à l'initialisation
							tempVecteurDernierCout[indiceColonne] = vecDroite[i]
							tempV = deepcopy(v)
							tempV[indicecolonne] = vecDroite[i]
							recResolutionBiObjectif(c,f,tempMatBoolC,tempV,tempVecteurDernierCout,mod(indiceColonne,8)+1, tempDeb, tempFin,BoolI,noeudAct)#modifier le f
    					end=#





						#=println(" ")
						println("indicecolonne : ", indiceColonne)
						println("deb = ", tempDeb)
						println("fin = ", tempFin)
						println("vecDroite = ", vecDroite)=#
						#=noeudAct = Arbre(tempDeb,tempFin,tempVecteurDernierCout,tempMatBoolC[:,indiceColonne],[])
						println(" ")
						println("Deb : ",noeudAct.deb)
						println("Fin : ",noeudAct.fin)
						push!(noeud.fils,noeudAct)
						if(indiceColonne != size(c)[2])
							recResolutionBiObjectif(c,f,tempMatBoolC,tempVecteurDernierCout,mod(indiceColonne,8)+1, tempDeb, tempFin,BoolI,noeudAct) #modifier le f
						end=#





function calculIntervalle(vecDroite::Array{Droite,1},deb::Rational{Int64},fin::Rational{Int64},i::Int64)
	#Calcul des intervalles en fonction des droites
	if (i==1)
		tempDeb = deb
	else
		tempI = diophentiennesToAffine(vecDroite[i])
		tempI1 = diophentiennesToAffine(vecDroite[i-1])
		tempDeb = (tempI.b - tempI1.b)//(tempI1.a - tempI.a)
	end
	if (i==size(vecDroite)[1])
		tempFin = fin
	else
		tempI = diophentiennesToAffine(vecDroite[i])
		tempI1 = diophentiennesToAffine(vecDroite[i+1])
		tempFin = (tempI.b - tempI1.b)//(tempI1.a - tempI.a)
	end

	return tempDeb,tempFin

end













#####################################################################################################################
#####################################################################################################################
#####################################################################################################################
#####################################################################################################################
#####################################################################################################################
#####################################################################################################################


include("lowerHullBound.jl")
include("droites.jl")
include("Parser.jl")

#=Entrées de la fonction :
	- c tableau de matrice des coût clients
	- f tableau de tableau des coût des entrepôts
=#

function InitialisationVarBiObjectif(c::Array{Array{Int64,2},1},f::Array{Array{Int64,1},1})
	#Initialisation de la matrice des somme pondéré de C
	cInit = Array{Droite,2}(undef,size(c[1])[1],size(c[1])[2])
	for i in 1:size(c[1])[1] #lignes
		for j in 1:size(c[1])[2] #colonnes
			if (c[2][i,j] == 0)
				c[2][i,j] = 1
			end
			if (c[1][i,j] == 0)
				c[1][i,j] = 1
			end
			if(c[1][i,j]==10000 || c[2][i,j]==10000 )
				cInit[i,j] = Droite(-1//1,-1//1,i)
			else
				temp =  Droite((c[1][i,j]-c[2][i,j]),c[2][i,j],i) # Ax + B
				cInit[i,j] = affineToDiophentiennes(temp)
			end
		end
	end

	fInit = Array{Droite,1}(undef,size(f[1])[1])
	for i in 1:size(f[1])[1]
		 temp = Droite(f[1][i]-f[2][i],f[2][i],i)
		 fInit[i] = affineToDiophentiennes(temp)
	end
#	println(" " )
#	println("pondération f : ", fInit)
#	println(" " )
#=	println(fInit)
	println(" " )=#
	#println("CInit ", cInit)


	MatBoolC = zeros(Bool,size(c[1],1),size(c[1],2)) #Matrice des coût ayant déjà été utilisé
	v = Array{Droite,1}(undef,size(cInit)[2])
	VecteurDernierCout = Array{Droite,1}(undef,size(cInit)[2]) #TODO Vérifier la taille du tableau
	BoolI = zeros(Bool,size(c[1],2))

	return cInit, fInit, MatBoolC, v, VecteurDernierCout, BoolI
end




function resolutionBiObjectif(c::Array{Array{Int64,2},1},f::Array{Array{Int64,1},1})

	function recInitResolutionBiObjectif(c::Array{Droite,2},f::Array{Droite,1},MatBoolC::Array{Bool,2},VecteurDernierCout::Array{Droite,1},indiceColonne::Int64,deb::Rational{Int64},fin::Rational{Int64},BoolI::Array{Bool,1})

		#Phase d'initialisation du coût minimum pour chaque client
		#vecDroite = convexSet(VecteurDroiteSansInf(c[:,indiceColonne]),deb,fin)
		vecDroite = convexSet(c[:,indiceColonne],deb,fin)
		#=println(" ")
		println(vecDroite)=#

		for i in 1:size(vecDroite)[1]
			tempMatBoolC = copy(MatBoolC)
			tempMatBoolC[vecDroite[i].ind,indiceColonne]= 1

			tempVecteurDernierCout = copy(VecteurDernierCout) # Même variable que pour V à l'initialisation
			tempVecteurDernierCout[indiceColonne] = vecDroite[i]
			tempDeb,tempFin = calculIntervalle(vecDroite,deb,fin,i)

			#=println("indicecolonne : ", indiceColonne)
			println("deb = ", tempDeb)
			println("fin = ", tempFin)=#
			#println("vecDroite = ", vecDroite)
#=			println(" ")
			println("Deb : ",noeudAct.deb)
			println("Fin : ",noeudAct.fin)=#

			if(indiceColonne != size(c)[2])
				recInitResolutionBiObjectif(c,f,tempMatBoolC,tempVecteurDernierCout,indiceColonne+1, tempDeb, tempFin,BoolI)
			else
				#println("Intervalle : [",tempDeb," , ",tempFin,"]")
				#println("MAtBoolCINIT : ",tempMatBoolC)
				recResolutionBiObjectif(c,f,tempMatBoolC,tempVecteurDernierCout,tempVecteurDernierCout,1, tempDeb, tempFin,BoolI)
			end
		end

	end
	function recResolutionBiObjectif(c::Array{Droite,2},f::Array{Droite,1},MatBoolC::Array{Bool,2},v::Array{Droite,1},VecteurDernierCout::Array{Droite,1},indiceColonne::Int64,deb::Rational{Int64},fin::Rational{Int64},BoolI::Array{Bool,1})

        if (all(BoolI)!=true) #Condition d'arret si tous les client sont saturé ou si tous les coût associés au service sont saturés
			#=println(" ")
			println("Colonne : ", indiceColonne)
			println("BoolI : ", BoolI)
			println("Intervalle : [",deb,";",fin,"]")=#


            if (BoolI[indiceColonne]==false)
				# recherche de l'ensemble des services minimum
				droiteSansInf = [i for i in VecteurDroiteSansInf(c[:,indiceColonne]) if MatBoolC[i.ind,indiceColonne] == false]
				#println("droiteSansInf : ",droiteSansInf )
				if(size(droiteSansInf)[1]>0)
					vecDroite = convexSet(droiteSansInf,deb,fin) # 1 argument correspond au droites != inf et pas

					#=println("F : ",f)
					println("vecDroite : ", vecDroite)=#
					servicesUtilise = [j for j in f if MatBoolC[j.ind,indiceColonne] == true]
					#vecFPlusDelta = Array{Droite,1}(undef,size(vecDroite)[1]+1)

					for i in 1:size(vecDroite)[1]
						tempMatBoolC = copy(MatBoolC)
						tempMatBoolC[vecDroite[i].ind,indiceColonne]= 1
						#=println("vecdroite[i] : ",diophentiennesToAffine(vecDroite[i]))
						println("vecDernierCout : ", diophentiennesToAffine(VecteurDernierCout[indiceColonne]))=#
						delta = SoustractionDroiteDiophentienne(vecDroite[i],VecteurDernierCout[indiceColonne])
						delta.ind = size(servicesUtilise,1)+1
						#=println("delta : ", diophentiennesToAffine(delta))

						println("servicesUtilise : ",servicesUtilise)=#

						vecFPLusDelta = vcat(servicesUtilise,delta)

						#Calcul des intervalles en fonction des droites
						tempDeb,tempFin = calculIntervalle(vecDroite,deb,fin,i)

						#println("vecFPLusDelta : ",vecFPLusDelta)
						#=println("tempDeb", tempDeb)
						println("tempFin", tempFin)=#

						#Calcul des différents deltas en fonction de f
						lowerHullVecFPLusDelta = convexSet(vecFPLusDelta,tempDeb,tempFin)

						#println("lowerHullVecFPLusDelta :", lowerHullVecFPLusDelta)

						tempVecteurDernierCout = copy(VecteurDernierCout) # Même variable que pour V à l'initialisation
						tempVecteurDernierCout[indiceColonne] = vecDroite[i]

						#println("MAtBoolC : ",MatBoolC)

						#Découpe des intervalles pour les F
						for j in 1:size(lowerHullVecFPLusDelta)[1]
							tempDebF,tempFinF = calculIntervalle(lowerHullVecFPLusDelta,tempDeb,tempFin,j)
							#=println("deb = ", tempDebF)
							println("fin = ", tempFinF)=#
							tempBoolI = copy(BoolI)
							tempV = copy(v)
							tempV[indiceColonne] = AdditionDroiteDiophentienne(v[indiceColonne],lowerHullVecFPLusDelta[j])
    						tempF = copy(f)
							for k in 1:size(f,1)
								if (MatBoolC[k,indiceColonne] == true)
									tempF[k] = SoustractionDroiteDiophentienne(f[k],lowerHullVecFPLusDelta[j])
									if(tempF[k].a == 0//1 && tempF[k].a == 0//1)
    									tempBoolI[indiceColonne] = true
										for l in 1:size(MatBoolC,2)
											if (MatBoolC[k,l]==true)
    											tempBoolI[l] = true
											end
										end
    								end
								end
							end
							recResolutionBiObjectif(c,tempF,tempMatBoolC,tempV,tempVecteurDernierCout,mod(indiceColonne,size(c,2))+1, tempDebF, tempFinF,tempBoolI)
						end

					end

				else	# étape correspondant au dernier coût possible +inf

					i = 1
                    while (MatBoolC[i,indiceColonne]==false)
						i+=1
                    end
					tempMatBoolC = copy(MatBoolC)
					tempMatBoolC[c[i,indiceColonne].ind,indiceColonne]= true

					servicesUtilise = [j for j in f if MatBoolC[j.ind,indiceColonne] == true]

					#Calcul des intervalles en fonction des droites
					tempDeb,tempFin = deb,fin
					#Calcul des différents deltas en fonction de f
					lowerHullVecFPLusDelta = convexSet(servicesUtilise,tempDeb,tempFin)

					tempVecteurDernierCout = copy(VecteurDernierCout) # Même variable que pour V à l'initialisation
					tempVecteurDernierCout[indiceColonne] = c[i,indiceColonne]

					#Découpe des intervalles pour les F
					for j in 1:size(lowerHullVecFPLusDelta)[1]
						tempDebF,tempFinF = calculIntervalle(lowerHullVecFPLusDelta,tempDeb,tempFin,j)
						#=println("debInf = ", tempDebF)
						println("finInf = ", tempFinF)=#
						tempBoolI = copy(BoolI)
						tempV = copy(v)
						tempV[indiceColonne] = AdditionDroiteDiophentienne(v[indiceColonne],lowerHullVecFPLusDelta[j])
    					tempF = copy(f)
						for k in 1:size(f,1)
							if (MatBoolC[k,indiceColonne] == true)
								tempF[k] = SoustractionDroiteDiophentienne(f[k],lowerHullVecFPLusDelta[j])
								if(tempF[k].a == 0//1 && tempF[k].a == 0//1)
    								tempBoolI[indiceColonne] = true
									for l in 1:size(MatBoolC,2)
										if (MatBoolC[k,l]==true)
    										tempBoolI[l] = true
										end
									end
    							end
							end
						end
						recResolutionBiObjectif(c,tempF,tempMatBoolC,tempV,tempVecteurDernierCout,mod(indiceColonne,size(c,2))+1, tempDeb, tempFin,tempBoolI)
					end
				end
			else
				#Peut etre rajouter un noeud
				recResolutionBiObjectif(c,f,MatBoolC,v,VecteurDernierCout,mod(indiceColonne,size(c,2))+1, deb, fin,BoolI)
			end

		else

			println("  ")
			println("Intervalle : [",deb," , ",fin,"]")
			#println("v : ",v)



		end
	end

	cInit, fInit, MatBoolC, v, VecteurDernierCout, BoolI = InitialisationVarBiObjectif(c,f)
	recInitResolutionBiObjectif(cInit,fInit,MatBoolC,VecteurDernierCout,1,0//1,1//1,BoolI)
	#return recResolutionBiObjectif(c,f,MatBoolC,v,VecteurDernierCout,indiceColonne,deb,fin,BoolI)
	#recResolutionBiObjectif()
	return 0;
end



####################################################################################################
   ############################ FONCTIONS AUXILIAIRES ##########################################
####################################################################################################


#=
-Entrée : Fonction de la forme y = ax + b
-Sortie : Fonction de la forme ax + by = 1
=#
function affineToDiophentiennes(drt::Droite)
	if(drt.b == 0//1)
		return Droite(0//1, 0//1,drt.ind)
	else
		#println("drt.a, drt.b : ",drt.a, drt.b)
		return Droite(-(drt.a)//drt.b, 1//drt.b,drt.ind)
	end
end


#=
-Entrée : Fonction de la forme ax + by = 1
-Sortie : Fonction de la forme y = ax + b
=#
function diophentiennesToAffine(drt::Droite)
 return Droite(-(drt.a / drt.b),1/drt.b,drt.ind)
end

#=
-Entrée : Vecteur de Droite
-Sortie : Vecteur de Droite sans les valeurs correspondant à +inf
=#
function VecteurDroiteSansInf(c::Array{Droite,1})
	return ([i for i in c if i.b != -1//1])
end


#=
-Entrée : Deux droites d1,d2 de la forme y = ax + b
-Sortie : Droite résultant de d1-d2
=#
function SoustractionDroite(d1::Droite,d2::Droite)
	return Droite(d1.a-d2.a,d1.b-d2.b,d1.ind)
end

#=
-Entrée : Deux droites d1,d2 de la forme y = ax + b
-Sortie : Droite résultant de d1-d2
=#
function SoustractionDroiteDiophentienne(d1::Droite,d2::Droite)
	tempd1 = diophentiennesToAffine(d1)
	tempd2 = diophentiennesToAffine(d2)
	#println("TESTTTTTT : ", Droite(tempd1.a-tempd2.a,tempd1.b-tempd2.b,tempd1.ind))
	return affineToDiophentiennes(Droite(tempd1.a-tempd2.a,tempd1.b-tempd2.b,tempd1.ind))
end

#=
-Entrée : Deux droites d1,d2 de la forme y = ax + b
-Sortie : Droite résultant de d1+d2
=#
function AdditionDroiteDiophentienne(d1::Droite,d2::Droite)
	tempd1 = diophentiennesToAffine(d1)
	tempd2 = diophentiennesToAffine(d2)
	return affineToDiophentiennes(Droite(tempd1.a+tempd2.a,tempd1.b+tempd2.b,tempd1.ind))
end


function calculIntervalle(vecDroite::Array{Droite,1},deb::Rational{Int64},fin::Rational{Int64},i::Int64)
	#Calcul des intervalles en fonction des droites
	if (i==1)
		tempDeb = deb
	else
		tempI = diophentiennesToAffine(vecDroite[i])
		tempI1 = diophentiennesToAffine(vecDroite[i-1])
		tempDeb = (tempI.b - tempI1.b)//(tempI1.a - tempI.a)
	end
	if (i==size(vecDroite)[1])
		tempFin = fin
	else
		tempI = diophentiennesToAffine(vecDroite[i])
		tempI1 = diophentiennesToAffine(vecDroite[i+1])
		tempFin = (tempI.b - tempI1.b)//(tempI1.a - tempI.a)
	end

	return tempDeb,tempFin

end


####################################################################################################
	############################### FONCTION TEST #############################################
####################################################################################################

function main()
#=	c1 = [[10,50,70] [20,10,30] [10,10,90] [40,10000,60]]
	c2 = [[30,80,10] [60,80,20] [10000,10,70] [40,20,10]]
	c = [c1,c2]
	f1 = [10,7,4]
	f2 = [12,8,7]
	f = [f1,f2]=#
	@time c,f = parser("F50-51.txt")
	@time resolutionBiObjectif(c,f)

end


function main2()
	f1::Vector{Int64} = [12,10]
    c1::Matrix{Int64} = [70 50 30;
                         40 10 70]
    f2::Vector{Int64} = [7,9]
    c2::Matrix{Int64} = [20 10 50;
                         40 90 100]
	c = [c1,c2]
	f = [f1,f2]
	@time resolutionBiObjectif(c,f)

end





