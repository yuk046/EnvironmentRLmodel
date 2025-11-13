function 		[nextStateSim,rewardSim,valid]=doActionInModel(actionSim,Model,currentState,MBparameters)

[Ps, nextStateSims, rewardSims]=getTransitionProb(currentState, actionSim, Model,Model,MBparameters);
l=length(Ps);
if l==0
    valid=false;
    nextStateSim= 0;
%    display(['new (st, act) pair: (' Model.nodenames{currentState} ', ' Model.actionName{actionSim} ') nextStateSims: ' mat2str(nextStateSims) ', rewardSims: ' num2str(rewardSims)])    
    rewardSim= 0;
else
    valid=true;
i=randsample(length(Ps),1,true,Ps);
nextStateSim= nextStateSims(i);
rewardSim= rewardSims(i);
end
%% log
%display(['ini stat: ' Model.nodenames{currentState} ' nextStateSim: ' Model.nodenames{nextStateSim} ' rew: ' num2str(rewardSim)]);
%display ('sim step, press key')
%pause

end