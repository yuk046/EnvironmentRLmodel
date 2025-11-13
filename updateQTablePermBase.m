
function [nQ,maxvar,dreward]=...
    updateQTablePermBase(QTablePerm,reward, new_state,action , currentState,stateActionVisitCountsFactor, MFParameters)
    %Q=QTablePerm;
    if(MFParameters.changeLearningFactorWithCounts)
%         display('MFParameters.changeLearningFactorWithCounts')
        alpha=MFParameters.alpha/stateActionVisitCountsFactor(currentState,action);
    else
        alpha=MFParameters.alpha;
    end
    gamma=MFParameters.gamma;
    oldVal=QTablePerm(currentState,action);
    newVal=max(QTablePerm(new_state,:));
    dreward=(reward+gamma*newVal -oldVal);
    maxvar=alpha *(reward+gamma*newVal -oldVal);
    nQ=oldVal+maxvar;...
    maxvar=abs(maxvar);
end
