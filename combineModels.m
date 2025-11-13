function Model=combineModels(baseModel,finalModel,resetModelFactor)
Model=baseModel;






%     Model.reward=cell(Model.Num_States,Model.Num_Actions);
%     Model.ps=cell(Model.Num_States,Model.Num_Actions);
%     Model.nextState=cell(Model.Num_States,Model.Num_Actions);
%     Model.counts=cell(Model.Num_States,Model.Num_Actions);
%

ns=Model.Num_States;
na=Model.Num_Actions;



for previousState=1:ns
    for action=1:na
        Model.ps{previousState,action}(:)=(1-resetModelFactor)*Model.ps{previousState,action}(:);
        Model.counts{previousState,action}(:)=(1-resetModelFactor)*Model.counts{previousState,action}(:);
        %            display(Environment.nextState{previousState, action})
        el=0*(1:length(finalModel.nextState{previousState, action}));
        
        
        for j=1:length(Model.nextState{previousState, action})
            endState=Model.nextState{previousState, action}(j);
            ps=Model.ps{previousState,action}(j);
            reward=Model.reward{previousState,action}(j);
            idxESt=finalModel.nextState{previousState, action}==endState;
            idxRew=finalModel.reward{previousState,action}==reward;
            id=find(idxESt .* idxRew);
            if ~isempty(id)
                Model.ps{previousState,action}(j)=Model.ps{previousState,action}(j)+resetModelFactor*(finalModel.ps{previousState,action}(id(1)));
                Model.counts{previousState,action}(j)=Model.counts{previousState,action}(j)+resetModelFactor*(finalModel.counts{previousState,action}(id(1)));
                el(id)=1;
                %display(['ok start: ' Model.nodenames{previousState}  ' act: ' Model.actionName{action} ' end: ' Model.nodenames{endState} ' rew: ' num2str(reward) ' dp: ' num2str(abs(ps-Environment.ps{previousState,action}(id(1)))) ' pM: ' num2str(ps) ' pE: ' num2str(Environment.ps{previousState,action}(id(1))) ' cnt: ' num2str(Model.counts{previousState,action}(j)) ]);            
                
            end
            
            
        end
        id2=find(el==0);
        if ~isempty(id2)
            for k=1:length(id2)
                j=id2(k);
                Model.nextState{previousState, action}(end+1)=finalModel.nextState{previousState, action}(j);
                Model.ps{previousState, action}(end+1)=resetModelFactor*finalModel.ps{previousState,action}(j);
                Model.counts{previousState, action}(end+1)=resetModelFactor*finalModel.counts{previousState,action}(j);
                Model.reward{previousState, action}(end+1)=finalModel.reward{previousState,action}(j);                
            end
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
end