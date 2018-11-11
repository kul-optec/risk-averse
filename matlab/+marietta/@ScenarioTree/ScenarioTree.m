classdef ScenarioTree < handle
    %SCENARIOTREE scenario tree
    %
    % This class contains methods that facilitate the manipulation of
    % scenario trees and tools to generate such a tree from data.
    %
    
    properties (Access = {?marietta.ScenarioTreeFactory})
        children;           % children of each node
        ancestor;           % ancestor of a node
        stage;              % stage in which a node resides
        leaves;             % indices of leave nodes
        probability;        % probability of a node
        value;              % a value at each node
        scenario_index;     % index of scenarios
        data;               % tree data (a structure at each node)
    end
    
    
    methods (Access = {?marietta.ScenarioTreeFactory})
        
        function verifyNode(obj, i)
            if i<=0
                error('marietta:nodeValue', 'node ID must be positive');
            end
            if i > obj.getNumberOfNodes
                error('marietta:nodeValue', 'node ID exceeds maximum ID');
            end
        end
        
        function verifyNotRootNode(obj, i)
            if i==1
                error('marietta:nodeValue', 'the root node is not allowed');
            end
        end
        
        function verifyNonleafNode(obj, i)
            if obj.getStageOfNode(i) == obj.getHorizon
                error('marietta:nodeValue', 'Leaf nodes are not allowed');
            end
        end
        
        function verifyScenarioID(obj, scenID)
            if scenID<=0
                error('marietta:scenarioIDValue', 'scenario ID must be positive');
            end
            if scenID > obj.getNumberOfScenarios
                error('marietta:scenarioIDValue', 'scenario ID exceeds maximum ID');
            end
        end
        
        makeScenarioIndex(treeObject);
        makeChildren(treeObject);
        makeLeaves(treeObject, nHorizon);
        makeData(treeObject);
    end
    
    
    methods (Access = {?marietta.ScenarioTreeFactory})
        function treeObject = ScenarioTree()
            % Private Constructor
        end
    end
    
    methods (Access = public)
        
        function delete(obj)
            %DELETE destructor of a ScenarioTree object
            obj.children=[];
            obj.ancestor=[];
            obj.stage=[];
            obj.leaves=[];
            obj.probability=[];
            obj.value=[];
            obj.scenario_index=[];
        end
        
        function disp(obj)
            %DISP displays the scenario tree
            %Displays the scenario tree without printing the variable name
            %
            fprintf('-----------------------------------\n');
            fprintf('Scenario tree\n')
            fprintf('-----------------------------------\n');
            if isempty(obj)
                fprintf('Emtpy scenario tree!\n');
            else
                fprintf('+ Horizon....................  %4d\n', obj.getHorizon());
                fprintf('+ Number of nodes............  %4d\n', obj.getNumberOfNodes());
                fprintf('+ Number of scenarios........  %4d\n', obj.getNumberOfScenarios());
                fprintf('+ Value dimension............  %4d\n', obj.getValueDimension());
            end
            fprintf('-----------------------------------\n');
        end
        
        function plot(obj)
            %PLOT plots an illustration of the scenario tree
            %
            if feature('ShowFigureWindows')
                for k=1:obj.getHorizon()
                    nodesAtStage = numel(obj.getNodesAtStage(k));
                    if nodesAtStage > 520, break; end
                end
                if k < obj.getHorizon()
                    warning('the tree is huge - plotting part of it');
                end
                treeplot(obj.ancestor(obj.stage<=k)','bs','r--')
            end
        end
        
        function a = isempty(obj)
            %ISEMPTY returns true iff the tree is empty of undefined
            %
            a = isempty(obj.ancestor) ...
                || isempty(obj.children) ...
                || isempty(obj.leaves) ...
                || isempty(obj.stage) ...
                || isempty(obj.probability) ...
                || isempty(obj.scenario_index);
        end
        
        function nnodes = getNumberOfNodes(obj)
            %GETNUMBEROFNODES returns the total number of nodes of the tree
            nnodes= numel(obj.ancestor);
        end
        
        function nnonleaf = getNumberOfNonleafNodes(obj)
            nnonleaf = length(obj.children);
        end
        
        
        function anc = getAncestorOfNode(obj, nodeID)
            %GETANCESTOROFNODE returns the node ID of the unique ancestor
            %of a node
            obj.verifyNode(nodeID);
            obj.verifyNotRootNode(nodeID);
            anc = obj.ancestor(nodeID);
        end
        
        function ancs = getAncestors(obj)
            %GETANCESTORS returns the array of ancestor nodes (array of
            %node IDs)
            %
            %The length of this array is equal to the total number of nodes
            %of the tree. By convention, the first element of the array is
            %equal to 0.
            
            ancs = obj.ancestor;
        end
        
        function ch = getChildrenOfNode(obj, nodeID)
            %GETCHILDRENOFNODE returns an array with the node IDs of the
            %children of a given node
            obj.verifyNode(nodeID);
            obj.verifyNonleafNode(nodeID);
            ch = obj.children(nodeID);
            ch = ch{1};
        end
        
        function st = getStageOfNode(obj, nodeID)
            %GETSTAGEOFNODE returns the stage in which a given node resides
            obj.verifyNode(nodeID);
            st = obj.stage(nodeID);
        end
        
        function n_pred = getHorizon(obj)
            %GETHORIZON returns the horizon of the tree
            %
            %The stages of the tree are indexed by k=0..N, with k=0
            %corresponding to the first stage at which the so-called root
            %node (with ID: 1) resides.
            %
            n_pred = obj.stage(obj.leaves(1));
        end
        
        function nodesAtStage = getNodesAtStage(obj, k)
            %GETNODESATSTAGE returns the IDs of the nodes which reside in
            %a given stage.
            %
            %Syntax:
            %nodesAtStage = tree.getNodesAtStage(k)
            %
            if k<0 || k>obj.getHorizon()
                error('marietta:stageValue', 'Stage index out of bounds');
            end
            nodesAtStage = find(obj.stage==k);
        end
        
        function nNodesAtStage = getNumberOfNodesAtStage(obj, k)
            %GETNUMBEROFNODESATSTAGE returns the number of nodes at a stage
            %
            if k<0 || k>obj.getHorizon()
                error('marietta:stageValue', 'Stage index out of bounds');
            end
            nNodesAtStage = sum(obj.stage==k);
        end
        
        function leaveNodes = getLeaveNodes(obj)
            %GETLEAVENODES returns the IDs of the leave nodes of the tree
            leaveNodes = obj.leaves;
        end
        
        function pr = getProbabilityOfNode(obj, nodeID)
            %GETPROBABILITYOFNODE returns the probability of a node
            %
            %This method returns the unconditional probability of a
            %specific node `nodeID` to be visited (given we start from the 
            %root node).
            %
            %See also
            %marietta.ScenarioTree.getConditionalProbabilityOfChildren
            obj.verifyNode(nodeID);
            pr = obj.probability(nodeID);
        end
        
        function nch = getNumberOfChildren(obj, nodeID)
            %GETNUMBEROFCHILDREN returns the number of children of a node
            %
            %The method throws an error if applied to a leaf node
            %
            %Syntax:
            %nch = tree.getNumberOfChildren(nodeID)
            %
            %where `nodeID` is a nonleaf node.
            %
            obj.verifyNode(nodeID);
            obj.verifyNonleafNode(nodeID);
            nch = numel(obj.getChildrenOfNode(nodeID));
        end
        
        function sbl = getSiblingsOfNode(obj, nodeID)
            %GETSIBLINGSOFNODE returns the IDs of the sibling nodes of a
            %given node
            %
            %The sibling nodes of a node `nodeID` are those nodes which share             
            %the same ancestor with node `nodeID`. Node `nodeID` itself is 
            %contained in the set of its siblings.
            %
            %By convention, the sibling nodes of nodeID=1 (root node) is the 
            %set {1} containing only the root node.
            obj.verifyNode(nodeID);
            if nodeID==1
                sbl = 1;
            else
                sbl = obj.getChildrenOfNode(obj.getAncestorOfNode(nodeID));
            end
        end
        
        function prch = getConditionalProbabilityOfChildren(obj, nodeID)
            %GETCONDITIONALPROBABILITYOFCHILDREN returns the probability
            %vector of the probability space of the children of a given
            %node `nodeID`.
            %
            %This method throws an error if applied to a leaf node.
            obj.verifyNode(nodeID);
            obj.verifyNonleafNode(nodeID);
            prob_i = obj.getProbabilityOfNode(nodeID);
            if prob_i == 0
                prch = [];
            else
                prch = obj.probability(obj.getChildrenOfNode(nodeID)) / prob_i;
            end
        end % -- END of getConditionalProbabilityOfChildren
        
        function v = getValueOfNode(obj, nodeID)
            %GETVALUEOFNODE returns the value which is associated with a
            %node of the tree.
            %
            obj.verifyNode(nodeID);
            if isempty(obj.value)
                v = [];
                return;
            end
            v = obj.value(nodeID, :)';
        end
        
        function setValueAtNode(obj, nodeId, value)
            %SETVALUEATNODE sets the value stored at a particular node
            %
            %Syntax:
            % tree.setValueAtNode(nodeId, value)
            %           
            obj.verifyNode(nodeId);
            obj.value(nodeId) = value;
        end
        function nw = getValueDimension(obj)
            %GETVALUEDIMENSION returns the dimension of the values which
            %are associated with the nodes of a tree
            nw = size(obj.value, 2);
        end
        
        function sc = getScenarioWithID(obj, nodeID)
            %GETSCENARIOWITHID returns the i-th scenario, i=1,...,nScen
            %
            %Syntax:
            %scenario = treeObjet.getScenarioWithID(i);
            %
            %Input arguments:
            % nodeID       Id of scenario (i=1,...,numberOfScenarios)
            %
            %Output arguments:
            % scenario     An array of indices of nodes, the first one
            %              being equal to 1 (root node) and the last one
            %              being the i-th leaf node.
            %
            obj.verifyScenarioID(nodeID);
            sc = obj.scenario_index{nodeID};
        end
        
        
        function nscen = getNumberOfScenarios(obj)
            %GETNUMBEROFSCENARIOS returns the total number of scenarios of
            %the tree
            %
            %The number of scenarios of a tree is equal to the number of
            %leaf nodes
            nscen = numel(obj.leaves);
        end
        
        function data = getData(obj)
            %GETDATA returns the data on the nodes of the scenario tree
            %
            %At every node of the scenario tree we assign a structure which
            %can hold additional information about the node (e.g.,
            %parameters of an associated dynamical system)
            %
            %See also
            %getDataAtNode, setDataField, mapValuesToData
            data = obj.data;
        end
        
        function dataAtNodeId = getDataAtNode(obj, nodeId)
            %GETDATAATNODE returns the value of the data at node `nodeId`
            %
            %See also
            %getData, setDataField, mapValuesToData
            dataAtNodeId = obj.data(nodeId);
        end
        
        function setDataField(obj, nodeId, fieldName, fieldValue)
            obj.data(nodeId).(fieldName)=fieldValue;
        end
        
        function setAllDataFields(obj, fieldName, fieldValue)
            for i=1:obj.getNumberOfNodes
                obj.setDataField(i, fieldName, fieldValue);
            end
        end
        
        function mapValuesToData(obj, values, data)
            %MAPVALUESTODATA maps values to data
            %
            %Syntax:
            %mapValuesToData(obj, values, data)
            %
            %Input arguments:
            % values        array of values 
            % data          array of structures of corresponding data
            %
            %This method is very useful when, for example, the user needs
            %to assign the values (A{i}, B{i}) at different nodes of the
            %tree of a Markov jump linear system
            %
            %See also 
            %getData
            for nodeId=1:obj.getNumberOfNodes
                val_at_node = obj.getValueOfNode(nodeId);
                id = values==val_at_node;
                if any(id)~=0
                    % Copy the fields of `data(id)` into obj.data(nodeId)
                    fieldNamesDataId = fieldnames(data(id));
                    for i = 1:length(fieldNamesDataId)
                        obj.data(nodeId).(fieldNamesDataId{i}) = data(id).(fieldNamesDataId{i});
                    end
                end
            end
        end
        
        function it = getIteratorNodesAtStage(obj, k)
            %GETITERATORNODESATSTAGE returns an iterator over all nodes at
            %a given stage
            %
            %Syntax
            % iter = tree.getIteratorNodesAtStage(k)
            %
            %Example:
            % iter = tree.getIteratorNodesAtStage(k)
            % while iter.hasNext()
            %     nodeId = iter.next();
            % end
            %
            %See also
            %marietta.ScenarioTree.getIteratorNonleafNodes
            it = marietta.util.ArrayIterator(obj.getNodesAtStage(k));
        end
        
        function it = getIteratorChildrenOfNode(obj, i)
            %GETITERATORCHILDRENOFNODE returns an iterator over all child
            %nodes of node i 
            %
            %Syntax
            % iter = tree.getIteratorChildrenOfNode(i)
            %
            %See also
            %marietta.ScenarioTree.getIteratorNonleafNodes, 
            %marietta.ScenarioTree.getIteratorNodesAtStage
            it = marietta.util.ArrayIterator(obj.getChildrenOfNode(i));
        end
        
        function it = getIteratorNonleafNodes(obj)
            %GETITERATORNONLEAFNODES returns an iterator over all nonleaf
            %nodes of the tree.
            %
            %Syntax
            % iter = tree.getIteratorNonleafNodes(k)
            %
            %Example:
            % iter = tree.getIteratorNonleafNodes(k)
            % while iter.hasNext()
            %     nodeId = iter.next();
            % end
            %
            %See also
            %marietta.ScenarioTree.getIteratorNodesAtStage
            array = find(obj.stage<obj.getHorizon());
            it = marietta.util.ArrayIterator(array);
        end
        
    end % -- END of public methods
       

end


