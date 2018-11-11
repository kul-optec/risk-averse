classdef QuadTerminalFunction < marietta.functions.TerminalFunction
    %QUADTERMINALFUNCTION Quadratic terminal function
    %
    % Terminal function of the form
    %  f(x) = x'*QN*x + qN'*x
    %
    
    properties
        QN = [];
        qN = [];
    end
    
    methods
        function obj = QuadTerminalFunction(QN, qN)
            obj.QN = QN;
            if nargin > 1, obj.qN = qN; end
        end
        
        function result = apply(obj, x)
            result = 0;
            if ~isempty(obj.QN)
                result = result + x' * obj.QN * x;
            end
            if ~isempty(obj.qN)
                result = result + obj.qN' * x;
            end
        end
    end
    
end

