function var = valueAtRisk(Z, p, alpha)

if alpha<=1e-6
    var = max(Z);
    return;
end
[Z, idx] = sort(Z);
p_cumsum = cumsum(p(idx));
var = Z(find(p_cumsum>1-alpha,1));