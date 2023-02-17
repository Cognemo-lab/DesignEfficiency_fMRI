% function [eff, itiArrayOut, durWagerOut, nNullTrialsGrid, durWagerGrid] ...
%     = run_efficiency_analysis_wager_fun(nNullTrialsArray, durWagerArray, ...
%     nItiJitters, DEBUG, tmpDir)

% Author:   Andreea Diaconescu
% Created:  2016-02-17; Modified: 2023-02-17
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 0. File, folder and path settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pathRoot        = '/Users/drea/Documents/Courses/CognemoSeries/design_eff/DiaconescuDesignEfficiency/ResultsEfficiency'; % where the efficiency analysis takes place
pathToCode      = '/Users/drea/Documents/Courses/CognemoSeries/design_eff/DiaconescuDesignEfficiency/Code'; % MODIFY
pathSPM         = '/Users/drea/Documents/Courses/CognemoSeries/design_eff/Toolboxes/spm12'; %MODIFY
tmpDir          = pathRoot;

addpath(pathToCode);
addpath(pathSPM);spm_jobman('initcfg');


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Parameters to Modify for optimization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


nVols               = 1320;     % MODIFY
TR                  = 2.69;     % in seconds
nSlices             = 37;
onsetSlice          = 18;% to which all regressors are temporally aligned

indCondArray        = [1 3 6]; % MODIFY to column nos for parameter of interest
nTrials             = 160;

meanIti             = 3; %seconds
rangeIti            = 1;


% number of parameter sets to try for each parameter
nNullTrialsArray    = round([10 20]/100*nTrials); % percentage of trials used as nulltrials
durWagerArray       = [6 8];  % in seconds 
nItiJitters         = 4;        % number of random jitter generation

% Options for output and estimation options

options.displayBatchJob             = false;
options.plotConditionConfiguration  = true;
options.ignoreHighPassFilter        = false;
options.plotEfficiencyResults       = true;
options.dispDesignEfficiency        = true; % displays all computed eff values immediately in loop



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Automatic adaptation of batch due to modification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load(fullfile(pathToCode, 'wager_efficiency_Pilot.mat'));
matlabbatch{1}.spm.stats.fmri_design.timing.RT = TR;
matlabbatch{1}.spm.stats.fmri_design.sess.nscan = nVols;
matlabbatch{1}.spm.stats.fmri_design.timing.fmri_t = nSlices;
matlabbatch{1}.spm.stats.fmri_design.timing.fmri_t0 = onsetSlice;
matlabbatch{1}.spm.stats.fmri_design.dir = ...
    cellstr(tmpDir); % MODIFY
matlabbatch{1}.spm.stats.fmri_design.sess.multi = ...
    cellstr(fullfile(tmpDir, 'WAGER_multiple_conditions.mat'));
%delete pre'existing conditions
matlabbatch{1}.spm.stats.fmri_design.sess.cond = ...
    struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, ...
    'pmod', {}, 'orth', {});




%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Run Efficiency calculation for different design configurations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create all configurations to try out
nItiJittersArray = 1:nItiJitters;
[nNullTrialsGrid, durWagerGrid, nItiJittersGrid] = ...
    ndgrid(nNullTrialsArray, durWagerArray, nItiJittersArray);


nConfigs    = numel(nNullTrialsGrid);
nConds      = numel(indCondArray);
eff         = zeros(nConfigs,1);
iMaxEff     = ones(1,nConds);
durWagerOut = zeros(1,nConfigs);
itiArrayOut = zeros(nTrials,nConfigs);


for n=1:nConfigs
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 3a. Retrieve inter-trial intervals and durations of response (wagering)
    % from a certain configuration
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    fprintf('Computing config %04d:\n', n);
    
    nNullTrials     = nNullTrialsGrid(n);
    iCurrentJitter  = nItiJittersGrid(n);
    durWager        = durWagerGrid(n);
    
    fprintf('nNullTrials = %d, index Jitter Config = %d, duration Wager = %d s\n', ...
        nNullTrials, iCurrentJitter, durWager);
    
    [itiArrayOut(:,n), durWagerOut(n)] = ...
        get_conditions_wager(meanIti, rangeIti, nNullTrials, durWager, tmpDir, ...
        pathToCode);
    
    %% Plot the timing of the current configuration
    if options.plotConditionConfiguration
        onsets = get_onsets_from_iti_durWager(itiArrayOut(:,n), durWagerOut(n));
        plot_onsets(onsets);set(gcf, 'WindowStyle','docked');
    end
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 3b. Specify design matrix via SPM from current condition config
    % (hrf convolution of conditions, resampling to bin time units, high-pass filtering)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % clean up previous design matrix
    cd(tmpDir);
    fileSPM = fullfile(tmpDir, 'SPM.mat');
    delete(fileSPM);
    disp(pwd);
    
    % Run specify design matrix
    if options.displayBatchJob
        spm_jobman('run', matlabbatch); % for debugging
        disp('')
        input('Please Play in Batch Editor, wait for job to finish, then Press ENTER to continue');
    else
        spm_jobman('run', matlabbatch);
    end
    disp(pwd);
    
    % wait for SPM.mat to be saved
    i = 1;
    
    disp('waiting for SPM file creation')
    while isempty(dir(fileSPM))
        pause(0.1);
        fprintf('.')
    end
    
    disp('waiting for SPM.mat saving');
    s = dir(fileSPM);
    fileSize = s.bytes;
    isSpmSaved = false;
    while ~isSpmSaved
        pause(0.1);
        fprintf('.')
        
        s = dir(fileSPM);
        
        % Check whether file size is still changing
        isSpmSaved = fileSize == s.bytes;
        
        if ~isSpmSaved
            fileSize = s.bytes;
        end
    end
    
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 3c. Retrieve (the right) computed design matrix X from SPM structure
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    load(fileSPM);
    
    if options.ignoreHighPassFilter
        
        %% A) Alternative: Access before prewhitening and filtering
        % X = SPM.xX.X;
        
    else
        %% B) High-pass filter X as SPM would do in spm_spm
        
        % create filter according to spm_sp and spm_filter
        xX = SPM.xX;
        xX.K.row = 1:nVols; xX.K.RT= TR; xX.K.HParam=128; xX.K = spm_filter(xX.K);
        
        % we cannot prewhiten without data (hyperparameter estimation);
        W = eye(nVols);
        
        xX.xKXs   = spm_sp('Set',spm_filter(xX.K,W*xX.X));
        
        % after pre-whitening and filtering
        X = xX.xKXs.X;
        
    end
    
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 3d. Compute Design efficiency for all contrasts of interest via
    %   eff = (c' (X'X)?{-1} c)?{-1} (from denominator of t-contrast)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    nCols = size(X,2);
    for iCond = 1:nConds
        c = zeros(nCols,1);
        c(indCondArray(iCond)) = 1;
        eff(n,iCond) = 1/(c'*pinv(X'*X)*c);
    end
    if options.dispDesignEfficiency
        fprintf(' %5.3f ', eff(n,:));fprintf('\n');
    end
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. Save Results to meaningful file for later recovery
%   results_eff_analysis_nNullTrials<nNullTrials>_durWager<durWager>.mat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n');
save(fullfile(pathRoot, sprintf('results_eff_analysis_nNullTrials%d_durWager%s.mat', ...
    nNullTrialsArray(1), regexprep(sprintf('%3.1f',durWagerArray(1)),'\.','c'))), ...
    'eff', 'itiArrayOut', 'durWagerOut', 'nNullTrialsGrid', 'durWagerGrid');


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5. Plot efficiency distribution over all considered configurations
% for contrasts of interest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if options.plotEfficiencyResults
    plot_efficiency_2d(eff,nNullTrialsGrid, durWagerGrid, nItiJittersGrid)
%         iCondArray = 1:size(eff,2);
%        plot_efficiency_results(eff, nNullTrialsGrid, durWagerGrid, iCondArray)
end
