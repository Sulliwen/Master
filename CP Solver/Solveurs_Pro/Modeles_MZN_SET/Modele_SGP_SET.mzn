
include "alldifferent.mzn";

% PARAMETRES
int: s;
int: k; % nombre de joueurs par groupe
int: p;

%brise symmetries
bool: a1; % brise symmetrie d'assertion 1: on fixe la premiere semaine
bool: a2; % brise symmetrie d'assertion 2: on fixe le 1er joueur des p premiers groupes de chaque semaine
bool: o1; % brise symmetrie d'ordre 1: les groupes sont ordonnés par leur indice de joueur minimum croissant
bool: o2; % brise symmetrie d'ordre 2: les semaines sont ordonnées selon l'indice du joueur second minimum de leur premier groupe

%surcontraintes
bool: sc1 = false;
bool: sc2 = false;

int : n = k*p;  % nombre total de golfeurs

int : groups = s*k; % nombre total de groupes

set of int: S = 1..s;             % ensemble des semaines
set of int: K = 1..k;           % ensemble des groupes dans une semaine
set of int: G = 1..(p*k); % ensemble des joueurs

array[S,K] of var set of G: A; % matrice de groupes

% autre modele possible: chaque joueur est une variable ensembliste
% -----------------------------------------
% Contraintes de faisabilité de l'instance
% -----------------------------------------
% -- Quelques contraintes "triviales" pour aider le solveur à rapidement sonder par infaisabilité

% Si s > 1, on doit avoir plus de groupes que de joueurs par groupe
%constraint if s > 1 then (p <= k) endif;
% On doit s'assurer qu'il y a assez de joueurs pour que, à chaque semaine, un joueur rencontre p-1 nouveaux joueurs
%constraint (s*(p-1)<=n);
% + d'autres ?

% -- Contraintes SGP
% On contraint la taille des groupes
constraint forall(sem in S, g in K)(card(A[sem,g]) = p); 
% Contrainte d'affectation bijective groupe/joueur: chaque semaine, un joueur ne peut jouer que dans un unique groupe
constraint forall(sem in S, g1 in K, g2 in K where g1!=g2)(card(A[sem,g1] intersect A[sem,g2]) = 0); 
% Contrainte de sociabilité: chaque pair de groupes doit avoir au plus un joueur en commun
constraint forall(s1 in S, s2 in S , k1 in K, k2 in K where s1!=s2)(card(A[s1,k1] intersect A[s2,k2]) <= 1);

% -- Contraintes brise-symmetrie (assertions)
% On assert la semaine 1 (a1)
constraint forall(g in K)(if a1 then A[1,g] = ((g-1)*p)+1..((g-1)*p)+p else true endif);
% On fixe les 1er joueurs des p premiers groupes (a2)
constraint forall(w in 1..s, i in 1..p)(if (a2 /\ not a1) then i in A[w,i] else true endif);
constraint forall(w in 2..s, i in 1..p)(if (a2 /\ a1) then i in A[w,i] else true endif);

% + d'autres contraintes pour améliorer la propagation ?

% Surcontrainte 1: On fixe le premier joueur des k groupes de chaque semaine
constraint forall(w in 2..s, i in 1..k)(if sc1 then i in A[w,i] else true endif);
% Surcontrainte 2: On fixe le 1er groupe de la 2eme semaines
constraint forall(i in K)(if sc2 then ((i-1)*p + 1) in A[2,1] else true endif);

% -- Contraintes brise-symmetrie (ordre)
% Ordre 0: intra groupe   (Les joueurs sont rangés par ordre croissant dans chaque groupe (non applicable avec les ensembles))
% Ordre 1: inter groupes  (Les joueurs d'indice les plus petits de chaque groupe sont rangés par ordre croissant (diminue drastiquement le temps de res))
constraint forall(sem in S, i in 1..(k-1))(if o1 then min(A[sem,i]) < min(A[sem,i+1]) else true endif);
% Ordre 2: inter semaines (Les joueurs d'indice les seconds plus petits de chaque semaine sont rangés par ordre croissant (augmente drastiquement le temps de res...)
constraint forall(i in 1..(s-1))(if o2 then min(A[i,1] diff min(A[i,1])..min(A[i,1])) < (min(A[i+1,1] diff min(A[i+1,1])..min(A[i+1,1]))) else true endif);

solve satisfy;
