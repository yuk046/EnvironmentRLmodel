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
}
