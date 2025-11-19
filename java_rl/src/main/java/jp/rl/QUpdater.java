package jp.rl;

public class QUpdater {

    public static class UpdateResult {
        public QTablePerm Q;
        public double maxk;
        public double maxvar;
        public double dreward;
        public double MA_noise_n;
    }

    public static UpdateResult updateQTablePerm(QTablePerm QtableIntegrated,
                                                double reward,
                                                int newState,
                                                int action,
                                                int currentState,
                                                int[][] counts,
                                                MFParameters parameters,
                                                int reset) {
        UpdateResult res = new UpdateResult();
        res.Q = QtableIntegrated;
        res.maxk = 0.0;
        res.MA_noise_n = 0.0;

        // Compute alpha/gamma according to MFParameters and counts
        UpdateBaseResult base = updateQTablePermBase(QtableIntegrated.mean, reward, newState, action, currentState, counts, parameters);
        res.dreward = base.dreward;

        double lambda = parameters.lambda_MF;
        double gamma = parameters.gamma_MF;
        // compute alpha according to counts if requested (match updateQLearning.m behaviour when changeLearningFactorWithCounts=true)
        double alphaForCurrent;
        if (parameters.changeLearningFactorWithCounts && counts != null && currentState >= 0 && currentState < counts.length && action >= 0 && action < counts[currentState].length) {
            int factor = counts[currentState][action];
            if (factor <= 0) factor = 1;
            alphaForCurrent = parameters.alpha_MF / (double) factor;
        } else {
            alphaForCurrent = parameters.alpha_MF;
        }

        // If lambda and gamma positive -> use eligibility traces (TD(lambda) style)
        if (lambda > 0.0 && gamma > 0.0) {
            // decay eTrace
            if (QtableIntegrated.eTrace == null) QtableIntegrated.eTrace = new double[QtableIntegrated.mean.length][QtableIntegrated.mean[0].length];
            int S = QtableIntegrated.mean.length - 1;
            int A = QtableIntegrated.mean[0].length - 1;
            double maxChange = 0.0;
            // decay existing traces
            for (int s = 1; s <= S; s++) for (int a = 1; a <= A; a++) QtableIntegrated.eTrace[s][a] *= (lambda * gamma);

            // set trace for current state-action
            QtableIntegrated.eTrace[currentState][action] = 1.0;

            // TD error d already computed in base.dreward
            double d = base.dreward;

            // apply updates to all state-actions using alpha adjusted for counts where appropriate
            for (int s = 1; s <= S; s++) {
                for (int a = 1; a <= A; a++) {
                    double alphaToUse = alphaForCurrent; // default
                    // if changeLearningFactorWithCounts and counts available for this (s,a), adjust per-entry
                    if (parameters.changeLearningFactorWithCounts && counts != null && s >= 0 && s < counts.length && a >= 0 && a < counts[s].length) {
                        int f = counts[s][a]; if (f <= 0) f = 1;
                        alphaToUse = parameters.alpha_MF / (double) f;
                    }
                    double change = alphaToUse * QtableIntegrated.eTrace[s][a] * d;
                    QtableIntegrated.mean[s][a] += change;
                    maxChange = Math.max(maxChange, Math.abs(change));
                }
            }
            res.Q = QtableIntegrated;
            res.maxvar = maxChange;
        } else {
            // fallback: standard one-step Q update (base.nq already computed)
            res.Q.mean[currentState][action] = base.nq;
            res.maxvar = Math.abs(base.maxvar);
        }

        return res;
    }

    private static class UpdateBaseResult {
        double nq;
        double maxvar;
        double dreward;
    }

    private static UpdateBaseResult updateQTablePermBase(double[][] QTablePerm,
                                                          double reward,
                                                          int new_state,
                                                          int action,
                                                          int currentState,
                                                          int[][] stateActionVisitCountsFactor,
                                                          MFParameters MFParameters) {
        UpdateBaseResult r = new UpdateBaseResult();
        double alpha;
        if (MFParameters.changeLearningFactorWithCounts) {
            int factor = 1;
            if (stateActionVisitCountsFactor != null && currentState < stateActionVisitCountsFactor.length && action < stateActionVisitCountsFactor[currentState].length) {
                factor = stateActionVisitCountsFactor[currentState][action];
                if (factor <= 0) factor = 1;
            }
            alpha = MFParameters.alpha_MF / (double) factor;
        } else {
            alpha = MFParameters.alpha_MF;
        }
        double gamma = MFParameters.gamma_MF;
        double oldVal = QTablePerm[currentState][action];
        double newVal = Double.NEGATIVE_INFINITY;
        for (int a = 1; a < QTablePerm[new_state].length; a++) if (QTablePerm[new_state][a] > newVal) newVal = QTablePerm[new_state][a];
        if (newVal == Double.NEGATIVE_INFINITY) newVal = 0.0;
        double dreward = (reward + gamma * newVal - oldVal);
        double maxvar = alpha * dreward;
        double nq = oldVal + maxvar;
        r.nq = nq;
        r.maxvar = Math.abs(maxvar);
        r.dreward = dreward;
        return r;
    }
}
