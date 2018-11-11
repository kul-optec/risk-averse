classdef RiskAverseOptimalController < matlab.mixin.Copyable
    %RISKAVERSEOPTIMALCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        parametricRiskCost;     % parametric risk used in the cost
        umin;                   % umin
        umax;                   % umax
        tree;                   % scenario tree
        controller;             % optimizer object of YALMIP
        
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        % The following fields are structure arrays with fields:
        %  - constraintFcn ..... constraint funct. (inst. of StageFunction
        %                        or TerminalFunction)
        %  - pRisk ............. a parametric risk function
        %  - stages ............ array of stages where the constraint is
        %                        imposed
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        stageWiseRiskConstraints; % stage-wise risk constraints
        nestedRiskConstraints;    % nested multistage risk constraints
        
        stats; % statistics (# decision variables and constraints)
        
        dynamics;     % system dynamics (marietta.functions.StageFunction)
        stageCost;    % stage cost function (StageFunction)
        terminalCost; % terminal cost function
        
        solver = 'mosek'; % solver
        constraints_var;  % constraints (YALMIP variable)
        optimalCost_var;  % optimal cost (YALMIP variable)
        X_var;            % state sequence (YALMIP variable)
        U_var;            % input sequence (YALMIP variable)
    end
    
    methods (Access = {?RiskConstraintTest})
        [constr, numConstr] = imposeStageRiskConstraint(obj, X, U, gt, pRisk, t);
        [constr, numConstr] = imposeNestedRiskConstraints(obj, X, U, gt, pRisk, t);
    end
    
    methods (Access = private)
        
        out = makeRAController(obj)
        [ F, J, U, X, stats ] = prepareOptimization(obj)
        [X, U, J, diagnostic] = solveNoOptimizer(obj, x)
        
        
        function constraint = makeConstrainStruct(~, constraint, ...
                pRisk, stages)
            constraint = struct('constraintFcn', constraint, ...
                'pRisk', pRisk, ...
                'stages', stages);
        end
        
        function verifyStagesConstraints(obj, stages, constraint)
            %VERIFYSTAGESCONSTRAINTS verify that the given constraint is
            %suitable for the given stages
            %
            %A marietta.functions.StageFunction can only be used as a
            %stage constraint (0 <= stage < N) and a 
            %marietta.functions.Terminal function can only be used as a 
            %constraint at stage = N. 
            
            if all(stages <= obj.tree.getHorizon()-1) && all(stages >= 0)
                if ~isa(constraint, 'marietta.functions.StageFunction')
                    error('marietta:TypeError', 'stage in [0,N-1] & stage cost function not a marietta.functions.StageFunction');
                end
            elseif length(stages)==1 && stages==obj.tree.getHorizon()
                if ~isa(constraint, 'marietta.functions.TerminalFunction')
                error('marietta:TypeError', 'stage = N & stage cost function not a marietta.functions.TerminalFunction');
                end
            else
                error('marietta:TypeError', 'stage out of bounds');
            end
        end
    end
    
    methods (Access = public)
        
        function obj = RiskAverseOptimalController()
            obj.stageWiseRiskConstraints = [];
            obj.nestedRiskConstraints = [];
            obj.stats.decisionVariableDimension = 0;
            obj.stats.numConstraints = 0;
        end
        
        makeController(obj);
        
        function obj = setInputBounds(obj,umin, umax)
            obj.umin = umin;
            obj.umax = umax;
        end
        
        function obj = setScenarioTree(obj,tree)
            if ~isa(tree, 'marietta.ScenarioTree')
                error('marietta:TypeError', 'Not a marietta.ScenarioTree');
            end
            obj.tree = tree;
        end
        
        function obj = setParametricRiskCost(obj, paramRisk)
            obj.parametricRiskCost = paramRisk;
        end
        
        function obj = setTerminalCost(obj, terminalCostFunction)
            if ~isa(terminalCostFunction, 'marietta.functions.TerminalFunction')
                error('marietta:TypeError', 'Not a marietta.functions.TerminalFunction');
            end
            obj.terminalCost = terminalCostFunction;
        end
        
        function obj = setDynamics(obj, dynamicsFunction)
            if ~isa(dynamicsFunction, 'marietta.functions.StageFunction')
                error('marietta:TypeError', 'Not a marietta.functions.StageFunction');
            end
            obj.dynamics = dynamicsFunction;
        end
        
        function obj = setStageCost(obj, stageCostFunction)
            if ~isa(stageCostFunction, 'marietta.functions.StageFunction')
                error('marietta:TypeError', 'Not a marietta.functions.StageFunction');
            end
            obj.stageCost = stageCostFunction;
        end
        
        function solution = control(obj, x)
            if ~isempty(obj.controller)
                % Use cached controller (created by makeController)
                ctrl = obj.controller;
                [out, status_code, status_message] = ctrl(x);
                U = out{1}; X = out{2}; J = out{3};
            else
                % In case makeController has not been invoked, or if it has
                % failed to create an optimizer object...
                [X, U, J, diagnostic] = obj.solveNoOptimizer(x);
                status_code = diagnostic.problem;
                status_message = diagnostic.info;
            end
            % Return the results as a `Solution` object
            solution = marietta.Solution(obj, X, U, J, status_code, status_message);
        end
        
        function obj = addStageWiseRiskConstraints(obj, constraint, ...
                pRisk, stages)
            obj.verifyStagesConstraints(stages, constraint);
            if ~isempty(stages)
                obj.stageWiseRiskConstraints=[obj.stageWiseRiskConstraints;
                    obj.makeConstrainStruct( ...
                    constraint, pRisk, stages)];
            end
        end
        
        function obj = addNestedRiskConstraints(obj, constraint, ...
                pRisk, stages)
            obj.verifyStagesConstraints(stages, constraint);
            if ~isempty(stages) 
                obj.nestedRiskConstraints = [obj.nestedRiskConstraints;
                    obj.makeConstrainStruct( ...
                    constraint, pRisk, stages)];
            end
        end
        
        function disp(obj)
            fprintf('-------------------------------------\n')
            fprintf('Risk-averse Optimal Controller\n')
            fprintf('-------------------------------------\n')
            if (obj.stats.decisionVariableDimension == 0)
                fprintf('Empty object!\n');
            else
                fprintf('Numer of decision variables : %7d\n', obj.stats.decisionVariableDimension);
                fprintf('Number of constraints       : %7d\n', obj.stats.numConstraints);
            end
            
        end
    end
    
end

