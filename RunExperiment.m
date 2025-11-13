function  RunExperiment( maxepisodes,varargin)
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

maxgamma=1;
Qgamma=zeros(maxgamma,Environment.Num_States,Environment.Num_Actions);
plot_graphs=true;
data=cell(2, maxgamma);
MFParameters=struct(...
    'alpha_MF',alpha,...
    'gamma_MF',gamma,...%gamma,...
    'lambda_MF',lambda,...
    'explorationFactor',epsilon,...
    'randExpl',true,...
    'softMax',false,...
    'softMax_t',0.00001);


for gamma_i=1:maxgamma
    
    if (maxgamma~=1)MFParameters.gamma_MF=gamma_i/(maxgamma+1); end
    
    if strcmp(method,'Qlearning')
        for episode=1:maxepisodes
            
            [~,steps,~,last_actions,last_states,last_reward,last_Q]=Episode_QLearning( maxsteps,  MFParameters,grafic,Environment,start,p_steps );
            
            
            if (plot_graphs)
                PlotQEvolution(maxsteps,MFParameters,Environment,last_Q,episode,maxepisodes,gamma_i);
                
                plotVisits(maxsteps,last_states,Environment,MFParameters,episode,maxepisodes,gamma_i);
                
                plotActionSelection(MFParameters,Environment,maxsteps,last_states,last_actions,episode,maxepisodes,gamma_i);
                
            end
            
            
            qt(:,:)=last_Q(maxsteps,:,:);
        end
    elseif  strcmp(method,'DP')
        qt = DP( maxsteps,  MFParameters,Environment);
    elseif  strcmp(method,'KTD')
        for episode=1:maxepisodes
            [total_reward,steps,Q,Model,last_actions,last_states,last_reward,last_Q,lastK,lastVar,lastDreward,lastMA_noise_n  ] =   Episode_KTD( maxsteps,  alpha, gamma,epsilon,MFParameters,grafic,Environment,start,p_steps );
            %[~,steps,~,last_actions,last_states,last_reward,last_Q]=Episode_QLearning( maxsteps,  MFParameters,grafic,Environment,start,p_steps );
            
            
            if (plot_graphs)
                figure; plot(1:maxsteps,smooth(lastK,50));title('Max Kalman Gain');
                figure;plot(1:maxsteps,smooth(lastVar,50));title('Max Q.var');
                figure;plot(1:maxsteps,smooth(abs(lastDreward),50));title('Max lastDreward');
                figure;plot(1:maxsteps,smooth(abs(lastMA_noise_n),50));title('Max lastMA_noise_n');
                PlotQEvolution(maxsteps,MFParameters,Environment,last_Q,episode,maxepisodes,gamma_i);
                
                plotVisits(maxsteps,last_states,Environment,MFParameters,episode,maxepisodes,gamma_i);
                
                plotActionSelection(MFParameters,Environment,maxsteps,last_states,last_actions,episode,maxepisodes,gamma_i);
                
            end
        end
        
        qt(:,:)=last_Q(maxsteps,:,:);Episode_MB_MF_No_Learning
    elseif  strcmp(method,'FW_NoLearning')
        
        for episode=1:maxepisodes
            [total_reward,steps,Q,Model,last_actions,last_states,last_reward,last_Q,lastK,lastVar,lastDreward,lastMA_noise_n  ] =   Episode_FW_NoLearning( maxsteps,  alpha, gamma,epsilon,MFParameters,grafic,Environment,start,p_steps );
            %[~,steps,~,last_actions,last_states,last_reward,last_Q]=Episode_QLearning( maxsteps,  MFParameters,grafic,Environment,start,p_steps );
            
            
            if (plot_graphs)
                %                 figure; plot(1:maxsteps,smooth(lastK,50));title('Max Kalman Gain');
                %                 figure;plot(1:maxsteps,smooth(lastVar,50));title('Max Q.var');
                %                 figure;plot(1:maxsteps,smooth(abs(lastDreward),50));title('Max lastDreward');
                %                 figure;plot(1:maxsteps,smooth(abs(lastMA_noise_n),50));title('Max lastMA_noise_n');
                PlotQEvolution(maxsteps,MFParameters,Environment,last_Q,episode,maxepisodes,gamma_i);
                
                plotVisits(maxsteps,last_states,Environment,MFParameters,episode,maxepisodes,gamma_i);
                
                plotActionSelection(MFParameters,Environment,maxsteps,last_states,last_actions,episode,maxepisodes,gamma_i);
                
            end
        end
        
        qt(:,:)=last_Q(maxsteps,:,:);
    elseif  strcmp(method,'FWBW_NoLearning')
        
        for episode=1:maxepisodes
            [total_reward,steps,Q,Model,last_actions,last_states,last_reward,last_Q,lastK,lastVar,lastDreward,lastMA_noise_n  ] =   Episode_FWBW_NoLearning( maxsteps,  alpha, gamma,epsilon,MFParameters,grafic,Environment,start,p_steps );
            %[~,steps,~,last_actions,last_states,last_reward,last_Q]=Episode_QLearning( maxsteps,  MFParameters,grafic,Environment,start,p_steps );
            
            
            if (plot_graphs)
                %                 figure; plot(1:maxsteps,smooth(lastK,50));title('Max Kalman Gain');
                %                 figure;plot(1:maxsteps,smooth(lastVar,50));title('Max Q.var');
                %                 figure;plot(1:maxsteps,smooth(abs(lastDreward),50));title('Max lastDreward');
                %                 figure;plot(1:maxsteps,smooth(abs(lastMA_noise_n),50));title('Max lastMA_noise_n');
                PlotQEvolution(maxsteps,MFParameters,Environment,last_Q,episode,maxepisodes,gamma_i);
                
                plotVisits(maxsteps,last_states,Environment,MFParameters,episode,maxepisodes,gamma_i);
                
                plotActionSelection(MFParameters,Environment,maxsteps,last_states,last_actions,episode,maxepisodes,gamma_i);
                
            end
        end
        
        qt(:,:)=last_Q(maxsteps,:,:);
    elseif  strcmp(method,'MF+MB')
        
        for episode=1:maxepisodes
            [total_reward,steps,Q,Model,last_actions,last_states,last_reward,last_Q,lastK,lastVar,lastDreward,lastMA_noise_n,last_maxD,last_meanD  ] =   Episode_Dim_UCT_UCRL( maxsteps,  alpha, gamma,epsilon,MFParameters,grafic,Environment,start,p_steps );
            %[~,steps,~,last_actions,last_states,last_reward,last_Q]=Episode_QLearning( maxsteps,  MFParameters,grafic,Environment,start,p_steps );
            
            
            if (plot_graphs)
                %                 figure; plot(1:maxsteps,smooth(lastK,50));title('Max Kalman Gain');
                %                 figure;plot(1:maxsteps,smooth(lastVar,50));title('Max Q.var');
                %                 figure;plot(1:maxsteps,smooth(abs(lastDreward),50));title('Max lastDreward');
                %                 figure;plot(1:maxsteps,smooth(abs(lastMA_noise_n),50));title('Max lastMA_noise_n');
                %figure;plot(1:maxsteps,smooth(abs(last_maxD),50),'LineWidth',2);title('Max Q up');
                %figure;plot(1:maxsteps,smooth(abs(last_meanD),50),'LineWidth',2);title('Mean Q up');
                plotUpdates(maxsteps,last_maxD,last_meanD,MFParameters,episode,maxepisodes,gamma_i)
                PlotQEvolution(maxsteps,MFParameters,Environment,last_Q,episode,maxepisodes,gamma_i);
                
                plotVisits(maxsteps,last_states,Environment,MFParameters,episode,maxepisodes,gamma_i);
                
                plotActionSelection(MFParameters,Environment,maxsteps,last_states,last_actions,episode,maxepisodes,gamma_i);
                
                
            end
        end
        
        qt(:,:)=last_Q(maxsteps,:,:);
    end
    
    
    
    
    Qgamma(gamma_i,:,:)=qt(:,:);
    displayQValueMean(qt,Environment)
    data{1,gamma_i}=qt;
    data{2,gamma_i}=strcat('QVal',num2str(MFParameters.gamma_MF),'.dat');
    
end
save('QVal.mat', 'data');

if (maxgamma>1)
    figure('Name','QValues over discount factor gamma');
    for episode=1:Environment.Num_States
        subplot(Environment.Num_States,1,episode);
        Q1(1:maxgamma,1:Environment.Num_Actions)=Qgamma(1:maxgamma,episode,1:Environment.Num_Actions);
        size(Q1)
        plot(Q1,'LineWidth',2);
        legend(Environment.actionName);
        title(['QValues over discount factor gamma: ' Environment.nodenames{episode}] );
    end
end
end