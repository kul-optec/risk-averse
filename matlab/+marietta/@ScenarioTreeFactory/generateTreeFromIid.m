function treeObject = generateTreeFromIid(probDist, options)
%GENERATETREEFROMIID generates tree from IID distribution
% Generates a scenario tree from an IID process with a given probability
% distribution.
%
% The generated tree describes a stochastic process (X_k)_k, with k=0..N
% where X_k in {1,...,s} and Prob[X_k = i] = p_i, given the probability
% vector p = (p1,...,ps).
%
%Syntax:
% tree = marietta.ScenarioTree.generateTreeFromIid(probDist, options);
%
%Input arguments:
% probDist      probability distribution
% options       a structure with options; this is a mandatory argument. The
%               structure must have the field `horizonLength` which is the
%               horizon length, N, of the tree to be generated. Additional
%               optional fields of `options` are:
%                 - branchingHorizon: the horizon length until which the
%                   tree should branch. After that, the tree does not
%                   branch and further. If this option is not provided, the
%                   default value is to set it equal to the horizon length.
%                   * Note 1. If `branchingHorizon` is provided, then only 
%                   the nodes at stages up to branchingHorizon-1 may have 
%                   branches. All nodes at stages from branchingHorizon 
%                   till the end of the horizon will have only one single 
%                   child.
%                   * Note 2. If `branchingHorizon` exceeds the horizon of
%                   the tree, it will be disregarded.
%
%Output arguments:
% tree          the generated scenario tree
%
%Remark #1. If any of the elements of `probDist` are equal to 0, these will
%be disregarded.
%
%See also:
%marietta.ScenarioTree.generateTreeFromMarkovChain
%marietta.ScenarioTree.generateTreeFromData

if ~isfield(options, 'horizonLength')
    error('marietta:generateTreeFromIid:options', ...
        'horizonLength missing from options')
end

if ~isfield(options, 'branchingHorizon')
    options.branchingHorizon = options.horizonLength;
end
options.branchingHorizon = min(options.branchingHorizon, options.horizonLength);

if options.horizonLength <= 0
    error('marietta:generateTreeFromIid:horizonLength', ...
            'horizon length must be positive');
end

probDist = vec(probDist);
verifyProbDist(probDist);
initProbDist = probDist;
probDist(probDist==0) = [];
treeObject = createAncestorArray(probDist, options);
treeObject.value = [];                              
makeStageArray(treeObject, probDist, options);      
makeLeaves(treeObject, options.horizonLength);                    
makeScenarioIndex(treeObject);                          
makeProbability(treeObject, probDist, options);
makeChildren(treeObject);
makeData(treeObject);
makeValuesIID(treeObject, initProbDist, options);



function makeValuesIID(treeObject, probDist, options)
values = find(probDist~=0);
treeObject.value = [0];
for t=1:options.branchingHorizon
    valuesAtStage = kron(ones(treeObject.getNumberOfNodesAtStage(t-1), 1), values);
    treeObject.value = [treeObject.value;
        valuesAtStage];
end
for t=1+options.branchingHorizon:options.horizonLength
    treeObject.value = [treeObject.value;
        valuesAtStage];
end
function verifyProbDist(probDist)
if any(probDist<0)
    error('marietta:generateTreeFromIid:probDist', 'negative probability value');
end
if abs(sum(probDist)-1)>1e-6
    error('marietta:generateTreeFromIid:probDist', ...
        'sum of probabilities not equal to 1');
end


function makeProbability(treeObject, probDist, options)
treeObject.probability = 1;
nBranching = options.branchingHorizon;
nHorizon = options.horizonLength;
pk = 1;
for stage = 1:nBranching
    pk = kron(probDist,pk);
    treeObject.probability = [treeObject.probability; pk];
end
for stage = nBranching+1:nHorizon
    treeObject.probability = [treeObject.probability; pk];
end

function makeStageArray(treeObject, probDist, options)
nBranching = options.branchingHorizon;
nHorizon = options.horizonLength;
dimProbSpace = numel(probDist);
treeObject.stage = 0;
for stage = 1:nBranching
    numNodesAtStage = dimProbSpace^stage;
    treeObject.stage = [treeObject.stage; stage * ones(numNodesAtStage, 1)];
end
for stage = nBranching+1:nHorizon
    treeObject.stage = [treeObject.stage; stage * ones(numNodesAtStage, 1)];
end

function treeObject = createAncestorArray(probDist, options)
nBranching = options.branchingHorizon;
nHorizon = options.horizonLength;
dimProbSpace = numel(probDist);
treeObject = marietta.ScenarioTree();
ancs = [0; ones(dimProbSpace, 1)];
nodeIdOffset = 1;
for stage = 1:nBranching
    treeObject.ancestor = [treeObject.ancestor; ancs];
    numNodesAtStage = dimProbSpace^stage;
    idsTemp = (1:numNodesAtStage);
    idsTemp = idsTemp + nodeIdOffset;
    nodeIdOffset = idsTemp(end);
    ancs = kron(idsTemp', ones(dimProbSpace,1));
end
for stage = nBranching:nHorizon-1
    treeObject.ancestor = [treeObject.ancestor; idsTemp'];
    idsTemp = nodeIdOffset + (1:numNodesAtStage);
    nodeIdOffset = idsTemp(end);
end