classdef NestedRiskTest < RiskConstraintTest
%     NESTEDRISKTEST unit tests for nested risk constraints
%     see also RiskConstraintTest

    % Test Method Block
    methods (Test)
           
        function testTerminalNestedRisk(testCase)
            alpha = 0.7;                    % alpha cost
            alpha_risk = 0.0;
            horizon_length = 5;             % prediction horizon
            branching_horizon = 5;          % branching horizon
            umin = -5; umax = 5;          % input bounds
            stages = horizon_length;    % stages to impose the risk constraints
            testCase.normLim = 0.7;         % Upper bound of the norm
            testCase.constrRisk = marietta.ParametricRiskFactory.createParametricAvarAlpha(alpha_risk);
            
            rao = testCase.setupBasicController(alpha, horizon_length, ...
                branching_horizon, umin, umax);
                                  
            StateNorm = marietta.functions.QuadTerminalFunction(eye(2));
            normConstraint = StateNorm - testCase.normLim;
            rao.addNestedRiskConstraints(normConstraint, testCase.constrRisk, stages);
            rao.makeController();
            
            x0 = testCase.generate_safe_x0(rao, [-1;-1]);
            testCase.solution = rao.control(x0);
            testCase.checkSolution(stages);
        end
        
        function testRobustNestedRisk(testCase)
            alpha = 0.7;                    % alpha cost
            alpha_risk = 0.0; 
            horizon_length = 3;             % prediction horizon
            branching_horizon = 5;          % branching horizon
            umin = -5; umax = 5;          % input bounds
            stages = horizon_length-1;    % stages to impose the risk constraints
            testCase.normLim = 0.7;         % Upper bound of the norm
            testCase.constrRisk = marietta.ParametricRiskFactory.createParametricAvarAlpha(alpha_risk);
            
            rao = testCase.setupController(alpha, horizon_length, ...
                                  branching_horizon, stages, umin, umax);
            
            x0 = testCase.generate_safe_x0(rao, [-1;-1]);
            testCase.solution = rao.control(x0);
            testCase.checkSolution(stages);
        end
        
        function testNestedRisk(testCase)
            alpha = 0.7;                    % alpha cost
            alpha_risk = 0.5;
            horizon_length = 5;             % prediction horizon
            branching_horizon = 5;          % branching horizon
            umin = -5; umax = 5;          % input bounds
            stages = horizon_length-1;    % stages to impose the risk constraints
            testCase.normLim = 0.7;         % Upper bound of the norm
            testCase.constrRisk = marietta.ParametricRiskFactory.createParametricAvarAlpha(alpha_risk);
            
            rao = testCase.setupController(alpha, horizon_length, ...
                                  branching_horizon, stages, umin, umax);
            
            x0 = testCase.generate_safe_x0(rao, [-1;-1]);
            testCase.solution = rao.control(x0);
            testCase.checkSolution(stages);
            
        end
        
    end
    
    methods (Access = private)
                
        function rao = setupController(testCase, alpha, N, ...
                branching_horizon, stages, umin, umax)
            
            rao = testCase.setupBasicController(alpha, N, ...
                branching_horizon, umin, umax);
            
            StateNorm = marietta.functions.SimpleQuadStateInputFunction(eye(2),0);
            normConstraint = StateNorm - testCase.normLim;
            rao.addNestedRiskConstraints(normConstraint, testCase.constrRisk, stages);
            rao.makeController();
        end
        
        function checkSolution(testCase, stages)
            import matlab.unittest.constraints.IsTrue;
            
            diagnose='Optimizer failed to find a feasible solution.';
            testCase.verifyEqual(testCase.solution.getStatusCode(), 0, diagnose);
            constraintViolationTol = 1e-6;
            for stage = stages                   
                nestedRisk = testCase.evaluateNestedRisk(stage, ...
                                       @(X) colVecNorm(X)^2-testCase.normLim);
                diagnose = sprintf('Risk constraint violated at stage %i. \n r(||x||^2-c) = %1.2e > %1.2e', ...
                stage, nestedRisk, constraintViolationTol);
                testCase.verifyThat(nestedRisk<=constraintViolationTol, IsTrue, diagnose);
            end
        end
        
        function nestedRisks = evaluateNestedRisk(obj, stage, constr)
            % Recursively evaluate the conditional risks from `stage` to 0. 
            tree = obj.scenarioTree; 
            pRisk = obj.constrRisk;
            sol = obj.solution;
            
            riskField = 'riskField';
            
            terminal = false; 
            if stage == tree.getHorizon()
                terminal = true; 
                stage = stage - 1; 
            end 
            nodesIter = tree.getIteratorNodesAtStage(stage);
            while nodesIter.hasNext()
                currNode = nodesIter.next; 
                childIter = tree.getIteratorChildrenOfNode(currNode); 
                Z = zeros(tree.getNumberOfChildren(currNode),1);
                childIdx = 1; 
                while childIter.hasNext()
                    currChild = childIter.next; 
                    if exist('constr', 'var')
                        solutionState = sol.getStates();
                        if terminal
                            Z(childIdx) = constr(solutionState(:, currChild));
                        else 
                            Z(childIdx) = constr(solutionState(:, currNode));
                        end
                    else
                        Z(childIdx) = tree.getDataAtNode(currChild).(riskField);
                    end
                    childIdx = childIdx + 1; 
                end
                distribution = tree.getConditionalProbabilityOfChildren(currNode);
                riskMeasure = pRisk(distribution);
                tree.setDataField(currNode, riskField, riskMeasure.risk(Z));
            end
            if stage > 0 
                nestedRisks = obj.evaluateNestedRisk(stage-1);
            else
                nestedRisks = tree.getDataAtNode(currNode).(riskField);
            end 
        end 
    end
end