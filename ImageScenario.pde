
import java.util.ArrayList;
import processing.core.*;

/**
 *
 * @author Jonux
 */
public class ImageScenario implements Scenario {

  private final PApplet applet;
  private final PImage image;

  private int scenarioTime = 3500;  // ms
  private int startTime;
  // private int userInput = 0;

  public ImageScenario(PApplet applet, String imageName, int scenarioTime) {
    this.applet = applet;
    this.image = applet.loadImage(imageName);
    this.scenarioTime = scenarioTime;
    this.startTime = applet.millis();
  }

  public void start2() {
    this.startTime = applet.millis();
  }

  public void stop2() {
  }

  // Returns true until scene timer is over
  public boolean draw2() {
    if (image != null) {
      applet.image(image, 0, 0, applet.width, applet.height);
    }

    if (scenarioTime > 0 && startTime + scenarioTime < applet.millis()) {
      System.out.println("Scene changed!");
      return false;
    }

    return true;
  }

  public int getStartTime() {
    return startTime;
  }
}