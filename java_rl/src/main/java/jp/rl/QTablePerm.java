package jp.rl;

public class QTablePerm {
    public double[][] mean; // 1-based indexing simulated by sizing (numStates+1)x(numActions+1)

    public QTablePerm(int numStates, int numActions) {
        this.mean = new double[numStates+1][numActions+1];
        for (int i = 0; i < mean.length; i++) for (int j = 0; j < mean[i].length; j++) mean[i][j] = 0.0;
    }
}
