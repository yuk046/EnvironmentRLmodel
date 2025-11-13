package jp.rl;

import java.util.*;

public class Stepper {
    private final Environment env;

    public Stepper(Environment env) {
        this.env = env;
    }

    // simplified step: select action (epsilon-greedy on Q), execute, optionally update model and Q
    public StepResult step(int currentState,
                           QTablePerm q,
                           Model model,
                           MFParameters mfParams,
                           boolean updateModelFlag,
                           boolean updateQTablePermFlag,
                           Random rng) {

        // epsilon-greedy action selection using explorationFactor
        double eps = mfParams.explorationFactor;
        int action;
        if (rng.nextDouble() < eps) {
            action = 1 + rng.nextInt(env.numActions);
        } else {
            // greedy
            double best = Double.NEGATIVE_INFINITY;
            int bestA = 1;
            for (int a = 1; a <= env.numActions; a++) {
                if (q.mean[currentState][a] > best) { best = q.mean[currentState][a]; bestA = a; }
            }
            action = bestA;
        }

        Environment.Transition t = env.sampleTransition(currentState, action, rng);
        int newState = t.nextState;
        double reward = t.reward;

        if (updateModelFlag) {
            model.updateModel(currentState, action, newState, reward, 0.999, false, 1.0);
        }

        if (updateQTablePermFlag) {
            // use QUpdater to perform MATLAB-equivalent base update
            // counts info not tracked here yet; pass null
            QUpdater.UpdateResult ur = QUpdater.updateQTablePerm(q, reward, newState, action, currentState, null, mfParams, 0);
            q = ur.Q;
        }

        StepResult r = new StepResult();
        r.action = action;
        r.newState = newState;
        r.reward = reward;
        r.q = q;
        r.model = model;
        return r;
    }

    public static class StepResult {
        public int action;
        public int newState;
        public double reward;
        public QTablePerm q;
        public Model model;
    }
}
