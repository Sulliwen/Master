include("Ascent.jl")




####################################################################################################################
######################################## DUAL ADJUSTMENT ###########################################################
####################################################################################################################


function dualAdjustment(c, v, s, MatBoolC, VecteurDernierCout, BoolI)
	println("Début adjustment")
	tempRes = sum(v) #résultat de l'itération précédente
#=	println("v : ", v)
	println("size v : ", length(v))=#

	#tempV : variable comportant les valeur Vj de l'itération précédante
	#tempS : variable comportant les valeur Si de l'itération précédante
	tempV = deepcopy(v)
	tempS = deepcopy(s)


	IstarJ = Array{Array{Int64,1},1}(undef,length(v)) #I*j
	IplusJ = Array{Array{Int64,1},1}(undef,length(v))


	res = sum(v)
	tempRes -= 1

	cpttest = 0
	while (tempRes < res)
		tempV = deepcopy(v)
		tempS = deepcopy(s)
		cpttest += 1
		println(" ")
		println("------------------------------- ")
		println("----------- itération ", cpttest,"-----------")
		println("------------------------------- ")
		JplusI = [(1,[])]
		Iplus = [] #I+
		Istar = [] #I*
		for i in 1:length(v)
			IstarJ[i] = []
			IplusJ[i] = []
		end

#=		println("s : ",s)
		println("v :", v)
		println("c : ", c)
		println("IplusJ", IplusJ)=#


		# Calcul des I*   							OK!!!!!!!
		for i in 1:length(s)
			if (s[i]==0)
				Istar = union(Istar, i)
				for j in 1:length(v)
					if(c[i,j] <= v[j])
	    				IstarJ[j] = union(IstarJ[j], i)
					end
				end
			end
		end

		# Calcul des I+ (y'en a potentiellement plusieurs)
		tabIplus = zeros(Bool,length(Istar),length(v))
		k = 1
		for i in Istar
			for j in 1:length(v)
				if(c[i,j] <= v[j])
					tabIplus[k,j] = 1
				end
			end
			k+=1
		end

		#println("tabIplus : ",tabIplus)

		#= Notes
		[
		[1,1,0,1,1]
		[1,0,0,1,1]
		[1,1,0,0,1]
		]
		for i in tabIplus[]
			for
			IplusPossibles = [{1,2}, {1,3}, {1,2,3}]
			IplusPossibles = [{1,2,3}]
			IplusPossibles = [{2,3}]

		Iplus = IplusPossibles[1]
		=#

		nbIplusPoss = factorial(length(Istar)) # nombre de combinaisons de lignes possibles = ?
		IplusPossibles = Vector{Vector{Int64}}(undef,nbIplusPoss)
		k = 1
		for i in 1:length(Istar)
			for j in i+1:length(Istar)
				if tabIplus[i,:].|tabIplus[j,:] == ones(Bool,length(v)) # si [11010011] | [10111111] == [11111111]
					IplusPossibles[k] = [Istar[i],Istar[j]]
					k+=1
				end
			end
		end

		Iplus = IplusPossibles[1]

		for i in Iplus
			for j in 1:length(v)
				if(c[i,j] < v[j])
    				#println(c[i,j])
					IplusJ[j] = union(IplusJ[j], i)
					Iplus = union(Iplus, i)
				end
			end
		end

#=		println("--------------------------------------------------")
		println("--------------------------------------------------")
		println("IstarJ : ", IstarJ)
		println("Istar : ", Istar)
		println("IplusJ : ", IplusJ)
		println("Iplus : ", Iplus)
		println("--------------------------------------------------")
		println("--------------------------------------------------")=#


		#Vérification si un |I+j|>1 									OK!!!!!!!!!!!!!!
		Ibool = false #Ibool donne l'indication si un |IplusJ| > 1
		indice = 1
		while (Ibool == false && indice < length(IplusJ))
			if(length(IplusJ[indice]) <= 1)
				indice += 1
			else
				Ibool = true
			end
		end

		#println("Iboolice :", Ibool,indice)

		if (Ibool == true)
			#println("IplusJ[indice,1] : ", IplusJ[indice,1][1])
			JplusI[1] = ((IplusJ[indice,1][1]),[])
			for i in 2:size(IplusJ[indice],1)
				push!(JplusI,(IplusJ[indice,1][i],[]))
			end
			#println("IstarJ : ",IstarJ)
			for i in 1:length(IplusJ[indice,1])
				for j in 1:length(IstarJ)
					if (IstarJ[j] == [IplusJ[indice,1][i]]) # on vérifie si I*(j) ne contient qu'une valeur et que cette valeur est = 0
						JplusI[i] = (JplusI[i][1],union(JplusI[i][2],j))   #horrible à implémenter     OK!!!!!!!
					end
				end
			end
			#println("indice : ",indice)
			#println("Debut retour en arrière")
			# Retour en arrière sur le dualAscent (Backtracking)
			#println("findmax ",findmax([c[x,indice] for x in 1:length(s) if(MatBoolC[x,indice]==true)])[2])
			MatBoolC[findmax([c[x,indice] for x in 1:length(s) if(MatBoolC[x,indice]==true)])[2],indice] = false  # problème doublons colonne
			#println("matboolC : ",MatBoolC)
			maxValIndiceDeux = findmax([c[x,indice] for x in 1:length(s) if(MatBoolC[x,indice]==true)])[1]
			VecteurDernierCout[indice] = maxValIndiceDeux
			delta = v[indice]-maxValIndiceDeux
			v[indice] -= delta

			for i in 1:length(s)
				if(MatBoolC[i,indice] == true)
					s[i] += delta
				end
			end
			Jplus = []
			#println("JplusI : ", JplusI)
            for i in 1:length(JplusI)
				Jplus = union(JplusI[i][2],Jplus)
            end

			#println("Jplus : ", Jplus)

			BoolI = zeros(Bool,size(c,2)) # Ré-Initialisation du BoolI
			#Mise à jour du BoolI après le retour en arrière
			for i in 1:length(s)
				if (s[i] == 0)
    				for j in 1:length(v)
						if(MatBoolC[i,j]==1)
    						BoolI[j] == true
						end
					end
				end
			end
			for j in 1:length(v)
				if(all(MatBoolC[:,j]) == true)
    				BoolI[j] = true
				end
			end

			#println("BoolI : ", BoolI)
			#println("Fin retour en arrière")
			# Fin du retour en arrière
			println("MatBoolC:", MatBoolC)
			println("BoolI : ", BoolI)
			println("TempS : ", s)
			println("TempV : ", v)
			println("VectDernierCout : ", VecteurDernierCout)
			println("JplusI : ", JplusI)
			println("----------------------------")



			v, s, MatBoolC, VecteurDernierCout, BoolI = dualAscentPourAdjustment(c,s,v, MatBoolC, VecteurDernierCout, BoolI , Jplus)

			println("----------------------------")
			println("MatBoolC:", MatBoolC)
			println("BoolI : ", BoolI)
			println("TempS : ", s)
			println("TempV : ", v)
			println("VectDernierCout : ", VecteurDernierCout)


			tempRes = res
			res = sum(v)
#=			println("tempres : ", tempRes)
			println("res : ", res)=#
		else
			println("problème résolu à l'optimalité")
			res = tempRes
		end

	end
	println("sortie programme")
	println("TempRes : ", tempRes)

	return tempV, tempS
end


