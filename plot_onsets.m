function plot_onsets(onsets)

figure;
for i = 1:length(onsets)
    subplot(2,1,1)
    stem(onsets{i}, i*ones(size(onsets{i}))); hold all;
    lgstr{i} = sprintf('condition %d', i);
    xlabel('time'); legend(lgstr); ylim([0, length(onsets) + 1]);
    title('onsets of different conditions');   
    
    subplot(2,1,2);
    plot(diff(onsets{i})); title('iti+duration between consecutive trials');
    xlabel('time');
end
