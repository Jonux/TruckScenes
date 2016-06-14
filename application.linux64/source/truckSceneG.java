import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.serial.*; 
import processing.video.*; 
import processing.core.PApplet; 
import processing.serial.Serial; 
import java.util.ArrayList; 
import java.util.Arrays; 
import java.util.List; 
import java.util.ArrayList; 
import processing.core.PApplet; 
import processing.core.PFont; 
import processing.core.PShape; 
import processing.sound.*; 
import java.util.ArrayList; 
import processing.core.*; 
import java.awt.Color; 
import processing.core.PApplet; 
import processing.core.PConstants; 
import processing.core.PGraphics; 
import java.awt.Color; 
import processing.core.*; 
import processing.video.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class truckSceneG extends PApplet {












DashboardApplet dashboard;

Serial myPort;
final int serialPortIdx = 0;
final  String dataFolderPath = "";
final  String videoFolderPath = dataFolderPath + "/video/";

ArrayList<Scenario> scenarios;
UserCommand userCommand;
int scenarioIdx;

int scenarioTimer;
int modeChangeDenied = 0;
int reactionTimer;

/*
 * Scenario setup
 * 
 * ECO -> SLIP (rainy)
 * SLIP -> ECO (sunny)
 * ECO -> HILL (winter uphill)
 * ECO -> WET (rainy)
 */
final SceneData[] scenes = {
  new SceneData(WeatherMode.UNKNOWN, dataFolderPath + "startView.png"), 
  new SceneData(0.67f, -0.5f, 0.33f, -0.05f, WeatherMode.ECO, WeatherMode.SLIPPERY, 0.0f, 15.0f, 2000, 8000, 3500, videoFolderPath + "scene1.mp4"), 
  new SceneData(0.0f, 0.8f, 0.7f, 0.8f, WeatherMode.SLIPPERY, WeatherMode.ECO, 0.0f, 15.0f, 2000, 8000, 3500, videoFolderPath + "scene2.mp4"), 
  new SceneData(0.6f, -0.3f, 0.4f, -0.08f, WeatherMode.ECO, WeatherMode.UPHILL, 0.0f, 15.0f, 2000, 8000, 3500, videoFolderPath + "scene3.mp4"), 
  new SceneData(0.75f, -0.47f, 0.41f, -0.02f, WeatherMode.ECO, WeatherMode.WET, 0.0f, 15.0f, 2000, 8000, 3500, videoFolderPath + "scene4.mp4"), 
  new SceneData(WeatherMode.UNKNOWN, dataFolderPath + "summaryView.png")
};

// Summary variables
double safetyOverallChange = 0;
double fuelOverallChange = 0;
ArrayList<QuestionStatus> sceneAnswers;
PShape starShapeFilled;
PShape starShapeHollow;

enum QuestionStatus {
  UNKNOWN, APPROVED, DENIED
}

public void settings() {
  size(1680, 1050, P2D);
  fullScreen(1);
  println(dataPath(""));
}

public void setup() {
  // Main display
  frameRate(25);

  scenarioIdx = 0;
  scenarios = new ArrayList<Scenario>();
  sceneAnswers = new ArrayList<QuestionStatus>();
  
  // Setup scenarios
  initializeScenarios();

  // Serial port communication setup
  System.out.println("Available Serial Ports\nCurrent Serial Port Idx: " + serialPortIdx);
  printArray(Serial.list());
  try {
    // final String[] l = Serial.list();
    // serialPortIdx = max(l.length - 1, 0);
    myPort = new Serial(this, Serial.list()[serialPortIdx], 9600);
  } 
  catch (Exception e) {
    System.out.println("Error opening serial port: Port busy");
    // exit();
  }

  // Setup dashboard display
  dashboard = new DashboardApplet(dataPath("") + "/");
  PApplet.runSketch(new String[] { dashboard.getClass().getName() }, dashboard);

  // Magic delay, wait to other thread to get ready. TODO: do this properly
  // delay(300);

  // Start scenarios
  restartScenarios();
 
  starShapeFilled = loadShape(dataPath("") + "/Filled star.svg");
  starShapeHollow = loadShape(dataPath("") + "/Unfilled star.svg");
  starShapeHollow.setFill(color(0, 176, 240)); // color(255, 209, 6)); yellow
  starShapeFilled.setFill(color(0, 176, 240));
}

public void initializeScenarios() {
  scenarios = new ArrayList<Scenario>();
  sceneAnswers = new ArrayList<QuestionStatus>();
  for (SceneData s : scenes) {
    if (s.sceneType == SceneType.IMAGE) {
      scenarios.add(new ImageScenario(this, s.fileName, -1));
    } else if (s.sceneType == SceneType.VIDEO) {
      scenarios.add(new VideoScenario(this, s.fileName, s.videoStartTime, s.videoEndTime));
    }

    // Summary answers to the questions
    sceneAnswers.add(QuestionStatus.UNKNOWN);
  }
}

public void initNextScenario() {
  scenarios.get(scenarioIdx).stop();
  scenarioIdx = (scenarioIdx + 1) % scenarios.size();
  sceneAnswers.set(scenarioIdx, QuestionStatus.UNKNOWN); // initialize selection

  println("Setting up scenario idx: " + scenarioIdx);
  Scenario nextScene = scenarios.get(scenarioIdx);
  if (nextScene instanceof VideoScenario) {
    ((VideoScenario) nextScene).setup(scenes[scenarioIdx].safetyAtStart, scenes[scenarioIdx].fuelEfficiencyAtStart);
  }
  println("Scene Starting: " + scenarioIdx);
  nextScene.start();

  scenarioTimer = millis();
  modeChangeDenied = 0;
  userCommand = UserCommand.UNKNOWN;
  println("Scene timer set: " + scenarioTimer);

  reactionTimer = -1;
  
  // Beginning of each scenario initialize the small screen's Weather mode
  dashboard.setWeatherMode(scenes[scenarioIdx].startWeatherMode);
  println("Dashboard weather " + dashboard.frameRate);
}

public void restartScenarios() {
  scenarios.get(scenarioIdx).stop();
  scenarioIdx = scenarios.size() - 1;
  println("(re)starting scenarios");
  initNextScenario();
}



/*
   * Update top bar sizes based on user inputs
 */
public void updateBarSizes() {
  // handle keyboard based events
  int keyEvent = handleUserEvent();

  // read user inputs
  int serialEvent = readSerial();

  // Update bar sizes
  Scenario s = scenarios.get(scenarioIdx);
  if (s instanceof VideoScenario) {
    TwinBar b1 = ((VideoScenario) s).getSafetyBar();

    if (serialEvent > 0 || keyEvent > 0
      || (modeChangeDenied == 0 && dashboard.hasModeActivationStarted() && !dashboard.isWeatherModeChanging())) {
      if (!b1.isBarInProgress() && !(b1.getBar2Process() == scenes[scenarioIdx].safetyWhenApproved
        && b1.getBar1Process() == scenes[scenarioIdx].fuelEfficiencyWhenApproved)) {
        safetyOverallChange += abs(scenes[scenarioIdx].safetyWhenApproved - b1.getBar2Process());
        fuelOverallChange += abs(scenes[scenarioIdx].fuelEfficiencyWhenApproved - b1.getBar1Process());
        b1.setBar12Progress(scenes[scenarioIdx].safetyWhenApproved, scenes[scenarioIdx].fuelEfficiencyWhenApproved, 1500);
      }
    }
  }
}

public void draw() {
  boolean running = scenarios.get(scenarioIdx).draw();

  // Move forward on scenarios
  if (!running) {
    initNextScenario();
  }

  // Build scenarios
  if (scenes[scenarioIdx].sceneType == SceneType.VIDEO) {

    // shorter waiting time, when mode is manually selected
    if (reactionTimer != -1 && millis() - reactionTimer > scenes[scenarioIdx].questionAfterTime)
    /*(dashboard.getModeActivationTimer() > scenes[scenarioIdx].questionAfterTime && 
      sceneAnswers.get(scenarioIdx) != QuestionStatus.UNKNOWN) */ {
      initNextScenario();

      // start mode activation
    } else if (scenarioTimer + scenes[scenarioIdx].questionAfterTime < millis()) {
      dashboard.startModeActivation(scenes[scenarioIdx].nextWeatherMode, scenes[scenarioIdx].questionReactTime);
    }
  }

  // the last scene
  if (scenarioIdx == scenes.length - 1) {
    // draw new background
    scenarios.get(scenarioIdx).draw();

    // calculate scores
    int scoreSafety = CalculateSafetyScore();
    int scoreFuel = CalculateFEScore();

    // Draw star scores
    int starSize = 70;
    fill(255,255,255);
    noStroke();
    rect(770, 425, starSize*6, starSize*4);
    // R: 255 G: 209 B: 6
    //255, 204, 0
    for (int i=0; i < 4; i++) {
      if (i < scoreFuel) {
        shape(starShapeFilled, 770+i*80, 425, starSize, starSize);
      } else { 
        shape(starShapeHollow, 770+i*80, 425, starSize, starSize);
      }
      
      if (i < scoreSafety) {
        shape(starShapeFilled, 770+i*80, 540, starSize, starSize);
      } else { 
        shape(starShapeHollow, 770+i*80, 540, starSize, starSize);
      }
    }
  }

  // Handle user inputs and update bar sizes
  updateBarSizes();

  // Handle fading events
  transitionBetweenScenarios();
  
  //fill(255);
  //textSize(16);
  //text("FPS: " + (int)frameRate, 20, 30);
}

public int CalculateSafetyScore() {
 int scoreSafety = 4;
 for (int i=0; i<sceneAnswers.size(); i++) {
   QuestionStatus q = sceneAnswers.get(i);
   if (q == QuestionStatus.DENIED) {
     if (i == 2) {
       //scoreSafety--;
     } else {
       scoreSafety = scoreSafety - 2;
     }
     
   }
 }
 return max(scoreSafety,0);
}

// Fuel efficiency score
public int CalculateFEScore() {
 int scoreFE = 4;
 QuestionStatus q = (2 < sceneAnswers.size()) ? sceneAnswers.get(2) : QuestionStatus.UNKNOWN;
 if (q == QuestionStatus.DENIED) {
   scoreFE--;
 }
 return max(scoreFE, 0);
}

public void transitionBetweenScenarios() {

  // Handle fade out from video scenarios
  int fadeTime = 800;
  if (scenes[scenarioIdx].sceneType == SceneType.VIDEO) {
    boolean videoIsEnding = ((VideoScenario)scenarios.get(scenarioIdx)).videoTimeLeft() < fadeTime;
    boolean userSelectionCompleted = (reactionTimer != -1 && millis() - reactionTimer + fadeTime  > scenes[scenarioIdx].questionAfterTime); //dashboard.getModeActivationTimer() + fadeTime > scenes[scenarioIdx].questionAfterTime && sceneAnswers.get(scenarioIdx) != QuestionStatus.UNKNOWN;

    int v = 0;
    if (videoIsEnding || userSelectionCompleted) {
      if (videoIsEnding) {
        v = (int)(255 * ((float)fadeTime - ((VideoScenario)scenarios.get(scenarioIdx)).videoTimeLeft()) / fadeTime);
      } else {
        v = 255 - (int)(255 * ((float)(scenes[scenarioIdx].questionAfterTime - (millis() - reactionTimer)) / fadeTime));
        //  v = 255 - (int)(255 * ((float)(scenes[scenarioIdx].questionAfterTime - dashboard.getModeActivationTimer()) / fadeTime));
      }
      
      fill(0, 0, 0, min(max(v,0), 255));
      rect(0, 0, width, height);
    }
  }

  // Handle fade in
  int fadeInTime = 1200;
  if (scenes[scenarioIdx].sceneType == SceneType.VIDEO) {
    int startT = scenarios.get(scenarioIdx).getStartTime();
    if (millis() - startT < fadeInTime) {
      int v = 255 - (int)((float)(millis() - startT) / fadeInTime * 255);
      fill(0, 0, 0, v);
      rect(0, 0, width, height);
    }
  }
}


/**
 * USER Interface keyboard (yes , no , start) DEBUG purposes
 */
public void keyReleased() {
  userCommand = UserCommand.fromKeyboard(key);
  println(scenarioIdx + ") Key pressed: " + key + "      Command: " + userCommand.name());
}

// Serial format:
// <6-bits for switch state><tab delimiter><char for gear>
// where the chars are p,r,n,d,s,- and + for park, reverse, neutral, drive,
// smart-auto and plus/minus
// return -1 if denied, 0 nothing happened, 1 approved
public int readSerial() {
  userCommand = UserCommand.UNKNOWN;
  try {
    while (myPort.available() > 0) {
      String line = myPort.readStringUntil('\n');
      if (line == null)
        continue;
      println("Serial Input: " + line);

      String[] q = splitTokens(line);
      if (q != null && q.length > 1 && q[1] != null && q[1].length() > 0) {
        userCommand = UserCommand.fromSerial(q[1].toLowerCase().charAt(0));
        println("Mode Selected: " + q[1].charAt(0) + "      Command " + userCommand.name());
      }
    }
  } 
  catch (Exception e) {
  }

  // Handle user command
  return handleUserEvent();
}

/**
 * Handle user interaction
 * @return 1 if topBarSet needs to be updated, else 0
 */
public int handleUserEvent() {

  switch (userCommand) {
  case UNKNOWN: 
    break;
  case START:
    if (scenarioIdx == 0) {
      initNextScenario();
    }
    break;
  case END: 
    if (scenarioIdx == scenarios.size() - 1) {
      restartScenarios();
    }
    break;
  case RESTART: 
    if (scenarioIdx != 0) {
      restartScenarios();
    }
    break;
  case NEXT: 
    if (scenarioIdx != 0) {
      initNextScenario();
    }
    break;
  case APPROVE: 
    if (dashboard.hasModeActivationStarted() && dashboard.isWeatherModeChanging()) {
      dashboard.completeWeatherModeSelection(true);
      modeChangeDenied = 0;
      sceneAnswers.set(scenarioIdx, QuestionStatus.APPROVED);
      reactionTimer = millis();
      return 1;
    }
    break;
  case DENY: 
    if (dashboard.hasModeActivationStarted() && dashboard.isWeatherModeChanging()) {
      dashboard.completeWeatherModeSelection(false);
      modeChangeDenied = 1;
      sceneAnswers.set(scenarioIdx, QuestionStatus.DENIED);
      reactionTimer = millis();
      return -1;
    }
    break;
  }
  return 0;
}







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
  private SoundFile soundFile;
  
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
    
      soundFile = new SoundFile(this, dataFolderPath + "airplaneding.mp3");
    println("soundFile" + soundFile);
    println("soundFile" + soundFile.frames() + "    " + soundFile.duration());
  
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
    final double aspectRatio = 550.0f/500.0f;
   
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

        text(activatingMsg[nextWeatherMode.value], startxpos+(int)(between*0.3f), (int)(this.height*0.3f));
        image(images.get(nextWeatherMode.value), endxpos-(int)(between*0.4f)-padding, (int)(this.height*0.1f), (int)(between*0.4f), (int)(aspectRatio*between*0.4f));

        double progress = ((double)(millis() - modeActivationTimer)) / timeToNextMode;
        // println(modeActivationTimer + " " + timeToNextMode + " " + millis() + " " + progress);
        drawBar(startxpos+padding+20, height - imgsize - padding*4 - barh - progBarH, between-(padding+20)*2, progBarH, progress);
        fill(0,0,0);
        //textSize(16);
        textFont(textFontSmall);
        text((int)(progress*100.0f)+"%", startxpos + between*0.5f, height - imgsize - padding*4 - barh - progBarH*0.3f);
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
      if (soundFile != null) {
        soundFile.play();
      }
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
/**
 * Abstract interface for truck scenarios
 * @author Jonux
 */
public interface Scenario {

  // returns true, if the scenario is running
  public boolean draw();

  // Start the scenario
  public void start();

  // Stop the scenario
  public void stop();

  // milliseconds from scenario started
  public int getStartTime();
}
//import truckscene.DashboardApplet.WeatherMode;

/*
 * Scene data container
 */
public class SceneData {

  public final float fuelEfficiencyAtStart;    // value between [-1, 1]
  public final float fuelEfficiencyWhenApproved;  // value between [-1, 1]
  
  public final float safetyAtStart;        // value between [-1, 1]
  public final float safetyWhenApproved;      // value between [-1, 1]
  
  public final WeatherMode startWeatherMode;
  public final WeatherMode nextWeatherMode;
  
  public final String fileName;
  public final float videoStartTime;        // time in minutes, value range [0, video_duration [
  public final float videoEndTime;        // time in minutes, value range [0, video_duration [
  
  public final int questionStartTime;    // milliseconds from scenario started
  public final int questionReactTime;    // milliseconds from question asked
  public final int questionAfterTime;    // milliseconds from question answered
  
  public final SceneType sceneType;
  
  //public enum SceneType {
  //  UNKNOWN, VIDEO, IMAGE
  //}
  
  // Video scene constructor
  public SceneData(
      float fuelEfficiencyAtStart, float safetyAtStart, 
      float fuelEfficiencyWhenApproved, float safetyWhenApproved,
      WeatherMode startWeatherMode, WeatherMode nextWeatherMode,
      float videoStartTime, float videoEndTime,
      int questionStartTime, int questionReactTime, int questionAfterTime, 
      String videoName) {
    this.fuelEfficiencyAtStart = fuelEfficiencyAtStart;
    this.safetyAtStart = safetyAtStart;
    this.fuelEfficiencyWhenApproved = fuelEfficiencyWhenApproved;
    this.safetyWhenApproved = safetyWhenApproved;
    this.startWeatherMode = startWeatherMode;
    this.nextWeatherMode = nextWeatherMode;
    this.videoEndTime = videoEndTime;
    this.videoStartTime = videoStartTime;
    this.questionStartTime = questionStartTime;
    this.questionReactTime = questionReactTime;
    this.questionAfterTime = questionAfterTime;
    this.fileName = videoName;
    this.sceneType = SceneType.VIDEO;
  }
  
  // Image scene constructor
  public SceneData(WeatherMode startWeatherMode, String imageName) {
    this.fuelEfficiencyAtStart = 0;
    this.safetyAtStart = 0;
    this.fuelEfficiencyWhenApproved = 0;
    this.safetyWhenApproved = 0;
    this.startWeatherMode = startWeatherMode;
    this.nextWeatherMode = startWeatherMode;
    this.videoEndTime = 0;
    this.videoStartTime = 0;
    this.questionStartTime = 0;
    this.questionReactTime = 0;
    this.questionAfterTime = 0;
    this.fileName = imageName;
    this.sceneType = SceneType.IMAGE;
  }
}






public class TwinBar {

  private String bar1;
  private String bar2;
  
  private float bar1process;
  private float bar2process;
  private Color backgroundColor = new Color(32, 32, 32);
  private Color roundedBoxColor = new Color(87, 87, 87);
  private Color barBackgroundColor = new Color(255, 255, 255);
  private Color textColor = new Color(255, 255, 255);
  
    /* Color values: 
     * 
     * Background 32,32,32
     * Roundedbox: 87, 87, 87
     * Green: 144, 209, 80
     * Red: 254, 0, 8
     * 
     */
  
  private PGraphics pg;
  private PApplet applet;
  
  // variables for bar animation
  private int timeStarted;
  private int timeToTarget;
  private float orginalBar1Pos;
  private float orginalBar2Pos;
  
  public TwinBar(PApplet applet, String bar1, String bar2, int sizeX, int sizeY, float bar2process, float bar1process){
    this.bar1 = bar1;
    this.bar2 = bar2;
    this.pg = applet.createGraphics(sizeX, sizeY);
    this.applet = applet;
    this.bar1process = bar1process;
    this.bar2process = bar2process;  
    this.timeToTarget = 0;
    this.timeStarted = applet.millis();
  }
  
  public int getWidth() {
    return this.pg.width;
  }
  
  public int getHeight() {
    return this.pg.height;
  }
  
  // Set color to Red or Green, based on value (between [-1, 1]).
  public void setColor(double value) {
    if (value < 0) {
      pg.fill(140+(int)(100*(-value)), 0, 0);
    } else {
      pg.fill(0, 140+(int)(100*(value)), 0);
    }
  }
  
  public void draw(int x, int y){
    pg.beginDraw();
    pg.background(backgroundColor.getRed(), backgroundColor.getGreen(), backgroundColor.getBlue());
    pg.fill(roundedBoxColor.getRed(), roundedBoxColor.getGreen(), roundedBoxColor.getBlue());
    pg.rect(0, 0, pg.width, pg.height, 10);
    
    // UX stuff
    int barHeight = 35;
    int barWidth = pg.width - 212 - 300;
    int barStartX = 300;
    int bar1StartY = 56;
    int bar2StartY = 102;
    int strokeWeight = 3;
    int halfSize = (int)(barWidth/2.0f);
    
    // background
    pg.fill(barBackgroundColor.getRed(), barBackgroundColor.getGreen(), barBackgroundColor.getBlue());
    pg.strokeWeight(strokeWeight);
    pg.stroke(0, 0, 0);
    pg.rect(barStartX, bar1StartY, barWidth, barHeight);
    pg.rect(barStartX, bar2StartY, barWidth, barHeight);
    
    // draw bars: Black magic, don't touch to animation logic
    double bar1Size = bar1process;
    double bar2Size = bar2process;
    if (isBarInProgress()) {
      double process = (double)(applet.millis() - timeStarted) / (double)timeToTarget;  // value range [0, 1]
      bar1Size =  bar1process + (orginalBar1Pos - bar1process) * (1.0f - process);
      bar2Size =  bar2process + (orginalBar2Pos - bar2process) * (1.0f - process);    // value range [-1, 1]
    }
    
    // fuel efficiency bar
    setColor(bar1Size);
    pg.strokeWeight(strokeWeight);
    pg.stroke(0, 0, 0);
    pg.rect(barStartX + halfSize, bar1StartY, (int)(halfSize*bar1Size), barHeight);
    
    // safety bar
    setColor(bar2Size);
    pg.strokeWeight(strokeWeight);
    pg.stroke(0, 0, 0);
    pg.rect(barStartX + halfSize, bar2StartY, (int)(halfSize*bar2Size), barHeight);
    
    // middle bar
    pg.fill(0,0,0,255);
    pg.rect(barStartX+halfSize-1, bar1StartY-barHeight/2, strokeWeight, 120);
    
    // left side texts
    pg.textSize(20);
    pg.textAlign(PConstants.RIGHT, PConstants.CENTER);
    pg.fill(textColor.getRed(), textColor.getGreen(), textColor.getBlue());
    pg.text(bar1, barStartX-12, bar1StartY+(barHeight/2));
    pg.text(bar2, barStartX-12, bar2StartY+(barHeight/2));

    pg.endDraw();
    
    applet.image(pg, x, y);
  }
  
//  public void drawBar(PGraphics g, int x, int y, int sx, int sy, float percent) {
//  g.fill(255);
//  g.rect(x,y, sx, sy);
//  g.fill(barColor.getRed(), barColor.getGreen(), barColor.getBlue());
//  g.rect(x,y, (int)(sx*percent), sy);
//}

  public boolean isBarInProgress() {
    return applet.millis() - timeStarted < timeToTarget;
  }
  
  public float getBar1Process(){
    return bar1process;
  }
  
  public float getBar2Process(){
    return bar2process;
  }
  
  public void setBar12Progress(float barprocess2, float barprocess1, int timeToTarget) {
    if (isBarInProgress()) return;
    orginalBar1Pos = this.bar1process;
    orginalBar2Pos = this.bar2process;
    this.bar1process = barprocess1; 
    this.bar2process = barprocess2;
    this.timeStarted = applet.millis();
    this.timeToTarget = timeToTarget;
    // System.out.println("Process1: " + barprocess1 + " orginal: " + orginalBar1Pos + "  time " + timeToTarget);
    // System.out.println("Process2: " + barprocess2 + " orginal: " + orginalBar2Pos + "  time " + timeToTarget);
    
  }
}

enum UserCommand {
  UNKNOWN('.'), START('s'), END('e'), APPROVE('+'), DENY('-'), RESTART('r'), NEXT('p');
  
  private final char value;
    private UserCommand(char value){
        this.value = value;
    }
    
    public static UserCommand fromSerial(char c) {
        switch (c) {
          case 's': return START;
          case 'd': return END;
          case '-': return DENY;
          case '+': return APPROVE;
          case 'p': return NEXT;
          case 'n': return RESTART;
          default: return UNKNOWN;
        }
    }
    
    public static UserCommand fromKeyboard(char c) {
        switch (c) {
          case 's': return START;
          case 'e': return END;
          case 'r': return RESTART;
          case 'n': return DENY;
          case 'y': return APPROVE;
          case 'p': return NEXT;
          default: return UNKNOWN;
        }
    }

  public char getValue() {
    return value;
  }
}





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
          videoClip.volume(0);
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
        
        applet.background(backgroundColor.getRed(), backgroundColor.getGreen(), backgroundColor.getBlue());
        applet.image(videoClip, (applet.width - videoClip.width)/2, barSetBackground.height); //, applet.width, applet.height - barSetBackground.height);
        applet.image(barSetBackground, 0, 0);

        
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

enum WeatherMode {
  ECO(0), SLIPPERY(1), UPHILL(2), WET(3), UNKNOWN(4);

  private int value;
  private WeatherMode(int value) {
    this.value = value;
  }
}

enum SceneType {
  UNKNOWN, VIDEO, IMAGE
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--present", "--window-color=#666666", "--stop-color=#cccccc", "truckSceneG" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
