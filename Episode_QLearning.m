function [ total_reward,steps,Q,last_actions,last_states,last_reward,last_Q] = Episode_QLearning( maxsteps,  MFParameters,~,environment,start,~ )
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
global QTablePerm;
QTablePerm=zeros(environment.Num_States,environment.Num_Actions);

stateActionVisitCounts=zeros(environment.Num_States,environment.Num_Actions);

total_reward = 0;

currentState=start;
% selects an action using the epsilon greedy selection strategy
%a   = e_greedy_selection(Q,s,epsilon);

    last_actions=zeros(1,maxsteps);

    last_states=zeros(1,maxsteps);

    last_reward=zeros(1,maxsteps);
    
    
    last_Q=zeros(maxsteps,environment.Num_States,environment.Num_Actions);
    
for steps=1:maxsteps     

    action=selectActionSimDyna(currentState,MFParameters, QTablePerm,stateActionVisitCounts,environment.nodenames,environment.actionName);
    stateActionVisitCounts(currentState,action)=stateActionVisitCounts(currentState,action)+1;
    
    %do the selected action and get the next car state    
    [reward, new_state]  = DoAction( action , currentState, environment );    


   
    
    updateQLearning(reward, new_state,action , currentState, MFParameters,stateActionVisitCounts);




   

    last_actions(steps)=action;

    last_states(steps)=currentState;

    last_reward(steps)=reward;
    
    last_Q(steps,:,:)=QTablePerm;
    
     
    
 
    
    
    %increment the step counter.
    
    currentState=new_state;
    
%     if mod(steps,maxsteps/10)==0
%         display(['Steps' num2str(steps)]);
%         displayQValueMean(QTablePerm,environment);
%     end
   
    % Plot of the mountain car problem
%     if (grafic==true)
%         Plot( x,a,steps,environment,start,goal,['PLANNING (N=' num2str(p_steps) ')']);
%     end
%     
%     % if reachs the goal breaks the episode
%     if (f==true)
%         break
%     end
    
end
Q=QTablePerm;
end