package jp.rl;

public class Main {
    public static void main(String[] args) {
    double[] betas = new double[]{0.0, 0.2, 0.4, 0.6, 0.8, 1.0};
    // Full experiment defaults (match MATLAB run_batch_beta_new / RunExperimentLearning96)
    int numAgents = 25; // agents per run (MATLAB: run_batch_beta_new)
    int numRuns = 75;   // independent runs per beta (MATLAB: run_batch_beta_new)

    // Environment / timing parameters - defaults chosen to match RunExperimentLearning96
    EnvironmentParameters envParams = new EnvironmentParameters();
    // envParams has sensible defaults (maxSteps=2600, startState=4, etc.)
        // allow optional first argument to specify rng base seed (for reproducibility)
        long rngBase = 0L;
        if (args != null && args.length > 0) {
            try {
                rngBase = Long.parseLong(args[0]);
                System.out.println("Using rngBase seed: " + rngBase);
            } catch (NumberFormatException e) {
                System.err.println("Invalid rngBase argument, using default 0");
            }
        }
        BatchRunner runner = new BatchRunner(betas, numAgents, numRuns, envParams, rngBase);
        try {
            runner.run();
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }
    }
}
