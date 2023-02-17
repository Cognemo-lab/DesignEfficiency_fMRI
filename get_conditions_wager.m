function [itiArray, durWager] = get_conditions_wager(meanIti, rangeIti, ...
    nNullTrials, durWager, pathRoot, pathToCode)
% Loads behavioral responses and fitted behavioral model (HGF) from an
% example subject, and adapts condition timing (onsets of trials) to input
% design configuration
%
% IN
%   meanIti
%   rangeIti
%   nNullTrials
%   durWager
%   pathRoot
%   pathToCode
%
% OUT
%   itiArray
%   durWager

if ~nargin
    nNullTrials = 20;
end

if nargin < 6
    pathToCode = mfilename('fullpath');
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 0. Fixed timing parameters, not subject to optimization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% MODIFY
nTrials         = 160;
durItiStart     = 3; %seconds
durCue          = 2;
durResp         = 3;
durOut          = 1;
datapath = mfilename('fullpath');

%% END - MODIFY


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Compute trial timing (onsets/durations/iti) from fixed and given (to
% be optimized) parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Compute itis between all trials
durTrialFixed   = durCue + durResp + durOut;
durNullTrial    = durTrialFixed + durWager; %seconds
durTrial        = durTrialFixed + durWager;

% draw each iti from a uniform distribution in meanIti +/- (rangeIti/2)
itiArray        =  meanIti - rangeIti/2 + rangeIti.*rand(nTrials - 1,1);

itiArray = [durItiStart; itiArray];

% Select null trials, prolong their iti
indNullTrials = 1 + randperm(nTrials - 1,nNullTrials);
itiArray(indNullTrials) = itiArray(indNullTrials) + durNullTrial;


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Specify Conditions for .mat-file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

names           = {'Advice','Wager','Outcome'};

onsets{1}       = cumsum(itiArray) + durTrial*(0:nTrials-1)'; % MODIFY
onsets{2}       = onsets{1} + durCue + durResp; % MODIFY
onsets{3}       = onsets{2} + durWager;

durations{1}    = durCue; % + average RT
durations{2}    = durWager;
durations{3}    = [0] ; % event has duration 0



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Specify parametric modulators from subject's responses and model fits
% (remember: model-based fMRI!)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Specify subjects and trajectories

subjectId       = 'Pilot';
responseModel   = 'softmax_multiple_readouts_reward_social';
perceptualModel = 'hgf_binary3l_reward_social';

load(fullfile(pathToCode, [subjectId '_' ...
    perceptualModel '_' responseModel '.mat']),'est','-mat');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The following complicated code is model-specific, it basically transforms
% model trajectories into asssumed observable quanitities in the brain that
% we probe with model-based fMRI, e.g. prediction errors, precisions...
% pmod = get_parametric_modulators_HGF()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Arbitration
pmod(1,1).name = {'Arbitration'}; % Arbitration
x_a=sgm(est.traj.muhat_a(:,2), 1);
x_r=sgm(est.traj.muhat_r(:,2), 1);

sa2hat_a=est.traj.sahat_a(:,2);
sa2hat_r=est.traj.sahat_r(:,2);

px = 1./(x_a.*(1-x_a));
pc = 1./(x_r.*(1-x_r));
ze1=est.p_obs.ze1;

pmod(1,1).param = {[ze1.*1./sa2hat_a.*px./...
    (ze1.*px.*1./sa2hat_a + pc.*1./sa2hat_r)]};
pmod(1,1).poly={[1]};

% Wager
pmod(1,2).name = {'Wager'}; % Arbitration
wx = ze1.*1./sa2hat_a.*px./(ze1.*px.*1./sa2hat_a + pc.*1./sa2hat_r);
wc = pc.*1./sa2hat_r./(ze1.*px.*1./sa2hat_a + pc.*1./sa2hat_r);

% Belief vector
b = wx.*x_a + wc.*x_r;
pib = 1./(b.*(1-b));
pmod(1,2).param = {[pib]}; % Precision (Model-based wager)
pmod(1,2).poly={[1]};

% Prediction Errors
pmod(1,3).name = {'Epsilon2_Adv','Epsilon2_Cue'}; % PEs
Epsilon2.Advice       = est.traj.da_a(:,1).*est.traj.sa_a(:,2);
Epsilon2.Reward       = abs(est.traj.da_r(:,1).*est.traj.sa_r(:,2));
pmod(1,3).param = {[Epsilon2.Advice],[Epsilon2.Reward]}; % Precision (Model-based wager)
pmod(1,3).poly={[1], [1]};



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. Finally: switch off orthogonalization of parametric modulators and
% save the multiple_conditions file for this configuration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

orth{1} = 0;
orth{2} = 0;
orth{3} = 0;
% save multiple_conditions onsets durations names pmod
save(fullfile(pathRoot, 'WAGER_multiple_conditions.mat'), ...
    'onsets', 'durations', 'names', 'pmod', 'orth');

