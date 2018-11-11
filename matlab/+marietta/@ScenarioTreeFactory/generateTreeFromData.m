function scenarioTreeObject = generateTreeFromData(data, options)
%GENERATETREEFROMDATA generates a scenario tree from data
%
%Syntax:
%tree = generateTreeFromData(data, ops)
%
%Input arguments:
% data  Stochastic variable. `data` is a 3D array where the first dimension 
%       is equal to the number of scenarios (number sequences of 
%       measurements), the second is the number of variables, i.e., the 
%       size of the uncertainty vector and the third dimension is the 
%       number of time instants.
%
% ops   Options; a mandatory input argument. `options` is a structure which 
%       must contain the following fields:
%         - ni: an array with the desired (maximum) branching factors at 
%           every stage. The length of this array is the horizon of the 
%           tree (the tree will have N+1 stages, 0..N). Branching factors 
%           are typically chosen to be high in the beginning and equal to 1 
%           after a certain stage.
%       Structure `ops` may further carry the following additional optional
%       fields:
%         - nScen: The maximum number of scenarios. (Default: Inf)
%         - Wscaling: whether scaling should be performed)
%         - Tmax: max number of scenarios to be processed
%
%Output arguments:
% tree  A ScenarioTree object constructed from the given data.
%
%See also:
%marietta.ScenarioTree.generateTreeFromIid
%marietta.ScenarioTree.generateTreeFromMarkovChain
if ~isstruct(options)
    error('options must be a structure');
end
if ~isfield(options, 'ni')
    error('options.ni must be specified (branching factors)');
end
ops.ni = options.ni;
ops.N  = length(ops.ni);
if isfield(options, 'Wscaling')
    ops.Wscaling = options.Wscaling;
else
    ops.Wscaling = 1;
end
if isfield(options, 'Tmax')
    ops.Tmax = options.Tmax;
else
    ops.Tmax = 1e4;
end
if ~isfield(options, 'nScen')
    ops.nScen = prod(options.ni)+10;
else
    nScen = options.nScen;
    maxNScen = min(prod(options.ni), size(data, 1));
    if nScen > maxNScen
        warning('Extravagant number of scenarios; saturating')
    end
    ops.nScen = min(maxNScen, nScen);
    
end
if length(size(data)) ~= 3 || ~isnumeric(data)
    error('The first argument (data) must be a 3D array');
else
    ops.nw = size(data, 2);
    tree = marietta.ScenarioTreeFactory.treeFormation(data, ops);
end
scenarioTreeObject = marietta.ScenarioTree();
scenarioTreeObject.stage = tree.stage;
scenarioTreeObject.children = tree.children;
scenarioTreeObject.ancestor = tree.ancestor;
scenarioTreeObject.probability = tree.prob;
scenarioTreeObject.leaves = tree.leaves;
scenarioTreeObject.value = tree.value;

makeScenarioIndex(scenarioTreeObject);
makeData(scenarioTreeObject);
end % -- END of function `generateTreeFromData`