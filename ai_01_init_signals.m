%% ai_01_init_signals.m
% Creates 10-second reference trajectories for Project 2 / Task 2.
%
% Set task2_experiment before running this script to choose the trajectory:
%   task2_experiment = 'smooth_lissajous';
%   task2_experiment = 'diagonal_pick_place';
%   task2_experiment = 'axis_sequential';
%
% If task2_experiment is not set, the first experiment is used.

clear xd yd zd xd_ref yd_ref zd_ref t task2_reference_meta

cfg = ai_config();

if ~exist('task2_experiment','var') || isempty(task2_experiment)
    task2_experiment = cfg.task2.experiments{1};
end

[t, xd, yd, zd, task2_reference_meta] = local_make_task2_reference(cfg, task2_experiment);
local_validate_reference(cfg, t, xd, yd, zd, task2_reference_meta.name);

xd_ref = timeseries(xd, t);
yd_ref = timeseries(yd, t);
zd_ref = timeseries(zd, t);

fprintf('Reference signals created for experiment: %s\n', task2_reference_meta.name);
fprintf('Duration = %.2f s, dt = %.4f s\n', t(end), cfg.sampleTime);
fprintf('Workspace stroke L = %.4f m\n', cfg.task2.strokeM);
fprintf('Workspace volume = %.4f m^3\n', cfg.task2.strokeM^3);

if cfg.showReferencePlot
    figure;
    plot(t, xd, t, yd, t, zd);
    grid on;
    xlabel('Time [s]');
    ylabel('Position [m]');
    legend('x_d', 'y_d', 'z_d');
    title(['Reference Trajectories: ' task2_reference_meta.name]);
end

function [t, xd, yd, zd, meta] = local_make_task2_reference(cfg, experimentName)
    T = str2double(cfg.stopTime);
    dt = cfg.sampleTime;
    L = cfg.task2.strokeM;
    t = (0:dt:T)';

    if isnumeric(experimentName)
        experimentName = cfg.task2.experiments{experimentName};
    end

    experimentName = char(experimentName);
    sT = t / T;

    switch lower(experimentName)
        case 'smooth_lissajous'
            xd = (L/2) * (1 - cos(2*pi*sT));
            yd = (L/2) * (1 - cos(2*pi*sT + 2*pi/3));
            zd = (L/2) * (1 - cos(2*pi*sT + 4*pi/3));

        case 'diagonal_pick_place'
            s = local_smoothstep(sT);
            xd = L * (0.10 + 0.80*s);
            yd = L * (0.85 - 0.70*s);
            zd = L * (0.20 + 0.60*s);

        case 'axis_sequential'
            third = T / 3;
            sx = local_smoothstep(t / third);
            sy = local_smoothstep((t - third) / third);
            sz = local_smoothstep((t - 2*third) / third);

            xd = L * (0.20 + 0.60*sx);
            yd = L * (0.20 + 0.60*sy);
            zd = L * (0.20 + 0.60*sz);

        otherwise
            error('Unknown task2_experiment "%s". Run ai_00_task2_workflow for valid names.', experimentName);
    end

    meta.name = experimentName;
    meta.durationS = T;
    meta.sampleTimeS = dt;
    meta.workspaceStrokeM = L;
    meta.workspaceVolumeM3 = L^3;
end

function y = local_smoothstep(x)
    x = min(max(x, 0), 1);
    y = x.^2 .* (3 - 2*x);
end

function local_validate_reference(cfg, t, xd, yd, zd, experimentName)
    T = str2double(cfg.stopTime);
    L = cfg.task2.strokeM;
    tol = 1e-9;

    if isempty(t) || abs(t(1)) > tol || abs(t(end) - T) > tol
        error('Reference "%s" must run from 0 to %.6g s.', experimentName, T);
    end

    if any(~isfinite([t(:); xd(:); yd(:); zd(:)]))
        error('Reference "%s" contains non-finite values.', experimentName);
    end

    if any([xd(:); yd(:); zd(:)] < -tol) || any([xd(:); yd(:); zd(:)] > L + tol)
        error('Reference "%s" leaves the [0, %.6g] m workspace stroke.', experimentName, L);
    end
end
