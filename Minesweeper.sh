#!/bin/bash
xdotool mousemove 1280 1024
cd projet/Minesweeper
touch highscore
javac Minesweeper.java
java Minesweeper
