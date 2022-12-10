#!/bin/bash

# génère une instance à partir d'un fichier texte -> bash parser.sh <nom du fichier> [k]
array=($(sed -n 2p $1 | cut -d' ' -f 2,3 | tr -d '\r')) # recupère le nombre d'aretes et de sommets
echo -e "{\n\t\"n\":${array[0]},\n\t\"m\":${array[1]},\n\t\"A\":[" > "$1.json" # ecrit n et m
mapfile -t x < <(tail -n+3 $1 | tr ' ' ',' | tr -d '\r') # map des aretes
printf "\t\t[%s],\n" "${x[@]::$((${#x[@]}-1))}" >> "$1.json" # ecrire toute les aretes sauf la derniere
printf "\t\t[%s]\n\t]" "${x[${#x[@]}-1]}" >> "$1.json" # ecrire derniere arete
if [[ $# -eq 2 ]]; then
	echo -e ",\n\t\"k\":$2\n}" >> "$1.json" # ajout du champs k si deux arguments
else
	echo -e "\n}" >> "$1.json"
fi
