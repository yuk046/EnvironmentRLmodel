package jp.rl;

import java.util.Random;

public class DebugMain {
    public static void main(String[] args) {
        double beta = 0.5; // set non-zero MB mixing factor for debug
        int numAgents = 1;
        int numRuns = 1;
        int maxsteps = 1050; // match MATLAB default
        int startState = 4;

        EnvironmentParameters envParams = new EnvironmentParameters();
        Environment environment = Environment.createFromParameters(envParams);

        InputVals inputVals = new InputVals();
        inputVals.maxsteps = maxsteps;
        inputVals.initDrugStartSteps = 50;
        inputVals.therapyStartSteps = 1050;
        inputVals.therapyEndSteps = 1050;
        inputVals.simulatedTherapy = false;
        inputVals.resetModelFactor = 0.99;
        inputVals.resetPolicyFactor = 0.99;
        inputVals.Environment = environment;
        inputVals.start = startState;

        MFParameters mf = new MFParameters();
        mf.alpha_MF = 0.1;
        mf.gamma_MF = 0.9;
        mf.lambda_MF = 0.9;
        mf.explorationFactor = 0.1;
        mf.randExpl = true;
        mf.softMax = false;
        mf.softMax_t = 1.0;
        mf.changeLearningFactorWithCounts = false;
        mf.updateQTablePerm = true; // enable Q-table updates for learning
        mf.useKTD = false;

        MBParameters mb = new MBParameters();
        mb.alpha = 0.2;
        mb.mb_factor = beta;
        mb.mf_factor = Math.max(0.0, 1.0 - beta);
        mb.runInternalSimulation = true;
        mb.updateModel = true;
        mb.MaxTotalSimSteps = 50;
        mb.StoppingPathLengthMB = 12;
        mb.pStopPath = 0.05;
        mb.MBMethod = "DPBound";
        mb.UCTK = 5.0;

        MBReplayParameters mbbw = new MBReplayParameters();
        mbbw.internalReplay = 1; // enable internalReplay for debugging

        inputVals.parametersMF = mf;
        inputVals.parametersMBFW = mb;
        inputVals.parametersMBBW = mbbw;
        inputVals.therapyModelLF = 2.0;
        inputVals.therapyMFLFF = 1.0;

        long seed = 0L; // deterministic seed for debug
        Random rng = new Random(seed);

        System.out.println("Starting debug run (beta=" + beta + ")");
        Result res = EpisodeWithResetAndStatistics.runDebug(inputVals, rng, true);
        System.out.println("Debug run finished. Last states:");
        System.out.println(res.lastStates);
    }
}
