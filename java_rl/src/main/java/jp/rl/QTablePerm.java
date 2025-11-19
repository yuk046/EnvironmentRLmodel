package jp.rl;

public class QTablePerm {
    public double[][] mean; // 1-based indexing simulated by sizing (numStates+1)x(numActions+1)
    // eligibility traces for TD-lambda updates (same sizing as mean)
    public double[][] eTrace;

    public QTablePerm(int numStates, int numActions) {
        this.mean = new double[numStates+1][numActions+1];
        for (int i = 0; i < mean.length; i++) for (int j = 0; j < mean[i].length; j++) mean[i][j] = 0.0;
        this.eTrace = new double[numStates+1][numActions+1];
        for (int i = 0; i < eTrace.length; i++) for (int j = 0; j < eTrace[i].length; j++) eTrace[i][j] = 0.0;
    }

    public void resetEligibility() {
        if (this.eTrace == null) return;
        for (int i = 0; i < eTrace.length; i++) for (int j = 0; j < eTrace[i].length; j++) eTrace[i][j] = 0.0;
    }
}
