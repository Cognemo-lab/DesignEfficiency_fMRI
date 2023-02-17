function onsets = get_onsets_from_iti_durWager(itiArray, durWager)
nTrials         = 160;
durCue          = 2;
durResp         = 3;
durOut          = 1;

durTrialFixed   = durCue +  durResp + durOut;
durTrial        = durTrialFixed + durWager;

onsets{1}       = cumsum(itiArray) + durTrial*(0:nTrials-1)';
onsets{2}       = onsets{1} + durCue + durResp; % MODIFY
onsets{3}       = onsets{2} + durWager;
