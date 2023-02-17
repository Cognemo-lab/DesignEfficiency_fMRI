function fh = plot_efficiency_2d(eff, nNullTrialsGrid, durWagerGrid, nItiJittersGrid)
% Plots efficiency in 2D for all contrasts and labels winning configuration
%
%   fh = plot_efficiency_2d(eff,nNullTrialsGrid, durWagerGrid, nItiJittersGrid)
%
% IN
%
% OUT
%
% EXAMPLE
%   plot_efficiency_2d
%
%   See also
%
% Author:   Saskia Klein & Lars Kasper
% Created:  2016-02-17
% Copyright (C) 2016 Institute for Biomedical Engineering
%                    University of Zurich and ETH Zurich
%
% This file is part of the Zurich fMRI Methods Evaluation Repository, which is released
% under the terms of the GNU General Public Licence (GPL), version 3. 
% You can redistribute it and/or modify it under the terms of the GPL
% (either version 3 or, at your option, any later version).
% For further details, see the file COPYING or
%  <http://www.gnu.org/licenses/>.
%
% $Id: new_function2.m 354 2013-12-02 22:21:41Z kasperla $

stringTitle = 'All Contrasts, Efficiency Comparison';
figure('Name', stringTitle, 'WindowStyle', 'docked');
subplot(2,1,1)
[maxEfficiency, indMax] = max(eff);

nConfigs = size(eff,1);
nContrasts = size(eff,2);
relEff = eff./repmat(maxEfficiency, nConfigs,1);
stringLegend = cellfun(@(x,y) sprintf('Contrast %d (max eff = %5.3f)',x,y), ...
    num2cell(1:nContrasts), num2cell(maxEfficiency), 'UniformOutput', false);



plot(relEff);
hold all;

for n = 1:nContrasts
text(indMax(n), 1,...
    sprintf('nNullTrials = %d, index Jitter Config = %d, duration Wager = %d s\n', ...
   nNullTrialsGrid(n), nItiJittersGrid(n), durWagerGrid(n)));
end

ylim([0 1.1])
legend(stringLegend);
xlabel('configuration');
ylabel('efficiency');
title('Relative Efficiency');

%% now with sorted efficiencies for distribution feeling
subplot(2,1,2);

for n = 1:nContrasts
    sortedRelEff(:,n) = sort(relEff(:,n), 'descend');
end

stringLegend = cellfun(@(x,y) sprintf('Contrast %d (max eff = %5.3f)',x,y), ...
    num2cell(1:nContrasts), num2cell(maxEfficiency), 'UniformOutput', false);


plot(sortedRelEff);
legend(stringLegend);
xlabel('configuration rank (sorted by best efficiency by contrast, not actual index)');
ylabel('efficiency');
title('Relative Efficiency (sorted descending for each contrast');
