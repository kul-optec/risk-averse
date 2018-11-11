classdef RiskConstraintTest < matlab.unittest.TestCase
    %RISKCONSTRAINTTEST Abstract class for unit tests on risk constraints  
    %
    %properties:
    %
    % scenarioTree (marietta.ScenarioTree): scenario tree associated with
    %                                      the current test case.
    % constrRisk(@(p)marietta.ConicRiskFactory.createAvar(vec(p),alpha)):
    %                                      risk measure used in the nested 
    %                                      risk constraints.
    % solution (marietta.Solution): the solution of the OC in the test case.
    % normLim (double): upper bound of the normRiskConstraints. 
    
    properties
        scenarioTree;
        constrRisk;
        solution;
        normLim;
    end
    
    methods   
%         function clear(obj)
%             obj.scenarioTree = [];
%             obj.constrRisk = [];
%             obj.solution = [];
%             obj.normLim = [];
%         end
%         
        function rao = setupBasicController(testCase, alpha, N, branching_horizon,...
                umin, umax)
                                   
            num_modes = 5;                  % number of modes of Markov chain
            lambda_poisson = 2;             % Poisson parameter
                                   
            QN = 70*eye(2);                 % terminal cost
            zeros_trans_matr_per_line = 3;  % Number of zeros in P (Markov trans. mat.)
            
            [tree, dynamics, stageCost] = exampleConstructor(num_modes, lambda_poisson, ...
                zeros_trans_matr_per_line, N, branching_horizon);
            
            testCase.scenarioTree = tree;
            % Terminal cost function...
            terminalCost = marietta.functions.QuadTerminalFunction(QN);
            
            %% Define the risk-averse optimal control problem
            pAvar = marietta.ParametricRiskFactory.createParametricAvarAlpha(alpha);
            rao = marietta.RiskAverseOptimalController();
            
            rao.setInputBounds(umin,umax)...
                .setScenarioTree(tree)...
                .setDynamics(dynamics)...
                .setStageCost(stageCost)...
                .setParametricRiskCost(pAvar)...
                .setTerminalCost(terminalCost);
        end
        
        function x0 = generate_safe_x0(obj, controller, c)
            
            umin = controller.umin; umax = controller.umax; 
            
            nx = controller.dynamics.getStateDimension();
            nu = controller.dynamics.getInputDimension();
            X = sdpvar(nx, controller.tree.getNumberOfNodes);
            U = sdpvar(nu, controller.tree.getNumberOfNonleafNodes);
            constraints = [];
            
            x_init = sdpvar(nx, 1);
            c_var = sdpvar(nx, 1); 
            %Impose system dynamics
            constraints = [constraints;
                X(:, 1) == x_init];
            
            % STEP 4D -- Impose system dynamics
            for i=2:controller.tree.getNumberOfNodes() % traverse all but the root
                ancNode = controller.tree.getAncestorOfNode(i);
                constraints = [constraints;
                    X(:, i) == controller.dynamics.apply(X(:, ancNode), U(:, ancNode), controller.tree.getValueOfNode(i))];
            end
            
            % STEP 4E -- Impose stage-wise risk constraints
            for i = 1:numel(controller.stageWiseRiskConstraints)
                riskConstraint = controller.stageWiseRiskConstraints(i);
                for t = riskConstraint.stages
                    [stageRiskConstraint, ~] = ...
                        controller.imposeStageRiskConstraint(X, U, riskConstraint.constraintFcn, riskConstraint.pRisk, t);
                    constraints = [constraints; stageRiskConstraint];
                end
            end
            
            % STEP 4F -- Impose nested risk constraints
            for i = 1:numel(controller.nestedRiskConstraints)
                riskConstraint = controller.nestedRiskConstraints(i);
                for t = riskConstraint.stages
                    [nestedRiskConstraint, ~] = ...
                        controller.imposeNestedRiskConstraint(X, U, riskConstraint.constraintFcn, riskConstraint.pRisk, t);
                    constraints = [constraints; nestedRiskConstraint];
                end
            end
            
            % STEP 5 - Impose additional constraints on U
            if ~isempty(umin)
                constraints = [constraints; U >= umin];
            end
            
            if ~isempty(umax)
                constraints = [constraints; U <= umax];
            end
            
            % Solve
            ops = sdpsettings;
            ops.solver = controller.solver;
            J = c_var'*x_init;   % cost
            opt = optimizer(constraints, J,ops, {c_var}, {X, J});
            out = opt(c);
            X = out{1};
            x0 = X(:,1);
        end
    end
end

