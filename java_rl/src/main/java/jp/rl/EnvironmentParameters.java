package jp.rl;

public class EnvironmentParameters {
    public double punishmentOutsideLine = -0.3;
    public int[] sides = new int[]{4,4};
    public int nHealthyGoals = 1;
    public double[] rewGoals = new double[]{1.0};
    public double pGetRewardGoals = 0.5;
    public double pGetRewardDrug = 0.5;
    public int nDrugGoals = 15;
    public double rewDG = 10.0;
    public double[] rewDGV = new double[]{1.0, 0.5};
    public double punDG = -4.0;
    public double[] punDGV = new double[]{-0.5, -0.75};
    public double[] pDG = new double[]{0.75};
    public double[] pDGV = new double[]{0.5,0.25};
    public double escaLationFactorDG = 0.5;
    public int nBaseStates = 6;
    public boolean deterministic = false;
    public int autoGen = 1;
    public double reducedPunishmentF = 0.3;
    public double minFactor = 0.001;
    // Timing / experiment parameters (defaults chosen to match MATLAB RunExperimentLearning96)
    public int maxSteps = 1050;       // MATLAB: RunExperimentLearning96 uses 2600
    public int startState = 4;        // initial state to match MATLAB code
    public int initDrugStartSteps = 50;
    public int therapyStartSteps = 1050;
    public int therapyEndSteps = 1050; // therapyStartSteps + 1000 by convention
}
