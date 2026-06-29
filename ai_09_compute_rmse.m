%% ai_09_compute_rmse.m
% Computes 3D RMSE from Task 2 To Workspace logs.
%
% Requires ai_07_prepare_task2_model('apply-and-save') or equivalent
% logging blocks to produce:
%   x_actual, y_actual, z_actual
%   x_ref_log, y_ref_log, z_ref_log
% The setup also logs x_error, y_error, z_error directly from the Sum
% blocks, but this RMSE recomputes error from reference and actual position.

cfg = ai_config();

if ~exist('task2_last_simOut','var')
    resultFile = fullfile(cfg.resultsDir, 'last_simulation_output.mat');
    if exist(resultFile, 'file')
        load(resultFile, 'simOut', 'allSimOut');
    else
        error('No simOut found. Run ai_04_run_simulation after applying Task 2 logging.');
    end
else
    simOut = task2_last_simOut;
end

task2_rmse = struct();
task2_rmse.units = 'm';
task2_rmse.experiments = struct();

if exist('allSimOut', 'var') && isstruct(allSimOut) && ~isempty(fieldnames(allSimOut))
    experimentNames = fieldnames(allSimOut);
    fprintf('\nTASK 2 RMSE FOR SIMULATION BATCH\n');

    for i = 1:numel(experimentNames)
        name = experimentNames{i};
        oneRmse = local_compute_rmse(allSimOut.(name), cfg);
        task2_rmse.experiments.(name) = oneRmse;
        fprintf('%s: X %.6f m, Y %.6f m, Z %.6f m, 3D %.6f m\n', ...
            name, oneRmse.axisRmse(1), oneRmse.axisRmse(2), oneRmse.axisRmse(3), oneRmse.rmse3d);
    end
    fprintf('\n');
else
    oneRmse = local_compute_rmse(simOut, cfg);
    task2_rmse.experiments.single = oneRmse;

    fprintf('\nTASK 2 RMSE\n');
    fprintf('RMSE X = %.6f m\n', oneRmse.axisRmse(1));
    fprintf('RMSE Y = %.6f m\n', oneRmse.axisRmse(2));
    fprintf('RMSE Z = %.6f m\n', oneRmse.axisRmse(3));
    fprintf('3D RMSE = %.6f m\n\n', oneRmse.rmse3d);
end

save(fullfile(cfg.resultsDir, 'last_rmse.mat'), 'task2_rmse');

function result = local_compute_rmse(simOut, cfg)
    [xActualRaw, tActualX] = local_get_timeseries(simOut, 'x_actual');
    [yActualRaw, tActualY] = local_get_timeseries(simOut, 'y_actual');
    [zActualRaw, tActualZ] = local_get_timeseries(simOut, 'z_actual');
    [xRefRaw, tRefX] = local_get_timeseries(simOut, 'x_ref_log');
    [yRefRaw, tRefY] = local_get_timeseries(simOut, 'y_ref_log');
    [zRefRaw, tRefZ] = local_get_timeseries(simOut, 'z_ref_log');

    t = unique([tActualX(:); tActualY(:); tActualZ(:); tRefX(:); tRefY(:); tRefZ(:)]);
    t = t(t >= 0 & t <= str2double(cfg.stopTime));

    xActual = interp1(tActualX, xActualRaw, t, 'linear', 'extrap');
    yActual = interp1(tActualY, yActualRaw, t, 'linear', 'extrap');
    zActual = interp1(tActualZ, zActualRaw, t, 'linear', 'extrap');
    xRef = interp1(tRefX, xRefRaw, t, 'linear', 'extrap');
    yRef = interp1(tRefY, yRefRaw, t, 'linear', 'extrap');
    zRef = interp1(tRefZ, zRefRaw, t, 'linear', 'extrap');

    actual = [xActual(:), yActual(:), zActual(:)];
    ref = [xRef(:), yRef(:), zRef(:)];
    err = ref - actual;

    result = struct();
    result.time = t;
    result.error = err;
    result.axisRmse = sqrt(mean(err.^2, 1, 'omitnan'));
    result.rmse3d = sqrt(mean(sum(err.^2, 2), 'omitnan'));
end

function [data, time] = local_get_timeseries(simOut, name)
    value = [];

    try
        value = simOut.get(name);
    catch
    end

    if isempty(value)
        try
            value = evalin('base', name);
        catch
        end
    end

    if isempty(value)
        error('Missing logged signal "%s". Apply Task 2 logging and rerun the simulation.', name);
    end

    if isa(value, 'timeseries')
        time = value.Time;
        data = squeeze(value.Data);
    elseif isstruct(value) && isfield(value, 'time') && isfield(value, 'signals')
        time = value.time;
        data = squeeze(value.signals.values);
    else
        error('Logged signal "%s" has unsupported class: %s', name, class(value));
    end

    time = time(:);
    data = data(:);

    valid = isfinite(time) & isfinite(data);
    time = time(valid);
    data = data(valid);

    [time, order] = sort(time);
    data = data(order);

    [time, uniqueIdx] = unique(time, 'stable');
    data = data(uniqueIdx);
end
