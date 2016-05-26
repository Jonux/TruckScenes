import java.util.ArrayList;

import processing.core.PApplet;
import processing.core.PFont;
import processing.core.PShape;

class DashboardApplet extends PApplet {

  final private int screenSizeX = 640;
  final private int screenSizeY = 480;

  private ArrayList<PImage> images;
  private ArrayList<PImage> inactiveImages;

  private String dataFolderPath; // = "data/";
  private String[] weatherFiles = {"icon_eco_active.png", "icon_rain_active.png", "icon_uphill_active.png", "icon_slippery_active.png", "icon_eco_active.png"};
  private String[] weatherFilesI = {"icon_eco_inactive.png", "icon_rain_inactive.png", "icon_uphill_inactive.png", "icon_slippery_inactive.png", "icon_eco_inactive.png"};
  private String[] activatingMsg = {"ACTIVATING\nECO MODE", "ACTIVATING\nRAIN MODE", "ACTIVATING\nUPHILL MODE", "ACTIVATING\nSLIPPERY\nMODE", "DISABLING\nWEATHER MODE"};

  private int modeActivationTimer;
  private int timeToNextMode;
  private WeatherMode nextWeatherMode;

  private boolean modeActivationStarted;
  private PFont textFontSmall;
  private PFont textFontBig;
  
  private WeatherMode weatherMode;

  public DashboardApplet(String dataFolderPath) {
    super();
    images = new ArrayList<PImage>();
    inactiveImages = new ArrayList<PImage>();
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
        images.add(loadImage(dataFolderPath + "" + s));
      } 
      catch (Exception e) {
        println("Unable to load image: " + s);
      }
    }
    // Load inactive weather icons
    for (String s : weatherFilesI) {
      try {
        inactiveImages.add(loadImage(dataFolderPath + "" + s));
      } 
      catch (Exception e) {
        println("Unable to load image: " + s);
      }
    }

    this.textFontSmall = loadFont( dataFolderPath + "VolvoBroad-24.vlw"); // createFont("Arial Bold", 32);
    this.textFontBig = loadFont(dataFolderPath + "VolvoBroad-46.vlw");
    
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
    
    int startxpos = 120; 
    int endxpos = width-startxpos;
    int between = width-2*startxpos;

    int imgsize = 80;
    int padding = 15;
    int barh = 8;
    
    int progBarH = 32;
    final double aspectRatio = 550.0/500.0;
   
    //rect(startxpos, 10, 5,480);
    //rect(endxpos, 10, 5,480);
    // Mode is changing
    if (isWeatherModeChanging()) {
      if (modeActivationTimer + timeToNextMode > millis()) {
        //textSize(30);
        //if (activatingMsg[nextWeatherMode.value].length() > 22) {
        //  textSize(25);
        //} 
        textFont(textFontBig);
        textAlign(CENTER);
        fill(255, 255, 255);

        text(activatingMsg[nextWeatherMode.value], startxpos+(int)(between*0.3), (int)(this.height*0.3));
        image(images.get(nextWeatherMode.value), endxpos-(int)(between*0.4)-padding, (int)(this.height*0.1), (int)(between*0.4), (int)(aspectRatio*between*0.4));

        double progress = ((double)(millis() - modeActivationTimer)) / timeToNextMode;
        // println(modeActivationTimer + " " + timeToNextMode + " " + millis() + " " + progress);
        drawBar(startxpos+padding+20, height - imgsize - padding*4 - barh - progBarH, between-(padding+20)*2, progBarH, progress);
        fill(0,0,0);
        //textSize(16);
        textFont(textFontSmall);
        text((int)(progress*100.0)+"%", startxpos + between*0.5, height - imgsize - padding*4 - barh - progBarH*0.3);
      } else {
        weatherMode = nextWeatherMode;
      }
    }

    fill(50, 50, 50);

    rect(0, this.height - imgsize - padding*2 - barh, (int)(this.width), barh);
    for (int i=0; i < weatherFiles.length-1; i++) {
      if (weatherMode.value == i && weatherMode != WeatherMode.UNKNOWN) {
        image(images.get(i), startxpos + 20 + (imgsize+padding)*i, this.height - imgsize - padding, imgsize, (int)(aspectRatio*imgsize));
      } else {
        image(inactiveImages.get(i), startxpos + 20 + (imgsize+padding)*i, this.height - imgsize - padding, imgsize, (int)(aspectRatio*imgsize));
      }
    }
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