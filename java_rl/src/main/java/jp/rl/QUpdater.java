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

        if (parameters.useKTD) {
            // KTD not implemented: fallback to base
            UpdateBaseResult base = updateQTablePermBase(QtableIntegrated.mean, reward, newState, action, currentState, counts, parameters);
            res.Q.mean[currentState][action] = base.nq;
            res.maxvar = base.maxvar;
            res.dreward = base.dreward;
        } else {
            UpdateBaseResult base = updateQTablePermBase(QtableIntegrated.mean, reward, newState, action, currentState, counts, parameters);
            res.Q.mean[currentState][action] = base.nq;
            res.maxvar = Math.abs(base.maxvar);
            res.dreward = base.dreward;
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
            alpha = MFParameters.alpha / (double) factor;
        } else {
            alpha = MFParameters.alpha;
        }
        double gamma = MFParameters.gamma;
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
