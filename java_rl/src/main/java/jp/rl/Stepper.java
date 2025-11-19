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
                           int[][] stateActionVisitCounts,
                           Random rng) {

        int action = 1;
        // selection behavior mirrors selectActionSimDyna (MATLAB)
        if (mfParams.randExpl) {
            if (rng.nextDouble() < mfParams.explorationFactor) {
                action = 1 + rng.nextInt(env.numActions);
            } else {
                double bestVal = Double.NEGATIVE_INFINITY;
                int bestA = 1;
                for (int a = 1; a <= env.numActions; a++) {
                    double v = q.mean[currentState][a];
                    // tiny noise to break ties as MATLAB did
                    double nv = v + 1e-8 * rng.nextDouble();
                    if (nv > bestVal) { bestVal = nv; bestA = a; }
                }
                action = bestA;
            }
        } else if (mfParams.softMax) {
            // softmax selection with temperature
            double T = mfParams.softMax_t;
            double[] w = new double[env.numActions + 1];
            for (int a = 1; a <= env.numActions; a++) w[a] = q.mean[currentState][a];
            double[] expw = new double[env.numActions + 1];
            double sum = 0.0;
            boolean allZero = true;
            for (int a = 1; a <= env.numActions; a++) {
                double val = Math.exp(w[a] / T);
                if (Double.isNaN(val) || val == 0.0) {
                    expw[a] = 0.0;
                } else {
                    expw[a] = val; allZero = false;
                }
                sum += expw[a];
            }
            if (allZero || sum == 0.0) {
                // fallback to greedy with tiny noise
                double bestVal = Double.NEGATIVE_INFINITY; int bestA = 1;
                for (int a = 1; a <= env.numActions; a++) {
                    double nv = q.mean[currentState][a] + 1e-8 * rng.nextDouble();
                    if (nv > bestVal) { bestVal = nv; bestA = a; }
                }
                action = bestA;
            } else {
                // sample according to weights
                double x = rng.nextDouble() * sum;
                double c = 0.0;
                for (int a = 1; a <= env.numActions; a++) {
                    c += expw[a];
                    if (x <= c) { action = a; break; }
                }
            }
        } else {
            // default greedy
            double best = Double.NEGATIVE_INFINITY; int bestA = 1;
            for (int a = 1; a <= env.numActions; a++) {
                if (q.mean[currentState][a] > best) { best = q.mean[currentState][a]; bestA = a; }
            }
            action = bestA;
        }

        // increment visit counts (MATLAB increments before update)
        if (stateActionVisitCounts != null) {
            if (currentState >= 0 && currentState < stateActionVisitCounts.length && action >= 0 && action < stateActionVisitCounts[currentState].length) {
                stateActionVisitCounts[currentState][action] += 1;
            }
        }

        Environment.Transition t = env.sampleTransition(currentState, action, rng);
        int newState = t.nextState;
        double reward = t.reward;

        if (updateModelFlag) {
            model.updateModel(currentState, action, newState, reward, 0.999, false, 1.0);
        }

        if (updateQTablePermFlag) {
            QUpdater.UpdateResult ur = QUpdater.updateQTablePerm(q, reward, newState, action, currentState, stateActionVisitCounts, mfParams, 0);
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
