package jp.rl;

import java.util.*;

public class EpisodeRunner {
    private final Environment env;
    private final Random rng;

    public EpisodeRunner(Environment env, Random rng) {
        this.env = env;
        this.rng = rng;
    }

    public Result runEpisode(int maxSteps, int startState) {
        List<Integer> lastStates = new ArrayList<>(maxSteps);
        List<Integer> lastActions = new ArrayList<>(maxSteps);
        List<Double> lastRewards = new ArrayList<>(maxSteps);

        // Create simple model and Q-table
        Model model = Model.createFromEnvironment(env, 4, false);
        QTablePerm q = new QTablePerm(env.numStates, env.numActions);
        // reset eligibility traces at start of episode to match typical TD(lambda) episode semantics
        q.resetEligibility();
        MFParameters mf = new MFParameters();
        Stepper stepper = new Stepper(env);

        // state-action visit counts (1-based indexing accommodated by sizing)
        int[][] stateActionVisitCounts = new int[env.numStates+1][env.numActions+1];

        int currentState = startState;
        for (int step = 0; step < maxSteps; step++) {
            Stepper.StepResult r = stepper.step(currentState, q, model, mf, true, true, stateActionVisitCounts, rng);
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
