Dans le fichier Ascent.jl

La méthode DUALOC appelle seulement la méthode dualAscentClassique

La méthode dualAscentClassique prend en paramètres
- c matrice des coûts des clients
- f vecteur du coût d'ouverture des services
Cette méthode retourne les v et les s pour nous permettre de calculer la solution ainsi que des tableaux de booléens pour les clients saturés.


La méthode dualAscentPourAdjustment comprend quelques paramètres en plus pour être utilisée dans le dual adjustment.


Dans le fichier Adjustment.jl

La méthode dualAdjustment prend en paramètres
- c matrice des coûts
- v vecteur des v obtenu avec le dual ascent
- s vecteur des s obtenu avec le dual ascent
- MatBoolC matrice de booléens pour les clients saturés obtenu avec le dual ascent
- VecteurDernierCout vecteur obtenu avec le dual ascent
- BoolI vecteur de booléens pour les clients saturés obtenu avec le dual ascent
Cette méthode retourne les vecteurs s et v.
On peut retourver la solution en additionnant les éléments de v.
