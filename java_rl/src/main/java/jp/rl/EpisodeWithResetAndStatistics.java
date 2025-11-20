package jp.rl;

import java.util.*;

public class EpisodeWithResetAndStatistics {

    public static Result run(InputVals inputVals) {
        // Initialize QTablePerm
    QTablePerm qTablePerm = new QTablePerm(inputVals.Environment.numStates, inputVals.Environment.numActions);
        // ensure eligibility traces are cleared at the start of the run/episode
        qTablePerm.resetEligibility();
        // priorCounts from MATLAB example
        int priorCounts = 4;
        boolean copyTransitions = inputVals.parametersMBFW != null && inputVals.parametersMBFW.updateModel;
    Model model = Model.createFromEnvironment(inputVals.Environment, priorCounts, copyTransitions);

    Model healthyModel = model;
    Model addictedModel = model;
    QTablePerm healthyQ = qTablePerm;
    QTablePerm addictedQ = qTablePerm;
    Model healedModel = model;
    QTablePerm healedQ = qTablePerm;

        int currentState = inputVals.start;
        double total_reward = 0.0;

        int maxsteps = inputVals.maxsteps;

        int reset = 1;

        int[][] stateActionVisitCounts = new int[inputVals.Environment.numStates+1][inputVals.Environment.numActions+1];
        int[][] stateActionVisitCountsSimul = new int[inputVals.Environment.numStates+1][inputVals.Environment.numActions+1];
        int[][] stateActionVisitCounts2 = new int[inputVals.Environment.numStates+1][inputVals.Environment.numActions+1];

        Stepper stepper = new Stepper(inputVals.Environment);

        List<Integer> last_actions = new ArrayList<>(maxsteps);
        List<Integer> last_states = new ArrayList<>(maxsteps);
        List<Double> last_reward = new ArrayList<>(maxsteps);

        for (int nStep = 1; nStep <= maxsteps; nStep++) {
            // environment phase changes
            if (nStep == inputVals.initDrugStartSteps) {
                inputVals.Environment = Utilities.changeToBaseReward(inputVals.Environment);
                healthyQ = new QTablePerm(qTablePerm.mean.length-1, qTablePerm.mean[0].length-1);
                healthyModel = model;
            } else if (nStep == inputVals.therapyStartSteps) {
                inputVals.Environment = Utilities.changeToTherapyReward(inputVals.Environment);
                addictedModel = model;
                addictedQ = qTablePerm;
                if (inputVals.simulatedTherapy) {
                    qTablePerm = Utilities.combinePolicies(qTablePerm, healthyQ, inputVals.resetPolicyFactor, inputVals.parametersMF);
                    if (inputVals.resetModelFactor >= 0 && inputVals.resetModelFactor <= 1) {
                        model = Utilities.combineModels(addictedModel, healthyModel, inputVals.resetModelFactor);
                    } else if (inputVals.resetModelFactor < 0) {
                        model = Utilities.punishDrugModel(healthyModel, inputVals.Environment, inputVals.resetModelFactor);
                    }
                } else {
                    // modify learning factors temporarily
                    inputVals.parametersMBFW.modelLearningFactor = inputVals.parametersMBFW.modelLearningFactor * inputVals.therapyModelLF;
                    inputVals.parametersMBFW.modelDecay = inputVals.parametersMBFW.modelDecay * 2.0;
                    inputVals.parametersMF.alpha_MF = inputVals.parametersMF.alpha_MF * inputVals.therapyMFLFF;
                }
            }

            if (nStep == inputVals.therapyEndSteps) {
                inputVals.Environment = Utilities.changeToBaseReward(inputVals.Environment);
                healedModel = model;
                healedQ = qTablePerm;
                // restore parameters would be implemented here
            }

            // execute agent step
            boolean runInternalSim = inputVals.parametersMBFW != null && inputVals.parametersMBFW.runInternalSimulation;
            boolean updateModelFlag = inputVals.parametersMBFW != null && inputVals.parametersMBFW.updateModel;
            boolean updateQFlag = inputVals.parametersMF != null && inputVals.parametersMF.updateQTablePerm;
            boolean internalReplayFlag = inputVals.parametersMBBW != null && inputVals.parametersMBBW.internalReplay == 1;

            Stepper.StepResult sr = stepper.step(currentState, qTablePerm, model, inputVals.parametersMF, updateModelFlag, updateQFlag, stateActionVisitCounts, new Random());

            int action = sr.action;
            double reward = sr.reward;
            int new_state = sr.newState;

            last_actions.add(action);
            last_states.add(currentState);
            last_reward.add(reward);
            total_reward += reward;

            currentState = new_state;

            // perform internal replay/simulation if requested
            if (internalReplayFlag) {
                // call internalReplay to update qTablePerm using model
                System.out.println("[internalReplay] starting internalReplay (step=" + nStep + ")");
                InternalSimulator.InternalReplayResult irr = InternalSimulator.internalReplay(qTablePerm, model, inputVals.parametersMBBW, stateActionVisitCountsSimul, reset, new Random());
                if (irr != null) {
                    System.out.println(String.format("[internalReplay] dmax=%.6f dmean=%.6f", irr.dmax, irr.dmean));
                    if (irr.q != null) {
                        qTablePerm = irr.q;
                    }
                }
            }

            // optional statistics placeholder
            if (inputVals.parametersMBFW != null && inputVals.parametersMBFW.computeStatistics) {
                // not implemented: compute per-state simulations
            }
        }

        Result res = new Result();
        res.lastStates = last_states;
        res.lastActions = last_actions;
        res.lastRewards = last_reward;
        res.maxSteps = maxsteps;
        return res;
    }

    // Debug version: uses provided Random and prints step-by-step information
    public static Result runDebug(InputVals inputVals, Random rng, boolean verbose) {
        QTablePerm qTablePerm = new QTablePerm(inputVals.Environment.numStates, inputVals.Environment.numActions);
        qTablePerm.resetEligibility();
        int priorCounts = 4;
        boolean copyTransitions = inputVals.parametersMBFW != null && inputVals.parametersMBFW.updateModel;
        Model model = Model.createFromEnvironment(inputVals.Environment, priorCounts, copyTransitions);

        int currentState = inputVals.start;
        double total_reward = 0.0;
        int maxsteps = inputVals.maxsteps;

        int[][] stateActionVisitCounts = new int[inputVals.Environment.numStates+1][inputVals.Environment.numActions+1];
        int[][] stateActionVisitCountsSimul = new int[inputVals.Environment.numStates+1][inputVals.Environment.numActions+1];

        Stepper stepper = new Stepper(inputVals.Environment);

        List<Integer> last_actions = new ArrayList<>(maxsteps);
        List<Integer> last_states = new ArrayList<>(maxsteps);
        List<Double> last_reward = new ArrayList<>(maxsteps);

        for (int nStep = 1; nStep <= maxsteps; nStep++) {
            if (nStep == inputVals.initDrugStartSteps) {
                inputVals.Environment = Utilities.changeToBaseReward(inputVals.Environment);
            } else if (nStep == inputVals.therapyStartSteps) {
                inputVals.Environment = Utilities.changeToTherapyReward(inputVals.Environment);
            }

            boolean runInternalSim = inputVals.parametersMBFW != null && inputVals.parametersMBFW.runInternalSimulation;
            boolean updateModelFlag = inputVals.parametersMBFW != null && inputVals.parametersMBFW.updateModel;
            boolean updateQFlag = inputVals.parametersMF != null && inputVals.parametersMF.updateQTablePerm;
            boolean internalReplayFlag = inputVals.parametersMBBW != null && inputVals.parametersMBBW.internalReplay == 1;

            Stepper.StepResult sr = stepper.step(currentState, qTablePerm, model, inputVals.parametersMF, updateModelFlag, updateQFlag, stateActionVisitCounts, rng);

            int action = sr.action;
            double reward = sr.reward;
            int new_state = sr.newState;

            if (verbose) {
                System.out.println(String.format("[step %d] state=%d action=%d reward=%.2f newState=%d", nStep, currentState, action, reward, new_state));
                // print Q values for current state and e-trace for debugging
                StringBuilder qsb = new StringBuilder();
                qsb.append(" Q=[");
                for (int a = 1; a <= inputVals.Environment.numActions; a++) {
                    qsb.append(String.format("%.3f", qTablePerm.mean[currentState][a]));
                    if (a < inputVals.Environment.numActions) qsb.append(", ");
                }
                qsb.append("]");
                StringBuilder esb = new StringBuilder();
                esb.append(" eTrace=[");
                for (int a = 1; a <= inputVals.Environment.numActions; a++) {
                    esb.append(String.format("%.3f", qTablePerm.eTrace[currentState][a]));
                    if (a < inputVals.Environment.numActions) esb.append(", ");
                }
                esb.append("]");
                System.out.println(qsb.toString() + esb.toString());
            }

            last_actions.add(action);
            last_states.add(currentState);
            last_reward.add(reward);
            total_reward += reward;

            currentState = new_state;

            if (internalReplayFlag) {
                System.out.println("[internalReplay] starting internalReplay (debug step=" + nStep + ")");
                InternalSimulator.InternalReplayResult irr = InternalSimulator.internalReplay(qTablePerm, model, inputVals.parametersMBBW, stateActionVisitCountsSimul, 1, rng);
                if (irr != null) {
                    System.out.println(String.format("[internalReplay] dmax=%.6f dmean=%.6f", irr.dmax, irr.dmean));
                    if (irr.q != null) {
                        qTablePerm = irr.q;
                    }
                }
            }

            // If MB runInternalSimulation flag is set, run planning and integrate MB Q into QTablePerm
            if (inputVals.parametersMBFW != null && inputVals.parametersMBFW.runInternalSimulation) {
                System.out.println("[runInternalSimulation] running planning integration (step=" + nStep + ")");
                InternalSimulator.RunInternalResult rres = InternalSimulator.runInternalSimulationInResetAndStatistics(qTablePerm, currentState, model, inputVals.parametersMBFW, stateActionVisitCountsSimul);
                if (rres != null && rres.qIntegrated != null) {
                    // compute difference before/after integration for visibility
                    int S = inputVals.Environment.numStates;
                    int A = inputVals.Environment.numActions;
                    double[][] before = new double[S+1][A+1];
                    for (int s = 1; s <= S; s++) for (int a = 1; a <= A; a++) before[s][a] = qTablePerm.mean[s][a];

                    // simple mixing of MF and MB Q-values by mb_factor/mf_factor
                    double mbf = inputVals.parametersMBFW.mb_factor;
                    double mff = inputVals.parametersMBFW.mf_factor;
                    for (int s = 1; s <= S; s++) {
                        for (int a = 1; a <= A; a++) {
                            qTablePerm.mean[s][a] = mff * qTablePerm.mean[s][a] + mbf * rres.qIntegrated.mean[s][a];
                        }
                    }

                    // compute max/mean absolute diff
                    double maxAbs = 0.0; double sumAbs = 0.0; int cnt = 0;
                    for (int s = 1; s <= S; s++) for (int a = 1; a <= A; a++) {
                        double d = Math.abs(qTablePerm.mean[s][a] - before[s][a]);
                        if (d > maxAbs) maxAbs = d;
                        sumAbs += d; cnt++;
                    }
                    double meanAbs = cnt>0 ? sumAbs / cnt : 0.0;
                    System.out.println(String.format("[runInternalSimulation] integrated MB Q into QTablePerm (mbf=%.3f mff=%.3f) maxDiff=%.6e meanDiff=%.6e", mbf, mff, maxAbs, meanAbs));
                }
            }
        }

        Result res = new Result();
        res.lastStates = last_states;
        res.lastActions = last_actions;
        res.lastRewards = last_reward;
        res.maxSteps = maxsteps;
        return res;
    }
}
