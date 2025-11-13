package jp.rl;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.io.File;
import java.io.FileWriter;
import java.nio.file.Files;
import java.util.*;

public class BatchRunner {
    private final double[] betas;
    private final int numAgents;
    private final int numRuns;
    private final EnvironmentParameters envParams;

    public BatchRunner(double[] betas, int numAgents, int numRuns, EnvironmentParameters envParams) {
        this.betas = betas;
        this.numAgents = numAgents;
        this.numRuns = numRuns;
        this.envParams = envParams;
    }

    public void run() throws Exception {
        File dataDir = new File("data");
        if (!dataDir.exists()) Files.createDirectories(dataDir.toPath());

        for (int ib = 0; ib < betas.length; ib++) {
            double beta = betas[ib];
            System.out.println(String.format("=== Beta = %.2f (%d/%d) ===", beta, ib+1, betas.length));

            Environment environment = Environment.createFromParameters(envParams);

            double[] percentAddictedPerRun = new double[numRuns];

            for (int runIdx = 0; runIdx < numRuns; runIdx++) {
                int addictedCount = 0;
                for (int agentIdx = 0; agentIdx < numAgents; agentIdx++) {
                    long seed = runIdx + agentIdx + (ib * 10000);
                    EpisodeRunner er = new EpisodeRunner(environment, seed);
                    Result res = er.runEpisode(200, 4); // short default

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
        }
    }
}
