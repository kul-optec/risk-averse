clear; clc;

p_avar = marietta.ParametricRiskFactory.createParametricAvar();

p = [0.1 0.2 0.7];             % probability vector
Z = [100 10 1];                % random variable
alpha = 0.5;                   % parameter of AVaR
risk_obj = p_avar(p, alpha);   % make risk object
risk_value = risk_obj.risk(Z); % use risk object

p_avar_05 = marietta.ParametricRiskFactory.createParametricAvarAlpha(0.5);
risk_obj_05 = p_avar_05(p);
risk_value_05 = risk_obj_05.risk(Z);