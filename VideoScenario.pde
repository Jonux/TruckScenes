
import java.awt.Color;
import processing.core.*;
import processing.video.*;

/**
 *
 * @author Jonux
 */
public class VideoScenario implements Scenario {
    
    private PApplet applet;
    private Movie videoClip;
    private String videoClipName;

    private TwinBar safetyBarSet;
    private PGraphics barSetBackground;
    
    private int startTime = 0;
    private float videoStartPos;
    private float videoEndPos;
    
    // UX stuff
    private final Color backgroundColor = new Color(32, 32, 32);
    private final int verticalMargin = 42;
    private final int roundedBoxWidth = 1250;
    private final int topBarHeight = 285;
    
    public VideoScenario(PApplet applet, String videoClipName, float videoStartPos, float videoEndPos) {
        this.applet = applet;
        this.videoClipName = videoClipName;

        this.safetyBarSet = new TwinBar(applet, "Fuel Efficiency", "Safety", roundedBoxWidth, topBarHeight - 2*verticalMargin, 0.0f, 0.0f);
        this.barSetBackground = applet.createGraphics(roundedBoxWidth, topBarHeight);
        this.startTime = applet.millis();
        
        this.videoEndPos = videoEndPos;
        this.videoStartPos = videoStartPos;
    }
    
    
    public TwinBar getSafetyBar() {
      return safetyBarSet;
    }
    
    public void setBarsStartSizes(float safetyProgress, float fuelEffProgress) {
      safetyBarSet.setBar12Progress(safetyProgress, fuelEffProgress, 0);
    }

    public void start() {
      if (videoClip == null) {
        System.err.println(this.videoClip + " NULL");
        return;
      }
      
        //videoClip.speed(1);
      System.out.println("Starting video playing from position: " + videoStartPos);
      
      
      // Black Magic:
      // Hack to go around Processing-video jump-location bug. 
      // It is NOT possible to jump on a video before playing it.
      videoClip.pause();
      videoClip.play();
      videoClip.jump(videoStartPos);
      System.out.println("Playing Video: " + videoClip.time() + "    "  + videoClip.duration());

        startTime = applet.millis();
    }
    
    public void stop(){
      videoClip.stop();
    }
    

    public void setup(float safetyProgress, float fuelEffProgress) {
        if (videoClip == null) {
          System.out.println("videoClipName: " + dataPath("") + videoClipName);
          videoClip = new Movie(applet, dataPath("") + videoClipName);
          //videoClip.frameRate(20);
        }
        
        if (videoClip != null) {
          videoClip.speed(1);
          videoClip.play();
          System.out.println(this.videoClip + "   " + videoStartPos + " pos: " + videoClip.time() + "   duration: "+ this.videoClip.duration());
        } else {
          System.err.println("Unable to load video: " + this.videoClip);
        }

        barSetBackground.beginDraw();
        barSetBackground.background(backgroundColor.getRed(), backgroundColor.getGreen(), backgroundColor.getBlue());
        barSetBackground.endDraw();
        
        setBarsStartSizes(safetyProgress, fuelEffProgress);
        
    }
    
    public boolean draw() {
        if (videoClip != null && videoClip.available()) {
            videoClip.read();
        }
        
        //applet.background(backgroundColor.getRed(), backgroundColor.getGreen(), backgroundColor.getBlue());
        applet.image(videoClip, (applet.width - videoClip.width)/2, barSetBackground.height); //, applet.width, applet.height - barSetBackground.height);
        //applet.image(barSetBackground, 0, 0);

        
        this.safetyBarSet.draw(applet.width/2 - safetyBarSet.getWidth()/2, verticalMargin);

        if (videoClip.time() >= videoEndPos) {
          return false;
        }

        return true;
    }
    
    public int floatTimeToMillis(float time) {
      return (int)(time*1000.0f);
    }
    
    public float videoTimeLeft() {
      return Math.min(Math.max(floatTimeToMillis(videoEndPos) - floatTimeToMillis(videoClip.time()), 0.0f), floatTimeToMillis(videoEndPos));
    }
    
    public int getStartTime() {
      return startTime;
    }
    
}