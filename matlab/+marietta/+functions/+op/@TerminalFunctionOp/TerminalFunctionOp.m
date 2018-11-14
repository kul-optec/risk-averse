classdef TerminalFunctionOp < marietta.functions.TerminalFunction
    %TerminalFunctionOp implements an operator between two terminal functions
    %
    %Function: OP(f1, f2), where f1 and f2 are two terminal functions and OP
    %is a binary oeprator
    
    properties
        f1; % function f1
        f2; % function f2
        op; % operator between f1 and f2, op(f1, f2)
    end
    
    methods
        function obj = TerminalFunctionOp(f1, f2, op)
            obj.f1 = f1;
            obj.f2 = f2;
            obj.op = op;
        end
        
        function result = apply(obj, x)
            if isnumeric(obj.f1)
                result = obj.f1 * obj.f2.apply(x);
                return;
            end
            result = obj.f1.apply(x);
            if isa(obj.f2, 'marietta.functions.TerminalFunction')
                result = obj.op(result, obj.f2.apply(x));
            elseif isnumeric(obj.f2)
                result = obj.op(result, obj.f2);
            end
        end
    end
    
end

