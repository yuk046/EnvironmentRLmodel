function EnvironmentOut=changeToBaseReward(Environment)
%Environment.drugState=(environmentParameters.n_healthy_goals+environmentParameters.n_base_states)+(1:environmentParameters.n_drug_goals);
EnvironmentOut=Environment;
% display('before normalisation')
% displayEnvironment(EnvironmentOut);
% display('press key')
% pause

for st= Environment.drugStates
    stpos=st - Environment.drugStates(1)+1;
    for action=1:Environment.Num_Actions
         v1=EnvironmentOut.reward{st,action}(:);
         v2=Environment.baseReward{stpos,action}(:);
%         display (EnvironmentOut.nodenames{st})
%         display (EnvironmentOut.actionName{action})
%         display(v1)
        EnvironmentOut.reward{st,action}(:)=Environment.baseReward{stpos,action}(:);
        EnvironmentOut.ps{st,action}(:)=Environment.basePs{stpos,action}(:);
%         v2=EnvironmentOut.reward{st,action}(:);
%         display(v2)
        
    end
end

for st= EnvironmentOut.drugReachabeState
    stpos=st - EnvironmentOut.drugReachabeState(1)+1;
    for action=EnvironmentOut.toDrugActionIdx
        %v3=EnvironmentOut.reward{st,action}(:);
%         display (EnvironmentOut.nodenames{st})
%         display (EnvironmentOut.actionName{action})
%         display(v3)
        EnvironmentOut.reward{st,action}=EnvironmentOut.baseRewardBaseState{stpos,action-EnvironmentOut.toDrugActionIdx+1};
%         v4=EnvironmentOut.reward{st,action}(:);
%         display(v4)
    end
end



EnvironmentOut=createInverseTransitions(EnvironmentOut);

% display('back to normal')
% displayEnvironment(EnvironmentOut);
% display('press key')
% pause
end