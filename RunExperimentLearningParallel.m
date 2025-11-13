function  RunExperimentLearningParallel( maxepisodes,varargin)
%RunExperiments, the main function of the experiment
%maxepisodes: maximum number of episodes to run the experiment

p = inputParser;
defaultMethod='QLearning';
expectedMethods= {'QLearning','DP','KTD','MF+MB','FWBW_NoLearning','FW_NoLearning'};


addRequired(p,'maxepisodes',@isnumeric);

addOptional(p,'method',defaultMethod,...
    @(x) any(validatestring(x,expectedMethods)));

parse(p,maxepisodes,varargin{:});

method=p.Results.method;


clc
start       = 2;
Environment  = TestCreateEnvironment();




%Model       = BuildModel(Environments ); % the Qtable

% planning steps
p_steps     = 50;

maxsteps    = 1e5;  % maximum number of steps per episode
alpha       = 0.1;   % learning rate
gamma       = 0.9;  % discount factor
lambda=.75;
epsilon     = 0.1;   % probability of a random action selection


grafic    = false; % indicates if display the graphical interface
grafic     = true;

maxInternalNoise=10;
Qgamma=zeros(maxInternalNoise,Environment.Num_States,Environment.Num_Actions);
plot_graphs=true;
data=cell(2, maxInternalNoise);
MFParameters=struct(...
    'alpha_MF',alpha,...
    'gamma_MF',gamma,...%gamma,...
    'lambda_MF',lambda,...
    'explorationFactor',epsilon,...
    'randExpl',true,...
    'softMax',false,...
    'softMax_t',0.00001);

 c = parcluster; 
j = c.batch(@Episode_Dim_UCT_UCRL, 1, { maxsteps, alpha, 1,MFParameters,Environment,start});
wait(j)
diary(j)
%load(j)
r= fetchOutputs (j)

% for internalNoiseIdx=1:maxInternalNoise
%     
%     %if (maxgamma~=1)MFParameters.gamma_MF=gamma_i/(maxgamma+1); end
%     
%     if  strcmp(method,'MF+MB')
%         noise=1;%internalNoiseIdx/(1+maxInternalNoise);
% %         for episode=1:maxepisodes
%             [total_reward,steps,Q,Model,last_actions,last_states,last_reward,last_Q,lastK,lastVar,lastDreward,lastMA_noise_n,last_maxD,last_meanD  ] = ...                
%              Episode_Dim_UCT_UCRL( maxsteps, alpha, noise,MFParameters,Environment,start);
%             %[~,steps,~,last_actions,last_states,last_reward,last_Q]=Episode_QLearning( maxsteps,  MFParameters,grafic,Environment,start,p_steps );
%             
%             
%             if (plot_graphs)
%                 %                 figure; plot(1:maxsteps,smooth(lastK,50));title('Max Kalman Gain');
%                 %                 figure;plot(1:maxsteps,smooth(lastVar,50));title('Max Q.var');
%                 %                 figure;plot(1:maxsteps,smooth(abs(lastDreward),50));title('Max lastDreward');
%                 %                 figure;plot(1:maxsteps,smooth(abs(lastMA_noise_n),50));title('Max lastMA_noise_n');
%                 %figure;plot(1:maxsteps,smooth(abs(last_maxD),50),'LineWidth',2);title('Max Q up');
%                 %figure;plot(1:maxsteps,smooth(abs(last_meanD),50),'LineWidth',2);title('Mean Q up');
%                 
%                 plotUpdates(maxsteps,last_maxD,last_meanD,MFParameters,internalNoiseIdx,maxInternalNoise,noise);
%                 
%                 plotReward(maxsteps,last_reward,MFParameters,internalNoiseIdx,maxInternalNoise,noise);
%                 
%                 PlotQEvolution(maxsteps,MFParameters,Environment,last_Q,internalNoiseIdx,maxInternalNoise,noise);
%                 
%                 plotVisits(maxsteps,last_states,Environment,MFParameters,internalNoiseIdx,maxInternalNoise,noise);
%                 
%                 plotActionSelection(MFParameters,Environment,maxsteps,last_states,last_actions,internalNoiseIdx,maxInternalNoise,noise);
%                 
%                 
%             end
% %         end
%         
%         qt(:,:)=last_Q(maxsteps,:,:);
%     end
%     
%     
%     
%     
%     Qgamma(internalNoiseIdx,:,:)=qt(:,:);
%     displayQValueMean(qt,Environment)
%     displayModel(Model)
%     displayEnvironment(Environment)
%     displayModelEnvironmentDiff(Model,Environment);
%     data{1,internalNoiseIdx}=qt;
%     data{2,internalNoiseIdx}=strcat('QVal',num2str(MFParameters.gamma_MF),'.dat');
%     
% end
% save('QVal.mat', 'data');
% 
% if (maxInternalNoise>1)
%     figure('Name','QValues over internal noise');
%     for episode=1:Environment.Num_States
%         subplot(Environment.Num_States,1,episode);
%         Q1(1:maxInternalNoise,1:Environment.Num_Actions)=Qgamma(1:maxInternalNoise,episode,1:Environment.Num_Actions);
%         size(Q1)
%         plot(Q1,'LineWidth',2);
%         legend(Environment.actionName);
%         title(['QValues over internal noise: ' Environment.nodenames{episode}] );
%     end
% end
end