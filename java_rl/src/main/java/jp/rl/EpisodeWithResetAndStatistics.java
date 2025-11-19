package jp.rl;

import java.util.*;

public class EpisodeWithResetAndStatistics {

    public static Result run(InputVals inputVals) {
        // Initialize QTablePerm
    QTablePerm qTablePerm = new QTablePerm(inputVals.Environment.numStates, inputVals.Environment.numActions);
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
                InternalSimulator.InternalReplayResult irr = InternalSimulator.internalReplay(qTablePerm, model, inputVals.parametersMBBW, stateActionVisitCountsSimul, reset, new Random());
                if (irr != null && irr.q != null) {
                    qTablePerm = irr.q;
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
}
