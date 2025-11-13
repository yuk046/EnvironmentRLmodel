function [previousStates, actions, rewardSims]=getDestinationTransitionProb(endState, Model,MBparameters)


	%if state transitions are known no need to use model
% 	if MBparameters.knownTransitions==1
% %        Ps=Environment.InversePs{endState};
%         previousStates=Environment.PreviousStates{endState};
%         actions=Environment.InverseActions{endState};
%     
%     %otherwise
%     
% 	else
	%	  Ps=Model.InversePs{endState};
        previousStates=Model.PreviousStates{endState};
        actions=Model.InverseActions{endState};
       
%     end
     rewardSims =Model.InverseReward{endState};
end