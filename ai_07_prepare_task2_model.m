function status = ai_07_prepare_task2_model(mode)
%AI_07_PREPARE_TASK2_MODEL Configure the Simulink PPP robot for Task 2.
%
% This script edits the loaded Simulink model only when mode is explicit.
% It does not save the .slx unless mode is 'apply-and-save'.
%
% Modes:
%   'dry-run'        Preview the operations. Default.
%   'apply-no-save'  Apply to the loaded model, do not save.
%   'apply-and-save' Apply to the loaded model and save the .slx.

if nargin < 1 || isempty(mode)
    mode = 'dry-run';
end

mode = validatestring(mode, {'dry-run', 'apply-no-save', 'apply-and-save'});
applyChanges = ~strcmp(mode, 'dry-run');
saveChanges = strcmp(mode, 'apply-and-save');

cfg = ai_config();
model = cfg.model;
subsys = [model '/Animation_Simscape'];

status = struct();
status.mode = mode;
status.operations = {};
status.warnings = {};

fprintf('\nTASK 2 MODEL PREPARATION\n');
fprintf('Mode: %s\n', mode);
fprintf('Model: %s\n', model);
fprintf('No .slx save will occur unless mode is apply-and-save.\n\n');

if saveChanges && ~local_save_already_confirmed()
    confirmText = input('Type SAVE_TASK2_MODEL to apply changes and save the .slx: ', 's');
    if ~strcmp(confirmText, 'SAVE_TASK2_MODEL')
        status = local_note(status, 'Save confirmation not received. No model changes were applied.');
        fprintf('Confirmation not received. No model changes applied or saved.\n\n');
        return;
    end
end

load_system(model);

axisMap = local_axis_map(subsys);

status = local_note(status, 'Set model stop time to 10 s and keep single-output simulation logging available.');
if applyChanges
    local_safe_set(model, 'StopTime', cfg.stopTime);
    local_safe_set(model, 'ReturnWorkspaceOutputs', 'on');
end

status = local_configure_reference_blocks(axisMap, status, applyChanges);
status = local_configure_robot_parameters(cfg, axisMap, status, applyChanges);
status = local_configure_control_connections(axisMap, status, applyChanges);
status = local_configure_logging(axisMap, status, applyChanges);

if saveChanges
    save_system(model);
    status = local_note(status, 'Saved configured Simulink model.');
elseif applyChanges
    status = local_note(status, 'Applied changes to the loaded model only. Save manually or rerun with apply-and-save after approval.');
else
    status = local_note(status, 'Dry run completed. No model changes were made.');
end

fprintf('\nOperations:\n');
for i = 1:numel(status.operations)
    fprintf('  - %s\n', status.operations{i});
end

if ~isempty(status.warnings)
    fprintf('\nWarnings:\n');
    for i = 1:numel(status.warnings)
        fprintf('  - %s\n', status.warnings{i});
    end
end

fprintf('\n');
end

function axisMap = local_axis_map(subsys)
    nl = sprintf('\n');

    axisMap = struct([]);

    axisMap(1).axis = 'x';
    axisMap(1).refVar = 'xd_ref';
    axisMap(1).actualVar = 'x_actual';
    axisMap(1).velocityVar = 'x_velocity';
    axisMap(1).errorVar = 'x_error';
    axisMap(1).refLogVar = 'x_ref_log';
    axisMap(1).forceVar = 'x_force_cmd';
    axisMap(1).joint = [subsys '/x_prismatic'];
    axisMap(1).rod = [subsys '/X-axis-rod'];
    axisMap(1).carriage = [subsys '/X_Joint'];
    axisMap(1).pid = [subsys '/PID Controller2'];
    axisMap(1).sum = [subsys '/Sum'];
    axisMap(1).refBlock = local_source_block_for_port(axisMap(1).sum, 1, local_find_from_workspace(subsys, axisMap(1).refVar, [subsys '/From' nl 'Workspace']));
    axisMap(1).psConverter = local_source_block_for_port(axisMap(1).sum, 2, [subsys '/PS-Simulink' nl 'Converter']);
    axisMap(1).forceConverter = local_destination_block_for_port(axisMap(1).pid, 1, [subsys '/Simulink-PS' nl 'Converter'], 'Simulink-PS');

    axisMap(2).axis = 'y';
    axisMap(2).refVar = 'yd_ref';
    axisMap(2).actualVar = 'y_actual';
    axisMap(2).velocityVar = 'y_velocity';
    axisMap(2).errorVar = 'y_error';
    axisMap(2).refLogVar = 'y_ref_log';
    axisMap(2).forceVar = 'y_force_cmd';
    axisMap(2).joint = [subsys '/y_prismatic'];
    axisMap(2).rod = [subsys '/Y_axis_rod'];
    axisMap(2).carriage = [subsys '/Y_joint'];
    axisMap(2).pid = [subsys '/PID Controller1'];
    axisMap(2).sum = [subsys '/Sum2'];
    axisMap(2).refBlock = local_source_block_for_port(axisMap(2).sum, 1, local_find_from_workspace(subsys, axisMap(2).refVar, [subsys '/From' nl 'Workspace2']));
    axisMap(2).psConverter = local_source_block_for_port(axisMap(2).sum, 2, [subsys '/PS-Simulink' nl 'Converter2']);
    axisMap(2).forceConverter = local_destination_block_for_port(axisMap(2).pid, 1, [subsys '/Simulink-PS' nl 'Converter1'], 'Simulink-PS');

    axisMap(3).axis = 'z';
    axisMap(3).refVar = 'zd_ref';
    axisMap(3).actualVar = 'z_actual';
    axisMap(3).velocityVar = 'z_velocity';
    axisMap(3).errorVar = 'z_error';
    axisMap(3).refLogVar = 'z_ref_log';
    axisMap(3).forceVar = 'z_force_cmd';
    axisMap(3).joint = [subsys '/z_prismatic'];
    axisMap(3).rod = [subsys '/Z_axis_rod'];
    axisMap(3).carriage = [subsys '/Z_joint'];
    axisMap(3).pid = [subsys '/PID Controller3'];
    axisMap(3).sum = [subsys '/Sum1'];
    axisMap(3).refBlock = local_source_block_for_port(axisMap(3).sum, 1, local_find_from_workspace(subsys, axisMap(3).refVar, [subsys '/From' nl 'Workspace1']));
    axisMap(3).psConverter = local_source_block_for_port(axisMap(3).sum, 2, [subsys '/PS-Simulink' nl 'Converter1']);
    axisMap(3).forceConverter = local_destination_block_for_port(axisMap(3).pid, 1, [subsys '/Simulink-PS' nl 'Converter3'], 'Simulink-PS');
end

function status = local_configure_reference_blocks(axisMap, status, applyChanges)
    status = local_note(status, 'Configure x/y/z From Workspace blocks to use xd_ref, yd_ref, zd_ref timeseries.');

    for i = 1:numel(axisMap)
        ax = axisMap(i);

        if applyChanges
            local_safe_set(ax.refBlock, 'VariableName', ax.refVar);
            local_safe_set(ax.refBlock, 'SampleTime', '-1');
            local_safe_set(ax.refBlock, 'Interpolate', 'on');
            local_safe_set(ax.refBlock, 'ZeroCross', 'on');
            local_safe_set(ax.refBlock, 'OutputAfterFinalValue', 'Extrapolation');
        end
    end
end

function status = local_configure_robot_parameters(cfg, axisMap, status, applyChanges)
    L = cfg.task2.strokeM;
    pid = cfg.task2.pid;

    rodDims.x = cfg.task2.rodDimsM.x;
    rodDims.y = cfg.task2.rodDimsM.y;
    rodDims.z = cfg.task2.rodDimsM.z_current_model;

    for i = 1:numel(axisMap)
        ax = axisMap(i);

        status = local_note(status, sprintf('Configure %s prismatic joint as force input with p/v sensing and [0, %.4f] m limits.', upper(ax.axis), L));
        status = local_note(status, sprintf('Set %s error Sum block to reference minus measured position.', upper(ax.axis)));
        status = local_note(status, sprintf('Set %s-axis PID to P=%g, I=%g, D=%g, N=%g.', upper(ax.axis), pid.P, pid.I, pid.D, pid.N));
        status = local_note(status, sprintf('Set %s feedback converter to m and force converter to N.', upper(ax.axis)));
        status = local_note(status, sprintf('Set %s rod/carriage masses and dimensions for total robot mass bookkeeping.', upper(ax.axis)));

        if applyChanges
            local_safe_set(ax.sum, 'Inputs', '|+-');

            local_safe_set(ax.joint, 'LowerLimitSpecify', 'on');
            local_safe_set(ax.joint, 'LowerLimitBound', '0');
            local_safe_set(ax.joint, 'UpperLimitSpecify', 'on');
            local_safe_set(ax.joint, 'UpperLimitBound', sprintf('%.12g', L));
            local_safe_set(ax.joint, 'TorqueActuationMode', 'InputTorque');
            local_safe_set(ax.joint, 'MotionActuationMode', 'ComputedMotion');
            local_safe_set(ax.joint, 'SensePosition', 'on');
            local_safe_set(ax.joint, 'SenseVelocity', 'on');
            local_safe_set(ax.joint, 'SenseAcceleration', 'off');
            local_safe_set(ax.joint, 'SpringStiffness', '0');
            local_safe_set(ax.joint, 'DampingCoefficient', '0');

            local_safe_set(ax.pid, 'Controller', 'PID');
            local_safe_set(ax.pid, 'Form', 'Parallel');
            local_safe_set(ax.pid, 'TimeDomain', 'Continuous-time');
            local_safe_set(ax.pid, 'P', sprintf('%.12g', pid.P));
            local_safe_set(ax.pid, 'I', sprintf('%.12g', pid.I));
            local_safe_set(ax.pid, 'D', sprintf('%.12g', pid.D));
            local_safe_set(ax.pid, 'N', sprintf('%.12g', pid.N));

            local_safe_set(ax.psConverter, 'Unit', 'm');
            local_safe_set(ax.forceConverter, 'Unit', 'N');

            local_safe_set(ax.rod, 'BrickDimensions', mat2str(rodDims.(ax.axis)));
            local_safe_set(ax.rod, 'Mass', sprintf('%.12g', cfg.task2.rodMassKg));
            local_safe_set(ax.carriage, 'BrickDimensions', mat2str(cfg.task2.carriageDimsM));
            local_safe_set(ax.carriage, 'Mass', sprintf('%.12g', cfg.task2.carriageMassKg));
        end
    end

    status = local_note(status, sprintf('Set gripper mass to %.1f kg; rods 3 x %.1f kg; carriages 3 x %.1f kg; total %.1f kg.', ...
        cfg.task2.gripperMassKg, cfg.task2.rodMassKg, cfg.task2.carriageMassKg, cfg.task2.totalMassKg));

    if applyChanges
        gripper = [get_param(axisMap(1).joint, 'Parent') '/Gripper'];
        local_safe_set(gripper, 'Mass', sprintf('%.12g', cfg.task2.gripperMassKg));
    end
end

function status = local_configure_control_connections(axisMap, status, applyChanges)
    status = local_note(status, 'Verify/connect reference, measured-position feedback, PID, and force-converter signal lines.');

    for i = 1:numel(axisMap)
        ax = axisMap(i);
        sys = get_param(ax.joint, 'Parent');

        if applyChanges
            local_connect_if_missing(sys, ax.refBlock, 1, ax.sum, 1);
            local_connect_if_missing(sys, ax.psConverter, 1, ax.sum, 2);
            local_connect_if_missing(sys, ax.sum, 1, ax.pid, 1);
            local_connect_if_missing(sys, ax.pid, 1, ax.forceConverter, 1);
        end
    end
end

function status = local_configure_logging(axisMap, status, applyChanges)
    status = local_note(status, 'Add To Workspace taps for x/y/z actual positions, velocities, tracking errors, references, and PID force commands.');

    for i = 1:numel(axisMap)
        ax = axisMap(i);
        sys = get_param(ax.joint, 'Parent');
        baseX = 210 + 120*i;
        y0 = -150;

        actualLogger = [sys '/Task2_' ax.axis '_actual_log'];
        velocityConverter = [sys '/Task2_' ax.axis '_velocity_converter'];
        velocityLogger = [sys '/Task2_' ax.axis '_velocity_log'];
        errorLogger = [sys '/Task2_' ax.axis '_error_log'];
        refLogger = [sys '/Task2_' ax.axis '_ref_log'];
        forceLogger = [sys '/Task2_' ax.axis '_force_log'];

        if applyChanges
            local_add_to_workspace(actualLogger, ax.actualVar, [baseX y0 baseX+95 y0+28]);
            local_add_velocity_logging(ax, velocityConverter, velocityLogger, [baseX y0+45 baseX+95 y0+73], [baseX+115 y0+45 baseX+210 y0+73]);
            local_add_to_workspace(errorLogger, ax.errorVar, [baseX y0+90 baseX+95 y0+118]);
            local_add_to_workspace(refLogger, ax.refLogVar, [baseX y0+135 baseX+95 y0+163]);
            local_add_to_workspace(forceLogger, ax.forceVar, [baseX y0+180 baseX+95 y0+208]);

            local_connect_if_missing(sys, ax.psConverter, 1, actualLogger, 1);
            local_connect_if_missing(sys, ax.sum, 1, errorLogger, 1);
            local_connect_if_missing(sys, ax.refBlock, 1, refLogger, 1);
            local_connect_if_missing(sys, ax.pid, 1, forceLogger, 1);
        end
    end
end

function local_add_velocity_logging(ax, converterBlock, loggerBlock, converterPosition, loggerPosition)
    sys = get_param(ax.joint, 'Parent');

    if ~local_block_exists(converterBlock)
        add_block(ax.psConverter, converterBlock, 'Position', converterPosition);
    end

    local_safe_set(converterBlock, 'Unit', 'm/s');
    local_add_to_workspace(loggerBlock, ax.velocityVar, loggerPosition);
    local_connect_if_missing(sys, converterBlock, 1, loggerBlock, 1);

    if ~local_connect_unused_joint_signal(sys, ax.joint, converterBlock)
        warning('Could not auto-connect velocity sensing for %s. Connect the unused v output of %s to %s manually if needed.', ...
            upper(ax.axis), ax.joint, converterBlock);
    end
end

function local_add_to_workspace(blockPath, variableName, position)
    if ~local_block_exists(blockPath)
        add_block('simulink/Sinks/To Workspace', blockPath, 'Position', position);
    end

    local_safe_set(blockPath, 'VariableName', variableName);
    local_safe_set(blockPath, 'SaveFormat', 'Timeseries');
    local_safe_set(blockPath, 'LimitDataPoints', 'off');
    local_safe_set(blockPath, 'Decimation', '1');
    local_safe_set(blockPath, 'SampleTime', '-1');
end

function connected = local_connect_unused_joint_signal(sys, jointBlock, converterBlock)
    connected = false;

    if ~local_block_exists(jointBlock) || ~local_block_exists(converterBlock)
        return;
    end

    dstPort = local_first_converter_input_port(converterBlock);
    if isempty(dstPort)
        return;
    end

    try
        if get_param(dstPort, 'Line') ~= -1
            connected = true;
            return;
        end
    catch
    end

    srcPorts = local_candidate_output_ports(jointBlock);
    for i = 1:numel(srcPorts)
        srcPort = srcPorts(i);

        try
            if get_param(srcPort, 'Line') ~= -1
                continue;
            end
        catch
            continue;
        end

        try
            add_line(sys, srcPort, dstPort, 'autorouting', 'on');
            connected = true;
            return;
        catch
        end
    end
end

function port = local_first_converter_input_port(blockPath)
    port = [];

    try
        ports = get_param(blockPath, 'PortHandles');
    catch
        return;
    end

    candidateFields = {'LConn', 'Inport'};
    for f = 1:numel(candidateFields)
        fieldName = candidateFields{f};
        if isfield(ports, fieldName) && ~isempty(ports.(fieldName))
            port = ports.(fieldName)(1);
            return;
        end
    end
end

function portsOut = local_candidate_output_ports(blockPath)
    portsOut = [];

    try
        ports = get_param(blockPath, 'PortHandles');
    catch
        return;
    end

    candidateFields = {'Outport', 'RConn', 'LConn'};
    for f = 1:numel(candidateFields)
        fieldName = candidateFields{f};
        if isfield(ports, fieldName) && ~isempty(ports.(fieldName))
            portsOut = [portsOut ports.(fieldName)]; %#ok<AGROW>
        end
    end
end

function local_connect_if_missing(sys, srcBlock, srcPort, dstBlock, dstPort)
    if ~local_block_exists(srcBlock) || ~local_block_exists(dstBlock)
        warning('Cannot connect missing block: %s -> %s', srcBlock, dstBlock);
        return;
    end

    srcHandle = local_output_port(srcBlock, srcPort);
    dstHandle = local_input_port(dstBlock, dstPort);

    if isempty(srcHandle) || isempty(dstHandle)
        warning('Cannot find port handles for connection: %s/%d -> %s/%d', srcBlock, srcPort, dstBlock, dstPort);
        return;
    end

    existingLine = get_param(dstHandle, 'Line');

    if existingLine ~= -1
        return;
    end

    add_line(sys, srcHandle, dstHandle, 'autorouting', 'on');
end

function port = local_input_port(blockPath, inputIndex)
    port = [];

    try
        ports = get_param(blockPath, 'PortHandles');
    catch
        return;
    end

    if isfield(ports, 'Inport') && numel(ports.Inport) >= inputIndex
        port = ports.Inport(inputIndex);
    end
end

function port = local_output_port(blockPath, outputIndex)
    port = [];

    try
        ports = get_param(blockPath, 'PortHandles');
    catch
        return;
    end

    if isfield(ports, 'Outport') && numel(ports.Outport) >= outputIndex
        port = ports.Outport(outputIndex);
    end
end

function srcBlock = local_source_block_for_port(dstBlock, dstPort, fallbackBlock)
    srcBlock = fallbackBlock;

    try
        ports = get_param(dstBlock, 'PortHandles');
        lineHandle = get_param(ports.Inport(dstPort), 'Line');

        if lineHandle == -1
            return;
        end

        srcHandle = get_param(lineHandle, 'SrcBlockHandle');
        if srcHandle ~= -1
            srcBlock = getfullname(srcHandle);
        end
    catch
    end
end

function dstBlock = local_destination_block_for_port(srcBlock, srcPort, fallbackBlock, preferredMask)
    dstBlock = fallbackBlock;

    try
        ports = get_param(srcBlock, 'PortHandles');
        lineHandle = get_param(ports.Outport(srcPort), 'Line');

        if lineHandle == -1
            return;
        end

        dstHandles = get_param(lineHandle, 'DstBlockHandle');
        for i = 1:numel(dstHandles)
            if dstHandles(i) == -1
                continue;
            end

            candidate = getfullname(dstHandles(i));
            try
                maskType = get_param(candidate, 'MaskType');
            catch
                maskType = '';
            end

            if contains(maskType, preferredMask)
                dstBlock = candidate;
                return;
            end
        end

        if ~isempty(dstHandles) && dstHandles(1) ~= -1
            dstBlock = getfullname(dstHandles(1));
        end
    catch
    end
end

function blockPath = local_find_from_workspace(subsys, variableName, fallbackBlock)
    blockPath = fallbackBlock;

    try
        candidates = find_system(subsys, 'SearchDepth', 1, 'BlockType', 'FromWorkspace');
        for i = 1:numel(candidates)
            try
                if strcmp(get_param(candidates{i}, 'VariableName'), variableName)
                    blockPath = candidates{i};
                    return;
                end
            catch
            end
        end
    catch
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

function status = local_note(status, msg)
    status.operations{end+1} = msg;
end

function confirmed = local_save_already_confirmed()
    confirmed = false;

    try
        confirmed = evalin('base', 'exist(''task2_model_save_confirmed'', ''var'') && task2_model_save_confirmed');
    catch
        confirmed = false;
    end
end
