import processing.serial.*;
import processing.video.*;

import processing.core.PApplet;
import processing.serial.Serial;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;


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
  new SceneData(0.67f, -0.5f, 0.33f, -0.05f, WeatherMode.ECO, WeatherMode.SLIPPERY, 0.0f, 15.0f, 2000, 5000, 3000, videoFolderPath + "scene1.mp4"), 
  new SceneData(0.0f, 0.8f, 0.7f, 0.8f, WeatherMode.SLIPPERY, WeatherMode.ECO, 0.0f, 15.0f, 2000, 8000, 5000, videoFolderPath + "scene2.mp4"), 
  new SceneData(0.6f, -0.3f, 0.4f, -0.08f, WeatherMode.ECO, WeatherMode.UPHILL, 0.0f, 15.0f, 2000, 8000, 5000, videoFolderPath + "scene3.mp4"), 
  new SceneData(0.75f, -0.47f, 0.41f, -0.02f, WeatherMode.ECO, WeatherMode.WET, 0.0f, 15.0f, 2000, 8000, 5000, videoFolderPath + "scene4.mp4"), 
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

void settings() {
  size(1680, 1050, P2D);
  //fullScreen(1);
  println(dataPath(""));
}

void setup() {
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
    exit();
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

void initializeScenarios() {
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

void initNextScenario() {
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

  // Beginning of each scenario initialize the small screen's Weather mode
  dashboard.setWeatherMode(scenes[scenarioIdx].startWeatherMode);
  println("Dashboard weather " + dashboard.frameRate);
}

void restartScenarios() {
  scenarios.get(scenarioIdx).stop();
  scenarioIdx = scenarios.size() - 1;
  println("(re)starting scenarios");
  initNextScenario();
}



/*
   * Update top bar sizes based on user inputs
 */
void updateBarSizes() {
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

void draw() {
  boolean running = scenarios.get(scenarioIdx).draw();

  // Move forward on scenarios
  if (!running) {
    initNextScenario();
  }

  // Build scenarios
  if (scenes[scenarioIdx].sceneType == SceneType.VIDEO) {

    // shorter waiting time, when mode is manually selected
    if (dashboard.getModeActivationTimer() > scenes[scenarioIdx].questionAfterTime && 
      sceneAnswers.get(scenarioIdx) != QuestionStatus.UNKNOWN) {
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
   /*
    // Set text on top of bubbles
    textSize(46);
    textAlign(CENTER);
    fill(0);
    text(String.format("%c%.1f%%", (safetyOverallChange >= 0) ? '+' : '-', safetyOverallChange), 1170, 640);
    text(String.format("%c%.1f%%", (fuelOverallChange >= 0) ? '+' : '-', fuelOverallChange * 10), 760, 640);
    */
  }

  // Handle user inputs and update bar sizes
  updateBarSizes();

  // Handle fading events
  transitionBetweenScenarios();
  
  fill(255);
  textSize(16);
  text("FPS: " + (int)frameRate, 20, 30);
}

int CalculateSafetyScore() {
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

int CalculateFEScore() {
 int scoreFE = 4;
 QuestionStatus q = (2 < sceneAnswers.size()) ? sceneAnswers.get(2) : QuestionStatus.UNKNOWN;
 if (q == QuestionStatus.DENIED) {
   scoreFE--;
 }
 return max(scoreFE, 0);
}

void transitionBetweenScenarios() {

  // Handle fade out from video scenarios
  int fadeTime = 1000;
  if (scenes[scenarioIdx].sceneType == SceneType.VIDEO) {
    boolean videoIsEnding = ((VideoScenario)scenarios.get(scenarioIdx)).videoTimeLeft() < fadeTime;
    boolean userSelectionCompleted = dashboard.getModeActivationTimer() + fadeTime > scenes[scenarioIdx].questionAfterTime && sceneAnswers.get(scenarioIdx) != QuestionStatus.UNKNOWN;

    int v = 0;
    if (videoIsEnding || userSelectionCompleted) {
      if (videoIsEnding) {
        v = (int)(255 * ((float)fadeTime - ((VideoScenario)scenarios.get(scenarioIdx)).videoTimeLeft()) / fadeTime);
      } else {
        v = 255 - (int)(255 * ((float)(scenes[scenarioIdx].questionAfterTime - dashboard.getModeActivationTimer()) / fadeTime));
      }
      fill(0, 0, 0, v);
      rect(0, 0, width, height);
    }
  }

  // Handle fade in
  int fadeInTime = 1000;
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
void keyReleased() {
  userCommand = UserCommand.fromKeyboard(key);
  println(scenarioIdx + ") Key pressed: " + key + "      Command: " + userCommand.name());
}

// Serial format:
// <6-bits for switch state><tab delimiter><char for gear>
// where the chars are p,r,n,d,s,- and + for park, reverse, neutral, drive,
// smart-auto and plus/minus
// return -1 if denied, 0 nothing happened, 1 approved
int readSerial() {
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
int handleUserEvent() {

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
      return 1;
    }
    break;
  case DENY: 
    if (dashboard.hasModeActivationStarted() && dashboard.isWeatherModeChanging()) {
      dashboard.completeWeatherModeSelection(false);
      modeChangeDenied = 1;
      sceneAnswers.set(scenarioIdx, QuestionStatus.DENIED);
      return -1;
    }
    break;
  }
  return 0;
}