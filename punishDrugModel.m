function ModelOut=punishDrugModel(ModelIn,Environment,punishment)
ModelOut=ModelIn;
% display('before therapy')
% displayEnvironment(EnvironmentOut);
% display('press key')
% pause

for st= Environment.drugStates
    stpos=st - Environment.drugStates(1)+1;
    for action=1:ModelOut.Num_Actions
%         v1=EnvironmentOut.reward{st,action}(:);
%         
%  display (EnvironmentOut.nodenames{st})
%             display (EnvironmentOut.actionName{action})
%             display(v1)
        ModelOut.reward{st,action}(:)=punishment*ones(size(ModelOut.reward{st,action}(:)));
%         v2=EnvironmentOut.reward{st,action}(:);
%         display(v2)

    end
end


for st= Environment.drugReachabeState
    
    for action=Environment.toDrugActionIdx
%         v3=EnvironmentOut.reward{st,action}(:);
%         display (EnvironmentOut.nodenames{st})
%             display (EnvironmentOut.actionName{action})
%                     display(v3)            

        ModelOut.reward{st,action}(:)=punishment*ones(size(ModelOut.reward{st,action}(:)));
%         v4=EnvironmentOut.reward{st,action}(:);
%          display(v4)       
    end
end

ModelOut=createInverseTransitions(ModelOut);
%pause
% display('after therapy')
% displayEnvironment(EnvironmentOut);
% display('press key')
% pause
end