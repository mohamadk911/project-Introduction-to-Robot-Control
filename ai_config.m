function cfg = ai_config()
% Central configuration file for AI + VS Code + MATLAB workflow.

cfg.model = 'robot_control_model';   % Simulink model filename without the .slx extension

cfg.stopTime = '10';
cfg.sampleTime = 0.01;
cfg.showReferencePlot = false;

cfg.reportsDir   = 'ai_reports';
cfg.resultsDir   = 'ai_results';
cfg.snapshotsDir = 'ai_snapshots';

% IU Robot Control / Project 2 / Task 2 design constants.
cfg.task2.totalMassKg = 15.0;
cfg.task2.workspaceVolumeM3 = 3.0;
cfg.task2.strokeM = nthroot(cfg.task2.workspaceVolumeM3, 3);
cfg.task2.rodThicknessM = 0.08;
cfg.task2.carriageDimsM = [0.15 0.15 0.20];
cfg.task2.rodMassKg = 3.0;
cfg.task2.carriageMassKg = 1.5;
cfg.task2.gripperMassKg = 1.5;

% The current model uses Simscape frame transforms before some rods.
% X rod is long in local +X. Y rod is long in local +Y.
% Z rod is also long in local +Y in this model, then rotated/aligned by
% Mount_Zrod / Tx_align-style transforms. If rebuilding with no transform,
% use [thickness thickness stroke] so the rod is long in local +Z.
cfg.task2.rodDimsM.x = [cfg.task2.strokeM cfg.task2.rodThicknessM cfg.task2.rodThicknessM];
cfg.task2.rodDimsM.y = [cfg.task2.rodThicknessM cfg.task2.strokeM cfg.task2.rodThicknessM];
cfg.task2.rodDimsM.z_current_model = [cfg.task2.rodThicknessM cfg.task2.strokeM cfg.task2.rodThicknessM];
cfg.task2.rodDimsM.z_no_transform = [cfg.task2.rodThicknessM cfg.task2.rodThicknessM cfg.task2.strokeM];

% Initial decentralized PID gains for force-actuated prismatic joints.
% These replace the default-looking P=1, I=1, D=0 loops on X/Y and keep
% all axes consistent with the already-tuned Z-axis controller.
cfg.task2.pid.P = 500;
cfg.task2.pid.I = 50;
cfg.task2.pid.D = 80;
cfg.task2.pid.N = 100;
cfg.task2.randomVariationFraction = 0.05;

cfg.task2.experiments = { ...
    'smooth_lissajous', ...
    'diagonal_pick_place', ...
    'axis_sequential' ...
};

if ~exist(cfg.reportsDir,'dir')
    mkdir(cfg.reportsDir);
end

if ~exist(cfg.resultsDir,'dir')
    mkdir(cfg.resultsDir);
end

if ~exist(cfg.snapshotsDir,'dir')
    mkdir(cfg.snapshotsDir);
end
end
