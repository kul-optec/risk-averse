function treeObject = generateTreeFromMarkovChain(...
    chainProbTransMatrix, initialDistribution, options)
%GENERATETREEFROMMARKOVCHAIN creates a scenario tree from a Markov chain
%
%Syntax:
% tree = generateTreeFromMarkovChain(...
%    chainProbTransMatrix, initialDistribution, options)
%
%Input arguments:
% chainProbTransMatrix  The probability transition matrix of the Markov
%                       chain
% initialDistribution   The initial distribution of the process
% options               A structure with options; this is a mandatory input
%                       argument. It must contain the field `horizonLength`
%                       which is the horizon length, N, of the tree to be
%                       generated. Additional optinal fields:
%                         - branchingHorizon: the horizon length until
%                           which the tree should branch. After that, the
%                           tree does not branch and further. If this
%                           option is not provided, the default value is to
%                           set it equal to the `horizonLength`. 
%                           * Note 1. If `branchingHorizon` is provided,
%                           then only the nodes at stages up to branchingHorizon-1
%                           may have branches. All nodes at stages from 
%                           branchingHorizon till the end of the horizon
%                           will have only one single child.
%                           * Note 2. If `branchingHorizon` exceeds the 
%                           horizon of the tree, it will be disregarded.
%
%Ouput argument:
% tree      The scenario tree generated from the given Markov chain and
%           initial distribution. The values (see method getValueOfNode in
%           marietta.ScenarioTree) of the tree, store the values of the under-
%           lying Markov process.
%
%See also:
%marietta.ScenarioTree.generateTreeFromIid
%marietta.ScenarioTree.generateTreeFromData

if ~isfield(options, 'horizonLength')
    error('marietta:generateTreeFromMarkovChain:options', ...
        'horizonLength missing from options')
end

if ~isfield(options, 'branchingHorizon')
    options.branchingHorizon = options.horizonLength;
end
options.branchingHorizon = min(options.branchingHorizon, options.horizonLength);

if options.horizonLength <= 0
    error('marietta:generateTreeFromMarkovChain:horizonLength', ...
            'horizon length must be positive');
end

if options.branchingHorizon == 1
    treeObject = marietta.ScenarioTreeFactory.generateTreeFromIid(...
        initialDistribution, options);
    return;
end

% Verify input data
initialDistribution = vec(initialDistribution);
verifyInput(chainProbTransMatrix, initialDistribution);

% Construct tree
treeObject = createAncestorValueStage(...
    chainProbTransMatrix, initialDistribution, options);
makeLeaves(treeObject, options.horizonLength);
makeScenarioIndex(treeObject);
makeProbability(treeObject, chainProbTransMatrix, initialDistribution, options);
makeChildren(treeObject);
makeData(treeObject);
updateValues(treeObject, options);


function updateValues(treeObject, options)
if options.branchingHorizon == options.horizonLength, return; end
valuesToRepeat = treeObject.getValueOfNode(...
    treeObject.getNodesAtStage(...
        options.branchingHorizon));
valuesToRepeat = valuesToRepeat(:);    
delta_horizon = options.horizonLength - options.branchingHorizon;
treeObject.value =  [treeObject.value;
    kron(ones(delta_horizon,1), valuesToRepeat)];

function makeProbability(treeObject, chainProbTransMatrix, initialDistribution, options)
nBranching = options.branchingHorizon;
nHorizon = options.horizonLength;
treeObject.probability = [1; vec(initialDistribution(initialDistribution~=0))];
for stage = 1:nBranching-1
    nodesAtStage = treeObject.getNodesAtStage(stage);
    for i=1:numel(nodesAtStage)
        node = nodesAtStage(i);
        thetaNode = treeObject.getValueOfNode(node);
        distNode = chainProbTransMatrix(thetaNode, :)';
        distNode = distNode(distNode~=0);
        treeObject.probability = [treeObject.probability;
            treeObject.getProbabilityOfNode(node) * distNode];
    end
end
for stage = nBranching:nHorizon-1
    previousProbVector = treeObject.probability(treeObject.stage==stage);
    treeObject.probability = [treeObject.probability;
            previousProbVector];
end

function treeObject = createAncestorValueStage(...
    chainProbTransMatrix, initialDistribution, options)
nBranching = options.branchingHorizon;
nHorizon = options.horizonLength;
treeObject = marietta.ScenarioTree();
% ------ construct first stage
nInitDistNonZero = sum(initialDistribution~=0);
treeObject.value = [0; find(initialDistribution~=0)];
treeObject.ancestor = [0; ones(nInitDistNonZero, 1)];
treeObject.stage = [0; ones(nInitDistNonZero, 1)];
cursorOfNode = 1;
nodesAtStage = nInitDistNonZero;
% ------ construct the ancestor array for subsequent stages
for stage = 1:nBranching-1
    nodesAddedAtThisStage = 0;
    newCursorPosition = cursorOfNode + nodesAtStage;
    for iNode = 1:nodesAtStage
        nodeID = cursorOfNode + iNode;
        cover = coverOfMode(chainProbTransMatrix, treeObject.value(nodeID));
        lengthCover = numel(cover);
        treeObject.ancestor = [treeObject.ancestor;
            nodeID * ones(lengthCover, 1) ];
        treeObject.value = [treeObject.value; vec(cover)];
        nodesAddedAtThisStage = nodesAddedAtThisStage + lengthCover;
    end
    nodesAtStage = nodesAddedAtThisStage;
    cursorOfNode = newCursorPosition;
    treeObject.stage = [treeObject.stage;
        (1+stage) * ones(nodesAddedAtThisStage,1)];
end
% ------ construct the ancestor array for the nonbranching part
for stage = nBranching:nHorizon-1
    treeObject.ancestor = [treeObject.ancestor;
        (cursorOfNode+1:cursorOfNode+nodesAtStage)'];
    cursorOfNode = cursorOfNode + nodesAtStage;
    treeObject.stage = [treeObject.stage;
        (1+stage) * ones(nodesAddedAtThisStage,1)];
end
% ----- END of `createAncestorValueStage` ---------------------------------


function cover = coverOfMode(chainProbTransMatrix, i)
cover = find(chainProbTransMatrix(i,:)~=0);

function verifyInput(chainProbTransMatrix, initialDistribution)
nProbSpace = numel(initialDistribution);
verifyProbDistribution(initialDistribution);
if any(size(chainProbTransMatrix) ~= [nProbSpace nProbSpace])
    error('marietta:generateTreeFromMarkovChain:probDist', ...
        'probability transition matrix has incompatible dimensions');
end
verifyProbTransitionMatrix(chainProbTransMatrix);


function verifyProbTransitionMatrix(chainProbTransMatrix)
for i=1:size(chainProbTransMatrix, 1)
    verifyProbDistribution(chainProbTransMatrix(i, :)');
end

function verifyProbDistribution(probDist)
if any(probDist<0)
    error('marietta:generateTreeFromMarkovChain:probDist', ...
        'negative probability value');
end
if abs(sum(probDist)-1)>1e-6
    error('marietta:generateTreeFromMarkovChain:probDist', ...
        'sum of probabilities not equal to 1');
end


