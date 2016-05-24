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