package jp.rl;

import java.util.*;

public class Model {
    public int numStates;
    public int numActions;
    public List<String> actionNames = new ArrayList<>();
    public List<String> nodeNames = new ArrayList<>();

    // For each state-action: probabilities, nextStates, rewards (mirror of Environment)
    public List<double[]> ps;
    public List<int[]> nextStates;
    public List<double[]> rewards;

    // counts for model learning
    public List<int[]> counts; // length = numStates*numActions, each element an int[] of counts per outcome

    public int priorCounts;

    // inverse transitions: for each endState (1-based) a list of PrevTransition entries
    public List<List<PrevTransition>> inverseTransitions;

    public static class PrevTransition {
        public int prevState;
        public int action;
        public double reward;
        public PrevTransition(int ps, int a, double r) { prevState = ps; action = a; reward = r; }
    }

    private Model() {}

    public static Model createFromEnvironment(Environment env, int priorCounts, boolean copyTransitions) {
        Model m = new Model();
        m.numStates = env.numStates;
        m.numActions = env.numActions;
        m.actionNames.addAll(env.actionNames);
        m.nodeNames.addAll(env.nodeNames);

        int total = m.numStates * m.numActions;
        m.ps = new ArrayList<>(Collections.nCopies(total, null));
        m.nextStates = new ArrayList<>(Collections.nCopies(total, null));
        m.rewards = new ArrayList<>(Collections.nCopies(total, null));
        m.counts = new ArrayList<>(Collections.nCopies(total, null));

        if (copyTransitions) {
            for (int i = 0; i < total; i++) {
                m.ps.set(i, env.ps.get(i).clone());
                m.nextStates.set(i, env.nextStates.get(i).clone());
                m.rewards.set(i, env.rewards.get(i).clone());
                m.counts.set(i, new int[m.ps.get(i).length]);
                Arrays.fill(m.counts.get(i), priorCounts);
            }
        } else {
            for (int i = 0; i < total; i++) {
                // initialize empty model: zero probs, single stay transition
                m.ps.set(i, new double[]{1.0});
                int state = (i / m.numActions) + 1;
                m.nextStates.set(i, new int[]{state});
                m.rewards.set(i, new double[]{0.0});
                m.counts.set(i, new int[]{priorCounts});
            }
        }
        m.priorCounts = priorCounts;
        // build inverse transitions map for sampling predecessors
        m.buildInverseTransitions();
        return m;
    }

    // simple updateModel to increment counts for observed transition
    public void updateModel(int currentState, int action, int newState, double reward, double modelDecay, boolean knownTransitions, double learningFactor) {
        int idx = (currentState - 1) * numActions + (action - 1);
        int[] cnt = counts.get(idx);
        int outcomeIndex = 0; // find matching nextState in stored nextStates
        int[] nsts = nextStates.get(idx);
        for (int i = 0; i < nsts.length; i++) {
            if (nsts[i] == newState) { outcomeIndex = i; break; }
        }
        if (outcomeIndex < cnt.length) cnt[outcomeIndex] += 1;
        else {
            // expand arrays
            int[] newCnt = Arrays.copyOf(cnt, outcomeIndex + 1);
            newCnt[outcomeIndex] = 1;
            counts.set(idx, newCnt);
        }
        // recompute ps estimate (simple normalized counts)
        int sum = 0; for (int v : counts.get(idx)) sum += v;
        double[] psArr = new double[counts.get(idx).length];
        for (int i = 0; i < psArr.length; i++) psArr[i] = (double) counts.get(idx)[i] / (double) sum;
        ps.set(idx, psArr);
        // rebuild inverse transitions for robustness (could be optimized)
        buildInverseTransitions();
    }

    public void buildInverseTransitions() {
        inverseTransitions = new ArrayList<>(numStates+1);
        for (int s = 0; s <= numStates; s++) inverseTransitions.add(new ArrayList<>());
        int total = numStates * numActions;
        for (int idx = 0; idx < total; idx++) {
            int state = idx / numActions + 1;
            int action = idx % numActions + 1;
            int[] nsts = nextStates.get(idx);
            double[] rws = rewards.get(idx);
            if (nsts != null) {
                for (int i = 0; i < nsts.length; i++) {
                    int to = nsts[i];
                    double rw = (rws != null && i < rws.length) ? rws[i] : 0.0;
                    inverseTransitions.get(to).add(new PrevTransition(state, action, rw));
                }
            }
        }
    }
}
