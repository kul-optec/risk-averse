clear; clc;

Q{1} = eye(2); Q{2} = 10*eye(2);
R{1} = 1; R{2} = 1.3;
quad_cost = marietta.functions.MarkovianQuadStateInputFunction(Q, R);