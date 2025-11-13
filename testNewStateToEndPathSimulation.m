function path_end = testNewStateToEndPathSimulation(actionSim, currentStateSim, nextStateSim, rewardSim, path_step, QTablePerm,Model, MBParameters)
                    
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

colnum=size(QTablePerm.mean,1);
if MBParameters.stopOnUncertaintyVal==1
    [~,act]=max(QTablePerm.mean(nextStateSim,:));
    
    nexVar=QTablePerm.var(colnum*(act-1)+nextStateSim,colnum*(act-1)+nextStateSim);
	if nexVar<MBParameters.StoppingPathThreshMB
			path_end =1;
		else 
			if path_step>= MBParameters.StoppingPathLengthMB
					path_end =1;
				else
					path_end =0;
			end
		

		end
	else
if rewardSim>MBParameters.StoppingPathThreshReward
	path_end =1;
		else 
			if path_step>= MBParameters. StoppingPathLengthMB
					path_end =1;
				else
					path_end =0;
			end
		

		end
end

end