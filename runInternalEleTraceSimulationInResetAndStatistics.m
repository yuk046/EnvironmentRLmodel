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


function [Qtable_Integrated,N_itr,stateActionVisitCountsOut]=runInternalEleTraceSimulationInResetAndStatistics...
    (QTablePerm,currentState,Model,MBParameters,stateActionVisitCounts)
N_itr=1;
Qtable_Integrated= QTablePerm;

if MBParameters.useMFToDriveMB
    QTablePermLocal=QTablePerm;
else
    QTablePermLocal=Qtable_Integrated;
end

Qtable_Integrated.mean=zeros(size(Qtable_Integrated.mean));
stateActionVisitCountsOut=stateActionVisitCounts;


%% begin_simulation_iteration_loop
while(N_itr<=MBParameters.MaxItrMB)
    %display('runInternalSimulation')
    %    while(N_itr<=10)
    
    currentStateSim= currentState;
    path_end=0;
    
    path_step=0;
    traceState=zeros(1,MBParameters.StoppingPathLengthMB);
    traceAction=zeros(1,MBParameters.StoppingPathLengthMB);
    traceW=zeros(1,MBParameters.StoppingPathLengthMB);
    %begin_path_simulation_iteration_loop
    while(path_end==0)
        %simulate one step
        
        
        actionSim=selectActionSim(currentStateSim,Model,MBParameters, QTablePermLocal,stateActionVisitCountsOut);
        traceW=MBParameters.lambda*MBParameters.gamma*traceW;
        traceW(path_step+1)=1;
        traceState(path_step+1)=currentStateSim;
        traceAction(path_step+1)=actionSim;
        
        [nextStateSim,rewardSim,valid]=doActionInModel(actionSim,Model,currentStateSim,MBParameters);
        if ~valid
            %display('new state cannot simulate');
            %displayModel(Model);
            %path_end=1;
            %N_itr
            break ;
        end;
        
        stateActionVisitCountsOut(currentStateSim,actionSim)=stateActionVisitCountsOut(currentStateSim,actionSim)+1;
        %path_end = testNewStateToEndPathSimulation(actionSim, currentStateSim, nextStateSim, rewardSim, path_step, Qtable_Integrated,Model, MBParameters);
        %path_end=true;
        
        
        
        %% update
        
        %Qtable_Integrated=updateQTablePermNoReset(Qtable_Integrated, rewardSim, nextStateSim,actionSim , currentStateSim,stateActionVisitCountsOut, MBParameters);
        
        [~,~,dreward]=...
            updateQTablePermBase(Qtable_Integrated.mean,rewardSim, nextStateSim,actionSim , currentStateSim,stateActionVisitCountsOut, MBParameters);
        
        currentStateSim= nextStateSim;
        path_step=path_step+1;
        path_end=(path_step==MBParameters.StoppingPathLengthMB);
        if path_end
            dreward=dreward+max(QTablePermLocal.mean(currentStateSim,:))*MBParameters.gamma;
        end
        for itrace=1:MBParameters.StoppingPathLengthMB
            if(traceW(itrace)==0)
                break;
            else
                if(MBParameters.UseMFToBoothMBFinalVAl)
                    dreward=traceW(itrace)*MBParameters.alpha*dreward;
                end
                    
                
                QTablePermLocal.mean(traceState(itrace),traceAction(itrace))=QTablePermLocal.mean(traceState(itrace),traceAction(itrace))+dreward;
                Qtable_Integrated.mean(traceState(itrace),traceAction(itrace))=Qtable_Integrated.mean(traceState(itrace),traceAction(itrace))+dreward;
            end
            
        end
        
        
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
