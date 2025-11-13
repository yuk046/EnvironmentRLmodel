function [QOut,maxK,maxvar,dreward,MA_noise_n]=updateQTablePermKTD(QIn,reward, new_state,action , currentState,MFParameters,reset)
%% initialisation of persistent data %%
QOut=QIn;
persistent time;

if isempty(time)
    time=0;
end

% persistent MA_noise_omega;
% 
% 
% persistent MA_noise_n; %MA parameters



persistent F;
if isempty(F) ||reset
    F=blkdiag(eye(numel( QIn.mean)),diag(1,-1));
    
end


persistent noiseSubMatrix;
if isempty(noiseSubMatrix) ||reset
    m=MFParameters.gamma_MF;
    noiseSubMatrix= [1 -m; -m m*m]; 
end

persistent P
persistent Pn
if isempty(P) ||reset
P=blkdiag(QOut.var,1*eye(2));
%Pn=0*P;
end

persistent X
persistent Pxr
persistent noiseMatrix
persistent r
persistent l
persistent colnum
persistent oldsigma_square_noise_external
persistent oldnoiseVal
noiseVal=MFParameters.noiseVal;
sigma_square_noise_external=MFParameters.sigma_square_noise_external;
if isempty(X) ||reset ||(noiseVal~=oldnoiseVal)||(sigma_square_noise_external~=oldsigma_square_noise_external)
    %display ('resetting noise matrix')
    oldnoiseVal=noiseVal;
    oldsigma_square_noise_external=sigma_square_noise_external;
    noiseMatrix=blkdiag(noiseVal*eye(numel(QIn.mean)),sigma_square_noise_external*noiseSubMatrix);
%     pause
% else
% display ('noise matrix == old ')    
% display (['oldnoiseVal= ', num2str(oldnoiseVal)])
% whos oldnoiseVal
% display (['noiseVal= ', num2str(noiseVal)])
% whos noiseVal
% display (['oldsigma_square_noise_external= ', num2str(oldsigma_square_noise_external)])
% whos oldsigma_square_noise_external
% display (['sigma_square_noise_external= ', num2str(sigma_square_noise_external)])
% whos sigma_square_noise_external
% pause
end
if isempty(X) ||reset
    
    X= [QIn.mean(:);0;0];
    l=length(X);
    xPts=zeros(l,l*2+1);
    wPts=zeros(1,l*2+1);
    r=zeros(1,l*2+1);
    %Pxr=X*0;

    colnum=size(QOut.mean,1);
end


%% START %%

%% PREDICTION STEP%%%

X=F* X;

Pn=F*P*F.'+noiseMatrix;

%% Compute Unscented Statistics %%
[xPts, wPts, nPts] =scaledSymmetricSigmaPoints(X,Pn,1,0,0);
wPts_r=wPts(1:(l*2+1));



[~, new_action]=max(QOut.mean(new_state,:));
for j=1:nPts    
    %Q=reshape(xPts(1:numel(QOut.mean),j),size(QOut.mean));
    %r(j)=Q(currentState,action)-MFParameters.gamma_MF*Q(new_state,new_action)+nj
    
    QValOldJ=xPts(colnum*(action-1)+currentState,j);
   
    QValNewJ=xPts(colnum*(new_action-1)+new_state,j);
   
    nj=xPts(l,j);
    
    r(j)=QValOldJ-MFParameters.gamma_MF*QValNewJ+nj;
end
MA_noise_n=max(xPts(l,:));

rhat=dot(wPts_r,r);
dr=r-rhat;

Pxr=(xPts-diag(X)*ones(size(xPts)))*((wPts_r .* dr).');
% for j=1:nPts;
%
%     Pxr=Pxr+(wPts_r(j) * dr(j) * (xPts(:,j)-X(:)));     
% end

Pr= max( dot(wPts_r,(dr.^2)),10^(-4));

K= Pxr* Pr^(-1)'; 

%% Correction %%%%%

dreward=(reward-rhat);
X= X+ K * dreward;
P = Pn-  Pr * (K * K.');

%% Logging %%%
maxK=max(abs(K));


maxvar=max(abs(P(:)));

QOut.mean=reshape(X(1:numel(QOut.mean)),size(QOut.mean));
%MA_noise_omega=X(numel(QOut.mean)+1);

%MA_noise_n=X(numel(QOut.mean)+2);

QOut.var=P(1:numel(QOut.mean),1:numel(QOut.mean));
QOut.time=0.1*QOut.time;
QOut.time(currentState,action)=1;
time=time+1;


