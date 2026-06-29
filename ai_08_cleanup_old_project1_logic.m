function status = ai_08_cleanup_old_project1_logic(mode)
%AI_08_CLEANUP_OLD_PROJECT1_LOGIC Review or remove inherited open-loop logic.
%
% Modes:
%   'dry-run'        List old blocks. Default.
%   'comment-no-save' Comment old blocks in the loaded model, do not save.
%   'delete-no-save'  Delete old blocks after DELETE_OLD_PROJECT1 confirmation, do not save.
%   'delete-and-save' Delete old blocks after DELETE_AND_SAVE_OLD_PROJECT1 confirmation and save the .slx.
%
% What to keep from the old working design:
%   - independent x/y/z axis thinking
%   - simple reference names and saturation/limit awareness
%
% What not to use for Task 2:
%   - root-level open-loop q*_ddot -> velocity_* -> position_* plant
%   - root-level x/y/z outputs for RMSE
%
% Do not run destructive modes until the Simscape PPP logging/control path
% has been checked visually in Simulink.

if nargin < 1 || isempty(mode)
    mode = 'dry-run';
end

mode = validatestring(mode, {'dry-run', 'comment-no-save', 'delete-no-save', 'delete-and-save'});

cfg = ai_config();
model = cfg.model;
load_system(model);

oldBlocks = local_old_project1_blocks(model);
existing = oldBlocks(cellfun(@local_block_exists, oldBlocks));

status.mode = mode;
status.oldBlocks = existing;

fprintf('\nOLD PROJECT 1 LOGIC REVIEW\n');
fprintf('Mode: %s\n', mode);
fprintf('These root-level blocks belong to the inherited open-loop double-integrator design:\n');
for i = 1:numel(existing)
    fprintf('  - %s\n', existing{i});
end

fprintf('\nLessons carried forward from old design:\n');
fprintf('  - Keep decentralized x/y/z channels; that maps well to PPP control.\n');
fprintf('  - Keep explicit stroke limits; now enforce them on the Simscape prismatic joints.\n');
fprintf('  - Replace the open-loop double-integrator plant with measured Simscape joint positions.\n');

switch mode
    case 'dry-run'
        fprintf('\nDry run only. No model changes made.\n');

    case 'comment-no-save'
        for i = 1:numel(existing)
            local_safe_set(existing{i}, 'Commented', 'on');
        end
        fprintf('\nCommented old blocks in the loaded model only. Not saved.\n');

    case {'delete-no-save', 'delete-and-save'}
        if ~isempty(existing)
            if strcmp(mode, 'delete-and-save')
                confirmPhrase = 'DELETE_AND_SAVE_OLD_PROJECT1';
            else
                confirmPhrase = 'DELETE_OLD_PROJECT1';
            end

            confirmText = input(sprintf('Type %s to continue: ', confirmPhrase), 's');
            if ~strcmp(confirmText, confirmPhrase)
                fprintf('\nConfirmation not received. No blocks deleted.\n\n');
                return;
            end
        end

        for i = 1:numel(existing)
            delete_block(existing{i});
        end

        fprintf('\nDeleted old blocks from the loaded model.\n');

        if strcmp(mode, 'delete-and-save')
            save_system(model);
            fprintf('Saved model after deletion.\n');
        else
            fprintf('Not saved. Save manually only after visual verification.\n');
        end
end

fprintf('\nKeep Animation_Simscape and its PID/prismatic-joint path. That is the Task 2 controlled PPP robot.\n\n');
end

function blocks = local_old_project1_blocks(model)
    names = { ...
        sprintf('From\nWorkspace'), ...
        sprintf('From\nWorkspace1'), ...
        sprintf('From\nWorkspace2'), ...
        'Saturation', ...
        'Saturation1', ...
        'Saturation2', ...
        'constant1', ...
        'constant2', ...
        'constant3', ...
        'q1_ddot', ...
        'q2_ddot', ...
        'q3_ddot', ...
        'velocity_1', ...
        'velocity_2', ...
        'velocity_3', ...
        'position_1', ...
        'position_2', ...
        'position_3', ...
        'q1', ...
        'q2', ...
        'q3', ...
        'x', ...
        'y', ...
        'z', ...
        'roll', ...
        'pitch', ...
        'yaw' ...
    };

    blocks = cell(size(names));
    for i = 1:numel(names)
        blocks{i} = [model '/' names{i}];
    end
end

function ok = local_block_exists(blockPath)
    try
        get_param(blockPath, 'Handle');
        ok = true;
    catch
        ok = false;
    end
end

function local_safe_set(blockPath, paramName, paramValue)
    try
        set_param(blockPath, paramName, paramValue);
    catch ME
        warning('Could not set %s on %s: %s', paramName, blockPath, ME.message);
    end
end
