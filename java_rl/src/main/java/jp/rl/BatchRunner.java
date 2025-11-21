package jp.rl;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.io.File;
import java.io.FileWriter;
import java.nio.file.Files;
import java.util.*;

// JFreeChart imports for plotting (to reproduce MATLAB plots)
import org.jfree.chart.ChartFactory;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.ChartUtils;
import org.jfree.data.xy.XYSeries;
import org.jfree.data.xy.XYSeriesCollection;

public class BatchRunner {
    private final double[] betas;
    private final int numAgents;
    private final int numRuns;
    private final EnvironmentParameters envParams;
    private final long rngBase;

    public BatchRunner(double[] betas, int numAgents, int numRuns, EnvironmentParameters envParams, long rngBase) {
        this.betas = betas;
        this.numAgents = numAgents;
        this.numRuns = numRuns;
        this.envParams = envParams;
        this.rngBase = rngBase;
    }

    public void run() throws Exception {
        File dataDir = new File("data");
        if (!dataDir.exists()) Files.createDirectories(dataDir.toPath());
        List<Double> meanAddictedAcrossBetas = new ArrayList<>();

        for (int ib = 0; ib < betas.length; ib++) {
            double beta = betas[ib];
            System.out.println(String.format("=== Beta = %.2f (%d/%d) ===", beta, ib+1, betas.length));

            Environment environment = Environment.createFromParameters(envParams);

            double[] percentAddictedPerRun = new double[numRuns];

            for (int runIdx = 0; runIdx < numRuns; runIdx++) {
                int addictedCount = 0;
                // ここでnumRunsごとにシードを設定している。
                long seedRun = this.rngBase + runIdx + (ib * 10000L);
                Random runRng = new Random(seedRun);
                for (int agentIdx = 0; agentIdx < numAgents; agentIdx++) {
                    // use the same runRng stream across agents so draws match MATLAB's rng seeded per run
                    // Build InputVals and parameters to call EpisodeWithResetAndStatistics (includes MB planning)
                    InputVals inputVals = new InputVals();
                    int maxSteps = envParams != null ? envParams.maxSteps : 2600;
                    int startState = envParams != null ? envParams.startState : 4;
                    inputVals.maxsteps = maxSteps;
                    inputVals.initDrugStartSteps = envParams != null ? envParams.initDrugStartSteps : 50;
                    inputVals.therapyStartSteps = envParams != null ? envParams.therapyStartSteps : 1000;
                    inputVals.therapyEndSteps = envParams != null ? envParams.therapyEndSteps : (inputVals.therapyStartSteps + 1000);
                    inputVals.simulatedTherapy = false;
                    inputVals.resetModelFactor = 0.99;
                    inputVals.resetPolicyFactor = 0.99;
                    inputVals.Environment = environment;
                    inputVals.start = startState;

                    // MF params
                    MFParameters mf = new MFParameters();
                    mf.alpha_MF = 0.1;
                    mf.gamma_MF = 0.9;
                    mf.lambda_MF = 0.9;
                    mf.explorationFactor = 0.1;
                    mf.randExpl = true;
                    mf.updateQTablePerm = true;

                    // MB params (set according to beta)
                    MBParameters mb = new MBParameters();
                    mb.mb_factor = beta;
                    mb.mf_factor = Math.max(0.0, 1.0 - beta);
                    mb.runInternalSimulation = true; // enable planning integration
                    mb.updateModel = true;
                    mb.modelLearningFactor = 1.0;
                    mb.modelDecay = 0.01;
                    mb.computeStatistics = false;
                    mb.MaxItrMB = 200;
                    mb.MaxTotalSimSteps = 50;
                    mb.StoppingPathLengthMB = 12;
                    mb.pStopPath = 0.05;
                    mb.UCTK = 5.0;

                    MBReplayParameters mbbw = new MBReplayParameters();
                    mbbw.internalReplay = 0;

                    inputVals.parametersMF = mf;
                    inputVals.parametersMBFW = mb;
                    inputVals.parametersMBBW = mbbw;
                    inputVals.therapyModelLF = 2.0;
                    inputVals.therapyMFLFF = 1.0;

                    // Run the episode using the debug-run variant that accepts RNG for reproducibility
                    Result res = EpisodeWithResetAndStatistics.runDebug(inputVals, runRng, false);

                    // determine addiction based on last states (use last state visits)
                    List<Integer> states = res.lastStates;
                    int drugVisits = 0;
                    for (int s : states) {
                        for (int ds : environment.drugStates) {
                            if (s == ds) drugVisits++;
                        }
                    }
                    int healthyVisits = 0;
                    for (int s : states) {
                        for (int hs : environment.goalStates) {
                            if (s == hs) healthyVisits++;
                        }
                    }
                    if (drugVisits > healthyVisits) addictedCount++;
                }
                percentAddictedPerRun[runIdx] = 100.0 * addictedCount / numAgents;
                System.out.println(String.format("[run %d/%d] %%addicted=%.2f", runIdx+1, numRuns, percentAddictedPerRun[runIdx]));
            }

            String bstr = String.format("%.2f", beta).replace('.', '_');
            Map<String,Object> out = new HashMap<>();
            out.put("percentAddicted", percentAddictedPerRun);
            Gson g = new GsonBuilder().setPrettyPrinting().create();
            try (FileWriter fw = new FileWriter(new File(dataDir, String.format("results_beta_%s.json", bstr)))) {
                fw.write(g.toJson(out));
            }
            System.out.println("Saved results for beta=" + beta);

            // record mean across runs for plotting
            double sum = 0.0;
            for (double v : percentAddictedPerRun) sum += v;
            double mean = percentAddictedPerRun.length>0 ? sum / percentAddictedPerRun.length : 0.0;
            meanAddictedAcrossBetas.add(mean);
        }

        // create plot percentAddicted vs beta (PNG)
        try {
            XYSeries series = new XYSeries("% Addicted");
            for (int i = 0; i < betas.length; i++) series.add(betas[i], meanAddictedAcrossBetas.get(i));
            XYSeriesCollection dataset = new XYSeriesCollection(series);
            JFreeChart chart = ChartFactory.createXYLineChart("Percent Addicted vs Beta", "beta", "% addicted", dataset);
            File chartFile = new File(dataDir, "percentAddicted_vs_beta.png");
            ChartUtils.saveChartAsPNG(chartFile, chart, 800, 600);
            System.out.println("Saved plot: " + chartFile.getAbsolutePath());
        } catch (Exception e) {
            System.err.println("Failed to create plot: " + e.getMessage());
        }
    }
}
