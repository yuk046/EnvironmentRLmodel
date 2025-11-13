function discard=discardCurrentSearchBrunch(backSearchTree,Model,QTablePerm,BReplayParameters)
%endState=backSearchTree.peek();
discard=false;%(time-QTablePerm.timeUpdate(endState))<BReplayParameters.max_time;
end
