clear; clc;

n = 10; Z = exp(linspace(0,5,n))';
p = exp(-0.5*(1:n))'; p = p/sum(p); xd = [];
for alpha = [0.001:0.01:0.1 0.2:0.1:0.9 0.94:0.02:1.0]
    avar = marietta.ConicRiskFactory.createAvar(p, alpha);
    evar = marietta.ConicRiskFactory.createEvar(p, alpha);
    avarZ = avar.risk(Z); evarZ = evar.risk(Z);
    xd = [xd; alpha avarZ evarZ];
end

figure;
plot(xd(:,1), xd(:,2),'-o','linewidth', 2); hold on;
plot(xd(:,1), xd(:,3),'-x','linewidth', 2);
legend('AVaR', 'EVaR'); grid on;
xlabel('alpha'); ylabel('risk')