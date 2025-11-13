function [Ps, nextStateSims, rewardSims]=getTransitionProb(currentState, actionSim,Environment, Model,MBparameters)

	rewardSims =Model.reward{currentState, actionSim};

	%if state transitions are known no need to use model
	if MBparameters.knownTransitions==1
        Ps=Environment.ps{currentState, actionSim};
        nextStateSims=Environment.nextState{currentState, actionSim};
    
    %otherwise
    
	else
		Ps=Model.ps{currentState, actionSim};
        
        nextStateSims=Model.nextState{currentState, actionSim};
	end
end