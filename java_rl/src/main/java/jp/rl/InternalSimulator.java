package jp.rl;

import java.util.*;

public class InternalSimulator {

    // selectEndState -- port of MATLAB selectEndState
    public static int selectEndState(QTablePerm q, Model model, MBReplayParameters bparams, MBParameters mbparams, Random rng) {
        int S = model.numStates;
        double[] Vt = new double[S+1];
        for (int s = 1; s <= S; s++) {
            double maxv = Double.NEGATIVE_INFINITY;
            for (int a = 1; a <= model.numActions; a++) if (q.mean[s][a] > maxv) maxv = q.mean[s][a];
            if (maxv == Double.NEGATIVE_INFINITY) maxv = 0.0;
            Vt[s] = maxv;
        }
        double meanV = 0.0; for (int s=1;s<=S;s++) meanV += Vt[s]; meanV /= S;

        double[][] r = new double[S+1][model.numActions+1];
        double[] rs = new double[S+1];
        for (int st=1; st<=S; st++) {
            for (int act=1; act<=model.numActions; act++) {
                double val = 0.0;
                double[] rewards = model.rewards.get((st-1)*model.numActions + (act-1));
                double[] ps = model.ps.get((st-1)*model.numActions + (act-1));
                if (rewards != null && ps != null) {
                    for (int i=0;i<Math.min(rewards.length, ps.length); i++) val += rewards[i] * ps[i];
                }
                r[st][act] = val;
            }
            double maxr = Double.NEGATIVE_INFINITY;
            for (int a=1;a<=model.numActions;a++) if (r[st][a] > maxr) maxr = r[st][a];
            if (maxr==Double.NEGATIVE_INFINITY) maxr = 0.0;
            rs[st] = maxr;
        }
        double meanR = 0.0; for (int s=1;s<=S;s++) meanR += rs[s]; meanR /= S;
        double[] d = new double[S+1];
        for (int s=1;s<=S;s++) {
            double diff = rs[s] - meanR;
            if (diff > 0) d[s] = diff * (bparams.P_starting_point_high_R);
            else d[s] = (-diff) * (bparams.P_starting_point_Low_R);
        }
        // weights = d+1
        double sum = 0.0; for (int s=1;s<=S;s++) sum += (d[s]+1.0);
        double x = rng.nextDouble() * sum;
        double cum = 0.0;
        for (int s=1;s<=S;s++) {
            cum += (d[s]+1.0);
            if (x <= cum) return s;
        }
        return S;
    }

    // find previous states/actions that can lead to endState by scanning model.nextStates
    public static class PrevTransition {
        public int prevState;
        public int action;
        public double reward;
        public PrevTransition(int ps,int a,double r){prevState=ps; action=a; reward=r;}
    }

    public static List<PrevTransition> getDestinationTransitionProb(int endState, Model model) {
        // fallback: scan model.nextStates (slower) if inverseTransitions not built
        List<PrevTransition> list = new ArrayList<>();
        if (model.inverseTransitions != null && model.inverseTransitions.size() > endState) {
            for (Model.PrevTransition p : model.inverseTransitions.get(endState)) {
                list.add(new PrevTransition(p.prevState, p.action, p.reward));
            }
            return list;
        }
        int total = model.numStates * model.numActions;
        for (int idx=0; idx<total; idx++) {
            int state = idx / model.numActions + 1;
            int action = idx % model.numActions + 1;
            int[] nsts = model.nextStates.get(idx);
            double[] rws = model.rewards.get(idx);
            if (nsts != null) {
                for (int i=0;i<nsts.length;i++) {
                    if (nsts[i] == endState) {
                        double rew = (rws!=null && i<rws.length)? rws[i] : 0.0;
                        list.add(new PrevTransition(state, action, rew));
                    }
                }
            }
        }
        return list;
    }

    // sampleTransitionToState (port sampleTransitionToState.m)
    public static Optional<PrevTransition> sampleTransitionToState(int endState, Model model, Random rng) {
        if (model.inverseTransitions != null && model.inverseTransitions.size() > endState) {
            List<Model.PrevTransition> list = model.inverseTransitions.get(endState);
            if (list == null || list.isEmpty()) return Optional.empty();
            int i = rng.nextInt(list.size());
            Model.PrevTransition p = list.get(i);
            return Optional.of(new PrevTransition(p.prevState, p.action, p.reward));
        } else {
            List<PrevTransition> list = getDestinationTransitionProb(endState, model);
            if (list.isEmpty()) return Optional.empty();
            int i = rng.nextInt(list.size());
            return Optional.of(list.get(i));
        }
    }

    // getTransitionProb (Environment vs Model)
    public static class TransitionProb {
        public double[] Ps;
        public int[] nextStateSims;
        public double[] rewardSims;
        public TransitionProb(double[] Ps,int[] ns,double[] rw){this.Ps=Ps; this.nextStateSims=ns; this.rewardSims=rw;}
    }

    public static TransitionProb getTransitionProb(int currentState,int action, Environment env, Model model, MBParameters mbparams) {
        // prefer env transitions if knownTransitions requested and env available
        if (mbparams != null && mbparams.knownTransitions && env != null) {
            int idx = (currentState-1)*env.numActions + (action-1);
            return new TransitionProb(env.ps.get(idx), env.nextStates.get(idx), env.rewards.get(idx));
        } else {
            int idx = (currentState-1)*model.numActions + (action-1);
            return new TransitionProb(model.ps.get(idx), model.nextStates.get(idx), model.rewards.get(idx));
        }
    }

    // doActionInModel
    public static class DoActionResult { public int nextState; public double reward; public boolean valid; }
    public static DoActionResult doActionInModel(int action, Model model, int currentState, MBParameters mbparams, Random rng) {
        TransitionProb tp = getTransitionProb(currentState, action, null, model, mbparams);
        DoActionResult r = new DoActionResult();
        if (tp == null || tp.Ps==null || tp.Ps.length==0) {
            r.valid = false; r.nextState=0; r.reward=0.0; return r;
        }
        double x = rng.nextDouble(); double cum=0.0;
        for (int i=0;i<tp.Ps.length;i++) { cum += tp.Ps[i]; if (x <= cum) { r.nextState = tp.nextStateSims[i]; r.reward = tp.rewardSims[i]; r.valid=true; return r; } }
        int last = tp.nextStateSims[tp.nextStateSims.length-1]; r.nextState=last; r.reward = tp.rewardSims[tp.rewardSims.length-1]; r.valid=true; return r;
    }

    // selectActionSim (calls UCT or Dyna)
    public static int selectActionSim(int currentState, Model model, MBParameters mbparams, QTablePerm qtable, int[][] stateActionVisitCounts, Random rng) {
        if ("UCT".equals(mbparams.MBMethod) || "UCT".equals(mbparams.MBMethod)) {
            return selectActionSimUCT(currentState, model, mbparams, qtable, stateActionVisitCounts, rng);
        } else {
            return selectActionSimDyna(currentState, mbparams, qtable, stateActionVisitCounts, model.nodeNames, model.actionNames, rng);
        }
    }

    public static int selectActionSimDyna(int currentState, MBParameters mfParams, double[][] QTablePermMean, int[][] stateActionVisitCounts, List<String> stateNames, List<String> actionNames, Random rng) {
        int num_actions = QTablePermMean[currentState].length - 1;
        if (mfParams.randExpl && rng.nextDouble() < mfParams.explorationFactor) {
            return 1 + rng.nextInt(num_actions);
        } else {
            double[] w = QTablePermMean[currentState];
            double best = Double.NEGATIVE_INFINITY; int bestA = 1;
            for (int a=1;a<=num_actions;a++) {
                double val = w[a] + 1e-8 * rng.nextDouble();
                if (val > best) { best = val; bestA = a; }
            }
            return bestA;
        }
    }

    public static int selectActionSimDyna(int currentState, MBParameters mfParams, QTablePerm qtable, int[][] stateActionVisitCounts, List<String> stateNames, List<String> actionNames, Random rng) {
        return selectActionSimDyna(currentState, mfParams, qtable.mean, stateActionVisitCounts, stateNames, actionNames, rng);
    }

    public static int selectActionSimUCT(int currentState, Model model, MBParameters mbparams, QTablePerm qtable, int[][] stateActionVisitCounts, Random rng) {
        int A = model.numActions;
        double t = mbparams.UCTK * (1 + sumRow(stateActionVisitCounts, currentState));
        double[] c = new double[A+1];
        for (int a=1;a<=A;a++) c[a] = Math.sqrt(t / (1.0 + stateActionVisitCounts[currentState][a]));
        double best = Double.NEGATIVE_INFINITY; int bestA=1;
        for (int a=1;a<=A;a++) {
            double val = qtable.mean[currentState][a] + c[a] + 1e-8*rng.nextDouble();
            if (val > best) { best = val; bestA = a; }
        }
        return bestA;
    }

    private static int sumRow(int[][] arr, int row) { if (arr==null) return 0; int s=0; for (int v: arr[row]) s+=v; return s; }

    // discard branch if it contains cycles or exceeds allowed depth
    public static boolean discardCurrentSearchBranchSimple(int[] backSearchTree, Model model, QTablePerm q, MBReplayParameters bparams) {
        if (backSearchTree == null) return true;
        int len = backSearchTree.length;
        if (len > bparams.sweepsDepth) return true;
        // detect simple cycle: repeated state in backSearchTree
        java.util.Set<Integer> s = new java.util.HashSet<>();
        for (int v : backSearchTree) {
            if (s.contains(v)) return true;
            s.add(v);
        }
        return false;
    }

    // Keep the old-named method but call the simple implementation
    public static boolean discardCurrentSearchBranch(int[] backSearchTree, Model model, QTablePerm q, MBReplayParameters bparams) {
        return discardCurrentSearchBranchSimple(backSearchTree, model, q, bparams);
    }

    // internalReplay port
    public static class InternalReplayResult { public QTablePerm q; public double dmax; public double dmean; }
    public static InternalReplayResult internalReplay(QTablePerm qOld, Model model, MBReplayParameters bparams, int[][] stateActionVisitCounts, int reset, Random rng) {
        QTablePerm qNew = qOld;
        int stepsTotal = 0;
        int sweeps = 0;
        while ((sweeps <= 10 * bparams.sweeps) && (stepsTotal < 10 * bparams.stepsTotal)) {
            sweeps++;
            int steps = 0;
            int goalState = selectEndState(qNew, model, bparams, null, rng);
            int maxDepth = bparams.sweepsDepth;
            List<Integer> backSearchTree = new ArrayList<>();
            backSearchTree.add(goalState);
            while (steps >= 0 && steps <= maxDepth && rng.nextDouble() > bparams.restart_sweep_Prob && stepsTotal < 10 * bparams.stepsTotal) {
                steps++; stepsTotal++;
                int endState = backSearchTree.get(steps-1);
                Optional<PrevTransition> opt = sampleTransitionToState(endState, model, rng);
                if (!opt.isPresent()) { steps = steps - 2; stepsTotal -= 0.5; continue; }
                PrevTransition pt = opt.get();
                int actionsim = pt.action;
                int currentState = pt.prevState;
                InternalSimulator.DoActionResult dar = doActionInModel(actionsim, model, currentState, null, rng);
                if (!dar.valid) { steps = steps - 1; stepsTotal -= 0.5; continue; }
                backSearchTree.add(currentState);
                // discard branch?
                if (discardCurrentSearchBranch(listToArray(backSearchTree), model, qNew, bparams)) {
                    // if discarded, remove the last added state and continue the sweep
                    backSearchTree.remove(backSearchTree.size()-1);
                    steps = steps - 1;
                    stepsTotal -= 0.5;
                    continue;
                }
                else {
                    // update QTablePerm with simulated reward
                    QUpdater.UpdateResult ur = QUpdater.updateQTablePerm(qNew, dar.reward, dar.nextState, actionsim, currentState, stateActionVisitCounts, new MFParameters(), reset);
                    qNew = ur.Q;
                    reset = 0;
                }
            }
        }
        // compute D
        double[] oldv = flatten(qOld.mean); double[] newv = flatten(qNew.mean);
        double dmax = Double.NEGATIVE_INFINITY; double dsum = 0.0;
        for (int i=0;i<oldv.length;i++) { double d = newv[i] - oldv[i]; if (d > dmax) dmax = d; dsum += d; }
        double dmean = dsum / oldv.length;
        InternalReplayResult res = new InternalReplayResult(); res.q = qNew; res.dmax = dmax; res.dmean = dmean; return res;
    }

    private static int[] listToArray(List<Integer> list) { int[] a=new int[list.size()]; for (int i=0;i<list.size();i++) a[i]=list.get(i); return a; }
    private static double[] flatten(double[][] m) { int rows = m.length; int cols = m[0].length; double[] out = new double[(rows)*(cols)]; int k=0; for (int i=0;i<rows;i++) for (int j=0;j<cols;j++) out[k++]=m[i][j]; return out; }

    // runInternalSimulationInResetAndStatistics port
    public static class RunInternalResult { public QTablePerm qIntegrated; public int N_itr; public int[][] stateActionVisitCountsOut; }
    public static RunInternalResult runInternalSimulationInResetAndStatistics(QTablePerm QTablePerm, int currentState, Model model, MBParameters MBParameters, int[][] stateActionVisitCounts) {
        RunInternalResult res = new RunInternalResult();
        res.N_itr = 1;
        QTablePerm qIntegrated = new QTablePerm(QTablePerm.mean.length-1, QTablePerm.mean[0].length-1);
        // zeros
        res.stateActionVisitCountsOut = new int[model.numStates+1][model.numActions+1];

        QTablePerm QTablePermLocal = MBParameters.useMFToDriveMB ? QTablePerm : qIntegrated;
        int totalsteps = 0;
        int N_itr = 1;
        Random rng = new Random();
        while (N_itr <= MBParameters.MaxItrMB && totalsteps < MBParameters.MaxTotalSimSteps) {
            int currentStateSim = currentState;
            int path_step = 0;
            boolean path_end = false;
            while (!path_end) {
                int actionSim = selectActionSim(currentStateSim, model, MBParameters, QTablePermLocal, res.stateActionVisitCountsOut, rng);
                res.stateActionVisitCountsOut[currentStateSim][actionSim]++;
                DoActionResult dar = doActionInModel(actionSim, model, currentStateSim, MBParameters, rng);
                if (!dar.valid) break;
                // update base
                // cannot access QUpdater.UpdateBaseResult (it's private); call the public updateQTablePerm
                QUpdater.UpdateResult ur = QUpdater.updateQTablePerm(QTablePermLocal, dar.reward, dar.nextState, actionSim, currentStateSim, res.stateActionVisitCountsOut, new MFParameters(), 0);
                QTablePermLocal.mean[currentStateSim][actionSim] = ur.Q.mean[currentStateSim][actionSim];
                qIntegrated.mean[currentStateSim][actionSim] = ur.Q.mean[currentStateSim][actionSim];
                currentStateSim = dar.nextState;
                path_step++; totalsteps++;
                path_end = (path_step == MBParameters.StoppingPathLengthMB) || (rng.nextDouble() < MBParameters.pStopPath);
            }
            N_itr++;
        }
        res.qIntegrated = qIntegrated; res.N_itr = N_itr; return res;
    }

    // runInternalSimulation port
    public static RunInternalResult runInternalSimulation(QTablePerm QTablePerm, int currentState, Model model, MBParameters MBParameters, boolean resetSim) {
        // use persistent-like stateActionVisitCounts stored in static map keyed by model hash
        int[][] stateActionVisitCounts = new int[model.numStates+1][model.numActions+1];
        return runInternalSimulationInResetAndStatistics(QTablePerm, currentState, model, MBParameters, stateActionVisitCounts);
    }
}
