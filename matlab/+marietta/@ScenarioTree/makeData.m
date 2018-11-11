function makeData(obj)
%MAKEDATA Summary of this function goes here
%   Detailed explanation goes here
nNodes = obj.getNumberOfNodes();
obj.data = repmat(struct(), nNodes, 1);

end

