%% ai_04_run_simulation.m
% Runs the three Task 2 reference experiments and saves simulation outputs.
%
% Optional before running:
%   task2_experiments_to_run = {'smooth_lissajous'};
%
% For RMSE, first apply logging blocks with:
%   ai_07_prepare_task2_model('apply-no-save')
% or, after explicit approval:
%   ai_07_prepare_task2_model('apply-and-save')

cfg = ai_config();
model = cfg.model;

if ~exist('task2_experiments_to_run','var') || isempty(task2_experiments_to_run)
    task2_experiments_to_run = cfg.task2.experiments;
end

if ischar(task2_experiments_to_run) || isstring(task2_experiments_to_run)
    task2_experiments_to_run = cellstr(task2_experiments_to_run);
end

load_system(model);
local_safe_set(model, 'StopTime', cfg.stopTime);
local_safe_set(model, 'ReturnWorkspaceOutputs', 'on');

logFile = fullfile(cfg.resultsDir, 'last_simulation_log.txt');
diary(logFile);

fprintf('SIMULATION RUN\n');
fprintf('Model: %s\n', model);
fprintf('Started: %s\n\n', datestr(now));

try
    allSimOut = struct();

    for i = 1:numel(task2_experiments_to_run)
        task2_experiment = task2_experiments_to_run{i};
        fprintf('\nExperiment %d/%d: %s\n', i, numel(task2_experiments_to_run), task2_experiment);

        ai_01_init_signals;

        simOut = sim(model);
        task2_last_simOut = simOut;

        safeName = matlab.lang.makeValidName(task2_reference_meta.name);
        allSimOut.(safeName) = simOut;

        resultFile = fullfile(cfg.resultsDir, ['simulation_output_' safeName '.mat']);
        save(resultFile, 'simOut', 'task2_reference_meta');
        fprintf('Saved output to: %s\n', resultFile);
    end

    resultFile = fullfile(cfg.resultsDir, 'last_simulation_output.mat');
    save(resultFile, 'simOut', 'allSimOut', 'task2_reference_meta');

    fprintf('\nSimulation batch completed successfully.\n');
    fprintf('Saved last output to: %s\n', resultFile);

catch ME
    fprintf('\nSIMULATION ERROR\n');
    fprintf('Message: %s\n', ME.message);

    if ~isempty(ME.stack)
        fprintf('\nStack:\n');
        for i = 1:numel(ME.stack)
            fprintf('%s, line %d\n', ME.stack(i).name, ME.stack(i).line);
        end
    end
end

fprintf('\nFinished: %s\n', datestr(now));
diary off;

fprintf('Simulation log saved to:\n%s\n', logFile);

function local_safe_set(blockPath, paramName, paramValue)
    try
        set_param(blockPath, paramName, paramValue);
    catch ME
        warning('Could not set %s on %s: %s', paramName, blockPath, ME.message);
    end
end
