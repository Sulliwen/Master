include("droites.jl")
include("Parser.jl")

mutable struct Arbre
	deb::Rational{Int64}
	fin::Rational{Int64}
	v::Array{Droite,1}
	VecteurDernierCout::Array{Droite,1}
	MatBoolC::Array{Bool,2}
	fils::Array{Arbre,1}
end

#=Entrées de la fonction :
	- c tableau de matrice des coût clients
	- f tableau de tableau des coût des entrepôts
=#
function InitialisationVarBiObjectif(c,f)
	#Initialisation de la matrice des somme pondéré de C
	cInit = Array{Droite,2}(undef,size(c[1])[1],size(c[1])[2])
	for i in 1:size(c[1])[1] #lignes
		for j in 1:size(c[1])[2] #colonnes
			if(c[1][i,j]==0)
				c[1][i,j]=1
			end
			if(c[2][i,j]==0)
				c[2][i,j]=1
			end
			temp =  Droite((c[1][i,j]-c[2][i,j]),c[2][i,j],i) # Ax + B
			cInit[i,j] = temp

		end
	end

	fInit = Array{Droite,1}(undef,size(f[1])[1])
	for i in 1:size(f[1])[1]
		 temp = Droite(f[1][i]-f[2][i],f[2][i],i)
		 fInit[i] = temp
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
	function recInitResolutionBiObjectif(c::Array{Droite,2},f::Array{Droite,1},MatBoolC::Array{Bool,2},VecteurDernierCout::Array{Droite,1},indiceColonne::Int64,deb::Rational{Int64},fin::Rational{Int64},BoolI::Array{Bool,1},noeud::Arbre)

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
			noeudAct = Arbre(tempDeb,tempFin,tempVecteurDernierCout,tempVecteurDernierCout,tempMatBoolC,[])
			#=println(" ")
			println("Deb : ",noeudAct.deb)
			println("Fin : ",noeudAct.fin)=#

			push!(noeud.fils,noeudAct)
			if(indiceColonne != size(c)[2])
				recInitResolutionBiObjectif(c,f,tempMatBoolC,tempVecteurDernierCout,indiceColonne+1, tempDeb, tempFin,BoolI,noeudAct)
			else
				#println("MatBoolCINIT : ",tempMatBoolC)

				recResolutionBiObjectif(c,f,tempMatBoolC,tempVecteurDernierCout,tempVecteurDernierCout,1, tempDeb, tempFin,BoolI,noeudAct)
			end
		end

	end
	function recResolutionBiObjectif(c::Array{Droite,2},f::Array{Droite,1},MatBoolC::Array{Bool,2},v::Array{Droite,1},VecteurDernierCout::Array{Droite,1},indiceColonne::Int64,deb::Rational{Int64},fin::Rational{Int64},BoolI::Array{Bool,1},noeud::Arbre)

        if (all(BoolI)!=true) #Condition d'arret si tous les client sont saturé ou si tous les coût associés au service sont saturés
			#=println(" ")
			println("Colonne : ", indiceColonne)
			println("BoolI : ", BoolI)
			println("Intervalle : [",deb,";",fin,"]")=#


            if (BoolI[indiceColonne]==false)
				# recherche de l'ensemble des services minimum
				droiteSansInf = [i for i in c[:,indiceColonne]if MatBoolC[i.ind,indiceColonne] == false]
				#println("droiteSansInf : ",droiteSansInf )
				if(size(droiteSansInf)[1]>0)
					vecDroite = convexSet(droiteSansInf,deb,fin) # 1 argument correspond au droites != inf et pas

					#=println("F : ",f)
					println("vecDroite : ", vecDroite)=#
					servicesUtilise = [j for j in f if MatBoolC[j.ind,indiceColonne] == true]
					#vecFPlusDelta = Array{Droite,1}(undef,size(vecDroite)[1]+1)

					for i in 1:size(vecDroite)[1]
						delta = SoustractionDroite(vecDroite[i],VecteurDernierCout[indiceColonne])
						delta.ind = size(servicesUtilise,1)+1
						#println("delta : ", delta)

						vecFPLusDelta = vcat(servicesUtilise,delta)

						#Calcul des intervalles en fonction des droites
						tempDeb,tempFin = calculIntervalle(vecDroite,deb,fin,i)

						#println("vecFPLusDelta : ",vecFPLusDelta)
						#=println("tempDeb", tempDeb)
						println("tempFin", tempFin)=#

						#Calcul des différents deltas en fonction de f
						lowerHullVecFPLusDelta = convexSet(vecFPLusDelta,tempDeb,tempFin)

						#println("lowerHullVecFPLusDelta :", lowerHullVecFPLusDelta)

						tempVecteurDernierCout = copy(VecteurDernierCout)
						tempVecteurDernierCout[indiceColonne] = vecDroite[i]

						#println("MAtBoolC : ",MatBoolC)

						#Découpe des intervalles pour les F
						for j in 1:size(lowerHullVecFPLusDelta)[1]
							tempMatBoolC = copy(MatBoolC)
							tempDebF,tempFinF = calculIntervalle(lowerHullVecFPLusDelta,tempDeb,tempFin,j)
							tempBoolI = copy(BoolI)
							tempV = copy(v)
							tempV[indiceColonne] = AdditionDroite(v[indiceColonne],lowerHullVecFPLusDelta[j])
    						tempF = copy(f)
							for k in 1:size(f,1)
								if (MatBoolC[k,indiceColonne] == true)
									tempF[k] = SoustractionDroite(f[k],lowerHullVecFPLusDelta[j])
									if(tempF[k].a == 0//1 && tempF[k].b == 0//1)
    									tempBoolI[indiceColonne] = true
										for l in 1:size(MatBoolC,2)
											if (MatBoolC[k,l]==true)
    											tempBoolI[l] = true
											end
										end
    								end
								end
							end
							if ((lowerHullVecFPLusDelta[j].a == delta.a) && (lowerHullVecFPLusDelta[j].b == delta.b))
								tempMatBoolC[vecDroite[i].ind,indiceColonne]= 1
							end
							recResolutionBiObjectif(c,tempF,tempMatBoolC,tempV,tempVecteurDernierCout,mod(indiceColonne,size(c,2))+1, tempDebF, tempFinF,tempBoolI,noeud)
						end
					end
				end
			else
				#Peut etre rajouter un noeud
				recResolutionBiObjectif(c,f,MatBoolC,v,VecteurDernierCout,mod(indiceColonne,size(c,2))+1, deb, fin,BoolI,noeud)
			end
		else
			noeudAct = Arbre(deb,fin,v,VecteurDernierCout,MatBoolC,[])
			push!(noeud.fils,noeudAct)
			println("Intervalle : [",deb," , ",fin,"]")
			println("  ")
		end
	end




	cInit, fInit, MatBoolC, v, VecteurDernierCout, BoolI = InitialisationVarBiObjectif(c,f)

	noeud = Arbre(0//1,1//1,VecteurDernierCout,VecteurDernierCout,MatBoolC,[])
	recInitResolutionBiObjectif(cInit,fInit,MatBoolC,VecteurDernierCout,1,0//1,1//1,BoolI,noeud)
	return noeud
end


####################################################################################################
   ############################ FONCTIONS AUXILIAIRES ##########################################
####################################################################################################


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
-Sortie : Droite résultant de d1+d2
=#
function AdditionDroite(d1::Droite,d2::Droite)
	return Droite(d1.a+d2.a,d1.b+d2.b,d1.ind)
end


function calculIntervalle(vecDroite::Array{Droite,1},deb::Rational{Int64},fin::Rational{Int64},i::Int64)
	#Calcul des intervalles en fonction des droites
	if (i==1)
		tempDeb = deb
	else
		tempI = vecDroite[i]
		tempI1 = vecDroite[i-1]
		tempDeb = (tempI.b - tempI1.b)//(tempI1.a - tempI.a)
	end
	if (i==size(vecDroite)[1])
		tempFin = fin
	else
		tempI = vecDroite[i]
		tempI1 = vecDroite[i+1]
		tempFin = (tempI.b - tempI1.b)//(tempI1.a - tempI.a)
	end

	return tempDeb,tempFin

end

function afficherSol(noeud::Arbre)
	liste = []
	getFeuilles(noeud, liste)
	println(liste)
	ll::Vector{Droite} = []
	resp = []
	x = []
	y = []
	for l in liste
		push!(x,l[1]*l[2])
		push!(y,l[1]*(1-l[2]))
	end
	println(x)
	println(y)
	display(scatter(x,y,label="p"))
end

function getFeuilles(abr::Arbre, liste)
	if abr.fils == []
#=		println("abr.matBoolC : ",abr.MatBoolC)
		println("deb : ",abr.deb)
		println("Fin : ",abr.fin)
		println(" ")=#
		push!(liste,abr)
	else
		for f in abr.fils
			getFeuilles(f, liste)
		end
	end
end


function CalculSolutionPrimal(noeud::Arbre,c::Array{Array{Int64,2},1},f::Array{Array{Int64,1},1},cInit::Array{Droite,2})

	feuilles::Array{Arbre,1} = []
	getFeuilles(noeud,feuilles)
	tabResult = []

	for j in 1:size(feuilles,1)
		#println(" ")
    	serviceAssocieClient = Array{Int64,1}(undef,size(c[1],2))
		ensembleServiceUtilise=Set{Int64}()

		for i in 1:size(c[1],2)
			servicesUtilise = [k for k in cInit[:,i] if feuilles[j].MatBoolC[k.ind,i] == true]
			#println("convexSet : ", convexSet(servicesUtilise,feuilles[j].deb,feuilles[j].fin))
			serviceAssocieClient[i] = convexSet(servicesUtilise,feuilles[j].deb,feuilles[j].fin)[1].ind
			union!(ensembleServiceUtilise,serviceAssocieClient[i])
		end

		#println("ensembleServiceUtilise : ", ensembleServiceUtilise )
		#println("serviceAssocieClient : ", serviceAssocieClient )

		sommeServicesC1 = 0
		sommeServicesC2 = 0
		for i in ensembleServiceUtilise
			sommeServicesC1 += f[1][i]
			sommeServicesC2 += f[2][i]
		end
		sommeClientServicesC1 = 0
		sommeClientServicesC2 = 0
		j = 1
		for i in serviceAssocieClient
			sommeClientServicesC1 += c[1][i,j]
			sommeClientServicesC2 += c[2][i,j]
			j=j+1
		end
		p1 = sommeServicesC1 + sommeClientServicesC1
		p2 = sommeServicesC2 + sommeClientServicesC2
		#println("p1 : ",p1)
		#println("p2 : ",p2)
		push!(tabResult,(p1,p2))
	end
	x = [tabResult[i][1] for i in 1:length(tabResult)]
	y = [tabResult[i][2] for i in 1:length(tabResult)]
	return (x,y)
end



function CalculSolutionDual(noeud::Arbre)
	feuilles::Array{Arbre,1} = []
	getFeuilles(noeud,feuilles)
	tabRes::Array{Droite,1} = []
	res::Droite = Droite(0//1,0//1,1)

	for i in 1:size(feuilles,1)
		sommeDroite::Droite = Droite(0//1,0//1,1)
		for j in feuilles[i].v
			sommeDroite = AdditionDroite(sommeDroite,j)
		end
		#=y = Rational(sommeDroite.a * feuilles[i].deb + sommeDroite.b)//Rational(1-feuilles[i].deb)
		res.b = y
		res.a = -feuilles[i].deb//Rational(1-feuilles[i].deb)=#
		push!(tabRes,sommeDroite)
	end

	return tabRes
end


####################################################################################################
	############################### FONCTION TEST #############################################
####################################################################################################


function main()
	c1 = [[10,50,70] [20,10,30] [10,10,90] [40,10000,60]]
	c2 = [[30,80,10] [60,80,20] [10000,10,70] [40,20,10]]
	c = [c1,c2]
	f1 = [10,7,4]
	f2 = [12,8,7]
	f = [f1,f2]
	#c,f = parser("F50-51.txt")
	@time noeudRes = resolutionBiObjectif(c,f)
	TupleRes = CalculSolutionDual(noeudRes)
	return TupleRes

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
	noeudRes = resolutionBiObjectif(c,f)

	return CalculSolutionDual(noeudRes)

end
