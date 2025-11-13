function actionSim=selectActionSimDyna(currentStateSim,MFParameters, QTablePermMean,stateActionVisitCounts,stateNames,actionNames)
num_actions=length(QTablePermMean(currentStateSim,:));
T=MFParameters.softMax_t;
if MFParameters.randExpl
    if rand() < MFParameters.explorationFactor
        actionSim=randi(num_actions);
        %             display(['Selecting random action: ' actionNames{actionSim} ' in state ' stateNames{currentStateSim}])
        
    else
        w=squeeze(QTablePermMean(currentStateSim,:));
        
        [~,actionSim]=max(w+0.00000001*rand(size(w)));
        %[~,actionSim]=max(w);
        %             display(['Selecting greedy action: ' actionNames{actionSim} ' in state ' stateNames{currentStateSim} ' val: ' num2str(val) ' w:' mat2str(w)])
        
    end
else if MFParameters.softMax
        %             w=squeeze(QTablePermMean(currentStateSim,:));
        w(:)=QTablePermMean(currentStateSim,:);
        we=exp(w/T);
        if any(isnan(we))||all(we==0)
            %we=we
            %w=w
            [~,actionSim]=max(w+0.00000001*rand(size(w)));
            %pause
        else
            actionSim=randsample(num_actions,1,true,we);
        end
        %display(['Selecting soft max action: ' actionNames{actionSim} ' in state ' stateNames{currentStateSim}])
    end
end
end
