package jp.rl;

import java.util.*;

public class Environment {
    public int numStates;
    public int numActions;
    public List<String> actionNames = new ArrayList<>();
    public List<String> nodeNames = new ArrayList<>();

    // For each state-action, list of possible next states and their probabilities
    public List<double[]> ps; // probabilities per (state*numActions + action)
    public List<int[]> nextStates; // nextStates per (state*numActions + action)
    public List<double[]> rewards; // rewards per (state*numActions + action)
    
    // drug/base specific rewards and probability helpers (porting MATLAB structures)
    public List<double[]> baseReward; // indexed by (drugPosIndex * numActions + action-1)
    public List<double[]> therapyReward;
    public List<double[]> basePs;
    public List<double[]> therapyPs;
    public Map<Integer,double[]> baseRewardBaseState = new HashMap<>();
    public Map<Integer,double[]> therapyRewardBaseState = new HashMap<>();

    public int[] drugStates;
    public int[] goalStates;
    public int[] drugReachableStates;
    public int toDrugActionIdx;

    private Random rng = new Random();

    private Environment() {}

    // helper setters for ported MATLAB behavior
    public void setBaseRewardForBaseState(int baseIdx, double[] vals) {
        baseRewardBaseState.put(baseIdx, vals);
    }
    public void setTherapyRewardForBaseState(int baseIdx, double[] vals) {
        therapyRewardBaseState.put(baseIdx, vals);
    }
    public void setBaseRewardEntry(int drugPosIndex, int action, double[] vals) {
        int idx = drugPosIndex * numActions + (action - 1);
        if (idx >= 0 && idx < baseReward.size()) baseReward.set(idx, vals);
    }
    public void setTherapyRewardEntry(int drugPosIndex, int action, double[] vals) {
        int idx = drugPosIndex * numActions + (action - 1);
        if (idx >= 0 && idx < therapyReward.size()) therapyReward.set(idx, vals);
    }

    public static Environment createFromParameters(EnvironmentParameters p) {
        Environment env = new Environment();
        int Num_States = p.nHealthyGoals + p.nDrugGoals + p.nBaseStates;
        int Num_Actions = p.nHealthyGoals + p.nBaseStates + (p.nDrugGoals > 0 ? 2 : 1);
        env.numStates = Num_States;
        env.numActions = Num_Actions;

        // basic action names
        // initialize action and node names (1-based style)
        for (int a = 1; a <= Num_Actions; a++) env.actionNames.add("");
        for (int st = 1; st <= Num_States; st++) env.nodeNames.add("");

        int total = Num_States * Num_Actions;
        env.ps = new ArrayList<>(Collections.nCopies(total, null));
        env.nextStates = new ArrayList<>(Collections.nCopies(total, null));
        env.rewards = new ArrayList<>(Collections.nCopies(total, null));

        // additional arrays used in MATLAB implementation for drug rewards
        env.baseReward = new ArrayList<>();
        env.therapyReward = new ArrayList<>();
        env.basePs = new ArrayList<>();
        env.therapyPs = new ArrayList<>();
        for (int i = 0; i < Math.max(1, p.nDrugGoals * Num_Actions); i++) {
            env.baseReward.add(null);
            env.therapyReward.add(null);
            env.basePs.add(null);
            env.therapyPs.add(null);
        }

        // helper lambdas
        java.util.function.BiConsumer<Integer,String> setActionName = (idx,name) -> env.actionNames.set(idx-1, name);
        java.util.function.BiConsumer<Integer,String> setNodeName = (idx,name) -> env.nodeNames.set(idx-1, name);

        int a_getDrugs = (p.nDrugGoals>0) ? (p.nHealthyGoals + p.nBaseStates + 2) : -1;
        int a_stay = (p.nHealthyGoals + p.nBaseStates + 1);

        setActionName.accept(a_stay, "a-stay");
        if (a_getDrugs>0) setActionName.accept(a_getDrugs, "a-getDrugs");

        // initialize default empty arrays
        for (int st = 1; st <= Num_States; st++) {
            for (int action = 1; action <= Num_Actions; action++) {
                int idx = (st - 1) * Num_Actions + (action - 1);
                env.ps.set(idx, new double[]{1.0});
                env.nextStates.set(idx, new int[]{st});
                env.rewards.set(idx, new double[]{0.0});
            }
        }

        // --- Goal states dynamics ---
        for (int st = 1; st <= p.nHealthyGoals; st++) {
            setNodeName.accept(st, "goal-"+st);
            for (int action = 1; action <= Num_Actions; action++) {
                int idx = (st - 1) * Num_Actions + (action - 1);
                if (action == st) {
                    setActionName.accept(st, "a-Goal-"+st);
                    double r = p.rewGoals.length >= st ? p.rewGoals[st-1] : p.rewGoals[0];
                    env.rewards.set(idx, new double[]{r});
                    env.ps.set(idx, new double[]{1.0});
                    env.nextStates.set(idx, new int[]{p.nHealthyGoals + (int)Math.ceil(p.nBaseStates/2.0)});
                } else {
                    env.rewards.set(idx, new double[]{0.0});
                    env.ps.set(idx, new double[]{1.0});
                    env.nextStates.set(idx, new int[]{st});
                }
            }
        }

        // --- Base states ---
        for (int st = p.nHealthyGoals+1; st <= p.nHealthyGoals + p.nBaseStates; st++) {
            setNodeName.accept(st, "base-"+st);
            int id = st - p.nHealthyGoals;
            for (int action = 1; action <= Num_Actions; action++) {
                int idx = (st - 1) * Num_Actions + (action - 1);
                if (action <= p.nHealthyGoals) {
                    env.rewards.set(idx, new double[]{0.0});
                    env.ps.set(idx, new double[]{1.0});
                    if (id == 1) env.nextStates.set(idx, new int[]{action}); else env.nextStates.set(idx, new int[]{st});
                } else if (action <= p.nHealthyGoals + p.nBaseStates) {
                    setActionName.accept(action, "a-toState-"+action);
                    if (Math.abs(st - action) <= 1) {
                        double p_succ = 0.99;
                        env.ps.set(idx, new double[]{1.0 - p_succ, p_succ});
                        env.rewards.set(idx, new double[]{0.0, 0.0});
                        env.nextStates.set(idx, new int[]{st, action});
                    } else {
                        double p_succ = 0.0001;
                        env.ps.set(idx, new double[]{1.0 - p_succ, p_succ});
                        env.rewards.set(idx, new double[]{0.0, p.punishmentOutsideLine});
                        env.nextStates.set(idx, new int[]{st, action});
                    }
                } else if (action == a_stay) {
                    env.rewards.set(idx, new double[]{0.0});
                    env.ps.set(idx, new double[]{1.0});
                    env.nextStates.set(idx, new int[]{st});
                } else if (action == a_getDrugs) {
                    int baseId = id - 1; // MATLAB used base index
                    if (st == (p.nHealthyGoals + p.nBaseStates)) {
                        // last base state leads towards drug start
                        // store baseRewardBaseState / therapyRewardBaseState for that baseId
                        env.setBaseRewardForBaseState(baseId, new double[]{p.rewDG});
                        env.setTherapyRewardForBaseState(baseId, new double[]{p.punDG});
                        env.nextStates.set(idx, new int[]{p.nHealthyGoals + p.nBaseStates + 1});
                    } else {
                        env.setBaseRewardForBaseState(baseId, new double[]{0.0});
                        env.setTherapyRewardForBaseState(baseId, new double[]{0.0});
                        env.nextStates.set(idx, new int[]{st});
                    }
                    env.ps.set(idx, new double[]{1.0});
                    env.rewards.set(idx, new double[]{0.0});
                }
            }
        }

        // --- Drug states ---
        for (int st = p.nHealthyGoals + p.nBaseStates + 1; st <= p.nHealthyGoals + p.nBaseStates + p.nDrugGoals; st++) {
            setNodeName.accept(st, "drug-"+st);
            int stpos = st - p.nHealthyGoals - p.nBaseStates; // 1-based within drugs
            double reducedPunishmentF = p.reducedPunishmentF;
            double r1 = p.punDG;
            double p1 = p.pDG.length>0 ? p.pDG[0] : 1.0;

            for (int action = 1; action <= Num_Actions; action++) {
                int idx = (st - 1) * Num_Actions + (action - 1);
                if (action <= p.nHealthyGoals + p.nBaseStates) {
                    // penalize
                    env.setBaseRewardEntry(stpos-1, action, new double[]{reducedPunishmentF * r1});
                    env.setTherapyRewardEntry(stpos-1, action, new double[]{reducedPunishmentF * r1});
                    env.rewards.set(idx, new double[]{p.punishmentOutsideLine});
                    env.ps.set(idx, new double[]{1.0});
                    env.nextStates.set(idx, new int[]{st});
                } else if (action == a_stay) {
                    if (st == (p.nHealthyGoals + p.nBaseStates + (int)Math.ceil(p.nDrugGoals/2.0))) {
                        // middle drug node: three outcomes
                        env.setBaseRewardEntry(stpos-1, action, new double[]{reducedPunishmentF*r1, r1, reducedPunishmentF*r1});
                        env.setTherapyRewardEntry(stpos-1, action, new double[]{reducedPunishmentF*r1, r1, reducedPunishmentF*r1});
                        env.rewards.set(idx, new double[]{p.punishmentOutsideLine, p.punishmentOutsideLine, p.punishmentOutsideLine});
                        env.ps.set(idx, new double[]{0.2, 0.6, 0.2});
                        int ns = Math.max((stpos+1) % (p.nDrugGoals+1),1) + p.nHealthyGoals + p.nBaseStates;
                        int pstat = stpos - 1;
                        if (pstat == 0) pstat = p.nDrugGoals;
                        pstat = pstat + p.nHealthyGoals + p.nBaseStates;
                        env.nextStates.set(idx, new int[]{ns, (p.nHealthyGoals + (int)Math.ceil(p.nBaseStates/2.0)), pstat});
                    } else {
                        env.setBaseRewardEntry(stpos-1, action, new double[]{reducedPunishmentF*r1, reducedPunishmentF*r1});
                        env.setTherapyRewardEntry(stpos-1, action, new double[]{reducedPunishmentF*r1, reducedPunishmentF*r1});
                        env.rewards.set(idx, new double[]{p.punishmentOutsideLine, p.punishmentOutsideLine});
                        env.ps.set(idx, new double[]{0.5, 0.5});
                        int ns = Math.max((stpos+1) % (p.nDrugGoals+1),1) + p.nHealthyGoals + p.nBaseStates;
                        int pstat = stpos - 1;
                        if (pstat == 0) pstat = p.nDrugGoals;
                        pstat = pstat + p.nHealthyGoals + p.nBaseStates;
                        env.nextStates.set(idx, new int[]{ns, pstat});
                    }
                } else if (action == a_getDrugs) {
                    // getDrugs from drug states
                    env.setTherapyRewardEntry(stpos-1, action, new double[]{reducedPunishmentF*r1, reducedPunishmentF*r1});
                    env.setBaseRewardEntry(stpos-1, action, new double[]{reducedPunishmentF*r1, reducedPunishmentF*r1});
                    env.rewards.set(idx, new double[]{p.punishmentOutsideLine, p.punishmentOutsideLine});
                    env.ps.set(idx, new double[]{p1, 1.0 - p1});
                    int ns = Math.max((stpos+1) % (p.nDrugGoals+1),1) + p.nHealthyGoals + p.nBaseStates;
                    int pstat = stpos - 1;
                    if (pstat == 0) pstat = p.nDrugGoals;
                    pstat = pstat + p.nHealthyGoals + p.nBaseStates;
                    env.nextStates.set(idx, new int[]{pstat, ns});
                }

                // append extra r1 to reward arrays analogously to MATLAB
                double[] oldReward = env.rewards.get(idx);
                double[] newReward = new double[oldReward.length + 1];
                System.arraycopy(oldReward, 0, newReward, 0, oldReward.length);
                newReward[newReward.length-1] = r1;
                env.rewards.set(idx, newReward);

                // therapyPs and basePs handling: store adjusted probabilities
                double[] currentPs = env.ps.get(idx);
                double[] therapyP = new double[currentPs.length + 1];
                for (int ii=0; ii<currentPs.length; ii++) therapyP[ii] = 0.8 * currentPs[ii];
                therapyP[currentPs.length] = 0.2;
                env.therapyPs.set((stpos-1)*Num_Actions + (action-1), therapyP);

                double[] baseP = new double[currentPs.length + 1];
                for (int ii=0; ii<currentPs.length; ii++) baseP[ii] = (1.0 - p.minFactor) * currentPs[ii];
                baseP[currentPs.length] = p.minFactor;
                env.basePs.set((stpos-1)*Num_Actions + (action-1), baseP);

                // finally append the central base state transition
                int central = p.nHealthyGoals + (int)Math.ceil(p.nBaseStates/2.0);
                int[] oldNext = env.nextStates.get(idx);
                int[] newNext = Arrays.copyOf(oldNext, oldNext.length + 1);
                newNext[newNext.length-1] = central;
                env.nextStates.set(idx, newNext);
            }
        }

        // verify probabilities sum to 1 (approx)
        for (int st = 1; st <= Num_States; st++) {
            for (int action = 1; action <= Num_Actions; action++) {
                int idx = (st - 1) * Num_Actions + (action - 1);
                double sum = 0.0; for (double v : env.ps.get(idx)) sum += v;
                if (Math.abs(sum - 1.0) > 5e-5) {
                    System.err.println("Warning: prob distribution does not sum to 1 for state="+st+" action="+action+" sum="+sum);
                }
            }
        }

        // finalize structural fields
        env.drugStates = new int[p.nDrugGoals];
        for (int i = 0; i < p.nDrugGoals; i++) env.drugStates[i] = p.nHealthyGoals + p.nBaseStates + 1 + i;
        env.goalStates = new int[p.nHealthyGoals];
        for (int i = 0; i < p.nHealthyGoals; i++) env.goalStates[i] = 1 + i;
        env.drugReachableStates = new int[p.nBaseStates];
        for (int i = 0; i < p.nBaseStates; i++) env.drugReachableStates[i] = p.nHealthyGoals + 1 + i;
        env.toDrugActionIdx = a_getDrugs;

        return env;
    }

    public Transition sampleTransition(int state, int action, Random r) {
        // state and action are 1-based to be consistent with MATLAB mapping used here
        int idx = (state - 1) * numActions + (action - 1);
        double[] probs = ps.get(idx);
        int[] nsts = nextStates.get(idx);
        double[] rws = rewards.get(idx);

        // sample according to probs
        double x = r.nextDouble();
        double cum = 0.0;
        for (int i = 0; i < probs.length; i++) {
            cum += probs[i];
            if (x <= cum) {
                return new Transition(nsts[i], rws[i]);
            }
        }
        // fallback
        int last = nsts[nsts.length - 1];
        double rw = rws[rws.length - 1];
        return new Transition(last, rw);
    }

    public static class Transition {
        public final int nextState;
        public final double reward;
        public Transition(int nextState, double reward) {
            this.nextState = nextState;
            this.reward = reward;
        }
    }
}
