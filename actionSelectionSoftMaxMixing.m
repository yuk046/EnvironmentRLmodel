function action=actionSelectionSoftMaxMixing(currentState,parametersMF, simQ,QLQ,mbf,mff)


num_actions=length(simQ(currentState,:));
T=parametersMF.softMax_t;

wMB=squeeze(simQ(currentState,:));
wMF=squeeze(QLQ(currentState,:));
w= mbf*wMB+mff*wMF;

wMBe=exp(mbf*wMB/T);
wMFe=exp(mff*wMF/T);
wMBe=wMBe/sum(wMBe);
wMFe=wMFe/sum(wMFe);
if(strcmp(parametersMF.mixmode,'+'))
we=wMBe + wMFe
else
we=wMBe .* wMFe
end

if any(isnan(we))||all(we==0)
    %we=we
    %w=w
    
    [~,action]=max(w+0.00000001*rand(size(w)));
    
else
    action=randsample(num_actions,1,true,we);
    
end

end