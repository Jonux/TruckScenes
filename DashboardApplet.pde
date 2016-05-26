import java.util.ArrayList;

import processing.core.PApplet;
import processing.core.PFont;
import processing.core.PShape;

class DashboardApplet extends PApplet {

  final private int screenSizeX = 640;
  final private int screenSizeY = 480;

  private ArrayList<PShape> images;
  private ArrayList<PShape> inactiveImages;

  private String dataFolderPath; // = "data/";
  private String[] weatherFiles = {"eco_white.svg", "rain_white.svg", "hill_white.svg", "slippery_white.svg", "eco_white.svg"};
  private String[] weatherFilesI = {"eco_grey.svg", "rain_gray.svg", "hill_gray.svg", "slippery_gray.svg", "eco_grey.svg"};
  private String[] activatingMsg = {"ACTIVATING\nECO MODE", "ACTIVATING\nWET MODE", "ACTIVATING\nUPHILL MODE", "ACTIVATING\nSLIPPERY MODE", "DISABLING\nWEATHER MODE"};

  private int modeActivationTimer;
  private int timeToNextMode;
  private WeatherMode nextWeatherMode;

  private boolean modeActivationStarted;
  private PFont textFont;

  private WeatherMode weatherMode;
  //public enum WeatherMode {
  //  ECO(0), SLIPPERY(1), UPHILL(2), WET(3), UNKNOWN(4);

  //  private int value;
  //    private WeatherMode(int value){
  //        this.value = value;
  //    }
  //}

  public DashboardApplet(String dataFolderPath) {
    super();
    images = new ArrayList<PShape>();
    inactiveImages = new ArrayList<PShape>();
    this.dataFolderPath = dataFolderPath; //"data\\";
    this.weatherMode = WeatherMode.UNKNOWN;
    this.nextWeatherMode = WeatherMode.UNKNOWN;
    this.modeActivationStarted = false;
  }

  public void settings() {
    size(screenSizeX, screenSizeY, P2D);
    fullScreen(2);
  }

  public void setup() {
    frameRate(25);
    //surface.setResizable(true);
    println(dataPath(""));

    // Load weather icons
    for (String s : weatherFiles) {
      try {
        println(dataFolderPath + " " + s);
        images.add(loadShape(dataFolderPath + "" + s));
      } 
      catch (Exception e) {
        println("Unable to load image: " + s);
      }
    }
    // Load inactive weather icons
    for (String s : weatherFilesI) {
      try {
        inactiveImages.add(loadShape(dataFolderPath + "" + s));
      } 
      catch (Exception e) {
        println("Unable to load image: " + s);
      }
    }

    this.textFont = createFont("Arial Bold", 32);
    textFont(textFont);
    modeActivationStarted = false;
  }

  private void drawBar(int x, int y, int sx, int sy, double percent) {
    fill(255);
    rect(x, y, sx, sy);
    fill(50, 50, 200);
    rect(x, y, (int)(sx*percent), sy);
    fill(255);
  }

  public void draw() {
    background(0);

    // this.height = (int)(9.0 / 16.0 * (float)this.width);
    // println(this.height);

    int startxpos = 120; 
    int endxpos = width-startxpos;
    int between = width-2*startxpos;
    // println("startxpos " + (width-2*startxpos));
    
    int imgsize = 80;
    int padding = 15;
    int barh = 8;
    
    int progBarH = 32;
    
   
    //rect(startxpos, 10, 5,480);
    //rect(endxpos, 10, 5,480);
    // Mode is changing
    if (isWeatherModeChanging()) {
      if (modeActivationTimer + timeToNextMode > millis()) {
        
        //println( "Len: " + activatingMsg[nextWeatherMode.value].length() + " " + activatingMsg[nextWeatherMode.value]);
        
        textSize(30);
        if (activatingMsg[nextWeatherMode.value].length() > 22) {
          textSize(26);
        } 
        
        textAlign(CENTER);
        fill(255, 255, 255);

        text(activatingMsg[nextWeatherMode.value], startxpos+(int)(between*0.3), (int)(this.height*0.3));
        shape(images.get(nextWeatherMode.value), endxpos-(int)(between*0.4)-padding, (int)(this.height*0.1), (int)(between*0.4), (int)(between*0.4));

        double progress = ((double)(millis() - modeActivationTimer)) / timeToNextMode;
        // println(modeActivationTimer + " " + timeToNextMode + " " + millis() + " " + progress);
        drawBar(startxpos+padding+20, height - imgsize - padding*3 - barh - progBarH, between-(padding+20)*2, progBarH, progress);
      } else {
        weatherMode = nextWeatherMode;
      }
    }

    fill(50, 50, 50);

    rect(0, this.height - imgsize - padding*2 - barh, (int)(this.width), barh);
    for (int i=0; i < weatherFiles.length-1; i++) {
      int extraH = (i==2) ? (int)(imgsize*0.6) : 0;
      if (weatherMode.value == i && weatherMode != WeatherMode.UNKNOWN) {
        shape(images.get(i), startxpos + 20 + (imgsize+padding)*i, this.height - imgsize - padding - extraH, imgsize, imgsize);
      } else {
        shape(inactiveImages.get(i), startxpos + 20 + (imgsize+padding)*i, this.height - imgsize - padding - extraH, imgsize, imgsize);
      }
    }

    //redraw();
  }

  /*
   * Starts mode activation
   */
  public void startModeActivation(WeatherMode nextMode, int timeToNextMode) {
    startModeActivation(nextMode, timeToNextMode, false);
  }

  public void startModeActivation(WeatherMode nextMode, int timeToNextMode, boolean override) {
    if (!modeActivationStarted || override) { 
      this.modeActivationTimer = millis();
      this.timeToNextMode = timeToNextMode;
      this.nextWeatherMode = nextMode;
      this.modeActivationStarted = true;
    }
  }

  public boolean hasModeActivationStarted() {
    return modeActivationStarted;
  }

  public boolean isWeatherModeChanging() {
    return weatherMode != nextWeatherMode;
  }

  public void completeWeatherModeSelection(boolean result) {
    if (result) {
      weatherMode = nextWeatherMode;
    } else {
      nextWeatherMode = weatherMode;
    }
  }

  public void setWeatherMode(WeatherMode w) {
    weatherMode = w;
    nextWeatherMode = w;
    this.modeActivationStarted = false;
  }

  public WeatherMode getWeatherMode() {
    return weatherMode;
  }

  /*
   * Returns timer in milliseconds from mode activation, else -1 
   */
  public int getModeActivationTimer() {
    if (!modeActivationStarted) return -1;
    return millis() - modeActivationTimer;
  }
}