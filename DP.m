function [QTablePerm, steps] = DP(   MFParameters,Environment)
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

QTablePerm=zeros(Environment.Num_States,Environment.Num_Actions);
H=ones(1,Environment.Num_States);
V=zeros(1,Environment.Num_States);
hmax=1000;
    steps=0;
while true
    steps=steps+1;
    [hmax,selectedstate]=max(H);
    if(hmax==0)
        display(strcat('converged in ',num2str(steps)));
        break;
    end;
    
    for action=1:Environment.Num_Actions
        %statename=Environment.nodenames{selectedstate}
        %actionname=Environment.actionName{action}
        
        reward_s=Environment.reward{selectedstate, action};

        Ps=Environment.ps{selectedstate, action};

        nextState=Environment.nextState{selectedstate, action};
        %sizereward_s=size(reward_s)
        %MFParameters.gamma_MF
        
        ip=V(nextState);
        gammaip=MFParameters.gamma*ip;
        %sizeip=size(ip)
        %sizeps=size(Ps)
        if ~isempty(Ps)
        %QTablePerm(selectedstate, action)=dot(Ps,reward_s+ gammaip);
        QTablePerm(selectedstate, action)=sum(Ps.*(reward_s+ gammaip));
        end
    end
    m=max(QTablePerm(selectedstate,:));
    d=abs(V(selectedstate)-m);
    V(selectedstate)=m;
    %displayModel(Environment)
    for st_H=1:Environment.Num_States
        idxst=(Environment.PreviousStates{selectedstate}==st_H);
        h=d*  max(idxst.*Environment.InversePs{selectedstate});
        if (st_H==selectedstate)
            
            
            H(st_H)=h;
        else
            H(st_H)=max(h,H(st_H));            
        end
    end
end
    
end