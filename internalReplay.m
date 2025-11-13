%  MBReplayParameters = struct(...
%                             P_starting_point_high_R,VP_starting_point_high_R,...
%                             P_starting_point_Low_R,VP_starting_point_Low_R,...
%                             P_starting_point_recent_change,VP_starting_point_recent_change,...
%                             alpha_MF_MBRep,Valpha_MF_MBRep,... 
%                             gamma_MF_MBRep,Vgamma_MF_MBRep,...
%                             lambda_MF_MBRep,Vlambda_MF_MBRep,...
%                             frequency,vfrequency,...
%                             sweeps,NSweeps,...
%                             P_update_After_Reward,VP_update_After_Reward,...
%                             sigma_square_noise_external,VSigma_square_noise_external,...
%                             noiseVal,VNoiseVal);

function [QTablePermNew,dmax,dmean]=internalReplay(QTablePermOld,Model,BReplayParameters,stateActionVisitCounts,reset)
%display('internalReplay')
    %backSearchTree=java.util.Stack();
    %backSearchTreeFailures=java.util.Stack();
    backSearchTree=0*(1:BReplayParameters.stepsTotal+1);
    
    QTablePermNew=QTablePermOld;
    stepsTotal=0;
    
    sweeps=0;
    while ((sweeps<=10*BReplayParameters.sweeps) && (stepsTotal<10*BReplayParameters.stepsTotal))
        sweeps=sweeps+1;
        steps=0;
        
        goalState=selectEndState(QTablePermNew,Model,BReplayParameters);

        backSearchTree(steps+1)=goalState;

        while((steps>=0) && (steps<=BReplayParameters.sweepsDepth) && (rand()>BReplayParameters.restart_sweep_Prob)&& (stepsTotal<10*BReplayParameters.stepsTotal) )
            steps=steps+1;
            stepsTotal=stepsTotal+1;
%              display(['*** Internal Replay step:']) 
            endState=backSearchTree(steps);
            
            [actionsim,currentState,~,valid]=sampleTransitionToState(endState,Model,BReplayParameters);
            
            %displayModel(Model);
%             pause
            if ~valid 
%                 display(['not valid endstate:']) 
                steps=steps-2;
                stepsTotal=stepsTotal-0.5; 
%                 pause
                continue
            end
            %actionsim=selectActionSim(currentState,Model,BReplayParameters, QTablePermNew,stateActionVisitCounts);
            [nextStateSim2,rewardSim2,valid2]=doActionInModel(actionsim,Model,currentState,BReplayParameters);
%              pause
            if ~valid2 
                steps=steps-1;
                %display(['not valid startstate:'])
                    stepsTotal=stepsTotal-0.5; 
                continue
            end
            backSearchTree(steps+1)=currentState;
            
            if(discardCurrentSearchBranch(backSearchTree,Model,QTablePermNew,BReplayParameters))
                    steps=steps-1;
                    stepsTotal=stepsTotal-0.5;                
            else
                
                QTablePermNew=updateQTablePerm(QTablePermNew, rewardSim2, nextStateSim2, actionsim , currentState, stateActionVisitCounts,BReplayParameters,reset);
                
                reset =0;
%                 break;
            end
        end
    end
    D=QTablePermNew.mean(:)-QTablePermOld.mean(:);
    dmax=max(D);
    dmean=mean(D);
end