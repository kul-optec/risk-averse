function makeLeaves(treeObject, nHorizon)
numNodes = numel(treeObject.ancestor);
numLeaveNodes = sum(treeObject.stage==nHorizon);
treeObject.leaves = (numNodes-numLeaveNodes+1:numNodes)';