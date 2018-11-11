function [tree, details] = treeFormation(data, options)
%TREE_FORMATION generates a scenario tree out of raw data
%
%Scenarios are deduced by forward selection
%The input is scenario of random variables
%
%Syntax: 
% Tree = TREE_FORMATION(W,ops);
% [Tree, details] = TREE_FORMATION(W,ops);
%
%Input arguments:
% W:    Stochastic variable. W is a 3D array where the first dimension is equal
%       to the number of scenarios (number sequences of measurements), the second
%       is the number of variables, i.e., the size of the uncertainty vector and
%       the third dimension is the number of time instants.
%
% ops:  This contains the options for the tree formation. It is a structure
%       containing the following fields:
%           - N: prediction horizon
%           - ni: branching factors
%           - Wscaling: 0/1 (whether scaling should be performed)
%           - Tmax: max number of scenarios to be processed
%           - nScen: No of scenaratios considered (subsampling)
%           - nw: lenght of the stochastic variable
%
%Output:  
% Tree: The scenario tree. It is a structre with fields
%         - stage:Indicate at what prediction stage is the node located
%         - value:The value of stochastic variable at eaach node
%         - prob:The probability of the node
%         - ancestor:The ancester node of each of the node
%         - children:The child node of each node
%         - leaves:The leaf nodes of the tree

% Authors: Ajay K. Sampathirao, Daniele Bernardini (4ward selection),
%          Pantelis Sopasakis

if ~isfield('P',options)
    options.P = ones(options.nScen,options.Tmax)/options.nScen; % probability distribution of w
end

Wscaled=zeros(size(data));
if options.Wscaling==1
    options.Wscaled = zeros(size(data));
    for i=1:options.nw
        Ww = data(:,i,:);
        Wscaled(:,i,:) = (data(:,i,:)-mean(Ww(:)))/std(Ww(:));
    end
else
    Wscaled = data;
end
tic
tree = struct('stage',0,'value',zeros(1,options.nw),'prob',1, ...
    'ancestor',0,'children',cell(1,1),'leaves',1);

% leaves is a dynamic field: it contains the index of nodes which are leaves
% during the tree construction. Root node is 1. Other nodes are indexed
% progressively as they are added to the tree.

Cluster = cell(1,1);
Cluster{1} = (1:options.nScen)'; % scenarios to consider for node n

N = min(options.N,size(data,3)); % modify N to take into account availability of data

while any(tree.stage(tree.leaves) < N)
    current_number_of_leaves = numel(tree.leaves);
    for l=1:current_number_of_leaves % for each leaf node
        k = tree.stage(tree.leaves(l)); % time stage of the current node
        if k < N % leaves of this node must be evaluated
            current_number_of_nodes = numel(tree.ancestor);
            % select the current node
            n = tree.leaves(l);
            % cut this node from leaves
            tree.leaves = [tree.leaves(1:l-1); tree.leaves(l+1:end)];
            if isempty(tree.leaves), tree.leaves = []; end
            % and create its leaves:
            % reduce scenarios
            % xi = w
            xi = data(Cluster{n},:,k+1); % data at the current stage
            xis = Wscaled(Cluster{n},:,k+1); % scaled data at the current stage
            numScen = size(xi,1); % no. of scenarios
            p = options.P(Cluster{n},k+1); % probabilities
            p = p/sum(p); % rescale p
            
            if numScen > options.ni(k+1)
                % Apply single stage scenario reduction
                [q,I,S2I] = single_stage(xis,p,options.ni(k+1)); % use the scaled value in scenario reduction
            else
                % No need to reduce scenarios
                q = p;
                I = 1:numScen;
                S2I = I;
            end
            new_nodes = numel(I);
            
            % Cluster deleted scenarios
            for i=1:new_nodes
                Cluster{current_number_of_nodes + i} = Cluster{n}(S2I==I(i));
            end
            
            % Update Tree
            tree.leaves(end+(1:new_nodes),1) =  current_number_of_nodes + (1:new_nodes)';
            tree.stage(end+(1:new_nodes),1) = k+1;
            tree.ancestor(end+(1:new_nodes),1) = n;
            tree.children{n,1} = current_number_of_nodes + (1:new_nodes)';
            tree.prob(end+(1:new_nodes),1) = tree.prob(n) * q(I);
            tree.value(end+(1:new_nodes),:) = xi(I,:); % this is the non scaled value
            
        end
    end
end
details.time=toc;




function [q,I,S2I] = single_stage(xi,p,ni)

numScenarios = size(xi,1); % no. of scenarios
scenarios = (1:numScenarios)'; % set of all scenarios
eliminatedScenarios = scenarios; % set of eliminated scenarios
I = zeros(ni,1); % set of reduced scenarios
for i=1:ni % for all scenarios that we want to keep
    Dmin = inf;
    for s=1:numel(eliminatedScenarios) % for all candidate scenarios
        D = 0;
        H = setdiff(scenarios,setdiff(eliminatedScenarios,s));
        for j=1:numel(eliminatedScenarios) % for all candidate scenarios but s
            if j~=s
                normximin = inf;
                for h=1:numel(H) % for all scenarios not in J\s
                    normxih = norm(xi(eliminatedScenarios(j),:)-xi(H(h),:));
                    if normxih < normximin
                        normximin = normxih;
                    end
                end
                D = D + p(eliminatedScenarios(j))*normximin;
            end
        end
        if D < Dmin % find the minimum D and the corresponding J index
            Dmin = D;
            smin = s;
        end
    end
    I(i) = eliminatedScenarios(smin);
    eliminatedScenarios = [eliminatedScenarios(1:(smin-1)); 
                           eliminatedScenarios((smin+1):end)];
end

% Apply redistribution rule: add probabilities of deleted scenarios to the
% one of the closest kept scenario
q = zeros(numScenarios,1); % probabilities after redistribution
S2I = zeros(numScenarios,1); % S2I(j)=i iff scenario i \in I is the closest to scenario j
for j=1:numScenarios % for all scenarios
    dmin = inf;
    for i=1:ni
        d = norm(xi(j,:)-xi(I(i),:));
        if d < dmin
            dmin = d;
            imin = i;
        end
    end
    S2I(j) = I(imin);
end

for i=1:ni
    q(I(i)) = sum(p(S2I==I(i))); % define probabilities of reduced scenarios
end
