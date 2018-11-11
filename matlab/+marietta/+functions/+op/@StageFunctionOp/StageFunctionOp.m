classdef StageFunctionOp < marietta.functions.StageFunction
    %StageFunctionOp implements an operator between two stage functions
    %
    %Function: OP(f1, f2), where f1 and f2 are two stage functions and OP
    %is a binary oeprator
    
    properties
        f1; % function f1
        f2; % function f2
        op; % operator between f1 and f2, op(f1, f2)
    end
    
    methods
        function obj = StageFunctionOp(f1, f2, op)
            obj.f1 = f1;
            obj.f2 = f2;
            obj.op = op;
        end
        
        function result = apply(obj, x, u, w)
            result = obj.f1.apply(x,u,w);
            if isa(obj.f2, 'marietta.functions.StageFunction')
                result = obj.op(result, obj.f2.apply(x,u,w));
            elseif isnumeric(obj.f2)
                result = obj.op(result, obj.f2);
            end
        end
        
        function nx = getStateDimension(obj)
            nx = obj.f1.getStateDimension;
        end
        
        function nu = getInputDimension(obj)
            nu = obj.f1.getInputDimension;
        end
        
        function nModes = getNumberOfModes(obj)
            nModes = obj.f1.getNumberOfModes;
        end
    end
    
end

