function updateQLearning(reward, new_state,action , currentState, MFParameters,stateActionVisitCounts)
    global QTablePerm;
    alpha=MFParameters.alpha_MF/stateActionVisitCounts(currentState,action);
    gamma=MFParameters.gamma_MF;
    oldVal=QTablePerm(currentState,action);
    newVal=max(QTablePerm(new_state,:));
    
    QTablePerm(currentState,action)=oldVal+...
        alpha *(reward+gamma*newVal -oldVal);
end


