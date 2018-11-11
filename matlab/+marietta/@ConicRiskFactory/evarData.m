function data = evarData(p, alpha)

if alpha < 1e-14
    data = marietta.ConicRiskFactory.maxData(numel(p));
    return;
end

if abs(alpha-1) < 1e-14
    data = marietta.ConicRiskFactory.avarData(p, alpha);
    return;
end

n = length(p); 
e1 = [1;0;0]; 
e2 = [0;1;0]; 
e3 = [0;0;1];

E = [ones(1,n);             % 1'*mu + 0'*nu == 1                          1
    -ones(1,n);             %                                             1
    -eye(n);                % -mu + 0*nu <= 0                             n
    zeros(1,n);             % 0*mu + 1'*nu <= -log(alpha)                 1
    kron(eye(n), -e2)];     % (0,-1,0)mu + (0,0,1)nu <=exp (pi,0,0)     3*n

F = [zeros(2,n);            % 1'*mu + 0'*nu == 1
    zeros(n,n);             % -mu + 0*nu <= 0
    ones(1,n);              % 0*mu + 1'*nu <= -log(alpha)
    kron(eye(n), e1)];      % (0,-1,0)mu + (0,0,1)nu <=exp (pi,0,0)

b = [1;                     % 1'*mu + 0'*nu = 1
    -1;
    zeros(n,1);             % -mu + 0*nu <= 0
    -log(alpha);            % 0*mu + 1'*nu <= -log(alpha)
    kron(p,e3)];            % (0,-1,0)mu + (0,0,1)nu <=exp (pi,0,0)

data.E = E;
data.F = F;
data.b = b;

data.meta.name = sprintf('entropic value-at-risk at level alpha=%.2f', alpha);
data.meta.alpha = alpha;
data.meta.n = n;
data.meta.r = n;
data.meta.m = 4*n+3;
data.meta.prob = p;

data.cone = marietta.ConvexCone(struct('l', n+3, 'ep', n));
