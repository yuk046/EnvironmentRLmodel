function Model =CreateModel(Environment,priorCounts,copyTransitions)

%if strcmp(MBParameters.modelType,'Exact')
if ~copyTransitions
    display('*** empty model****');
    Model.Num_States=Environment.Num_States;
    Model.Num_Actions=Environment.Num_Actions;
    Model.actionName=Environment.actionName;
    Model.nodenames=Environment.nodenames;
    Model.reward=cell(Model.Num_States,Model.Num_Actions);
    Model.ps=cell(Model.Num_States,Model.Num_Actions);
    Model.nextState=cell(Model.Num_States,Model.Num_Actions);
    Model.PreviousStates=cell(Model.Num_States);
    Model.InverseActions=cell(Model.Num_States);
    Model.InverseReward=cell(Model.Num_States);
    Model.InversePs=cell(Model.Num_States);
    Model.counts=cell(Model.Num_States,Model.Num_Actions);
else
    display('*** copying model****');
    %pause
    Model=Environment;
     Model.counts=cell(Model.Num_States,Model.Num_Actions);
end;
Model.priorCounts=0;

for st=1:Environment.Num_States
    for act=1:Environment.Num_Actions
        Model.counts{st,act}=priorCounts*Model.ps{st, act}(:);
        Model.priorCounts=min(Model.priorCounts,min(Model.counts{st,act}));
    end
end
if Model.priorCounts~=0
    Model.priorCounts=Model.priorCounts*priorCounts;
else
    Model.priorCounts=priorCounts;
end
%end
displayModel(Model);
% pauseをなくした。
displayModelEnvironmentDiff(Model,Environment);
%pause
end
% getDestinationTransitionProb.m	9	rewardSims =Model.InverseReward(endState).vals;
% getDestinationTransitionProb.m	14	Ps=Model.Ps(endState);
% getDestinationTransitionProb.m	15	previousStates=Model.PreviousState(endState).vals;
% getDestinationTransitionProb.m	16	actions=Model.InverseActions(endState).vals;
% getDestinationTransitionProb.m	17	rewardSims =Model.InverseRewardSims(endState).vals;
% getTransitionProb.m	3	rewardSims =Model.rewardSims(currentState, actionSim);
% getTransitionProb.m	13	Ps=Model.Ps(searchState, actionSim);
% getTransitionProb.m	14	nextStateSims=Model.nextStateSims(currentState, actionSim);
% updateQtable_IntegratedWithSimulatedPathTDLambda.m	19	elegibilityTraceSim=zeros((1+(Model.NumStates-1)*(MBParameters.gamma_MB>0)),1);
% updateQtable_IntegratedWithSimulatedPathTDLambda.m	25	for i= 1:Model.NumStates