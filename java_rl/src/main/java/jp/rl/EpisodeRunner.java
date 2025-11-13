package jp.rl;

import java.util.*;

public class EpisodeRunner {
    private final Environment env;
    private final Random rng;

    public EpisodeRunner(Environment env, long seed) {
        this.env = env;
        this.rng = new Random(seed);
    }

    public Result runEpisode(int maxSteps, int startState) {
        List<Integer> lastStates = new ArrayList<>(maxSteps);
        List<Integer> lastActions = new ArrayList<>(maxSteps);
        List<Double> lastRewards = new ArrayList<>(maxSteps);

        // Create simple model and Q-table
        Model model = Model.createFromEnvironment(env, 4, false);
        QTablePerm q = new QTablePerm(env.numStates, env.numActions);
        MFParameters mf = new MFParameters();
        Stepper stepper = new Stepper(env);

        int currentState = startState;
        for (int step = 0; step < maxSteps; step++) {
            Stepper.StepResult r = stepper.step(currentState, q, model, mf, true, true, rng);
            lastStates.add(currentState);
            lastActions.add(r.action);
            lastRewards.add(r.reward);
            currentState = r.newState;
        }

        Result res = new Result();
        res.lastStates = lastStates;
        res.lastActions = lastActions;
        res.lastRewards = lastRewards;
        res.maxSteps = maxSteps;
        return res;
    }
}
