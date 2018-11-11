
classdef StageWiseRiskTest < RiskConstraintTest
    %STAGEWISERISKTEST unit tests for stage-wise risk constraints
    %see also:
    %   RiskConstraintTest, NestedRiskTest

    %% Test Method Block
    methods (Test)
        function testEvarStageConstraints(testCase)
            alpha = 0.5;                    % alpha cost
            alpha_risk = 0.5; 
            horizon_length = 2;             % prediction horizon
            branching_horizon = 3;          % branching horizon
            umin = -10; umax = 10;          % input bounds
            stages = 2:horizon_length-1;    % stages to impose the risk constraints
            testCase.normLim = 0.7;         % Upper bound of the norm
            testCase.constrRisk = marietta.ParametricRiskFactory.createParametricEvarAlpha(alpha_risk);
            
            rao = testCase.setupController(alpha, horizon_length, ...
                                  branching_horizon, stages, umin, umax);
            
            x0 = [0.8;0.5];
            testCase.solution = rao.control(x0);
            testCase.checkSolution(stages);
        end
        
        function testTerminalRisk(testCase)
            alpha = 0.5;                    % alpha
            alpha_risk = 0.;
            horizon_length = 6;             % prediction horizon
            branching_horizon = 3;          % branching horizon
            umin = -10; umax = 10;          % input bounds
            stages = horizon_length;      % stages to impose the risk constraints
            testCase.normLim = 0.1;         % Upper bound of the norm
            testCase.constrRisk = marietta.ParametricRiskFactory.createParametricAvarAlpha(alpha_risk);
                           
            rao = testCase.setupBasicController(alpha, horizon_length, ...
                                             branching_horizon, umin, umax);
            
            stateNorm = marietta.functions.QuadTerminalFunction(eye(2));
            normConstraint = stateNorm-testCase.normLim;
            rao.addStageWiseRiskConstraints(normConstraint, testCase.constrRisk, stages);            
            rao.makeController();
            x0 = testCase.generate_safe_x0(rao, [-1;-1]);            
            testCase.solution = rao.control(x0);
            
%             figure(1);
%             subplot(211); testCase.solution.plotStateCoordinate(1);
%             subplot(212); testCase.solution.plotStateCoordinate(2);
%             
%             figure(2);
%             testCase.solution.plotFunctionErrorBar(normConstraint, alpha_risk, testCase.scenarioTree.getHorizon);
%             ylabel('constraint function');
%             legend('Expected', [num2str(100*(1-alpha_risk)) '-percentile'], 'Worst case');
%                                    
            testCase.checkSolution(stages);
        end
%         
        function testRobustRisk(testCase)
            alpha = 0.5;                    % alpha
            alpha_risk = 0.0; 
            horizon_length = 6;            % prediction horizon
            branching_horizon = 3;          % branching horizon
            umin = -10; umax = 10;          % input bounds
            stages = 1:horizon_length-1;    % stages to impose the risk constraints
            testCase.normLim = 0.5;         % Upper bound of the norm
            testCase.constrRisk = marietta.ParametricRiskFactory.createParametricAvarAlpha(alpha_risk);
            
            rao = testCase.setupController(alpha, horizon_length, ...
                                  branching_horizon, stages, umin, umax);
            
            x0 = testCase.generate_safe_x0(rao, [-1;-1]);            
            testCase.solution = rao.control(x0);
            testCase.checkSolution(stages);
        end
%         
        function testStageRisk(testCase)
            alpha = 0.7;                    % alpha
            alpha_risk = 0.5; 
            horizon_length = 6;            % prediction horizon
            branching_horizon = 3;          % branching horizon
            umin = -10; umax = 10;          % input bounds
            stages = 1:horizon_length-1;    % stages to impose the risk constraints
            testCase.normLim = 0.4;         % Upper bound of the norm
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
            
            stageStateNorm = marietta.functions.SimpleQuadStateInputFunction(eye(2),0);
            stageConstraint = stageStateNorm - testCase.normLim;
            rao.addStageWiseRiskConstraints(stageConstraint, testCase.constrRisk, stages);
            rao.makeController();
        end
        
        
        function checkSolution(testCase, stages)
            import matlab.unittest.constraints.IsTrue;
            
            diagnose='Optimizer failed to find a feasible solution.';
            testCase.verifyEqual(testCase.solution.getStatusCode(), 0, diagnose);
            constraintViolationTol = 1e-5;
            
            for stage = stages
                if stage == testCase.scenarioTree.getHorizon() 
                    nextNodes = testCase.scenarioTree.getNodesAtStage(stage);
                    ancestors = nextNodes; 
                else 
                    nextNodes = testCase.scenarioTree.getNodesAtStage(stage+1);
                    ancestors = testCase.scenarioTree.getAncestorOfNode(nextNodes);
                end
                probDist = testCase.scenarioTree.getProbabilityOfNode(nextNodes);
                solutionState = testCase.solution.getStates();
                norms = colVecNorm(solutionState(:,ancestors)).^2;
                riskMeasure = testCase.constrRisk(probDist);
                risk=riskMeasure.risk(norms-testCase.normLim);
                diagnose = sprintf('Risk constraint violated at stage %i. \n r(||x||^2-c) = %1.2e > %1.2e', ...
                stage, risk, constraintViolationTol);
                testCase.verifyThat(risk<=constraintViolationTol, IsTrue, diagnose);
            end
        end
    end
end