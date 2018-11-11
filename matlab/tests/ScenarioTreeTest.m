classdef ScenarioTreeTest < matlab.unittest.TestCase
    
    
    %% Test Method Block
    methods (Test)
        
        function testFromData(testCase)
            rng(1); nSamples = 1e5; nHorizon = 5;
            data = zeros(nSamples, 1, nHorizon);
            for i = 1:nSamples
                for t = 1:nHorizon
                    data(i,1,t) = t * (2*randi(2) - 3) *  (1 + 0.05*randn);
                end
            end
            
            options.ni = [2 2 2 2 2 2 2];
            tree = marietta.ScenarioTreeFactory.generateTreeFromData(data, options);
            
            % Assertions
            testCase.assertFalse(tree.isempty());
            testCase.verifyEqual(tree.getHorizon(), nHorizon);
            for stage = 0:tree.getHorizon-1
                nodesAtStage = tree.getNodesAtStage(stage);
                numNodesAtStage = tree.getNumberOfNodesAtStage(stage);
                testCase.verifyEqual(numel(nodesAtStage), numNodesAtStage);
                for i=1:numNodesAtStage
                    nodeId = nodesAtStage(i);
                    testCase.verifyTrue(tree.getNumberOfChildren(nodeId) ...
                        <= options.ni(stage+1));
                end
                probAtStage = tree.getProbabilityOfNode(nodesAtStage);
                testCase.verifyEqual(sum(probAtStage), 1, 'RelTol', 1e-4);
            end
        end % ----- END of `testFromData`
        
        
        function testFromMarkovChainBranchingHorizon(testCase)
            initialDistr = [0.3; 0.1; 0.0; 0.6];
            probTransitionMatrix = [
                0.7  0.2  0.0  0.1;
                0.25 0.6  0.05 0.1;
                0.4  0.1  0.5  0.0;
                0.0  0.0  0.3  0.7];
            ops.horizonLength = 8;
            ops.branchingHorizon = 3;
            tree = marietta.ScenarioTreeFactory.generateTreeFromMarkovChain(...
                probTransitionMatrix, initialDistr, ops);
            
            % Assertions
            testCase.assertFalse(tree.isempty());
            testCase.verifyEqual(tree.getValueDimension(), 1);
            
            testCase.verifyEqual(tree.getNumberOfScenarios(), 26);
            testCase.verifyEqual(tree.getNumberOfNodes(), 169);
            testCase.verifyEqual(tree.getHorizon(), ops.horizonLength);
            
            for stage = ops.branchingHorizon:ops.horizonLength-1
                nodesAtStage = tree.getNodesAtStage(stage);
                for i = 1:tree.getNumberOfNodesAtStage(stage)
                    nodeId = nodesAtStage(i);
                    testCase.verifyEqual(tree.getNumberOfChildren(nodeId), 1);
                end
                probAtStage = tree.getProbabilityOfNode(nodesAtStage);
                testCase.verifyEqual(sum(probAtStage), 1, 'RelTol', 1e-4);
            end
            
            ops2.horizonLength = 3;
            ops2.branchingHorizon = 3;
            tree2 = marietta.ScenarioTreeFactory.generateTreeFromMarkovChain(...
                probTransitionMatrix, initialDistr, ops2);
            
            numNodes2 = tree2.getNumberOfNodes();
            ancestors = tree.getAncestors();
            testCase.verifyEqual(ancestors(1:numNodes2), tree2.getAncestors());
            
        end % ----- END of `testFromMarkovChainBranchingHorizon`
        
        
        function testFromMarkovChain(testCase)
            initialDistr = [0.3; 0.0; 0.0; 0.7];
            probTransitionMatrix = [
                0.7  0.2  0.0  0.1;
                0.25 0.6  0.05 0.1;
                0.4  0.1  0.5  0.0;
                0.0  0.0  0.3  0.7];
            ops.horizonLength = 4;
            tree = marietta.ScenarioTreeFactory.generateTreeFromMarkovChain(...
                probTransitionMatrix, initialDistr, ops);
            
            % Assertions
            testCase.assertFalse(tree.isempty());
            testCase.verifyEqual(tree.getValueDimension, 1);
            testCase.verifyEqual(tree.getSiblingsOfNode(1), 1);
            
            testCase.verifyEqual(tree.getNumberOfNodes(), 63);
            testCase.verifyEqual(tree.getNumberOfScenarios(), 41);
            testCase.verifyEqual(tree.getHorizon(), ops.horizonLength);
            testCase.verifyEqual(tree.getProbabilityOfNode(1), 1);
            
            % Stage #1: verify probability distribution
            nodesAtFirstStage = tree.getNodesAtStage(1);
            for i = 1:numel(nodesAtFirstStage)
                nodeId = nodesAtFirstStage(i);
                valueOfNode = tree.getValueOfNode(nodeId);
                testCase.verifyEqual(initialDistr(valueOfNode), ...
                    tree.getProbabilityOfNode(nodeId));
            end
            
            % Stage #k (k=2..N): verify probability distribution
            for stage = 2:tree.getHorizon()
                nodesAtThisStage = tree.getNodesAtStage(stage);
                % iterate over all nodes at this stage
                for i=1:tree.getNumberOfNodesAtStage(stage)
                    node = nodesAtThisStage(i);
                    currentNode = node;
                    probNode = 1;
                    for j = 1:stage-1
                        ancNode = tree.getAncestorOfNode(currentNode);
                        currentValue = tree.getValueOfNode(currentNode);
                        ancValue = tree.getValueOfNode(ancNode);
                        transProb = probTransitionMatrix(ancValue, currentValue);
                        probNode = probNode * transProb;
                        currentNode = ancNode;
                    end
                    probNode = probNode * initialDistr(ancValue);
                    testCase.verifyEqual(probNode, tree.getProbabilityOfNode(node), ...
                        'RelTol', 1e-6);
                end
            end
            
            % verify that the sum of all probabilities at every stage are
            % equal to 1
            for stage = 0:ops.horizonLength
                probAtStage = tree.getProbabilityOfNode(tree.getNodesAtStage(stage));
                testCase.verifyEqual(sum(probAtStage), 1, 'RelTol', 1e-8);
            end
            
            % verify that the conditional probability vectors at all
            % nonleaf nodes are equal to the conditional probability
            % vectors induced by the prob. transition matrix
            for stage = 1:ops.horizonLength-1
                nodesAtStage = tree.getNodesAtStage(stage);
                for i = 1:tree.getNumberOfNodesAtStage(stage)
                    node = nodesAtStage(i);
                    condProb = tree.getConditionalProbabilityOfChildren(node);
                    markovCondProb = probTransitionMatrix(tree.getValueOfNode(node), :)';
                    markovCondProb = vec(markovCondProb(markovCondProb~=0));
                    testCase.verifyEqual(condProb, markovCondProb, 'RelTol', 1e-6);
                end
            end
            
        end % ----- END of `testFromMarkovChain`
        
        function testFromIid(testCase)
            probDist = [0.6 0.4];
            ops = struct('horizonLength', 15, 'branchingHorizon', 4);
            tree = marietta.ScenarioTreeFactory.generateTreeFromIid(probDist, ops);
            
            % Assertions
            testCase.assertFalse(tree.isempty());
            testCase.verifyEqual(tree.getNumberOfScenarios, ...
                numel(probDist)^ops.branchingHorizon);
            testCase.verifyEqual(tree.getNumberOfNodes, 207);
            testCase.verifyEqual(tree.getSiblingsOfNode(1), 1);
            % test that the children and ancestors of the tree are properly
            % defined
            for nodeId = 2:tree.getNumberOfNodes
                sibl = tree.getSiblingsOfNode(nodeId);
                isLeafNode = (tree.getStageOfNode(nodeId) == ops.horizonLength);
                if isLeafNode
                    testCase.verifyEqual(numel(sibl), 1);
                else
                    children = tree.getChildrenOfNode(nodeId);
                    for childId = 1:numel(children)
                        ch = children(childId);
                        testCase.verifyEqual(tree.getAncestorOfNode(ch), nodeId);
                    end
                end
                testCase.verifyEqual(sum(sibl == nodeId), 1);
            end
            testCase.verifyEqual(tree.getHorizon(), ops.horizonLength);
            for stage=0:ops.branchingHorizon-1
                testCase.verifyEqual(tree.getNumberOfNodesAtStage(stage), ...
                    numel(probDist)^stage);
            end
            for stage = ops.branchingHorizon:ops.horizonLength
                testCase.verifyEqual(tree.getNumberOfNodesAtStage(stage), ...
                    numel(probDist)^ops.branchingHorizon);
            end
            testCase.verifyEqual(tree.getChildrenOfNode(1), [2;3]);
            for stage = ops.branchingHorizon:ops.horizonLength
                probAtStage = tree.getProbabilityOfNode(...
                    tree.getNodesAtStage(stage));
                testCase.verifyEqual(sum(probAtStage), 1, 'RelTol', 1e-4);
            end
            nScenarios = tree.getNumberOfScenarios;
            for iScen = 1:nScenarios
                scenario = tree.getScenarioWithID(iScen);
                testCase.verifyEqual(numel(scenario), ops.horizonLength+1);
                for stage = ops.horizonLength+1:-1:2
                    testCase.verifyEqual(...
                        tree.getAncestorOfNode(scenario(stage)), ...
                        scenario(stage-1));
                end
                for stage = 1:ops.horizonLength
                    children = tree.getChildrenOfNode(scenario(stage));
                    testCase.verifyTrue(...
                        sum(children == scenario(stage+1)) == 1, true);
                end
                
            end
        end % ---- END of `testFromIid`
        
    end
end