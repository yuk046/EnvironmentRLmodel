package jp.rl;

import java.util.Arrays;

public class DP {

    // Value iteration for MDP defined by Environment
    // Returns greedy policy (1-based action index per state) and value function (1-based indexing arrays)
    public static class DPResult {
        public double[] V; // 1-based, length numStates+1
        public int[] policy; // 1-based actions per state, length numStates+1
    }

    public static DPResult valueIteration(Environment env, double gamma, double tol, int maxIter) {
        int S = env.numStates;
        int A = env.numActions;
        double[] V = new double[S+1];
        int[] policy = new int[S+1];
        Arrays.fill(V, 0.0);
        Arrays.fill(policy, 1);

        for (int it = 0; it < maxIter; it++) {
            double delta = 0.0;
            double[] Vnew = new double[S+1];
            for (int s = 1; s <= S; s++) {
                double best = Double.NEGATIVE_INFINITY;
                int bestA = 1;
                for (int a = 1; a <= A; a++) {
                    int idx = (s - 1) * A + (a - 1);
                    double[] ps = env.ps.get(idx);
                    int[] nsts = env.nextStates.get(idx);
                    double[] rws = env.rewards.get(idx);
                    double qsa = 0.0;
                    for (int i = 0; i < ps.length; i++) {
                        int ns = nsts[i];
                        double rw = (rws != null && i < rws.length) ? rws[i] : 0.0;
                        qsa += ps[i] * (rw + gamma * V[ns]);
                    }
                    if (qsa > best) { best = qsa; bestA = a; }
                }
                Vnew[s] = best;
                policy[s] = bestA;
                delta = Math.max(delta, Math.abs(Vnew[s] - V[s]));
            }
            V = Vnew;
            if (delta < tol) break;
        }
        DPResult res = new DPResult();
        res.V = V;
        res.policy = policy;
        return res;
    }
}
