
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.io.File;
import javax.swing.JOptionPane;

import MG2D.geometrie.Texture;
import MG2D.Couleur;
import MG2D.geometrie.Point;
import MG2D.geometrie.Triangle;
import MG2D.Clavier;

public class Pointeur {

    private int value;
    private Texture triangleGauche;
    private Texture triangleDroite;
    private Texture rectangleCentre;

    public Pointeur() {
        this.triangleGauche = new Texture("img/star.png", new Point(30, 492), 40, 40);
        // this.triangleDroite = new Triangle(Couleur .ROUGE, new Point(550, 560), new Point(520, 510), new Point(550, 460), true);
        this.triangleDroite = new Texture("img/star.png", new Point(530, 492), 40, 40);
        this.rectangleCentre = new Texture("img/select2.png", new Point(80, 460), 440, 100);
        this.value = Graphique.tableau.length - 1;
    }

    public void lancerJeu(ClavierBorneArcade clavier) {
        if (clavier.getBoutonJ1ATape()) {
            try {
                // arrêter la musique si elle tourne
                Graphique.stopMusiqueFond();
                
                String scriptName = Graphique.tableau[getValue()].getNom() + ".sh";
                File scriptFile = new File(scriptName);
                
                if (!scriptFile.exists()) {
                    System.err.println("Script not found: " + scriptName);
                    return;
                }
                
                // Lire le contenu du script
                String scriptContent = new String(Files.readAllBytes(Paths.get(scriptName)));
                String[] lines = scriptContent.split("\n");
                
                File workDir = new File(System.getProperty("user.dir"));
                
                // Parser et exécuter les commandes du script
                for (String line : lines) {
                    line = line.trim();
                    
                    // Ignorer les lignes vides et les commentaires
                    if (line.isEmpty() || line.startsWith("#")) {
                        continue;
                    }
                    
                    // Gérer les commandes cd
                    if (line.startsWith("cd ")) {
                        String dirPath = line.substring(3).trim();
                        workDir = new File(System.getProperty("user.dir"), dirPath);
                        System.out.println("Changing directory to: " + workDir.getAbsolutePath());
                    }
                    // Gérer les commandes touch (créer fichier vide)
                    else if (line.startsWith("touch ")) {
                        String filename = line.substring(6).trim();
                        File file = new File(workDir, filename);
                        if (!file.exists()) {
                            file.createNewFile();
                            System.out.println("Created file: " + file.getAbsolutePath());
                        }
                    }
                    // Ignorer les commandes xdotool (non disponible)
                    else if (line.startsWith("xdotool")) {
                        System.out.println("Skipping xdotool command (not available): " + line);
                    }
                    // Gérer les autres commandes (java, javac, python, etc.)
                    else if (!line.isEmpty()) {
                        System.out.println("Executing: " + line);
                        executeCommand(line, workDir);
                    }
                }
            }
            catch (IOException | InterruptedException e) {
                e.printStackTrace();
                JOptionPane.showMessageDialog(null, "Erreur: " + e.getMessage(), "Erreur", JOptionPane.ERROR_MESSAGE);
            }
        }
    }
    
    private void executeCommand(String command, File workDir) throws IOException, InterruptedException {
        // Diviser la commande en arguments
        String[] args = parseCommand(command);
        
        // Injecter le classpath pour les commandes javac et java
        if (args.length > 0 && (args[0].equals("javac") || args[0].equals("java"))) {
            // Construire le classpath
            String cp = ".";
            
            // Chercher MG2D dans le répertoire courant et les parents
            File checkDir = workDir;
            boolean found = false;
            for (int i = 0; i < 3; i++) { // Chercher jusqu'à 3 niveaux de parent
                File mg2dDir = new File(checkDir, "MG2D");
                if (mg2dDir.exists()) {
                    cp = ".:../../MG2D:../../../MG2D";
                    found = true;
                    break;
                }
                // Chercher aussi MG2D.jar
                File[] files = checkDir.listFiles();
                if (files != null) {
                    for (File f : files) {
                        if (f.getName().startsWith("MG2D") && f.getName().endsWith(".jar")) {
                            cp = ".:../../MG2D.jar:../../../MG2D.jar";
                            found = true;
                            break;
                        }
                    }
                }
                if (found) break;
                checkDir = checkDir.getParentFile();
                if (checkDir == null) break;
            }
            
            // Ajouter le classpath si ce n'est pas déjà présent
            boolean hasCP = false;
            for (String arg : args) {
                if (arg.equals("-cp") || arg.equals("-classpath")) {
                    hasCP = true;
                    break;
                }
            }
            
            if (!hasCP) {
                java.util.List<String> newArgs = new java.util.ArrayList<>();
                newArgs.add(args[0]); // javac ou java
                newArgs.add("-cp");
                newArgs.add(cp);
                for (int i = 1; i < args.length; i++) {
                    newArgs.add(args[i]);
                }
                args = newArgs.toArray(new String[0]);
            }
        }
        
        ProcessBuilder pb = new ProcessBuilder(args);
        pb.directory(workDir);
        pb.inheritIO(); // Afficher la sortie du processus
        
        System.out.println("Running in: " + workDir.getAbsolutePath());
        Process process = pb.start();
        process.waitFor();
    }
    
    private String[] parseCommand(String command) {
        // Gérer les guillemets et espaces
        java.util.List<String> args = new java.util.ArrayList<>();
        StringBuilder current = new StringBuilder();
        boolean inQuotes = false;
        
        for (int i = 0; i < command.length(); i++) {
            char c = command.charAt(i);
            
            if (c == '"' || c == '\'') {
                inQuotes = !inQuotes;
            } else if (c == ' ' && !inQuotes) {
                if (current.length() > 0) {
                    args.add(current.toString());
                    current = new StringBuilder();
                }
            } else {
                current.append(c);
            }
        }
        
        if (current.length() > 0) {
            args.add(current.toString());
        }
        
        return args.toArray(new String[0]);
    }

    public int getValue() {
        return value;
    }

    public void setValue(int value) {
        this.value = value;
    }

    public Texture getTriangleGauche() {
        return triangleGauche;
    }

    public void setTriangleGauche(Texture triangleGauche) {
        this.triangleGauche = triangleGauche;
    }

    public Texture getTriangleDroite() {
        return triangleDroite;
    }

    public void setTriangleDroite(Texture triangleDroite) {
        this.triangleDroite = triangleDroite;
    }

    public Texture getRectangleCentre() {
        return rectangleCentre;
    }

    public void setRectangleCentre(Texture rectangleCentre) {
        this.rectangleCentre = rectangleCentre;
    }

}
