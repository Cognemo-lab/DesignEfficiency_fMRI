function plot_efficiency_results(eff, nNullTrialsGrid, durRespGrid, iCondArray)
if nargin < 4
    iCondArray = 1:size(eff,2);
end

for c = iCondArray
    titstr = sprintf('Contrast %d', c);
    figure('Name', titstr, 'WindowStyle', 'docked');
    plot3(nNullTrialsGrid(:),durRespGrid(:), eff(:,c),'*');
    grid on
    xlabel('nNullTrials');
    ylabel('durWager');
    zlabel('Design Efficiency');
    title(titstr);
end