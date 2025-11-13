function QTablePermOut=combinePolicies(QTablePermIn,QFinal,resetPolicyFactor,MFParameters)
QTablePermOut=QTablePermIn;
QTablePermOut.mean=(1-resetPolicyFactor)*QTablePermOut.mean+resetPolicyFactor*QFinal.mean;
if MFParameters.useKTD
    QTablePermOut.var=(1-resetPolicyFactor)*QTablePermOut.var+resetPolicyFactor*QFinal.var;
end
end