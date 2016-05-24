
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