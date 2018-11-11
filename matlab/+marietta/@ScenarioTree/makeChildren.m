function makeChildren(treeObject)
nonLeaveNodes = find(treeObject.stage<=treeObject.getHorizon()-1);
treeObject.children = cell(numel(nonLeaveNodes), 1);
for i = 1:numel(nonLeaveNodes)
    treeObject.children{nonLeaveNodes(i)} = find(treeObject.ancestor==i);
end