function data = maxData(n)
%MAXDATA Summary of this function goes here
%   Detailed explanation goes here

data.E = sparse([ones(1,n); -ones(1,n); -eye(n)     ]);
data.b =        [1        ; -1        ; zeros(n,1) ];
data.cone = marietta.ConvexCone(struct('l', n + 2));

end

