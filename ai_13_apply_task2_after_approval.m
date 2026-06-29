%% ai_13_apply_task2_after_approval.m
% Applies and saves the Task 2 Simulink setup after explicit MATLAB approval.
%
% This is the only convenience script that intentionally saves the .slx.
% It requires typing APPLY_TASK2 in the MATLAB Command Window.

cfg = ai_config();

fprintf('\nAPPLY TASK 2 SIMULINK SETUP\n');
fprintf('Model: %s\n', cfg.model);
fprintf('This will add/configure Task 2 blocks and save the .slx.\n');
fprintf('It will not delete old Project 1 root blocks.\n');
fprintf('Old cleanup remains a separate deliberate step: ai_08_cleanup_old_project1_logic(''dry-run'').\n\n');

confirmText = input('Type APPLY_TASK2 to apply and save the Simulink model: ', 's');

if ~strcmp(confirmText, 'APPLY_TASK2')
    fprintf('Confirmation not received. No model changes saved.\n');
    return;
end

task2_model_save_confirmed = true;
try
    ai_07_prepare_task2_model('apply-and-save');
catch ME
    clear task2_model_save_confirmed
    rethrow(ME);
end
clear task2_model_save_confirmed

ai_11_check_task2_setup;

fprintf('\nTask 2 setup was applied and saved.\n');
fprintf('Next safe checks:\n');
fprintf('  ai_04_run_simulation\n');
fprintf('  ai_05_find_logged_signals\n');
fprintf('  ai_09_compute_rmse\n\n');
