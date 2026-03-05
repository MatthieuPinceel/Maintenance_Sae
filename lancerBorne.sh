#!/bin/bash

setxkbmap borne


cd /home/pi/git/borne_arcade
echo "nettoyage des répertoires"
echo "Veuillez patienter"
./clean.sh
./compilation.sh

echo "Installation des dépendances"
./setup-raspberry.sh

echo "Lancement du  Menu"
echo "Veuillez patienter"

javac -d . *.java
java Main

./clean.sh
for i in {30..1}
do
    echo Extinction de la borne dans $i secondes
    sleep 1
done

sudo halt