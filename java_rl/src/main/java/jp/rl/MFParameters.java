package jp.rl;

public class MFParameters {
    // Model-free parameters (match MATLAB naming)
    public double alpha_MF = 0.1; // base learning rate for MF
    public double gamma_MF = 0.9; // discount for MF
    public double lambda_MF = 0.9; // eligibility trace factor (not yet used)
    public double explorationFactor = 0.1; // epsilon for randExpl
    public boolean randExpl = true; // if true, use epsilon-greedy; if false and softMax==true, use softmax
    public boolean softMax = false;
    public double softMax_t = 1.0; // temperature for softmax

    // other flags
    public boolean updateQTablePerm = true;
    public boolean useKTD = false;
    public boolean changeLearningFactorWithCounts = false;
}
