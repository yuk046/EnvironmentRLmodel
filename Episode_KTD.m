function [ total_reward,i,Q,Model,last_actions,last_states,last_reward,last_Q,lastMaxK,lastMaxVar,lastDreward,lastMA_noise_n ] = Episode_Dim_UCT_UCRL( maxsteps, alpha, gamma,epsilon,MFParameters,grafic,Environment,start,p_steps )
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
global QTablePerm
MBParameters=struct('alpha_MB',alpha,...
    'StoppingPathThreshMB',10,...
    'stoppingThreshMB',20,...
    'MaxItrMB',10,...
    'StopSimMB',10,...
    'SelectActionSimMB','DYNA',...
    'knownTransitions',1,...
    'stopOnUncertaintyVal',1,...
    'gamma_MB',MFParameters.gamma_MF,...
    'lambda_MB',MFParameters.lambda_MF,...,
    'sigma_square_noise_external',0.000001,...
    'noiseVal',0.000001,...
    'noiceVar',0.000001);


QTablePerm_t.mean=zeros(Environment.Num_States,Environment.Num_Actions);
QTablePerm_t.var=2*eye(Environment.Num_States*Environment.Num_Actions);
QTablePerm=QTablePerm_t;

    last_actions=zeros(1,maxsteps);

    last_states=zeros(1,maxsteps);

    last_reward=zeros(1,maxsteps);
    lastMaxK=zeros(1,maxsteps);
    lastMaxVar=lastMaxK;
    lastDreward=lastMaxK;
    lastMA_noise_n=lastMaxK;
    
    
    last_Q=zeros(maxsteps,Environment.Num_States,Environment.Num_Actions);
    



MBParameters=setstructfields(MBParameters,MFParameters);



Model =CreateModel(Environment,MBParameters);

currentState           = start;

total_reward = 0;


% selects an action using the epsilon greedy selection strategy
%a   = e_greedy_selection(Q,s,epsilon);

stateActionVisitCounts=zeros(Environment.Num_States,Environment.Num_Actions);

for i=1:maxsteps
    
    %run internal simulations
    Qtable_Integrated=QTablePerm;
    %select action a
    action=actionSelection(currentState,Model,MBParameters, Qtable_Integrated,Environment,stateActionVisitCounts);
    
    
    %do the selected action and get the next car state
    [reward, new_state]  = DoAction( action , currentState, Environment );
        
    
    [QTablePerm,maxK,maxVar,dreward,MA_noise_n]=updateQTablePerm(Qtable_Integrated,reward, new_state,action , currentState, MBParameters,i==1);
                
    
    last_actions(i)=action;
    
    last_states(i)=currentState;
    
    last_reward(i)=reward;
    lastMaxK(i)=maxK;
    lastMaxVar(i)=maxVar;
    lastDreward(i)=max(abs(dreward));
    lastMA_noise_n(i)=MA_noise_n;
    
    
    last_Q(i,:,:)=QTablePerm.mean;
    currentState=new_state;
    
    

    Q=QTablePerm.mean;
end


