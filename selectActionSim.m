function actionSim=selectActionSim(currentStateSim,Model,MBParameters, Qtable_Integrated,stateActionVisitCounts)


if strcmp(MBParameters.SelectAction,'UCT')
	actionSim =selectActionSimUCT(currentStateSim,Model,MBParameters, Qtable_Integrated.mean,stateActionVisitCounts);

else
    if strcmp(MBParameters.SelectAction,'DYNA')

	actionSim =selectActionSimDyna(currentStateSim,MBParameters, Qtable_Integrated.mean,stateActionVisitCounts,Model.nodenames,Model.actionName);
    

    end
end

end

