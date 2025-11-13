function EnvironmentOut=changeToTherapyReward(Environment)
EnvironmentOut=Environment;
% display('before therapy')
% displayEnvironment(EnvironmentOut);
% display('press key')
% pause

for st= EnvironmentOut.drugStates
    stpos=st - EnvironmentOut.drugStates(1)+1;
    for action=1:EnvironmentOut.Num_Actions
%         v1=EnvironmentOut.reward{st,action}(:);
%         
%  display (EnvironmentOut.nodenames{st})
%             display (EnvironmentOut.actionName{action})
%             display(v1)
        EnvironmentOut.reward{st,action}(:)=EnvironmentOut.therapyReward{stpos,action}(:);
        EnvironmentOut.ps{st,action}(:)=EnvironmentOut.therapyPs{stpos,action}(:);
%         v2=EnvironmentOut.reward{st,action}(:);
%         display(v2)

    end
end


for st= EnvironmentOut.drugReachabeState
    
    for action=EnvironmentOut.toDrugActionIdx

%         v3=EnvironmentOut.reward{st,action}(:);
%         display (EnvironmentOut.nodenames{st})
%             display (EnvironmentOut.actionName{action})
%                     display(v3)            
            stpos=st-EnvironmentOut.drugReachabeState(1)+1;
        EnvironmentOut.reward{st,action}(:)=(EnvironmentOut.therapyRewardBaseState{stpos,action-EnvironmentOut.toDrugActionIdx+1}(:));
%         v4=EnvironmentOut.reward{st,action}(:);
%          display(v4)       
    end
end

EnvironmentOut=createInverseTransitions(EnvironmentOut);
%pause
% display('after therapy')
% displayEnvironment(EnvironmentOut);
% display('press key')
% pause
end