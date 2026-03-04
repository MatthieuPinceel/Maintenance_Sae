#!/bin/bash
xdotool mousemove 1280 1024
cd projet/Puissance_X
javac Main.java
java Main

# -Dsun.java2d.pmoffscreen=false : Améliore les performances sur les système Unix utilisant X11 (donc Raspbian est concerné).
# -Dsun.java2d.opengl=true : Utilise OpenGL (peut améliorer les performances).
