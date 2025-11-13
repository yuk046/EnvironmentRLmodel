function [ total_reward,i,Q,Model,last_actions,last_states,last_reward,last_Q,lastMaxK,lastMaxVar,lastDreward,lastMA_noise_n,last_maxD,last_meanD ] =...
    Episode_Dim_UCT_UCRL( maxsteps, Environment,start,parameters)
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

Model =CreateModel(Environment,parameters,4,parameters.knownTransitions);


currentState           = start;

total_reward = 0;

reset=1;


% selects an action using the epsilon greedy selection strategy
%a   = e_greedy_selection(Q,s,epsilon);

stateActionVisitCounts=zeros(Model.Num_States,Model.Num_Actions);
stateActionVisitCounts2=stateActionVisitCounts;

for i=1:maxsteps
    
    %run internal simulations
    if parameters.runInternalSimulation
        [QTablePerm,~]=runInternalSimulation(QTablePerm,currentState,Model,parameters,reset);
        reset=0;

        end
    %Qtable_Integrated=QTablePerm;
    %select action a
    action=actionSelection(currentState,Model,parameters, QTablePerm,stateActionVisitCounts);
    
    %do the selected action and get the next car state
    [reward, new_state]  = DoAction( action , currentState, Environment );
    
    %QTablePerm=Qtable_Integrated;
    
    if parameters.updateModel
        decay=0.995;
        Model=updateModel(reward, new_state,action , currentState,Model,decay,parameters.knownTransitions);
    end
    %display('actualInteraction')
    
    if parameters.updateQTablePerm
        [QTablePerm,maxK,maxVar,dreward,MA_noise_n]=updateQTablePerm(QTablePerm,reward, new_state,action , currentState, parameters,reset);
        reset=0;
    end
    
    if parameters.internalReplay
        [QTablePerm,maxdiffQp,meanQp]=internalReplay(QTablePerm,Model,parameters,stateActionVisitCounts2,reset);
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


