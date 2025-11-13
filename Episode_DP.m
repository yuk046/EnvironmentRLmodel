function [ total_reward,i,Q,Model,last_actions,last_states,last_reward,last_Q,lastMaxK,lastMaxVar,lastDreward,lastMA_noise_n,last_maxD,last_meanD ] =...
    Episode_DP( maxsteps,Environment,start,parameters)

  
    

QTablePerm_t.mean=zeros(Environment.Num_States,Environment.Num_Actions);
QTablePerm_t.time=zeros(Environment.Num_States,Environment.Num_Actions);
QTablePerm_t.var=1.5*eye(Environment.Num_States*Environment.Num_Actions);
QTablePerm=QTablePerm_t;

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
Model =CreateModel(Environment,priorCounts,parameters.knownTransitions);

currentState           = start;

total_reward = 0;

reset=1;


% selects an action using the epsilon greedy selection strategy
%a   = e_greedy_selection(Q,s,epsilon);

stateActionVisitCounts=zeros(Environment.Num_States,Environment.Num_Actions);
stateActionVisitCounts2=stateActionVisitCounts;

QTablePerm = DP(   parameters,Environment);
for i=1:maxsteps
    
    %run internal simulations
    %[QTablePerm,~]=runInternalSimulation(QTablePerm,currentState,Model,MBParameters,reset);reset=0;
    %Qtable_Integrated=QTablePerm;
    %select action a
    
    action =selectActionSimDyna(currentState,parameters, QTablePerm,stateActionVisitCounts,Model.nodenames,Model.actionName);
    
    %do the selected action and get the next car state
    [reward, new_state]  = DoAction( action , currentState, Environment );
    
    %QTablePerm=Qtable_Integrated;
    
    
    Model=updateModel(reward, new_state,action , currentState,Model,0.995,parameters.knownTransitions);
    
    %display('actualInteraction')
    %[QTablePerm,maxK,maxVar,dreward,MA_noise_n]=updateQTablePerm(QTablePerm,reward, new_state,action , currentState, parameters,reset);reset=0;
    %reset=0;
    
    %[QTablePerm,maxdiffQp,meanQp]=internalReplay(QTablePerm,Model,parameters,stateActionVisitCounts2,reset);reset=0;
    
    
    
    
    
    last_actions(i)=action;
    
    last_states(i)=currentState;
    
    last_reward(i)=reward;
    %lastMaxK(i)=maxK;
    %lastMaxVar(i)=maxVar;
    %lastDreward(i)=max(abs(dreward));
    %lastMA_noise_n(i)=MA_noise_n;
%   last_maxD(i)=maxdiffQp;
 %   last_meanD(i)=meanQp;
    
    last_Q(i,:,:)=QTablePerm;
    Q=QTablePerm;
    currentState=new_state;
    
    
    
    
end


