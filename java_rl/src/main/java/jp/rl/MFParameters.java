package jp.rl;

public class MFParameters {
    public double alpha = 0.1;
    public double gamma = 0.9;
    public double lambda = 0.9;
    public double explorationFactor = 0.1;
    public boolean updateQTablePerm = true;
    public boolean useKTD = false;
    public boolean changeLearningFactorWithCounts = false;
}
