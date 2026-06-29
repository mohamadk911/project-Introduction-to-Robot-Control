%% ai_00_task2_workflow.m
% Ordered Task 2 MATLAB/Simulink workflow.
%
% This file is intentionally non-destructive. It prints the intended order
% and the model-changing scripts keep dry-run defaults.

cfg = ai_config();

fprintf('\nTASK 2 PPP ROBOT CONTROL WORKFLOW\n');
fprintf('Model: %s\n', cfg.model);
fprintf('Stop time: %s s\n', cfg.stopTime);
fprintf('Workspace stroke: %.4f m, volume: %.4f m^3\n', ...
    cfg.task2.strokeM, cfg.task2.workspaceVolumeM3);
fprintf('Total target mass: %.1f kg\n\n', cfg.task2.totalMassKg);

fprintf('Recommended order:\n');
fprintf('  1. ai_01_init_signals.m\n');
fprintf('     Create one of the three 10 s reference trajectories.\n');
fprintf('  2. ai_07_prepare_task2_model(''dry-run'')\n');
fprintf('     Preview Task 2 Simulink changes: references, PID, joint limits, masses, logging.\n');
fprintf('  3. With your approval only: ai_13_apply_task2_after_approval\n');
fprintf('     Type an explicit confirmation in MATLAB, then apply and save changes.\n');
fprintf('  4. ai_11_check_task2_setup\n');
fprintf('     Check applied model parameters, reference blocks, control loops, and logging.\n');
fprintf('  5. ai_08_cleanup_old_project1_logic(''dry-run'')\n');
fprintf('     Review old open-loop blocks before commenting or confirmed deletion.\n');
fprintf('  6. ai_04_run_simulation.m\n');
fprintf('     Run the three reference experiments.\n');
fprintf('  7. ai_05_find_logged_signals.m\n');
fprintf('     Confirm x/y/z actual, reference, error, velocity, and force logs exist.\n');
fprintf('  8. ai_09_compute_rmse.m\n');
fprintf('     Compute 3D tracking RMSE from logged Task 2 signals.\n');
fprintf('  9. ai_12_run_task2_campaign\n');
fprintf('     Optional after approval: run nominal plus randomized repeat simulations.\n');
fprintf(' 10. ai_10_randomize_task2_parameters(''dry-run'')\n');
fprintf('     Preview a single random +/-5%% manipulator parameter set.\n\n');

fprintf('Control and logging contract:\n');
fprintf('  Each axis is controlled independently: reference - measured p -> PID -> Simulink-PS force input.\n');
fprintf('  Position p is feedback for PID; velocity v is logged as x/y/z_velocity and is not used by the PID.\n');
fprintf('  Sum outputs are logged as x/y/z_error so tracking error is visible in Simulink.\n');
fprintf('  RMSE uses x/y/z_actual and x/y/z_ref_log; direct error logs are extra evidence.\n\n');
fprintf('  If ai_11 flags a velocity converter input, connect the unused prismatic-joint v port to Task2_*_velocity_converter.\n\n');

fprintf('Task 2 requirement coverage:\n');
fprintf('  Nominal mass %.1f kg, workspace %.1f m^3, three 10 s experiments, and random +/-%.1f%% parameter repeats are configured in ai_config.\n\n', ...
    cfg.task2.totalMassKg, cfg.task2.workspaceVolumeM3, 100*cfg.task2.randomVariationFraction);

fprintf('Rod direction notes:\n');
fprintf('  X-axis-rod: [L, %.2f, %.2f], long in local +X.\n', ...
    cfg.task2.rodThicknessM, cfg.task2.rodThicknessM);
fprintf('  Y_axis_rod: [%.2f, L, %.2f], long in local +Y.\n', ...
    cfg.task2.rodThicknessM, cfg.task2.rodThicknessM);
fprintf('  Z_axis_rod in current model: [%.2f, L, %.2f], long in local +Y then rotated by transforms.\n', ...
    cfg.task2.rodThicknessM, cfg.task2.rodThicknessM);
fprintf('  Z rod if rebuilt without transforms: [%.2f, %.2f, L], long in local +Z.\n\n', ...
    cfg.task2.rodThicknessM, cfg.task2.rodThicknessM);

fprintf('Old Project 1 logic should not drive Task 2 RMSE:\n');
fprintf('  Root-level From Workspace, constant*, q*_ddot, velocity_*, position_*, Saturation*, q* scopes, x/y/z/roll/pitch/yaw outputs.\n\n');
