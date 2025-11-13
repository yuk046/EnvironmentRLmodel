%function [ total_reward,i,Q,Model,last_actions,last_states,last_reward,last_Q,lastMaxK,lastMaxVar,lastDreward,lastMA_noise_n,last_maxD,last_meanD ] =...
function Results =...
    Episode_WithStateSwitch_And_Statistics( inputVals)

QTablePerm.mean=zeros(inputVals.Environment.Num_States,inputVals.Environment.Num_Actions);
QTablePerm.time=zeros(inputVals.Environment.Num_States,inputVals.Environment.Num_Actions);
QTablePerm.var=1.5*eye(inputVals.Environment.Num_States*inputVals.Environment.Num_Actions);

last_actions=zeros(1,inputVals.maxsteps);

last_states=zeros(1,inputVals.maxsteps);

last_reward=zeros(1,inputVals.maxsteps);
lastMaxK=zeros(1,inputVals.maxsteps);
lastMaxVar=lastMaxK;
lastDreward=lastMaxK;
lastMA_noise_n=lastMaxK;
last_maxD=lastMaxK;
last_meanD=lastMaxK;


last_Q=zeros(inputVals.maxsteps,inputVals.Environment.Num_States,inputVals.Environment.Num_Actions);
priorCounts=4;
inputVals.parametersMBFW.knownTransitions
copyTransitionsFromEnvironment=(inputVals.parametersMBFW.knownTransitions);

Model =CreateModel(inputVals.Environment,priorCounts,copyTransitionsFromEnvironment);
HealthyModel=Model;
AddictedModel=Model;
HealthyQ=QTablePerm;
AddictedQ=QTablePerm;
HealedModel=Model;
HealedQ=QTablePerm;
currentState           = inputVals.start;

total_reward = 0;

reset=1;
switchGoalTime=inputVals.switchGoalTime;


% selects an action using the epsilon greedy selection strategy
%a   = e_greedy_selection(Q,s,epsilon);

stateActionVisitCounts=zeros(Model.Num_States,Model.Num_Actions);
stateActionVisitCountsSimul=stateActionVisitCounts;
stateActionVisitCounts2=stateActionVisitCounts;
%inputVals.Environment=changeToTherapyReward(inputVals.Environment);
j=0;
stepsToComputeStatistics=0;
obsidx=0

drugtime=min(inputVals.therapyStartSteps,inputVals.maxsteps)-inputVals.initDrugStartSteps;
for nStep=1:inputVals.maxsteps
    
    %% change environment phase (initial,drug,therapy,postDrug)
    
    for goalid=1:inputVals.Environment.n_healthy_goals;
        if nStep>=switchGoalTime(goalid)
            for stgoal = 1:(inputVals.Environment.n_healthy_goals)
                if ~isempty(inputVals.Environment.defaultReward)
                inputVals.Environment.reward{stgoal,stgoal}=inputVals.Environment.defaultReward;
                else
                    inputVals.Environment.reward{stgoal,stgoal}=0;
                end
            end
            inputVals.Environment.reward{goalid,goalid}=inputVals.Environment.alternateReward(goalid);
    
    
        end
    end
    
    
    if nStep==inputVals.initDrugStartSteps
        inputVals.Environment=changeToBaseReward(inputVals.Environment);
        HealthyQ=QTablePerm;
        HealthyModel=Model;
    elseif nStep==inputVals.therapyStartSteps
        inputVals.Environment=changeToTherapyReward(inputVals.Environment);
        AddictedModel=Model;
        AddictedQ=QTablePerm;
        if inputVals.simulatedTherapy
            QTablePerm=combinePolicies(QTablePerm,HealthyQ,inputVals.resetPolicyFactor,inputVals.parametersMF);
            if(inputVals.resetModelFactor>=0 && inputVals.resetModelFactor<=1)
                Model=combineModels(AddictedModel,HealthyModel,inputVals.resetModelFactor);
                
            elseif inputVals.resetModelFactor<0
                Model=punishDrugModel(HealthyModel,inputVals.Environment,inputVals.resetModelFactor);
            end
        else
            originalMBlF=inputVals.parametersMBFW.modelLearningFactor;
            originalMFlF=inputVals.parametersMF.alpha;
            originalModelDecay=inputVals.parametersMBFW.modelDecay;
            inputVals.parametersMBFW.modelLearningFactor=inputVals.parametersMBFW.modelLearningFactor*inputVals.therapyModelLF;
            inputVals.parametersMBFW.modelDecay=2*inputVals.parametersMBFW.modelDecay;
            
            inputVals.parametersMF.alpha=inputVals.parametersMF.alpha*inputVals.therapyMFLFF;
        end
    end
    if (nStep==inputVals.therapyEndSteps)
        inputVals.Environment=changeToBaseReward(inputVals.Environment);
        HealedModel=Model;
        HealedQ=QTablePerm;
        if(~inputVals.simulatedTherapy)
            inputVals.parametersMBFW.modelLearningFactor=originalMBlF;
            inputVals.parametersMF.alpha=originalMFlF;
            inputVals.parametersMBFW.modelDecay=originalModelDecay;
        end
        
    end
    
    
    %% execute agent
    
    
    [reward,action, new_state,~,~,~,~,~,~,QTablePerm,stateActionVisitCounts,reset,stateActionVisitCountsSimul,Model,stateActionVisitCounts2] =...
        step(inputVals.parametersMBBW.internalReplay,...
        inputVals.parametersMBFW.runInternalSimulation,...
        inputVals.parametersMBFW.updateModel,...
        inputVals.parametersMF.updateQTablePerm,...
        inputVals.parametersMBBW.internalReplay,...
        currentState,...
        Model,...
        inputVals.Environment,...
        QTablePerm,...
        stateActionVisitCountsSimul,...
        reset,...
        inputVals.parametersMF,...
        inputVals.parametersMBFW,...
        inputVals.parametersMBBW,...
        stateActionVisitCounts,...
        stateActionVisitCounts2);
    
    
    
    if inputVals.parametersMBFW.computePolicyWithDP
        
        if j==0
            %             display('parametersMBFW.computePolicyWithDP')
            QTablePerm.mean = DP(   inputVals.parametersMBFW,inputVals.Environment);
            Environment=inputVals.Environment;
            save (strcat('Environment',num2str(nStep,'%06i'),'.mat'),'Environment')
            j=100;
        else
            j=j-1;
        end
    end
    %     if(reward~=0) || (currentState==1)
    %         found=false;
    %         for obsidx1=1:obsidx
    %             if (observed(obsidx1).action==action &&...
    %                     observed(obsidx1).currentState==currentState &&...
    %                     observed(obsidx1).reward==reward &&...
    %                     observed(obsidx1).new_state==new_state)
    %                 found=true;
    %                 break
    %             end
    %         end
    %         if ~found
    %             obsidx=obsidx+1;
    %             observed(obsidx).action=action;
    %             action=action
    %             observed(obsidx).currentState=currentState;
    %             currentState=currentState
    %             observed(obsidx).reward=reward;
    %             reward=reward
    %             observed(obsidx).new_state=new_state;
    %             new_state=new_state
    %             nStep=nStep
    %             pause
    %             displayQValueMean(QTablePerm.mean,inputVals.Environment);
    %             pause
    %         end
    %     end
    
    
    
    
    
    
    
    
    
    last_actions(nStep)=action;
    
    last_states(nStep)=currentState;
    last_reward(nStep)=reward;
    
    %lastMaxK(i)=maxK;
    %lastMaxVar(i)=maxVar;
    %lastDreward(i)=max(abs(dreward));
    %lastMA_noise_n(i)=MA_noise_n;
    %   last_maxD(i)=maxdiffQp;
    %   last_meanD(i)=meanQp;
    
    last_Q(nStep,:,:)=QTablePerm.mean;
    currentState=new_state;
    
    
    
    Q=QTablePerm.mean;
    
    
    if inputVals.parametersMBFW.computeStatistics
        if stepsToComputeStatistics<=0
            inputVals.parametersMBFW.stepsToComputeStatistics=inputVals.parametersMBFW.periodToComputeStatistics;
            for stateForStatistics=1:inputVals.Environment.Num_States;
                for iStatisticsSteps=1:inputVals.parametersMBFW.statisticsStepsPerState
                    [reward1(iStatisticsSteps,stateForStatistics),...
                        action1(iStatisticsSteps,stateForStatistics),...
                        new_state1(iStatisticsSteps,stateForStatistics),~,~,~,~,~,~] = ...
                        step(inputVals.parametersMBBW.internalReplay,...
                        inputVals.parametersMBFW.runInternalSimulation,...
                        inputVals.parametersMBFW.updateModel,...
                        inputVals.parametersMF.updateQTablePerm,...
                        inputVals.parametersMBBW.internalReplay,... % 追加した
                        stateForStatistics,...
                        Model,...
                        inputVals.Environment,...
                        QTablePerm,...
                        stateActionVisitCountsSimul,...
                        reset,...
                        inputVals.parametersMF,...
                        inputVals.parametersMBFW,...
                        inputVals.parametersMBBW,...　% 追加した
                        stateActionVisitCounts,...
                        stateActionVisitCounts2);
                    
                end
            end
        else
            stepsToComputeStatistics=stepsToComputeStatistics-1;
        end
    end
end


Results.total_reward=total_reward;
Results.i=nStep;
Results.Q=Q;
Results.Model=Model;
Results.last_actions=last_actions;
Results.last_states=last_states;
Results.last_reward=last_reward;
Results.last_Q=last_Q;
Results.lastMaxK=lastMaxK;
Results.lastMaxVar=lastMaxVar;
Results.lastDreward=lastDreward;
Results.lastMA_noise_n=lastMA_noise_n;
Results.last_maxD=last_maxD;
Results.last_meanD=last_meanD;
Results.HealthyModel=HealthyModel;
Results.HealthyQ=HealthyQ;
Results.AddictedModel=AddictedModel;
Results.AddictedQ=AddictedQ;
Results.HealedModel=HealedModel;
Results.HealedQ=HealedQ;
end
