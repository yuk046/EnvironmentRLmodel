%    MBParameters=struct(alpha_MB,Valpha_MB,…
%	StoppingPathThresh,VStoppingPathThresh,…
%	StoppingPathLength,VStoppingPathLength,…
%	StoppingPathThreshReward=VStoppingPathThreshReward,…
%	stoppingThresh,VstoppingThresh,…
%	MaxItr,VMaxItr,…
%	StopSim,VStopSim,…
%	SelectActionSim,VSelectActionSim,…
%	stopOnUncertaintyVal,VstopOnUncertaintyVal);
%	QTablePerm=struct(QTablePermMean,VQTablePermMean,…
%		QTableVar,VQTableVar)


function [Qtable_Integrated,N_itr]=runInternalSimulationSeparteMFMB(QTablePerm,currentState,Model,MBParameters,resetSim)
persistent stateActionVisitCounts;
if isempty(stateActionVisitCounts) || resetSim
    stateActionVisitCounts=zeros(Model.Num_States,Model.Num_Actions);
end
path_num=1;
path_step=1;
N_itr=1;
Qtable_Integrated= QTablePerm;


%% begin_simulation_iteration_loop
while(N_itr<=MBParameters.MaxItrMB)
%display('runInternalSimulation')
%    while(N_itr<=10)
    
    currentStateSim= currentState;
    path_end=0;
    reset=resetSim;
    path_step=0;
    
    %begin_path_simulation_iteration_loop
    while(path_end==0)
        %simulate one step
        baseEF=MBParameters.explorationFactor;
        %MBParameters.explorationFactor=10*MBParameters.explorationFactor;
        actionSim=selectActionSim(currentStateSim,Model,MBParameters, Qtable_Integrated,stateActionVisitCounts);
        MBParameters.explorationFactor=baseEF;

        
        [nextStateSim,rewardSim,valid]=doActionInModel(actionSim,Model,currentStateSim,MBParameters);
        if ~valid
            %display('new state cannot simulate');
            %displayModel(Model);
            %path_end=1;
            %N_itr
            break ;
        end;
        stateActionVisitCounts(currentStateSim,actionSim)=stateActionVisitCounts(currentStateSim,actionSim)+1;
        %path_end = testNewStateToEndPathSimulation(actionSim, currentStateSim, nextStateSim, rewardSim, path_step, Qtable_Integrated,Model, MBParameters);
        %path_end=true;
            
        
        
        %% update                 
        Qtable_Integrated=updateQTablePerm(Qtable_Integrated, rewardSim, nextStateSim,actionSim , currentStateSim,stateActionVisitCounts, MBParameters,reset);
        currentStateSim= nextStateSim;
        reset=0;
        path_step=path_step+1;
        path_end=(path_step==MBParameters.StoppingPathLengthMB);
        
        %% logging
             % 		Paths_Sampled(path_num).action(path_step)= actionSim;
        % 		Paths_Sampled(path_num).state(path_step)= currentStateSim;
        % 		Paths_Sampled(path_num).reward(path_step)= rewardSim;
        % 		Paths_Sampled(path_num).path_end(path_step)=path_end;
        % 		Paths_Sampled(path_num).steps=path_step;
        % 		Paths_Sampled(path_num).last_state=nextStateSim;
        %updateQtable_IntegratedWithSimulatedPathTDLambda(nextStateSim, rewardSim, currentStateSim,actionSim,Model,MBParameters,Model,stateActionVisitCounts);
        
        
        %end_path_simulation_iteration_loop
    end
    N_itr=N_itr+1;
    
    %display(['simulation done, steps:' num2str(path_step)])
end


%updateQtable_IntegratedWithSimulatedPathBacktracking(path_num, Paths_Sampled,Qtable_Integrated,Model,MBParameters);
%path_num= path_num+1;

%end_simulation_iteration_loop

end
