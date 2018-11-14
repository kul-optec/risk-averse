classdef MarkovianLinearStateInputFunction < marietta.functions.StageFunction
    %MarkovianLinearStateInputFunction Markovian linear function
    %It is a function of the form
    %
    % f(x,u,w) = A(w) * x + B(w) * u + p(w),
    %   
    %it is f: X x U w W --> X
    
    properties (Access = private)
        A = [];
        B = [];
        p = [];
        nx = 0;
        nu = 0;
        nModes = 0;
    end
    
    methods
        
        function obj = MarkovianLinearStateInputFunction(A, B, p)
            obj.A = A;
            obj.B = B;
            if nargin > 2
                obj.p = p;
            end
            
            obj.nx = size(A{1}, 1);
            if ~isempty(B)
                obj.nu = size(B{1}, 2);
            else
                obj.nu = 0;
            end
            obj.nModes = length(A);
        end
        
        function result = apply(obj, x, u, w)            
            result = 0;
            if ~isempty(obj.A), result = result + obj.A{w} * x; end
            if ~isempty(obj.B), result = result + obj.B{w} * u; end
            if ~isempty(obj.p), result = result + obj.p{w}; end
        end
        
        function nx = getStateDimension(obj)
            nx = obj.nx;
        end
        
        function nu = getInputDimension(obj)
            nu = obj.nu;
        end
        
        function nModes = getNumberOfModes(obj)
            nModes = obj.nModes;
        end
            
    end
    
end


