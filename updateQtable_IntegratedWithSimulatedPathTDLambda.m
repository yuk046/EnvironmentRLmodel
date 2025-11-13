%    MBParameters=struct(alpha_MB,Valpha_MB,…
%      gamma_MB,Vgamma_MB,…
% 	lambda_MB,Vlambda_MB,…
%	StoppingPathThresh,VStoppingPathThresh,…
%	StoppingPathLength,VStoppingPathLength,…
%	StoppingPathThreshReward=VStoppingPathThreshReward,…
%	stoppingThresh,VstoppingThresh,…
%	MaxItr,VMaxItr,…
%	StopSim,VStopSim,…
%	SelectActionSim,VSelectActionSim,…
%	stopOnUncertaintyVal,VstopOnUncertaintyVal);



function updateQtable_IntegratedWithSimulatedPathTDLambda(nextStateSim, rewardSim, currentStateSim,actionSim,Model,MBParameters,environment,stateActionVisitCounts)
%% init
persistent elegibilityTraceSim;
global Qtable_Integrated_loc;
if isempty(elegibilityTraceSim)
    elegibilityTraceSim=zeros(size(Qtable_Integrated_loc.mean));
end
%% getNextAction
nextAct=selectActionSim(currentStateSim,Model,MBParameters, Qtable_Integrated_loc,environment,stateActionVisitCounts);
qnew=Qtable_Integrated_loc.mean(nextStateSim,nextAct);
qOld=Qtable_Integrated_loc.mean(currentStateSim,actionSim);
d= rewardSim+ MBParameters.gamma_MB*qnew -qOld ;

if MBParameters.gamma_MB>0
    elegibilityTraceSim=MBParameters.lambda_MB*MBParameters.gamma_MB*elegibilityTraceSim;
    elegibilityTraceSim(currentStateSim,actionSim)=1;    
    Qtable_Integrated_loc.mean=		Qtable_Integrated_loc.mean+MBParameters.alpha_MB*elegibilityTraceSim*d;
    
else
    Qtable_Integrated_loc.mean(currentStateSim,actionSim)=		Qtable_Integrated_loc.mean(currentStateSim,actionSim)+MBParameters.alpha_MB*d;
end
end
