function tightenChildren(parent, factor)
% Tighten up layout of children to remove margins
% Factor can be a single number from 0 to 1 indicating fraction of stuff to
% hide, or a 1x2 to indicate in each dimension

if length(factor) == 1
    factor = [factor, factor];
end

numChildren = length(parent.Children);

for childIdx = 1:numChildren
    child = parent.Children(childIdx);
    originalUnits = child.Units;
    child.Units = 'normalized';
    child.Position(1:2) = child.Position(1:2) - factor;
    child.Position(3:4) = child.Position(3:4) .* (1+2*factor);
    child.Units = originalUnits;
end