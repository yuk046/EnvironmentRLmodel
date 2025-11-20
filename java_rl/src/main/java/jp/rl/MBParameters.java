package jp.rl;

public class MBParameters {
    public double alpha = 0.2;
    public double mb_factor = 0.5;
    public double mf_factor = 0.5;
    public boolean computePolicyWithDP = false;
    public boolean mixMFMBPolicies = true;
    public boolean softMaxMix = false;
    public String MBMethod = "DPBound";
    public boolean runInternalSimulation = false;
    public boolean updateModel = false;
    public double modelLearningFactor = 1.0;
    public double modelDecay = 0.01;
    public boolean computeStatistics = false;
    public int MaxItrMB = 10;
    public int MaxTotalSimSteps = 50;
    public int StoppingPathLengthMB = 12;
    public double pStopPath = 0.05;
    public double explorationFactor = 0.1;
    public boolean useMFToDriveMB = false;
    public boolean knownTransitions = false;
    public double UCTK = 5.0;
    public boolean randExpl = false;
}
