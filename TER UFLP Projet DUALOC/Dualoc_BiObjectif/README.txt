Le dossier courant Dualoc_BiObjectif contient un ensemble de fichiers relatif à la résolution du problème UFLP biobjectif.


Le fichier Parser.jl contient une fonction parser qui prend en paramètre une instance et retourne les matrices des coûts des 2 objectifs avec les vecteurs de coûts d'ouverture des services.

Le fichier droites.jl contient les fonctions utiles au calcul de l'enveloppe inférieure.

Le ficher lowerHullBound.jl contient aussi une autre approche pour calculer l'enveloppe inférieure

Les fichiers Multi_criteres contiennent la fonction resolutionBiObjectif
pour exécuter, on peut appeler la méthode main.
