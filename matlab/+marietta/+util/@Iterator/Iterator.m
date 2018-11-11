classdef (Abstract) Iterator < handle
    %ITERATOR is an abstract iterator class
    %   Iterators are used as follows:
    %
    % while it.hasNext
    %   x = it.next
    % end
    %
    %The facilitate the traversal of certain arrays (e.g., the traversal of
    %all non-leaf nodes of a scenario tree)
    %
    %See also
    %marietta.ScenarioTree.getIteratorNodesAtStage
    %marietta.ScenarioTree.getIteratorNonleafNodes
    
    properties (Access = protected)
        cursor;
    end           
    
    methods (Abstract)             
        flag = hasNext(obj)        
        nxt = next(obj)
    end
    
    methods (Access = public)
        
        function restart(obj)
            %RESTART rewinds the cursor to the beginning
            obj.cursor = 0;
        end
        
    end
    
end

