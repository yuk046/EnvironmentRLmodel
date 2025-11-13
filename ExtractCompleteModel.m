function    Model=ExtractCompleteModel(ModelIn)


%ps=cell(Num_States,Num_Actions);
%reward=cell(Num_States,Num_Actions);
%nextState=cell(Num_States,Num_Actions);
%gr_idx=1;
%define goal state dynamics
Model=ModelIn;

for st=1:Model.Num_States
    for act=1:Model.Num_Actions
        if (isempty(Model.counts{st,act})) 
                Model.nextState{st,act}(1)=st;    
                Model.reward{st,act}(1)=0;    
                Model.counts{st,act}(1)=Model.priorCounts+1;
                Model.ps{st,act}(1)=1;
        end
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
