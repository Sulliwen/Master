#!/usr/bin/env julia

#using Plots

mutable struct Droite
	a::Rational{Int64}
	b::Rational{Int64}
	ind::Int64
end # Une droite est représentée par une équation de la forme y = ax + b

mutable struct Point
	x::Rational{Int64}
	y::Rational{Int64}
	ind::Int64
end

a1 = [10 20 10 40 ; 50 10 10 10000 ; 70 30 90 60]
a2 = [30 60 10000 40 ; 80 80 10 20 ; 10 20 70 10]

p1 = [2, 4, 1, 5, 3, 6]
p2 = [3, 2, 6, 5, 5, 2]

pt1 = [162, 212, 132, 172, 142, 182, 102, 130]
pt2 = [87, 146, 176, 226, 116, 166, 196, 239]

pp1 = [10, 50, 40, 70, 10]
pp2 = [30, 80, 60, 10, 50]

#=function nonDomines(p1::Vector{Int64}, p2::Vector{Int64})
	p::Vector{Droite} = []
	println(size(p))
	println(p1)
	println(p2)
	pnd = []  # points
	en::Vector{Droite} = []
	sp = sortperm(p1) # sort points
	ind = sp[1] # indice
	last = p2[ind]
	push!(pnd, (p1[ind], p2[ind], ind))
	delta = p1[ind] - p2[ind]
	push!(p,Droite(delta,p2[ind],ind))
	push!(en,Droite(delta,p2[ind],ind))
	for i in 2:length(p1)
		ind = sp[i]
		if p2[ind] < last
			last = p2[ind]
			push!(pnd, (p1[ind], p2[ind], ind))
			delta = p1[ind] - p2[ind]
			push!(p,Droite(delta,p2[ind],ind))
			println(Droite(delta,p2[ind],ind))
		end
		delta = p1[ind] - p2[ind]
		push!(en,Droite(delta,p2[ind],ind))
	end
	println(pnd)
	compareDroites(p,en)
	return p
end

function compareDroites(droites::Array{Droite}, ens::Array{Droite})#, pts::Vector{Point})
	p = plot()
	pp = plot()
	println(droites)
	println(ens)
	for d in ens
		color = :grey11
		for dd in droites
			if dd.a == d.a && dd.b == d.b
				color = :auto
			end
		end
		x = [0,1]
		y = [d.b, d.a + d.b]
		display(plot!(p, x, y, ylims=(0,300), label=d.id, linecolor=color))
	end
	#display(plot!(p, [pt.x for pt in pts], [pt.y for pt in pts]))
end=#

function convexSet(droites::Vector{Droite}, borneInf::Rational{Int64}, borneSup::Rational{Int64})
	#droites = [diophentiennesToAffine(i) for i in droites]
	#println(droites)
	convex::Vector{Droite} = [] # vecteur solution
	dmin::Droite = droites[1]
	pmin = dmin.a * borneInf + dmin.b
	# droite avec la plus petite ordonnée à l'origine
	for d in droites
		if d.a * borneInf + d.b <= pmin
			if d.a * borneInf + d.b != pmin
				dmin = d					#ensemble de droite min avec la plus petite ordonnée à l'origine?
				pmin = d.a * borneInf + d.b
			else
				if d.a < dmin.a
    				dmin = d
					pmin = d.a * borneInf + d.b
				end
			end
		end
	end
	#println(dmin)
	push!(convex, dmin)
	pointSet::Vector{Point} = []
	select::Vector{Bool} = fill(true, length(droites)) # array boolean, true si on prend la droite
	select = triDroites(select, droites, dmin, borneSup)
	#println(select)
	while any(select) # boucler tant qu'il y a une droite qui intersecte
		pti = [intersection(dmin, droites[i], i) for i in 1:length(droites) if select[i]] # points d'intersection sur la droite donnée
		pmin = pti[1]
		# trouver le point minimum
		for p in pti
			if p.y < pmin.y
				pmin = p
			end
		end
		push!(pointSet, pmin)
		dmin = droites[pmin.ind] # droite de l'intersection
		#println(dmin)
		push!(convex, dmin)
		select = triDroites(select, droites, dmin, borneSup)
		#println(select)
	end
	#afficherDroites(droites, pointSet, borneInf, borneSup)
	#convex = [affineToDiophentiennes(i) for i in convex]
	return convex
end

# retourne les droites qui peuvent servir, plus inclines que la droite courante
# droites, l'ensemble des droites a calculer
# d, droite à comparer
function triDroites(ar::Vector{Bool}, droites::Vector{Droite}, d::Droite, borne::Rational{Int64})
	for i in 1:length(droites)
		if ar[i]
			if droites[i].a * borne + droites[i].b >= d.a * borne + d.b
				ar[i] = false
			end
		end
	end
	return ar
end

function intersection(d1::Droite, d2::Droite, ind::Int64)
	x = (d1.b - d2.b) / (d2.a - d1.a)
	y = d1.a * x + d1.b
	return Point(x, y, ind)
end

function afficherDroites(droites::Vector{Droite}, pts::Vector{Point}, borneInf::Rational{Int64}, borneSup::Rational{Int64})
	for p in pts
		#println("x:",p.x)
	end
	plt = plot()
	for d in droites
		#x = [0,1]
		#y = [d.b, d.a + d.b]
		x = [borneInf, borneSup]
		y = [d.a * borneInf + d.b, d.a * borneSup + d.b]
		lab = string(d.ind, " ", numerator(d.a), " ", numerator(d.b))
		display(plot!(plt, x, y, label=lab))#,xlims=(borneInf,borneSup)))#, ylims=(0,300), label=lab))
	end
	ptx = [pt.x for pt in pts] # abscisses des points
	pty = [pt.y for pt in pts] # ordonnées des points
	display(scatter!(plt, ptx, pty, markershape=:circle, markersize=4, c=:black, label="I"))
end

#d = calculDroites(a1,a2)
#p = calculIntersections(d[:,1])
#afficherDroites(d[:,1], p)

#en = calculDroites(pt1,pt2)
#p = nonDomines(a1[:,1],a2[:,1])
#nonDomines(pt1,pt2)

function calcDroites(p1::Vector{Int64}, p2::Vector{Int64})
	droites::Vector{Droite} = [] # droites correspondantes
	for i in 1:length(p1)
		delta = p1[i] - p2[i]
		push!(droites, affineToDiophentiennes(Droite(delta,p2[i],i)))
	end
	return droites
end

#droites = calcDroites(pt1,pt2)
#convexSet(droites,0.5,0.75)

 function afficherArbre(abr, file)
 	#s = string("[\\text{[", round(float(abr.deb),digits = 2), ";", round(float(abr.fin),digits = 2), "]}\n")
 	s = string("[\\text{[", abr.deb, ";", abr.fin, "]}\n")
 	#println(s)
 	write(file, s)
 	for f in abr.fils
 		afficherArbre(f, file)
 	end
 	#println("]")
 	write(file, "]\n")
 end

#=
function afficherArbre(abr, file)
	#s = string("[\\text{[", round(float(abr.deb),digits = 2), ";", round(float(abr.fin),digits = 2), "]}\n")
	s = string("[\\text{[", abr.deb, ";", abr.fin, "]}\n")
	#println(s)
	if abr.fils == []
		write(file, s)
		write(file, "]\n")
	end
	for f in abr.fils
		afficherArbre(f, file)
	end
	#println("]")
end=#
