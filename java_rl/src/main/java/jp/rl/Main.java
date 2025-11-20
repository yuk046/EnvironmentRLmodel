package jp.rl;

public class Main {
    public static void main(String[] args) {
        double[] betas = new double[]{0.0, 0.2, 0.4, 0.6, 0.8, 1.0};
        // Use full-experiment defaults matching MATLAB `run_batch_beta.m`
        int numAgents = 50;
        int numRuns = 150;
        int maxsteps = 1050; // steps per episode
        int startState = 4; // initial state

        EnvironmentParameters envParams = new EnvironmentParameters();
        BatchRunner runner = new BatchRunner(betas, numAgents, numRuns, maxsteps, startState, envParams);
        try {
            runner.run();
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }
    }
}
