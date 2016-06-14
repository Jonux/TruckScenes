
import java.util.ArrayList;
import processing.core.*;

/**
 *
 * @author Jonux
 */
public class ImageScenario implements Scenario {

  private PApplet applet;
  private PImage image;

  private int scenarioTime = 3500;  // ms
  private int startTime;
  // private int userInput = 0;

  public ImageScenario(PApplet applet, String imageName, int scenarioTime) {
    this.applet = applet;
    this.image = applet.loadImage(imageName);
    this.scenarioTime = scenarioTime;
    this.startTime = applet.millis();
  }

  public void start() {
    this.startTime = applet.millis();
  }

  public void stop() {
  }

  // Returns true until scene timer is over
  public boolean draw() {
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