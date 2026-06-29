%% ai_12_run_task2_campaign.m
% Runs the Task 2 nominal tests and random +/-5% repeat tests.
%
% This script changes the loaded model during the MATLAB session but does
% not save the .slx. Run it only after you decide that in-memory model
% changes are okay. Use ai_07_prepare_task2_model('apply-and-save') when
% you are ready to permanently add the logging/configuration blocks.
%
% Optional before running:
%   task2_random_repeat_count = 3;

cfg = ai_config();

if ~exist('task2_random_repeat_count', 'var') || isempty(task2_random_repeat_count)
    task2_random_repeat_count = 3;
end

task2_campaign = struct();
task2_campaign.started = datestr(now);
task2_campaign.randomRepeatCount = task2_random_repeat_count;
task2_campaign.experiments = cfg.task2.experiments;
task2_campaign.nominal = struct();
task2_campaign.random = struct([]);

fprintf('\nTASK 2 SIMULATION CAMPAIGN\n');
fprintf('Nominal run plus %d randomized repeat(s).\n', task2_random_repeat_count);
fprintf('The loaded model may change during this session; this script does not save the .slx.\n\n');

ai_07_prepare_task2_model('apply-no-save');
ai_10_randomize_task2_parameters('reset-no-save');
task2_reset_guard = onCleanup(@() ai_10_randomize_task2_parameters('reset-no-save'));

task2_campaign.setupCheck = ai_11_check_task2_setup;
if ~task2_campaign.setupCheck.pass
    error('Task 2 setup check failed. Fix the listed setup issues before running the campaign.');
end

task2_experiments_to_run = cfg.task2.experiments;
ai_04_run_simulation;
ai_09_compute_rmse;
task2_campaign.nominal.rmse = task2_rmse;

for repeatIdx = 1:task2_random_repeat_count
    fprintf('\nRANDOMIZED REPEAT %d/%d\n', repeatIdx, task2_random_repeat_count);
    variation = ai_10_randomize_task2_parameters('apply-no-save', repeatIdx);
    task2_experiments_to_run = cfg.task2.experiments;
    ai_04_run_simulation;
    ai_09_compute_rmse;

    task2_campaign.random(repeatIdx).variation = variation;
    task2_campaign.random(repeatIdx).rmse = task2_rmse;
end
% Clearing the guard restores nominal parameters on normal completion.
clear task2_reset_guard

task2_campaign.finished = datestr(now);
campaignFile = fullfile(cfg.resultsDir, 'task2_campaign_results.mat');
save(campaignFile, 'task2_campaign');

fprintf('\nTask 2 campaign saved to: %s\n\n', campaignFile);
