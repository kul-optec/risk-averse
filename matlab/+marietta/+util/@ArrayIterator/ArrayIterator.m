classdef ArrayIterator < marietta.util.Iterator
    %ARRAYITERATOR Iterator over the elements of an array
    
    properties (Access = private)
        array;        
    end
    
    methods
        function obj = ArrayIterator(array)
            %ARRAYITERATOR constructor for ArrayIterator
            %
            %Syntax:
            % iter = marietta.util.ArrayIterator(array)
            obj.array = array(:);
            obj.cursor = 0;
        end
        
        function flag = hasNext(obj)
            %HASNEXT returns true if the cursor has not reached the end of
            %the stream and false otherwise; it also moves the cursor to
            %the next position.
            %
            %See also
            %marietta.util.ArrayIterator.next
            flag = obj.cursor < numel(obj.array);
            obj.cursor = obj.cursor + 1;
        end
        
        function nxt = next(obj)
            %NEXT returns the next object in the row; it does not move the
            %cursor.
            %
            %See also
            %marietta.util.ArrayIterator.hasNext
            nxt = obj.array(obj.cursor);
        end
    end
    
end
