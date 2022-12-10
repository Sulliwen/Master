
mutable struct Droite
    a::Rational{Int64}
    b::Rational{Int64}
	ind::Int64
end # Une droite est représentée par une équation de la forme ax + by = 1

# Début Convex hull (code modifié à partir d'une source sur internet à retrouver...)
mutable struct Point
    x::Rational{Int64}
    y::Rational{Int64}
    ind::Int64
end

function Base.isless(p::Point, q::Point)
    p.x < q.x || (p.x == q.x && p.y < q.y)
end

function isrightturn(p::Point, q::Point, r::Point)
    (q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x) < 0
end

function grahamscan(points::Vector{Point})
    sort!(points)
    upperhull = halfhull(points)
    lowerhull = halfhull(reverse(points))
    [upperhull..., lowerhull[2:end-1]...]
end

function halfhull(points::Vector{Point})
    halfhull = points[1:2]
    for p in points[3:end]
        push!(halfhull, p)
        while length(halfhull) > 2 && !isrightturn(halfhull[end-2:end]...)
            deleteat!(halfhull, length(halfhull) - 1)
        end
    end
	return halfhull
end
#Fin convex hull

# Détermination d'une enveloppe inférieure de droite sur le segment [deb,fin] (En réalité, [deb - tol,fin])
# Entrées : Vecteur de droites (dont on veut calculer l'enveloppe inférieure), deb, fin, tol
# Sortie : Vecteur de droites (définissant l'enveloppe inférieure dans l'ordre)
function lowerHull(Lc::Vector{Droite}, deb::Rational{Int64}, fin::Rational{Int64}, tol::Rational{Int64})
    i::Int64 = 0
    nbPts::Int64 = length(Lc) + 3 # Nombres de points utilisés pour le calcul d'enveloppe convexe incluant les trois points "dummy"
    P::Vector{Point} = Vector{Point}(undef,nbPts)
    Lmod::Vector{Droite} = Vector{Droite}(undef,length(Lc)) # Vecteur de Droites dont les équations sont modifiées par le changement de repère
    Lr::Vector{Droite} = Vector{Droite}(undef,0) # Vecteur de Droites qui sera retourné par l'algorithme
	chgOK::Bool = true

    # Changement de repère (x' = x - deb <==> x = x' + deb)
    c::Rational{Int64} = 0
    for i in 1:length(Lc)
        # On a donc ax + by = 1 <==> ax' + by = c où c = 1 - a*deb
        # donc (a/c)x' + (b/c)y = 1
        c = 1 - Lc[i].a * deb
		if (c == 0//1)
			 deb = deb + 2 * tol
			 chgOK = false
			 break
		end
		#println("c : ",c)
        Lmod[i] = Droite(Lc[i].a//c,Lc[i].b//c,Lc[i].ind)
    end

	if (!chgOK)
    	for i in 1:length(Lc)
     	   # On a donc ax + by = 1 <==> ax' + by = c où c = 1 - a*deb
       	 # donc (a/c)x' + (b/c)y = 1
        	c = 1 - Lc[i].a * deb
	        Lmod[i] = Droite(Lc[i].a//c,Lc[i].b//c,Lc[i].ind)
		end
    end
    # Association des points duaux aux droites
  	for i in 1:length(Lmod)
        P[i] = Point(Lmod[i].a,Lmod[i].b,i)
  	end # Boucle d'instanciation des points "légitimes"
    n::Int64 = length(Lmod)
    P[n+1] = Point(-1//tol,0,n+1) # Point "dummy" associé à la droite d'équation x = - tol soit (-1/tol)x = 1
    P[n+2] = Point(1//(fin - deb),0,n+2) # Point "dummy" associé à la droite d'équation x = fin - deb soit (1/(fin-deb))x = 1
    P[n+3] = Point(0,-1,n+3) # Point "dummy" associé à la droite d'équation -y = 1 soit y = -1

    #@show P


  	PF::Vector{Point} = grahamscan(P) # PF contient les points qui ne sont pas situés à l'intérieur de l'enveloppe convexe

    # Transformation en points en droites
    i = 1
    while (PF[i].ind > n)
        i += 1
    end # On saute les dummy points
    while (i <= length(PF)) && (PF[i].ind <= n) # On s'arrête aux dummy points
        push!(Lr,Lc[PF[i].ind])
        i += 1
    end
    return Lr
end

# Petit test sur un exemple simple
function essai()
    Lc::Vector{Droite} = [Droite(0,1//6,1),Droite(0,1//4,2),Droite(-1,1//3,3),Droite(1//2,1//6,4),Droite(7//8,1//8,5)]
    return lowerHull(Lc,1//2,1//1,1//10) # Le calcul se fait ici sur l'intervalle [1/2,1], le 1/10 correspond au fait qu'on utilise la droite x = 1/2-1/10 pour borner le polytope
end
