import MG2D.geometrie.Point;
import MG2D.geometrie.Rectangle;
import MG2D.geometrie.Texture;


public class BoiteImage extends Boite{

    Texture image;

    BoiteImage(Rectangle rectangle, String image) {
	super(rectangle);
    java.io.File f = new java.io.File(image + "/photo_small.png");
    if (f.exists()) {
        this.image = new Texture(image+"/photo_small.png", new Point(760, 648));
    } else {
        this.image = null;
    }
    }

    public Texture getImage() {
	return this.image;
    }

    public void setImage(String chemin) {
    java.io.File f = new java.io.File(chemin + "/photo_small.png");
    if (f.exists() && this.image != null) {
        this.image.setImg(chemin+"/photo_small.png");
    } else if (f.exists()) {
        this.image = new Texture(chemin+"/photo_small.png", new Point(760, 648));
    }
    //this.image.setTaille(400, 320);
    }

}
