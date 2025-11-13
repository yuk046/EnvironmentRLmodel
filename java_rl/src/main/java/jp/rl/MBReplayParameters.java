package jp.rl;

public class MBReplayParameters {
    public double sigma_square_noise_external = 0.000001;
    public double noiseVal = 0.000001;
    public double P_starting_point_high_R = 1.0;
    public double P_starting_point_Low_R = 1.0;
    public int internalReplay = 0;
    // Added fields expected by InternalSimulator
    public int sweeps = 5;
    public int stepsTotal = 100;
    public int sweepsDepth = 20;
    public double restart_sweep_Prob = 0.1;
}
