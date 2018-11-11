function [constraint, numConstraints] = imposeStageRiskConstraint(obj, X, U, gt, pRisk, t)
%IMPOSESTAGERISKCONSTRAINT evaluate the given stage-wise risk constraints.  

numConstraints = 0;
tree = obj.tree; 

terminal = false; % impose terminal risk constraint.  

if t == tree.getHorizon() 
    % Terminal constraint activated -- evaluate Gt at stage N. 
    terminal = true; 
    % evaluating risk_(N-1)
    t = t-1; 
end

nb_nodes_next = tree.getNumberOfNodesAtStage(t+1);
Gt = sdpvar(nb_nodes_next, 1); 
iterNextStage = tree.getIteratorNodesAtStage(t+1); 

idx = 1; 
while iterNextStage.hasNext
    iNode = iterNextStage.next;
    ancNode = tree.getAncestorOfNode(iNode);
    if terminal
        Gt(idx) = gt.apply(X(:,iNode)); % at terminal stage 
    else
        Gt(idx) = gt.apply(X(:, ancNode), U(:, ancNode), tree.getValueOfNode(iNode));
    end
    idx = idx + 1; 
end 

probdist_next = tree.getProbabilityOfNode(tree.getNodesAtStage(t+1));
riskMeasure = pRisk(probdist_next);
dualDim = length(riskMeasure.getData().b);

yt      = sdpvar(dualDim, 1);
etaNext = sdpvar(nb_nodes_next, 1);

riskData = riskMeasure.getData(); 
constraint = [Gt <= etaNext;                                  %(23a)
              riskData.cone.imposeDualConicInequality(yt);    %(23b)
              riskData.E'*yt == etaNext;                      %(23c)
              riskData.b'*yt <= 0];                           %(23e)

numConstraints = numConstraints + nb_nodes_next + dualDim + ...
    + size(riskData.E, 2) + size(riskData.b, 2);

if isfield(riskData, 'F')
    constraint = [constraint;
                  riskData.F'*yt == 0];                        %(23d)
    numConstraints = numConstraints + size(riskData.F, 2);
end
end
