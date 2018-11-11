function [constraint, numConstraints] = imposeNestedRiskConstraint(obj, X, U, gt, pRisk, t)
%IMPOSENESTEDRISKCONSTRAINT evaluate the given nested risk constraints.  
	
numConstraints = 0; 
tree = obj.tree; 

terminal = false; 

if t == tree.getHorizon() 
    % Terminal constraint activated -- evaluate Gt at stage N. 
    terminal = true; 
    % evaluating risk_(N-1)
    t = t-1; 
end

%% Evaluate the constraint function
nb_nodes_next = tree.getNumberOfNodesAtStage(t+1); 
Gt = sdpvar(nb_nodes_next, 1); 
iterNextStage = tree.getIteratorNodesAtStage(t+1); 

idx = 1; 
while iterNextStage.hasNext
    currNode = iterNextStage.next;
    ancNode = tree.getAncestorOfNode(currNode);
    if terminal
        Gt(idx) = gt.apply(X(:,currNode)); % at terminal stage 
    else
        Gt(idx) = gt.apply(X(:, ancNode), U(:, ancNode), tree.getValueOfNode(currNode));
    end
    idx = idx + 1; 
end

%% Build decision variable 
nVars = 0; 

% Decision variables xi^i for all nodes from stage 1 to t+1 
for stage = 1:t+1
    nVars = nVars + tree.getNumberOfNodesAtStage(stage);
end 
nodeVariables = sdpvar(nVars, 1); 

%% Initialize constraint with nodes at stage t+1 

constraint = Gt <= nodeVariables(tree.getNodesAtStage(t+1)-1); % (24a)
numConstraints = numConstraints + nb_nodes_next; 

%% Nest risk measures backward until stage 0. 
for stage = t:-1:0
    
	iterNodes =  tree.getIteratorNodesAtStage(stage);
	    
	while iterNodes.hasNext
        currNode = iterNodes.next; 
	
		probdist_child = tree.getConditionalProbabilityOfChildren(currNode);
		riskMeasure = pRisk(probdist_child);
		dualDim = length(riskMeasure.getData().b);
		yt = sdpvar(dualDim, 1);
        
        childVars = nodeVariables(tree.getChildrenOfNode(currNode)-1);
        
        if (currNode == 1)  % Reached root node --> b'*y = 0
            currVar = 0; 
        else % Otherwise --> b'*y = xi^i
            currVar = nodeVariables(currNode-1);
        end 
        
		constraint = [constraint; 
                      riskMeasure.getData.cone.imposeDualConicInequality(yt);%(26a)
		    		  riskMeasure.getData().E'*yt == childVars;%(26b)
		              riskMeasure.getData().b'*yt <= currVar]; %(26d)
        
        numConstraints = numConstraints + dualDim + ...
            + size(riskMeasure.getData().E, 2) + size(riskMeasure.getData().b, 2);

		if isfield(riskMeasure.getData(), 'F')
		    constraint = [constraint;
		        riskMeasure.getData().F'*yt == 0];    %(23c)
            numConstraints = numConstraints + size(riskMeasure.getData().F, 2);
		end
	end % -- end while 
end % -- end for  
end % -- end function 