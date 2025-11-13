function EnvironmentOut=createInverseTransitions(EnvironmentIn)
EnvironmentOut=EnvironmentIn;


kx=ones(EnvironmentOut.Num_States,1);
for previousState=1:EnvironmentOut.Num_States
    for action=1:EnvironmentOut.Num_Actions
        for j=1:length(EnvironmentOut.nextState{previousState, action})
            %                 previousState=previousState
            %                 action=action
            %                 j=j
            endState=EnvironmentOut.nextState{previousState, action}(j);
            k=kx(endState);
            kx(endState)=k+1;
            EnvironmentOut.PreviousStates{endState}(k)=previousState;
            EnvironmentOut.InverseActions{endState}(k)=action;
            length (EnvironmentOut.reward{previousState,action});
            
            EnvironmentOut.InverseReward{endState}(k)=EnvironmentOut.reward{previousState,action}(j);
            EnvironmentOut.InversePs{endState}(k)=EnvironmentOut.ps{previousState,action}(j);
            %s(gr_idx)=previousState;
            %t(gr_idx)=endState;
            %w(gr_idx)=ps{previousState,action}(j);
            %nodeLab{gr_idx}=['a_' int2str(action) '_r_' int2str(reward{previousState,action}(j))];
            %gr_idx=gr_idx+1;
        end
        
    end
end

