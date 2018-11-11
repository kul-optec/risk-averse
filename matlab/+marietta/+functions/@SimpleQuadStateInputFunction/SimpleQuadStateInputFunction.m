classdef SimpleQuadStateInputFunction < marietta.functions.StageFunction
    %SIMPLEQUADSTATEINPUTFUNCTION Simple quadratic function
    %
    %Function of the form
    %
    % f(x,u,w) = x'*Q*x + u'*R*u + q'*x + r'*u + c
    %
    %This function does not depend on w.
    %
    
    properties
        Q = [];
        R = [];
        q = [];
        r = [];
        c = [];
    end
    
    
    methods
        function obj = SimpleQuadStateInputFunction(Q, R, q, r, c)
            if nargin > 0
                obj.Q = Q;
                if nargin > 1
                    obj.R = R;
                    if nargin > 2
                        obj.q = q;
                        if nargin > 3
                            obj.r = r;
                            if nargin > 4
                                obj.c = c;
                            end
                        end
                    end
                end
            end
        end
        
        function result = apply(obj, x, u, w)
            result = 0;
            if ~isempty(obj.Q), result = result + x'*obj.Q*x; end
            if ~isempty(obj.R), result = result + u'*obj.R*u; end
            if ~isempty(obj.q), result = result + obj.q'*x; end
            if ~isempty(obj.r), result = result + obj.r'*u; end
            if ~isempty(obj.c), result = result + obj.c; end
        end
        
        function nx = getStateDimension(obj)
            nx = -1;
        end
        
        function nu = getInputDimension(obj)
            nu = -1;
        end
        
        function nModes = getNumberOfModes(obj)
            nModes = -1;
        end
    end
    
end

