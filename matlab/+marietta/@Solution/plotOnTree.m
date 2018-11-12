function plotOnTree(obj, z, plot_spec)
%PLOTONTREE plots an array z, versus time connecting the elements z(i) to z(anc(i)). 
% 
%Syntax:
% solution.plotOnTree(z, plot_spec)
% solution.plotOnTree(z) 
% 
%Input arguments: 
% z : the data to be plotted. For each node i, the element z(i) must exist.
% plot_spec : specifications that can be passed to the plot function. 

tree = obj.rao.tree;
time_axis = 0:tree.getHorizon;
hold on; grid on; plot_spec_ = struct('marker', '.', 'color', [0,0,0,1],'linewidth', 1.5);
if nargin >=3, plot_spec_ = plot_spec; end
for t=1:time_axis(end)
    iterNodesStageT = tree.getIteratorNodesAtStage(t);
    while iterNodesStageT.hasNext()
        iNode = iterNodesStageT.next();
        ancNode = tree.getAncestorOfNode(iNode);
        if iNode > numel(z), return; end
        plot_spec_.color(4) = 0.05+0.95*tree.getProbabilityOfNode(iNode);
        plot([t-1 t], [z(ancNode), z(iNode)], plot_spec_);
    end
end
axis tight