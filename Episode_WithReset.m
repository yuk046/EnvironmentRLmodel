    %function [ total_reward,i,Q,Model,last_actions,last_states,last_reward,last_Q,lastMaxK,lastMaxVar,lastDreward,lastMA_noise_n,last_maxD,last_meanD ] =...
function Results =...
    Episode_WithReset( maxsteps,initDrugStartSteps,therapyStartSteps,therapyEndSteps,simulatedTherapy,resetModelFactor,resetPolicyFactor,Environment,start,parametersMF,parametersMBFW,parametersMBBW)
% Episode do one episode of the mountain car with sarsa learning
% maxstepts: the maximum number of steps per episode
% Q: the current QTable
% alpha: the current learning rate
% gamma: the current discount factor
% epsilon: probablity of a random action
% statelist: the list of states
% actionlist: the list of actions

% Maze
% based on the code of:
%  Jose Antonio Martin H. <jamartinh@fdi.ucm.es>
%
%


QTablePerm.mean=zeros(Environment.Num_States,Environment.Num_Actions);
QTablePerm.time=zeros(Environment.Num_States,Environment.Num_Actions);
QTablePerm.var=1.5*eye(Environment.Num_States*Environment.Num_Actions);

last_actions=zeros(1,maxsteps);

last_states=zeros(1,maxsteps);

last_reward=zeros(1,maxsteps);
lastMaxK=zeros(1,maxsteps);
lastMaxVar=lastMaxK;
lastDreward=lastMaxK;
lastMA_noise_n=lastMaxK;
last_maxD=lastMaxK;
last_meanD=lastMaxK;


last_Q=zeros(maxsteps,Environment.Num_States,Environment.Num_Actions);
priorCounts=4;
parametersMBFW.knownTransitions
copyTransitionsFromEnvironment=(parametersMBFW.knownTransitions);

Model =CreateModel(Environment,priorCounts,copyTransitionsFromEnvironment);
HealthyModel=Model;
AddictedModel=Model;
HealthyQ=QTablePerm;
AddictedQ=QTablePerm;
HealedModel=Model;
HealedQ=QTablePerm;
currentState           = start;

total_reward = 0;

reset=1;


% selects an action using the epsilon greedy selection strategy
%a   = e_greedy_selection(Q,s,epsilon);

stateActionVisitCounts=zeros(Model.Num_States,Model.Num_Actions);
stateActionVisitCounts2=stateActionVisitCounts;
Environment=changeToTherapyReward(Environment);
j=0;
for i=1:maxsteps
    %% change environment phase (initial,drug,therapy,postDrug)
    if i==initDrugStartSteps
        Environment=changeToBaseReward(Environment);
        HealthyQ=QTablePerm;
        HealthyModel=Model;
    elseif i==therapyStartSteps
        Environment=changeToTherapyReward(Environment);
        AddictedModel=Model;
        AddictedQ=QTablePerm;
        if simulatedTherapy
            QTablePerm=combinePolicies(QTablePerm,HealthyQ,resetPolicyFactor,parametersMF);
            if(resetModelFactor>=0 & resetModelFactor<=1)
            Model=combineModels(AddictedModel,HealthyModel,resetModelFactor);
            
            elseif resetModelFactor<0
                Model=punishDrugModel(HealthyModel,Environment,resetModelFactor);                
            end
        end
    end    
    if (i==therapyEndSteps)
        Environment=changeToBaseReward(Environment);
        HealedModel=Model;
        HealedQ=QTablePerm;
    end
    
    
    %% execute agent
    %run internal simulations
    if parametersMBFW.runInternalSimulation
%        display('parametersMBFW.runInternalSimulation')
        [QTablePermOut,~]=runInternalSimulation(QTablePerm,currentState,Model,parametersMBFW,reset);
        
        reset=0;
    end
    
    if parametersMBFW.computePolicyWithDP 
         
        if j==0
%             display('parametersMBFW.computePolicyWithDP')
            QTablePerm.mean = DP(   parametersMBFW,Environment);
            
            save (strcat('Environment',num2str(i,'%06i'),'.mat'),'Environment')
            j=100;
        else
            j=j-1;
        end
        
        
    end
    %Qtable_Integrated=QTablePerm;
    %select action a
    if (parametersMBFW.mixMFMBPolicies )
        QtableSelect=QTablePerm;
        QtableSelect.mean=parametersMBFW.mf_factor*QTablePerm.mean+parametersMBFW.mb_factor*QTablePermOut.mean;
        action=actionSelection(currentState,Model,parametersMF, QtableSelect,stateActionVisitCounts);
    else
        QTablePerm.mean=parametersMBFW.mf_factor*QTablePerm.mean+parametersMBFW.mb_factor*QTablePermOut.mean;
    action=actionSelection(currentState,Model,parametersMF, QTablePerm,stateActionVisitCounts);
    end
    
    %do the selected action and get the next car state
    [reward, new_state]  = DoAction( action , currentState, Environment );
    
    %QTablePerm=Qtable_Integrated;
    
    if parametersMBFW.updateModel
   %     display('parametersMBFW.updateModel')
        decay=0.995;
        Model=updateModel(reward, new_state,action , currentState,Model,decay,parametersMBFW.knownTransitions);
    end
    %display('actualInteraction')
    
    if parametersMF.updateQTablePerm
    %     display('parametersMF.updateQTablePerm')
        [QTablePerm,maxK,maxVar,dreward,MA_noise_n]=updateQTablePerm(QTablePerm, reward, new_state, action , currentState, stateActionVisitCounts, parametersMF,reset);
        
        reset=0;
    end
    
    if parametersMBBW.internalReplay
      %  display('parametersMBBW.internalReplay')
        [QTablePerm,maxdiffQp,meanQp]=internalReplay(QTablePerm,Model,parametersMBBW,stateActionVisitCounts2,reset);
        reset=0;
    end
    
    
    
    
    last_actions(i)=action;
    
    last_states(i)=currentState;
    
    last_reward(i)=reward;
    %lastMaxK(i)=maxK;
    %lastMaxVar(i)=maxVar;
    %lastDreward(i)=max(abs(dreward));
    %lastMA_noise_n(i)=MA_noise_n;
    %   last_maxD(i)=maxdiffQp;
    %   last_meanD(i)=meanQp;
    
    last_Q(i,:,:)=QTablePerm.mean;
    currentState=new_state;
    
    
    
    Q=QTablePerm.mean;
end


Results.total_reward=total_reward;
Results.i=i;
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
