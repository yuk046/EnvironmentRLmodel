function [action,currentState,reward,valid]=sampleTransitionToState(endState,Model,MBparameters)

[previousStates, actions, rewardSims]=getDestinationTransitionProb(endState, Model,MBparameters);
if isempty(previousStates)
    valid =false;
    currentState=0;
    action=0;
    reward= 0;
else
    valid= true;
i=randsample(length(previousStates),1);

currentState=previousStates(i);
action=actions(i);
reward= rewardSims(i);
end
end