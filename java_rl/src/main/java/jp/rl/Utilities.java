package jp.rl;

public class Utilities {
    // Placeholder: convert environment to therapy rewards
    public static Environment changeToTherapyReward(Environment env) {
        // For now, return same env. A fuller implementation would swap reward arrays.
        return env;
    }

    public static Environment changeToBaseReward(Environment env) {
        return env;
    }

    // Combine policies (Q tables) - simple convex combination
    public static QTablePerm combinePolicies(QTablePerm current, QTablePerm other, double resetPolicyFactor, MFParameters mf) {
        QTablePerm out = new QTablePerm(current.mean.length-1, current.mean[0].length-1);
        for (int s = 1; s < out.mean.length; s++) {
            for (int a = 1; a < out.mean[s].length; a++) {
                out.mean[s][a] = resetPolicyFactor * other.mean[s][a] + (1.0 - resetPolicyFactor) * current.mean[s][a];
            }
        }
        return out;
    }

    // Simple model combination: currently returns current (placeholder)
    public static Model combineModels(Model addictedModel, Model healthyModel, double resetModelFactor) {
        return addictedModel; // placeholder, proper merging needed
    }

    public static Model punishDrugModel(Model healthyModel, Environment env, double resetModelFactor) {
        // placeholder: a proper implementation should modify healthyModel using environment and resetModelFactor
        return healthyModel;
    }
}
