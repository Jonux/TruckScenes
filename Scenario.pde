/**
 * Abstract interface for truck scenarios
 * @author Jonux
 */
public interface Scenario {

  // returns true, if the scenario is running
  public boolean draw2();

  // Start the scenario
  public void start2();

  // Stop the scenario
  public void stop2();

  // milliseconds from scenario started
  public int getStartTime();
}