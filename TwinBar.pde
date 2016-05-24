import java.awt.Color;

import processing.core.PApplet;
import processing.core.PConstants;
import processing.core.PGraphics;

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
    int halfSize = (int)(barWidth/2.0);
    
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
      bar1Size =  bar1process + (orginalBar1Pos - bar1process) * (1.0 - process);
      bar2Size =  bar2process + (orginalBar2Pos - bar2process) * (1.0 - process);    // value range [-1, 1]
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