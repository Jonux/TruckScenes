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