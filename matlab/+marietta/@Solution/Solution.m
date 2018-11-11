classdef Solution < handle
    %SOLUTION Solution of a scenario-based risk-averse optimal control
    %problem
    %
    
    properties (Access = private)
        rao;          % risk averse optimal control object
        X;            % state sequence/process
        U;            % input sequence/process
        J;            % optimal cost
        QN;           % terminal cost matrix
        status_code;  % status code
        status_msg;   % status message
        
        plotOpts;     % default plot options
    end
    
    methods (Access = private)
        plotOnTree(obj, z, plot_spec);
        
        function errorBarPlot(obj, plotData) 
            opts = obj.plotOpts;
            plot(plotData.n:plotData.N, plotData.average, opts);
            opts.color = [0.5, 0.5, 0.5];
            opts.linestyle = '--'; opts.linewidth = 1; 
            hold on;
            plot(plotData.n:plotData.N, plotData.quantile, opts);
            %                 errorbar(n:N, average, zeros(numElements,1), ...
            %                     quantile - average, '-kx');
            opts.color = [0.7, 0.1, 0.15];
            plot(plotData.n:plotData.N, plotData.max, opts);
            
            xlim([plotData.n-1, plotData.N+1]);
%             ylim([0, 1.1*max(plotData.max)]);
            xlabel('stage k'); 
            grid on;
        end 
    end
    
    methods
        function obj = Solution(rao, X, U, J, status_code, status_msg)
            if nargin == 0, return; end
            obj.rao = rao;
            obj.X = X;
            obj.U = U;
            obj.J = J;
            obj.status_code = status_code;
            obj.status_msg = status_msg;
            obj.plotOpts = struct('color', 'k', ... 
                                  'linewidth', 2, ...
                                  'linestyle', '-', ... 
                                  'marker', '.', ... 
                                  'markersize', 15);
        end
        
        function status_code = getStatusCode(obj)
            %GETSTATUSCODE returns the status code of the solution. The
            %status code 0 corresponds to a feasible solution. See the
            %status message for more information.
            %
            %See also
            %getStatusMessage
            %
            status_code = obj.status_code;
        end
        
        function status_msg = getStatusMessage(obj)
            %GETSTATUSMESSAGE returns a message which explains the status
            %code.
            %
            %See also
            %getStatusCode
            %
            status_msg = obj.status_msg;
        end
        
        function plotStateCoordinate(obj, iState)
            %PLOTSTATECOORDINATE plots the i-th coordinate of the system
            %state on the scenario tree.
            %
            %Example:
            % figure(1);
            % subplot(211); solution.plotStateCoordinate(1);
            % subplot(212); solution.plotStateCoordinate(2);
            %
            %See also
            %plotInputCoordinate
            %
            obj.plotOnTree(obj.X(iState,:));
            xlabel('stage k');
            ylabel(['x_' num2str(iState) '(k)']);
        end
        
        function plotInputCoordinate(obj, iInput)
            %PLOTINPUTCOORDINATE plots the i-th coordinate of the sequence
            %of inputs.
            %
            %Syntax:
            %solution.plotInputCoordinate(iInput);
            %
            %See also
            %plotStateCoordinate
            obj.plotOnTree(obj.U(iInput,:));
            xlabel('stage k');
            ylabel('control action');
        end
        
        function optValue = getOptimalValue(obj)
            %GETOPTIMALVALUE returns the optimal value of the solution
            %
            %See also
            %getStates, getControlActions
            %
            optValue = obj.J;
        end
        
        function Xsol = getStates(obj)
            %GETSTATES returns the state sequence in an nx-by-numNodes
            %matrix, where nx is the state dimension and numNodes is the
            %number of nodes of the tree. The state at the i-th node is
            %stored at X(:, i).
            %
            %See also
            %getControlActions, getOptimalValue
            %
            Xsol = obj.X;
        end
           
        function Usol = getControlActions(obj)
            %GETCONTROLACTIONS returns the sequence of optimal control
            %actions in an nu-by-numNonLeafNodes matrix, where nu is the
            %dimensions of the control actions and numNonLeafNodes is the
            %number of non-leaf nodes of the tree. The inputs at the i-th
            %node is stored at U(:, i).
            %
            %See also
            %getStates, getOptimalValue
            %
            Usol = obj.U;
        end
                
        function distribution = getDistributionTerminalFunction(obj, fun)
            %GETDISTRIBUTIONTERMINALFUNCTION returns the probability
            %distribution of a given terminal function at the terminal
            %stage of the scenario tree. It returns a numLeafNodes-by-2
            %matrix, whose first column stores the probability of each of
            %the leaf nodes and the second column stores the respective
            %terminal cost values.
            %
            %See also
            %getDistributionStageCost, plotCostErrorBar
            %
            nLeafNodes = obj.rao.tree.getNumberOfScenarios();
            distribution = zeros(nLeafNodes ,2);
            iter = obj.rao.tree.getIteratorNodesAtStage(obj.rao.tree.getHorizon());
            i = 1;
            while iter.hasNext()
                nodeId = iter.next();
                distribution(i, 1) = obj.rao.tree.getProbabilityOfNode(nodeId);
                x = obj.X(:, nodeId);
                distribution(i, 2) = fun.apply(x);
                i = i + 1;
            end
            distribution = sortrows(distribution, 2);
        end
        
        function distribution = getDistributionStageCost(obj, stage)
            %GETDISTRIBUTIONSTAGECOST returns the probability distribution
            %of the stage cost at a given stage.  It returns a 
            %numNodesAtStage-by-2 matrix, whose first column stores the 
            %probability of each of the nodes at the given stage and the 
            %second column stores the respective stage cost values.
            %
            %See also
            %getDistributionTerminalCost, plotCostErrorBar
            %
            distribution = obj.getDistributionFunction(obj.rao.stageCost, stage);
        end
        
        function distribution = getDistributionTotalCost(obj)
            %GETDISTRIBUTIONTOTALCOST returns the distribution of the total
            %cost. 
            %Distribution is a 2 x nb_leaf_nodes matrix, where the first
            %column contains the probabilities of the scenarios and the
            %second column contains the total costs of those scenarios
            %
            %Syntax: 
            %distribution = solution.plotTotalCostDistribution()
            % 
            
            terminalCost = obj.rao.terminalCost;
            stageCost = obj.rao.stageCost; 
            
            nLeafNodes = obj.rao.tree.getNumberOfScenarios();
            distribution = zeros(nLeafNodes ,2);
            iter = obj.rao.tree.getIteratorNodesAtStage(obj.rao.tree.getHorizon());
            i = 1;
            while iter.hasNext()
                nodeId = iter.next();
                distribution(i, 1) = obj.rao.tree.getProbabilityOfNode(nodeId);
                x = obj.X(:, nodeId);
                distribution(i, 2) = terminalCost.apply(x);
                for t = obj.rao.tree.getHorizon():-1:1
                    child = nodeId; 
                    nodeId = obj.rao.tree.getAncestorOfNode(nodeId);
                    x = obj.X(:,nodeId);
                    u = obj.U(:,nodeId);
                    w = obj.rao.tree.getValueOfNode(child);
                    distribution(i, 2) = distribution(i, 2) ... 
                                         + stageCost.apply(x, u, w);
                end 
                i = i + 1;
            end
            distribution = sortrows(distribution, 2);            
        end 
        
        function varargout = plotCostErrorBar(obj, delta, lastStage, firstStage)
            %PLOTCOSTERRORBAR plots an error bar of the cost at every stage
            %of the tree. The plot show the average value of the
            %(stage/terminal) cost and an error bar which corresponds to
            %the 1-delta quantile of the cost. For example, for delta=0.05,
            %the plot show an error line below which lies the 95% of all
            %realizations of the cost.
            %
            %Syntax:
            %solution.plotCostErrorBar(delta);
            %solution.plotCostErrorBar(delta, lastStage);
            %solution.plotCostErrorBar(delta, lastStage, firstStage);
            %
            %data = solution.plotCostErrorBar(...);  
            % - No figure created, but all the plotting data is returned.
            %
            %Input arguments:
            %delta           quantile level
            %lastStage       last stage 
            %firstStage      first stage
            %
            %See also
            %plotFunctionErrorBar, getDistributionStageCost, getDistributionTerminalCost
            
            % Input parsing, allows to add the terminal cost automatically
            % if needed
            if nargin < 3
                N = obj.rao.tree.getHorizon();
            else
                N = lastStage;
            end

            if nargin < 4
                n = 0;
            else
                n = firstStage;
            end
            
            % Acquire data to plot for the stage costs 
            plotDataStages = obj.plotFunctionErrorBar(obj.rao.stageCost, delta, N, n);
            
            % Add data to plot for the terminal cost if necessary
            if N >= obj.rao.tree.getHorizon() 
                plotDataTerm = obj.plotFunctionErrorBar(obj.rao.terminalCost, delta, N, N);
                fields = fieldnames(plotDataStages);
                for i = 1:numel(fields)
                    field = fields{i};
                    plotDataStages.(field) = [plotDataStages.(field);
                                              plotDataTerm.(field)];
                end
                plotDataStages.n = n; plotDataStages.N = N; 
            end
            
            if nargout ~= 0
                varargout{1} = plotDataStages;  
            else
                obj.errorBarPlot(plotDataStages);
                legendEntries = {'Expected cost', [num2str(100*(1-delta)) '-percentile'], 'Worst case cost'};
                if delta == 1
                    legendEntries{2} = 'Best case cost';
                end
                legend(legendEntries{:});
                ylabel('cost');
            end
        end
        
        function distribution = getDistributionFunction(obj, fun, stage)
            %GETDISTRIBUTIONSTAGECOST returns the probability distribution
            %of the stage cost at a given stage.  It returns a
            %numNodesAtStage-by-2 matrix, whose first column stores the
            %probability of each of the nodes at the given stage and the
            %second column stores the respective stage cost values.
            %
            %See also
            %getDistributionTerminalCost, plotCostErrorBar
            %
            if stage < 0 || stage > obj.rao.tree.getHorizon()
                error('marietta:stageValue', 'stage cannot be < 0 or > tree.getHorizon');
            end
            if stage == obj.rao.tree.getHorizon()
                distribution = obj.getDistributionTerminalFunction(fun);
                return;
            end
            nNodesAtNextStage = obj.rao.tree.getNumberOfNodesAtStage(stage+1);
            distribution = zeros(nNodesAtNextStage, 2);
            iter = obj.rao.tree.getIteratorNodesAtStage(stage+1);
            i = 1;
            while iter.hasNext()
                nodeId = iter.next();
                distribution(i,1) = obj.rao.tree.getProbabilityOfNode(nodeId);
                ancNode = obj.rao.tree.getAncestorOfNode(nodeId);
                wValue = obj.rao.tree.getValueOfNode(nodeId);
                x = obj.X(:, ancNode);
                u = obj.U(:, ancNode);
                if isa(fun, 'marietta.functions.TerminalFunction')
                    distribution(i,2) = fun.apply(x); 
                else
                    distribution(i,2) = fun.apply(x, u, wValue);
                end 
                i = i + 1;
            end
            distribution = sortrows(distribution, 2);
        end 
        
        function varargout = plotFunctionErrorBar(obj, fun, delta, lastStage, firstStage)
            %PLOTFUNCTIONERRORBAR plots an error bar of a given function 
            %at every stage of the tree. The plot show the average value of
            %the function and an error bar which corresponds to
            %the 1-delta quantile of the function. For example, for delta=0.05,
            %the plot show an error line below which lies the 95% of all
            %realizations of the function.
            %
            %If the given function is a marietta.functions.StageFunction,
            %then it is not evaluated at the final stage. 
            % 
            %
            %Syntax:
            %solution.plotFunctionErrorBar(fun, delta);
            %solution.plotFunctionErrorBar(fun, delta, lastStage);
            %solution.plotFunctionErrorBar(fun, delta, lastStage, firstStage);
            %
            %data = solution.plotFunctionErrorBar(...);  
            % - No figure created, but all the plotting data is returned.
            %
            %Input arguments:
            %fun             marietta.functions.StageFunction
            %                or marietta.functions.TerminalFunction
            %                
            %delta           quantile level
            %lastStage       last stage
            %firstStage      first stage
            %
            %See also
            %getDistributionStageCost, getDistributionTerminalCost
            %
            if nargin < 4
                N = obj.rao.tree.getHorizon();
            else
                N = min(obj.rao.tree.getHorizon(), lastStage);
            end
            
            if isa(fun, 'marietta.functions.StageFunction')
                N = min(N, obj.rao.tree.getHorizon()-1); 
            end
            
            if nargin < 5
                n = 0;
            else
                n = firstStage;
            end
            numElements = N-n+1;
            quantile = zeros(numElements,1);
            average = zeros(numElements,1);
            maximum = zeros(numElements,1);
            for stage = n:N
                i = stage-n+1;
                distribution = obj.getDistributionFunction(fun, stage);
                probabilities = cumsum(distribution(:, 1));
                quant = find(probabilities>=1-delta,1);
                if isempty(quant) && delta <= 1e-10
                    % Rounding errors can make probabilities(end) slightly smaller than 1
                    quant = numel(probabilities);
                end 
                quantile(i) = distribution(quant,2);
                average(i) = distribution(:,1)'*distribution(:,2);
                maximum(i) = max(distribution(:, 2));
            end
            
            plotData = struct('n', n, ... 
                              'N', N, ...
                              'average', average, ...
                              'quantile', quantile, ... 
                              'max', maximum);
                          
            if nargout ~= 0 
                varargout{1} = plotData;  
            else
            obj.errorBarPlot(plotData);
            end
        end
        
        function plot2DPhaseProfile(obj, state1, state2, plotOpts)
            %PLOT2DPHASEPROFILE plots a 2D phase profile of two coordinates
            %of the state.
            %
            %Syntax:
            %solution.plot2DPhaseProfile(state1, state2)
            %solution.plot2DPhaseProfile(state1, state2, plotOpts) 
            %
            %
            %where state1 and state2 are two state coordinates.
            %plotOpts is a struct with fields `color` and/or 
            %`transparency`. 
            % plotOpts.color: vector with at least 3 elements. If it has 4
            % elements, the 4th element is used for the transparency, which
            % may be overridden by the plotOpts.transparency option. 
            % plotOpts.transparency: boolean. If true, then the
            % transparency of the lines is scaled with the probability of
            % the nodes. The default is false.
            % 
            %See also:
            %getDistributionStageCost, getDistributionTerminalCost, plotCostErrorBar
            %
            hold on; 
            time_axis = 0:obj.rao.tree.getHorizon();
            
            color_ = [0 0 0 1]; 
            transparency = false; 
            if nargin >= 4 % Plotopts are passed
                if isfield(plotOpts, 'color')
                    color = plotOpts.color; 
                    assert(numel(color) >= 3, 'The color must be an RGB tuple.');
                    if numel(color ~= 4)
                        color_ = [color(1:3), 1];
                    else
                        color_ = color;
                    end
                end
                if isfield(plotOpts, 'transparency')
                    transparency = plotOpts.transparency;
                end
            end
            
            plotoptions = struct('marker', 'none', 'color' , color_) ;
            for t=1:time_axis(end)
                iterNodesStageT = obj.rao.tree.getIteratorNodesAtStage(t);
                while iterNodesStageT.hasNext()
                    iNode = iterNodesStageT.next();
                    ancNode = obj.rao.tree.getAncestorOfNode(iNode);
                    x = obj.X([state1, state2], iNode);
                    xanc = obj.X([state1, state2], ancNode);
                    if transparency
                        plotoptions.color(4) = 0.1 + 0.9*obj.rao.tree.getProbabilityOfNode(iNode);
                    end
                    plot([x(1) xanc(1)], [x(2) xanc(2)], plotoptions);
                end
            end
        end
        
        function disp(obj)
            if iscell(obj.status_msg)
                fprintf('Solution ( %s)\n', obj.status_msg{1});
            else
                fprintf('Solution ( %s)\n', obj.status_msg);
            end
            fprintf('State dimension    : %5d\n', size(obj.X, 1));
            fprintf('Input dimension    : %5d\n', size(obj.U, 1));
            fprintf('Prediction horizon : %5d\n', obj.rao.tree.getHorizon());
            fprintf('Number of nodes    : %5d\n', obj.rao.tree.getNumberOfNodes());
            fprintf('Status code        : %5d\n', obj.status_code)
        end
    end
    
end

