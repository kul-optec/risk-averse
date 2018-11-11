classdef ConvexCone < handle
    %CONVEXCONE convex cone
    %
    %This corresponds to the Cartesian product of certain elementary
    %cones, namely, the zero, linear, second-order, PSD, exponential, dual
    %exponential and power cones (in this order).
    %
    %
    %More: For details and mathematical background, read the online
    %documentation at https://kul-forbes.github.io/scs/page_cones.html
    %
    
    properties (Access = private)
        f = 0;   % dimension of zero cone
        q = [];  % dimensions of SO cones
        p = [];  % dimensions of power cones
        s = [];  % dimensions of PSD cones
        l = 0;   % dimension of linear cone
        ep = 0;  % number of (3D) primal exponential cones
        ed = 0;  % dimension of (3D) dual exponential cones
    end
    
    methods
        function cone = ConvexCone(varargin)
            %Constructor of a ConvexCone object
            %
            %Syntax:
            %cone = marietta.ConvexCone();
            %cone = marietta.ConvexCone(coneStructure);
            %cone = marietta.ConvexCone(f, q, p, s, l, ep, ed);
            %
            %Input arguments:
            %none              if no input arguments are provided, then an
            %                  empty cone is created
            %coneStructure     a structure with fields any of: f, q, p, s,
            %                  l, ep, ed (see below for details)
            %f                 dimension of zero cone
            %q                 dimensions of SO cones
            %p                 dimensions of power cones
            %s                 dimensions of PSD cones
            %l                 dimension of linear cone
            %ep                number of (3D) primal exponential cones
            %ed                dimension of (3D) dual exponential cones
            %
            %Visit https://kul-forbes.github.io/scs/page_cones.html for
            %details.
            %
            %See also
            %isempty, imposeDualConicInequality
            %
            if nargin == 0, return; end
            if nargin == 1 && isstruct(varargin{1})
                cone_struct = varargin{1};
                if isfield(cone_struct, 'f'), cone.f = cone_struct.f; end
                if isfield(cone_struct, 'q'), cone.q = cone_struct.q; end
                if isfield(cone_struct, 'p'), cone.p = cone_struct.p; end
                if isfield(cone_struct, 'q'), cone.s = cone_struct.s; end
                if isfield(cone_struct, 'l'), cone.l = cone_struct.l; end
                if isfield(cone_struct, 'ep'), cone.ep = cone_struct.ep; end
                if isfield(cone_struct, 'ed'), cone.ed = cone_struct.ed; end
            end
            if nargin == 7
                cone.f = varargin{1};
                cone.q = varargin{2};
                cone.p = varargin{3};
                cone.s = varargin{4};
                cone.l = varargin{5};
                cone.ep = varargin{6};
                cone.ed = varargin{7};
            end
        end
        
        function flag = isempty(cone)
            %ISEMPTY returns 1 if the cone is empty and 0 otherwise
            %
            flag = cone.getZeroConeDimension()==0 ...
                && cone.getPositiveOrthantDimension()==0 ...
                && isempty(cone.q) ...
                && isempty(cone.p) ...
                && isempty(cone.s) ...
                && cone.getPrimalExponentialConeDimension() == 0 ...
                && cone.getDualExponentialConeDimension() == 0;
        end
        
        function flag = isPositiveOrthant(cone)
            %ISPOSITIVEORTHANT returns 1 if the cone is a positive orthant
            %and 0 otherwise
            flag = cone.getPositiveOrthantDimension()>0 ...
                && cone.getZeroConeDimension()==0 ...
                &&  isempty(cone.q) ...
                && isempty(cone.p) ...
                && isempty(cone.s) ...
                && cone.getPrimalExponentialConeDimension()==0 ...
                && cone.getDualExponentialConeDimension()==0;
        end
        
        function constraint = imposeDualConicInequality(cone, y)
            %IMPOSEDUALCONICINEQUALITY imposes the dual constraints `y in K*`
            %where K* is the dual cone
            %
            %Syntax:
            % constraint = cone.imposeDualConicInequality(y)
            %
            %where `y` is a dual vector of appropriate dimensions.
            %
            constraint = [];
            idxPosOrth = cone.f + 1 : cone.f+cone.l;
            idxPriExp  = cone.f + cone.l+1 : cone.f + cone.l + 3*cone.ep;
            if ~isempty(idxPosOrth)
                constraint = (y(idxPosOrth) >= 0); 
            end
            numExpConstr = numel(idxPriExp)/3;
            for i = 1:numExpConstr
                idx_dual_exp = idxPriExp(3*(i-1)+(1:3));
                y_temp = y(idx_dual_exp);
                u = y_temp(1);
                v = y_temp(2);
                w = y_temp(3);
                constraint = [constraint;
                    u <= -1e-14;
                    w >= 1e-14;
                    kullbackleibler(-u, w) <= v - u];
            end
        end
        
        function cone_struct = asStruct(cone)
            %ASSTRUCT returns a structure with fields f, q, p, s, l, ep,
            %ed, i.e., it casts the current ConvexCone object as a
            %structure.
            %
            cone_struct = struct('f', cone.f, 'q', cone.q, 'p', cone.p,...
                's', cone.s, 'l', cone.l, 'ep', cone.ep, 'ed', cone.ed);
        end
        
        function zeroConeDim = getZeroConeDimension(cone)
            %GETZEROCONEDIMENSION returns the dimension of the zero cone
            %
            zeroConeDim = cone.f;
        end
        
        function posOrthDim = getPositiveOrthantDimension(cone)
            posOrthDim = cone.l;
        end
        
        function priExpConeDim = getPrimalExponentialConeDimension(cone)
            if isempty(cone.ep), priExpConeDim = 0; return; end
            priExpConeDim = cone.ep;
        end
        
        function dualExpConeDim = getDualExponentialConeDimension(cone)
            if isempty(cone.ed), dualExpConeDim = 0; return; end
            dualExpConeDim = cone.ed;
        end
    end
    
end

