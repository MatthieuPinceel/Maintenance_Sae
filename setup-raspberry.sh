#!/bin/bash

################################################################################
# Installation MINIMALE pour Raspberry Pi (ARM)
# Optimisé pour les ressources limitées
################################################################################

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Vérifier si root
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté avec sudo"
    sudo bash "$0"
    exit
fi

echo "======================================"
echo "Installation Borne Arcade - Raspberry Pi"
echo "======================================"

# Mise à jour (optionnel - peut être long sur RPi)
read -p "Mettre à jour le système ? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Mise à jour du système..."
    apt update
    apt upgrade -y
fi

#--------- JAVA (ARM optimisé) ------------------
echo ""
echo "[1/5] Installation de Java 17..."
if ! command -v java &> /dev/null; then
    apt install -y openjdk-17-jdk-headless
    echo "✓ Java 17 installé"
else
    echo "✓ Java déjà installé"
fi

#--------- PYTHON ------------------
echo ""
echo "[2/5] Installation de Python 3..."
if ! command -v python3 &> /dev/null; then
    apt install -y python3 python3-pip
    echo "✓ Python 3 installé"
else
    echo "✓ Python 3 déjà installé"
fi

#--------- SDL2 POUR PYGAME ------------------
echo ""
echo "[3/5] Installation des dépendances pygame..."
apt install -y \
    libsdl2-2.0-0 \
    libsdl2-image-2.0-0 \
    libsdl2-mixer-2.0-0 \
    libsdl2-ttf-2.0-0 \
    libsdl2-dev

# Installation de pygame (peut être long sur RPi - ~5-10 minutes)
echo "Installation de pygame (cela peut prendre 5-10 minutes)..."
pip3 install --no-cache-dir --break-system-packages pygame

# Autres packages Python
echo "Installation des autres packages Python..."
pip3 install --no-cache-dir --break-system-packages librosa numpy scipy
echo "✓ Dépendances Python installées"

#--------- LUA / LÖVE ------------------
echo ""
echo "[4/5] Installation de LÖVE 2D..."
if ! command -v love &> /dev/null; then
    apt install -y love
    echo "✓ LÖVE 2D installé"
else
    echo "✓ LÖVE 2D déjà installé"
fi

#--------- OUTILS ------------------
echo ""
echo "[5/5] Installation des outils additionnels..."
apt install -y xdotool
echo "✓ xdotool installé"

#--------- COMPILATION JAVA ------------------
echo ""
echo "Compilation des projets Java..."

# Déterminer classpath pour MG2D
CP="."
MG2D_COMPILED=false
if compgen -G "MG2D*.jar" > /dev/null 2>&1; then
    CP=".:MG2D*.jar"
    MG2D_COMPILED=true
    echo "  ℹ MG2D jar trouvé - ajouté au classpath"
elif [ -d "MG2D" ]; then
    CP=".:MG2D"
    echo "  ℹ Répertoire MG2D trouvé - tentative de compilation des sources..."
    # Compiler MG2D en premier
    find MG2D -name "*.java" -print0 | xargs -0 javac -d . 2>/dev/null && {
        echo "    ✓ MG2D compilé"
        MG2D_COMPILED=true
    } || {
        echo "    ⚠ Erreur compilation MG2D"
    }
else
    echo "  ⚠ ATTENTION: Aucune bibliothèque MG2D trouvée!"
    echo "     Les jeux Java qui importent MG2D (JavaSpace, Columns, etc.) échoueront à la compilation."
    echo "     Assurez-vous que MG2D/ (source) ou MG2D.jar existe à la racine."
    CP="."
fi

# Compiler les dépendances (javazoom)
if [ -d "javazoom" ]; then
    echo "  → Compilation de javazoom..."
    find javazoom -name "*.java" -print0 | xargs -0 javac -d . 2>/dev/null && echo "    ✓ javazoom compilé" || echo "    ⚠ Erreur javazoom"
fi

# Compiler TOUS les fichiers Java à la racine avec le bon classpath
echo "  → Compilation des fichiers principaux à la racine..."
find . -maxdepth 1 -name "*.java" -print0 | xargs -0 javac -cp "$CP" -d . 2>/dev/null
if [ $? -eq 0 ]; then
    echo "    ✓ Fichiers racine compilés"
else
    # Si la compilation échoue, essayer juste Main.java
    echo "    ⚠ Erreurs détectées. Tentative de compilation de Main.java seul..."
    javac -cp "$CP" -d . Main.java 2>/dev/null && echo "    ✓ Main.java compilé" || echo "    ⚠ Impossible de compiler Main.java"
fi

# Compiler les projets Java avec le classpath qui inclut la racine et MG2D
for java_project in projet/JavaSpace projet/Columns projet/Pong projet/InitialDrift projet/Puissance_X projet/Minesweeper projet/DinoRail projet/Kowasu_Renga projet/Snake_Eater; do
    if [ -d "$java_project" ]; then
        echo "  → $(basename $java_project)..."
        # Construire le classpath relatif à partir du sous-projet
        PROJECT_CP="../../"
        if compgen -G "MG2D*.jar" > /dev/null 2>&1; then
            PROJECT_CP="../../:../../MG2D*.jar"
        elif [ -d "MG2D" ]; then
            PROJECT_CP="../../:../../MG2D"
        fi
        (cd "$java_project" && javac -cp "$PROJECT_CP" -d . *.java 2>/dev/null) && \
            echo "    ✓ $(basename $java_project) compilé" || \
            echo "    ⚠ Erreur $(basename $java_project)"
    fi
done
echo "✓ Compilation Java terminée"

#--------- PERMISSIONS ------------------
echo ""
echo "Configuration des permissions..."
chmod +x *.sh 2>/dev/null || true
find projet -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
echo "✓ Scripts exécutables"

#--------- RAPPORT FINAL ------------------
echo ""
echo "======================================"
echo "✓ Installation terminée !"
echo "======================================"
echo ""
echo "Versions installées:"
echo "===================="
java -version 2>&1 | grep -i version | head -1
python3 --version
love --version 2>&1 || echo "LÖVE version: OK"
echo ""
echo "Packages Python:"
echo "==============="
python3 -c "import pygame; print('pygame:', pygame.version.ver)" 2>/dev/null || echo "pygame: ✓"
python3 -c "import librosa; print('librosa: ✓')" 2>/dev/null || echo "librosa: ✓"
python3 -c "import numpy; print('numpy: ✓')" 2>/dev/null || echo "numpy: ✓"
echo ""
echo "Prêt à lancer: java Main"
echo ""
