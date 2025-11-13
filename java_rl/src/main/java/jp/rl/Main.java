package jp.rl;

public class Main {
    public static void main(String[] args) {
        double[] betas = new double[]{0.0, 0.2, 0.4, 0.6, 0.8, 1.0};
        int numAgents = 2; // small by default for quick run
        int numRuns = 3;

        EnvironmentParameters envParams = new EnvironmentParameters();
        BatchRunner runner = new BatchRunner(betas, numAgents, numRuns, envParams);
        try {
            runner.run();
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }
    }
}
