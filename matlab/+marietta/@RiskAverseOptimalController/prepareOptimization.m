function [ constraints, optimalCost, U, X, stats ] = prepareOptimization( obj )
%PREPAREOPTIMIZATION Summary of this function goes here
%   Detailed explanation goes here

tree = obj.tree;
parametricRisk = obj.parametricRiskCost;
umin = obj.umin;
umax = obj.umax;
stageWiseRiskConstraints = obj.stageWiseRiskConstraints;
nestedRiskConstraints = obj.nestedRiskConstraints;

% STEP 1 -- Construct all risks rho^i (at all non-leaf nodes)
risk_cache = repmat(parametricRisk(1), tree.getNumberOfNonleafNodes, 1);
dual_dim = zeros(tree.getNumberOfNonleafNodes, 1);
iterNonLeaf = tree.getIteratorNonleafNodes();
while iterNonLeaf.hasNext()
    nodeId = iterNonLeaf.next();
    pi = tree.getConditionalProbabilityOfChildren(nodeId);
    risk = parametricRisk(pi);
    risk.compress;   % (optional step)
    risk_cache(nodeId) = risk;
    dual_dim(nodeId) = length(risk.getData.b);
end

% STEP 2 -- index of vector Y
dual_dim_cumsum = cumsum(dual_dim);
idx_dual_vector = [1; 1+dual_dim_cumsum(1:end)];

% STEP 3 -- Define decision variables (YALMIP)
nx = obj.dynamics.getStateDimension();
nu = obj.dynamics.getInputDimension();
Y = sdpvar(sum(dual_dim), 1);
S = sdpvar(tree.getNumberOfNodes, 1);
T = sdpvar(tree.getNumberOfNodes, 1);
X = sdpvar(nx, tree.getNumberOfNodes);
U = sdpvar(nu, tree.getNumberOfNonleafNodes);
stats.decisionVariableDimension = numel(Y) + numel(S) + numel(T) + numel(X) ...
    + numel(U);


% ------------- PROBLEM CONSTRUCTION --------------------------------------

constraints = [];  % constraints of the problem
numConstraints = 0;

%Step 4(A-B) Impose constraint at stages t=0, N-1
iterNonLeaf.restart();
while iterNonLeaf.hasNext()
    nodeId = iterNonLeaf.next();
    riskDataNodeId = risk_cache(nodeId).getData;
    childNodeId = tree.getChildrenOfNode(nodeId);
    idx_range = idx_dual_vector(nodeId):idx_dual_vector(nodeId+1)-1;
    numChildren = tree.getNumberOfChildren(nodeId);
    constraints = [constraints;
        riskDataNodeId.cone.imposeDualConicInequality(Y(idx_range));
        riskDataNodeId.E' * Y(idx_range) == T(childNodeId) + S(childNodeId);
        riskDataNodeId.b' *  Y(idx_range) <= S(nodeId)];
    numConstraints = numConstraints + numel(idx_range) + numChildren + 1;
    if isfield(riskDataNodeId, 'F')
        constraints = [constraints;
            riskDataNodeId.F' * Y(idx_range) == 0];
        numConstraints = numConstraints + numChildren;
    end
end


% STEP 4C -- Impose constraints Z <= S
% (1) Stage N: Z_N <= S_N
nodesAtStageN = tree.getNodesAtStage(tree.getHorizon);
if ~isempty(obj.terminalCost)
    for i = 1:numel(nodesAtStageN)
        nodeId = nodesAtStageN(i);
        constraints = [constraints;
            obj.terminalCost.apply(X(:, nodeId)) <= S(nodeId)];
        numConstraints = numConstraints + 1;
    end
end


% (2) Stage t=0..N-1: Z_t <= tau_t+1
iterNonLeaf.restart();
while iterNonLeaf.hasNext()
    nodeId = iterNonLeaf.next();
    childNodeId = tree.getChildrenOfNode(nodeId);
    for j = 1:numel(childNodeId)
        i_plus = childNodeId(j);
        w_plus = tree.getValueOfNode(i_plus);
        constraints = [constraints;
            obj.stageCost.apply(X(:, nodeId), U(:, nodeId), w_plus) <= T(childNodeId)];
        numConstraints = numConstraints + 1;
    end
end


% STEP 4D -- Impose system dynamics
for i=2:tree.getNumberOfNodes() % traverse all but the root
    ancNode = tree.getAncestorOfNode(i);
    constraints = [constraints;
        X(:, i) == obj.dynamics.apply(X(:, ancNode), U(:, ancNode), tree.getValueOfNode(i))];
    numConstraints = numConstraints + nx;
end

% STEP 4E -- Impose stage-wise risk constraints
for i = 1:numel(stageWiseRiskConstraints)
    riskConstraint = stageWiseRiskConstraints(i);
    for t = riskConstraint.stages
        [stageRiskConstraint, numStageRiskConstraints] = ...
            obj.imposeStageRiskConstraint(X, U, riskConstraint.constraintFcn, riskConstraint.pRisk, t);
        constraints = [constraints; stageRiskConstraint];
        numConstraints = numConstraints + numStageRiskConstraints;
    end
end

% STEP 4F -- Impose nested risk constraints
for i = 1:numel(nestedRiskConstraints)
    riskConstraint = nestedRiskConstraints(i);
    for t = riskConstraint.stages
        [nestedRiskConstraint, numNestedRiskConstraints] = ...
            obj.imposeNestedRiskConstraint(X, U, riskConstraint.constraintFcn, riskConstraint.pRisk, t);
        constraints = [constraints; nestedRiskConstraint];
        numConstraints = numConstraints + numNestedRiskConstraints;
    end
end

% STEP 5 - Impose additional constraints on U
if ~isempty(umin)
    constraints = [constraints; U >= umin];
    numConstraints = numConstraints + numel(U);
end

if ~isempty(umax)
    constraints = [constraints; U <= umax];
    numConstraints = numConstraints + numel(U);
end

if ~isempty(obj.xmin)
    constraints = [constraints; X >= obj.xmin];
    numConstraints = numConstraints + numel(X);
end

if ~isempty(obj.xmax)
    constraints = [constraints; X <= obj.xmax];
    numConstraints = numConstraints + numel(X);
end


if ~isempty(obj.Fx) && ~isempty(obj.Fu)
    nFx = size(obj.Fx, 1);
    iterNonLeaf.restart();
    while iterNonLeaf.hasNext()
        nodeId = iterNonLeaf.next();
        if ~isempty(obj.fmax)
            constraints = [constraints;
                obj.Fx * X(:, nodeId) + obj.Fu * U(:, nodeId) <= obj.fmax];
            numConstraints = numConstraints + nFx;
        end
        if ~isempty(obj.fmin)
            constraints = [constraints;
                obj.Fx * X(:, nodeId) + obj.Fu * U(:, nodeId) >= obj.fmin];
            numConstraints = numConstraints + nFx;
        end
    end
end

optimalCost = S(1);   % cost
stats.numConstraints = numConstraints;
end
