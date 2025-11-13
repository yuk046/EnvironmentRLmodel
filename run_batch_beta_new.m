% run_batch_beta_new.m
% Wrapper to run multiple episodes across MF/MB balance (beta) values
% This version uses RunExperimentLearning96 and CreateEnvironmentMultiStepDeterministic7
%
% Usage:
%   Edit configuration below (betas, numAgents, numRuns). Then run:
%     run_batch_beta_new
%
% Notes:
% - This script calls RunExperimentLearning96 which internally uses
%   CreateEnvironmentMultiStepDeterministic7 and Episode_WithReset_And_Statistics
% - Addiction is defined as "agent visited any drug-goal state more than healthy states"
% - Results are saved to data/results_beta_<v>.mat

clearvars; close all;

% --- Configuration ---
betas = [0 0.2 0.4 0.6 0.8 1.0];
numAgents = 15;   % agents per run
numRuns = 45;    % independent runs per beta
experimentname = 'batch_beta_experiment';

% whether to print per-agent visit counts (drug vs healthy)
displayVisitCounts = true;

% If only a single state should be considered the "drug goal" for addiction
% (override). Set to [] to use Environment.drugStates (default range).
specificDrugGoalState = 8;

% Random seed base (so results are repeatable if desired)
rngBase = 0;

% Helper: decide whether an agent developed addiction based on saved data
% New criterion: agent is 'addicted' when the number of visits to drug-goal
% states is greater than the number of visits to healthy goal states.
function addicted = isAgentAddicted(last_states, drugStates, healthyStates)
    addicted = false;
    if isempty(last_states)
        return
    end
    drugVisits = sum(ismember(last_states, drugStates));
    healthyVisits = sum(ismember(last_states, healthyStates));
    addicted = (drugVisits > healthyVisits);
end

% Determine drug and healthy state indices based on standard environment parameters
% According to CreateEnvironmentMultiStepSequentialPunishment convention:
% drug states: (n_healthy_goals + n_base_states) + (1:n_drug_goals)
n_healthy = 1;
n_base = 6;
n_drug = 15;
drugStateStart = n_healthy + n_base + 1;
drugStates = drugStateStart:(drugStateStart + n_drug - 1);
healthyStates = 1:n_healthy;

% Main loop
for ib = 1:numel(betas)
    beta = betas(ib);
    fprintf('\n=== Beta = %.2f (%d/%d) ===\n', beta, ib, numel(betas));
    fprintf('Configuration: beta=%.2f, numAgents=%d, numRuns=%d\n', beta, numAgents, numRuns);
    
    % prepare per-beta log file
    dataFolder = fullfile(pwd,'data');
    if ~exist(dataFolder,'dir')
        mkdir(dataFolder);
    end
    bstr = strrep(num2str(beta),'.','_');
    logfname = fullfile(dataFolder, sprintf('log_beta_%s.txt', bstr));
    fidlog = fopen(logfname,'w');
    if fidlog>0
        fprintf(fidlog,'Run batch log\nStart time: %s\n', datestr(now));
        fprintf(fidlog,'beta=%g, numAgents=%d, numRuns=%d\n\n', beta, numAgents, numRuns);
        fclose(fidlog);
    end

    % prepare storage for percent addicted per run
    percentAddictedPerRun = zeros(numRuns,1);

    for runIdx = 1:numRuns
        % Optionally seed RNG per run for reproducibility
        rng(rngBase + runIdx + ib*1e4);
        
        addictedCount = 0;
        
        for agentIdx = 1:numAgents
            % Calculate fileId to control parameters in RunExperimentLearning96
            % We need to set mbFactor = beta, mfFactor = 1-beta
            % Looking at RunExperimentLearning96 code:
            % For 'MF+MB' method (when fileId triggers it), or other methods,
            % the mbFactor is set from MBFs array based on fileId
            %
            % We'll use a custom approach: directly modify the experiment after creation
            % But RunExperimentLearning96 needs to be called with appropriate fileId
            %
            % Strategy: Call with method where we can control mb_factor
            % From the code: MBFs=[0 0.05 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.95 1.0];
            % [mbFactorIDX,alphaMFIDX,therapymethod]=ind2sub([length(MBFs),length(alphaMFs),3],(mod(fileId,length(MBFs)*length(alphaMFs)*3)+1));
            %
            % To set specific mbFactor, we need to calculate fileId that gives us the right mbFactorIDX
            
            MBFs = [0 0.05 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.95 1.0];
            alphaMFs = [0.01 0.05 0.1];
            
            % Find closest mbFactor index
            [~, mbFactorIDX] = min(abs(MBFs - beta));
            alphaMFIDX = 3; % use alphaMF = 0.1
            therapymethod = 1; % balanced therapy
            
            % Calculate fileId: (mod(fileId,length(MBFs)*length(alphaMFs)*3)+1) should equal
            % sub2ind([length(MBFs),length(alphaMFs),3], mbFactorIDX, alphaMFIDX, therapymethod)
            linearIdx = sub2ind([length(MBFs),length(alphaMFs),3], mbFactorIDX, alphaMFIDX, therapymethod);
            fileId = linearIdx - 1; % because mod(fileId,...)+1 = linearIdx
            
            % Create unique experiment name for this run
            expname = sprintf('%s_beta%.2f_run%d_agent%d', experimentname, beta, runIdx, agentIdx);
            
            % Call RunExperimentLearning96
            % It will create Environment using CreateEnvironmentMultiStepDeterministic7
            % and run Episode_WithReset_And_Statistics
            try
                % Suppress output
                evalc('RunExperimentLearning96(1, expname, ''method'', ''MF+MB'', ''fileId'', fileId);');
            catch ME
                fprintf('Error in RunExperimentLearning96 at beta=%.2f run=%d agent=%d\n', beta, runIdx, agentIdx);
                rethrow(ME);
            end
            
            % Load results from saved files
            % RunExperimentLearning96 saves to: experimentname/data/.../last_states.mat
            % We need to find the most recent directory
            dataDir = fullfile(pwd, expname, 'data');
            if exist(dataDir, 'dir')
                % Find all subdirectories
                subdirs = dir(dataDir);
                subdirs = subdirs([subdirs.isdir] & ~ismember({subdirs.name}, {'.', '..'}));
                if ~isempty(subdirs)
                    % Sort by date modified (most recent first)
                    [~, sortIdx] = sort([subdirs.datenum], 'descend');
                    newestDir = subdirs(sortIdx(1));
                    
                    % Navigate through nested structure to find the actual data directory
                    searchPath = fullfile(dataDir, newestDir.name);
                    innerDirs = dir(searchPath);
                    innerDirs = innerDirs([innerDirs.isdir] & ~ismember({innerDirs.name}, {'.', '..'}));
                    if ~isempty(innerDirs)
                        searchPath = fullfile(searchPath, innerDirs(1).name);
                    end
                    
                    statesFile = fullfile(searchPath, 'last_states.mat');
                    if exist(statesFile, 'file')
                        loadedData = load(statesFile);
                        last_states = loadedData.last_states;
                        
                        % compute per-agent visit counts
                        if exist('specificDrugGoalState','var') && ~isempty(specificDrugGoalState)
                            envDrugStates = specificDrugGoalState;
                        else
                            envDrugStates = drugStates;
                        end
                        
                        drugVisits = sum(ismember(last_states, envDrugStates));
                        healthyVisits = sum(ismember(last_states, healthyStates));
                        
                        if displayVisitCounts
                            fprintf('  agent %d: drugVisits=%d, healthyVisits=%d\n', agentIdx, drugVisits, healthyVisits);
                        end
                        
                        % append to log
                        if exist('logfname','var')
                            fidlog = fopen(logfname,'a');
                            if fidlog>0
                                fprintf(fidlog,'run=%d agent=%d drugVisits=%d healthyVisits=%d\n', runIdx, agentIdx, drugVisits, healthyVisits);
                                fclose(fidlog);
                            end
                        end
                        
                        % evaluate addiction
                        if isAgentAddicted(last_states, envDrugStates, healthyStates)
                            addictedCount = addictedCount + 1;
                        end
                    else
                        fprintf('Warning: Could not find last_states.mat for beta=%.2f run=%d agent=%d\n', beta, runIdx, agentIdx);
                    end
                else
                    fprintf('Warning: No data subdirectory found for beta=%.2f run=%d agent=%d\n', beta, runIdx, agentIdx);
                end
            else
                fprintf('Warning: Data directory not found for beta=%.2f run=%d agent=%d\n', beta, runIdx, agentIdx);
            end
        end
        
        percentAddictedPerRun(runIdx) = 100 * addictedCount / numAgents;
        fprintf('[%s] beta=%.2f run %d/%d: %%addicted=%.2f\n', datestr(now,'HH:MM:SS'), beta, runIdx, numRuns, percentAddictedPerRun(runIdx));
        
        % append to log
        if exist('logfname','var')
            fidlog = fopen(logfname,'a');
            if fidlog>0
                fprintf(fidlog,'run=%d, percentAddicted=%.4f\n', runIdx, percentAddictedPerRun(runIdx));
                fclose(fidlog);
            end
        end
    end

    % Save results for this beta
    bstr = strrep(num2str(beta),'.','_');
    outfname = fullfile(pwd, 'data', sprintf('results_beta_%s.mat', bstr));
    percentAddicted = percentAddictedPerRun; %#ok<NASGU>
    save(outfname, 'percentAddicted');
    fprintf('Saved %s (nRuns=%d)\n', outfname, numRuns);
end

fprintf('\nAll done. Generated %d files in %s\n', numel(betas), fullfile(pwd,'data'));
