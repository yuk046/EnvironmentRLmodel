function    Model=updateModel(rew, new_state,action , st,ModelIn,decay,transitionKnown,learningFactor)


%ps=cell(Num_States,Num_Actions);
%reward=cell(Num_States,Num_Actions);
%nextState=cell(Num_States,Num_Actions);
%gr_idx=1;
%define goal state dynamics
Model=ModelIn;

for i=1:Model.Num_States
    for j=1:Model.Num_Actions
        Model.counts{i,j}=(1-decay)*Model.counts{i,j};
    end
end

% rew=rew
% new_state=new_state
% action=action
% st=st

nextStates=Model.nextState{st,action};
ps=Model.ps{st,action};
rewards=Model.reward{st,action};
counts=Model.counts{st,action};

idxStates=nextStates(:)==new_state;
idxRew=rewards(:)==rew;

id=find(idxStates.*idxRew);

next=length(Model.nextState{st,action})+1;
if (isempty(id))
    
    %     display(['Model.nextState{' Model.nodenames{st} ',' Model.actionName{action} '}'])
    %     display('Old transition')
    %     for i=1:next-1
    %         display(Model.nodenames{ Model.nextState{st,action}(i)})
    %     end
    Model.nextState{st,action}(next)=new_state;
    %     display('New transition')
    %     for i=1:next
    %         display(Model.nodenames{ Model.nextState{st,action}(i)})
    %     end
    %display(mat2str(Model.nextState{st,action}))
    
    Model.reward{st,action}(next)=rew;
    
    Model.counts{st,action}(next)=Model.priorCounts+1;
    %pause
else
    Model.counts{st,action}(id(1))=Model.counts{st,action}(id(1))+learningFactor;
end

for i=1:Model.Num_States
    for action2=1:Model.Num_Actions
        tot=sum(Model.counts{st,action2});
        Model.ps{st,action2}=Model.counts{st,action2}/tot;
    end
end

kx=ones(Model.Num_States,1);

for i=1:Model.Num_States
    for action2=1:Model.Num_Actions
        for j=1:length(Model.nextState{i, action2})
            endState=Model.nextState{i, action2}(j);
            k=kx(endState);
            kx(endState)=k+1;
            Model.PreviousStates{endState}(k)=i;
            Model.InverseActions{endState}(k)=action2;
            Model.InverseReward{endState}(k)=Model.reward{i,action2}(j);
            Model.InversePs{endState}(k)=Model.ps{i,action2}(j);
            %                 s(gr_idx)=previousState;
            %             t(gr_idx)=endState;
            %             w(gr_idx)=ps{previousState,action}(j);
            %             nodeLab{gr_idx}=['a_' int2str(action) '_r_' int2str(reward{previousState,action}(j))];
            %             gr_idx=gr_idx+1;
        end
        
    end
end



%G = graph(s,t,w)

end
