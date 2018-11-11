function data = avarData(p, alpha)

n = length(p);

if alpha < 1e-14
    data = marietta.ConicRiskFactory.maxData(n);
    return;
end

data.E = sparse([ones(1,n); -ones(1,n); alpha * eye(n); -eye(n)     ]);
data.b =        [1        ; -1        ; p             ;  zeros(n,1) ];

data.cone = marietta.ConvexCone(struct('l', 2*n + 2));
data.meta.name = sprintf('average value-at-risk at level alpha=%.2f', alpha);
data.meta.n = n;
data.meta.r = 0;
data.meta.m = 2*n+2;
