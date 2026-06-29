function summary = ai_11_check_task2_setup()
%AI_11_CHECK_TASK2_SETUP Check the loaded Simulink model against Task 2 setup.
%
% This is a console checker, not a report generator. It does not edit or
% save the model.

cfg = ai_config();
model = cfg.model;
subsys = [model '/Animation_Simscape'];
load_system(model);

summary = struct();
summary.pass = true;
summary.messages = {};

axisMap = local_axis_map(subsys);
rodDims.x = cfg.task2.rodDimsM.x;
rodDims.y = cfg.task2.rodDimsM.y;
rodDims.z = cfg.task2.rodDimsM.z_current_model;

fprintf('\nTASK 2 SETUP CHECK\n');
fprintf('Model: %s\n\n', model);

summary = local_check_task2_constants(summary, cfg, axisMap);
summary = local_check_param(summary, model, 'StopTime', cfg.stopTime);
summary = local_check_param(summary, model, 'ReturnWorkspaceOutputs', 'on');

for i = 1:numel(axisMap)
    ax = axisMap(i);

    summary = local_check_block(summary, ax.joint, [upper(ax.axis) ' prismatic joint']);
    summary = local_check_block(summary, ax.sum, [upper(ax.axis) ' error Sum block']);
    summary = local_check_block(summary, ax.pid, [upper(ax.axis) ' PID controller']);
    summary = local_check_block(summary, ax.rod, [upper(ax.axis) ' rod solid']);
    summary = local_check_block(summary, ax.refBlock, [upper(ax.axis) ' reference source']);
    summary = local_check_block(summary, ax.actualLogger, [upper(ax.axis) ' actual logger']);
    summary = local_check_block(summary, ax.velocityConverter, [upper(ax.axis) ' velocity converter']);
    summary = local_check_block(summary, ax.velocityLogger, [upper(ax.axis) ' velocity logger']);
    summary = local_check_block(summary, ax.errorLogger, [upper(ax.axis) ' tracking-error logger']);
    summary = local_check_block(summary, ax.refLogger, [upper(ax.axis) ' reference logger']);
    summary = local_check_block(summary, ax.forceLogger, [upper(ax.axis) ' force logger']);
    summary = local_check_block(summary, ax.psConverter, [upper(ax.axis) ' position feedback converter']);
    summary = local_check_block(summary, ax.forceConverter, [upper(ax.axis) ' force command converter']);

    if local_block_exists(ax.joint)
        summary = local_check_param(summary, ax.joint, 'LowerLimitSpecify', 'on');
        summary = local_check_numeric_param(summary, ax.joint, 'LowerLimitBound', 0, 1e-9);
        summary = local_check_param(summary, ax.joint, 'UpperLimitSpecify', 'on');
        summary = local_check_numeric_param(summary, ax.joint, 'UpperLimitBound', cfg.task2.strokeM, 1e-3);
        summary = local_check_param(summary, ax.joint, 'SensePosition', 'on');
        summary = local_check_param(summary, ax.joint, 'SenseVelocity', 'on');
        summary = local_check_param(summary, ax.joint, 'SenseAcceleration', 'off');
        summary = local_check_param(summary, ax.joint, 'TorqueActuationMode', 'InputTorque');
        summary = local_check_param(summary, ax.joint, 'MotionActuationMode', 'ComputedMotion');
        summary = local_check_numeric_param(summary, ax.joint, 'SpringStiffness', 0, 1e-9);
        summary = local_check_numeric_param(summary, ax.joint, 'DampingCoefficient', 0, 1e-9);
    end

    if local_block_exists(ax.sum)
        summary = local_check_param(summary, ax.sum, 'Inputs', '|+-');
    end

    summary = local_check_signal_connection(summary, ax.refBlock, 1, ax.sum, 1, [upper(ax.axis) ' reference feeds error Sum']);
    summary = local_check_signal_connection(summary, ax.psConverter, 1, ax.sum, 2, [upper(ax.axis) ' measured position feeds error Sum']);
    summary = local_check_signal_connection(summary, ax.sum, 1, ax.pid, 1, [upper(ax.axis) ' tracking error feeds PID']);
    summary = local_check_signal_connection(summary, ax.pid, 1, ax.forceConverter, 1, [upper(ax.axis) ' PID force command feeds Simulink-PS converter']);
    summary = local_check_output_connected_to_block(summary, ax.forceConverter, ax.joint, [upper(ax.axis) ' force converter feeds prismatic joint']);
    summary = local_check_output_connected_to_block(summary, ax.joint, ax.psConverter, [upper(ax.axis) ' joint position sensing feeds PS-Simulink converter']);

    if local_block_exists(ax.pid)
        summary = local_check_param(summary, ax.pid, 'Controller', 'PID');
        summary = local_check_param(summary, ax.pid, 'Form', 'Parallel');
        summary = local_check_param(summary, ax.pid, 'TimeDomain', 'Continuous-time');
        summary = local_check_numeric_param(summary, ax.pid, 'P', cfg.task2.pid.P, 1e-9);
        summary = local_check_numeric_param(summary, ax.pid, 'I', cfg.task2.pid.I, 1e-9);
        summary = local_check_numeric_param(summary, ax.pid, 'D', cfg.task2.pid.D, 1e-9);
        summary = local_check_numeric_param(summary, ax.pid, 'N', cfg.task2.pid.N, 1e-9);
    end

    if local_block_exists(ax.psConverter)
        summary = local_check_param(summary, ax.psConverter, 'Unit', 'm');
    end

    if local_block_exists(ax.forceConverter)
        summary = local_check_param(summary, ax.forceConverter, 'Unit', 'N');
    end

    if local_block_exists(ax.refBlock)
        summary = local_check_param(summary, ax.refBlock, 'VariableName', ax.refVar);
        summary = local_check_param(summary, ax.refBlock, 'SampleTime', '-1');
        summary = local_check_param(summary, ax.refBlock, 'Interpolate', 'on');
    end

    if local_block_exists(ax.velocityConverter)
        summary = local_check_param(summary, ax.velocityConverter, 'Unit', 'm/s');
        summary = local_check_input_connected(summary, ax.velocityConverter, 1, [upper(ax.axis) ' velocity converter input']);
        summary = local_check_output_connected_to_block(summary, ax.joint, ax.velocityConverter, [upper(ax.axis) ' joint velocity sensing feeds velocity converter']);
    end

    if local_block_exists(ax.rod)
        summary = local_check_numeric_param(summary, ax.rod, 'Mass', cfg.task2.rodMassKg, 1e-9);
        summary = local_check_vector_param(summary, ax.rod, 'BrickDimensions', rodDims.(ax.axis), 1e-6);
    end

    if local_block_exists(ax.carriage)
        summary = local_check_numeric_param(summary, ax.carriage, 'Mass', cfg.task2.carriageMassKg, 1e-9);
        summary = local_check_vector_param(summary, ax.carriage, 'BrickDimensions', cfg.task2.carriageDimsM, 1e-6);
    end

    if local_block_exists(ax.actualLogger)
        summary = local_check_param(summary, ax.actualLogger, 'VariableName', ax.actualVar);
        summary = local_check_param(summary, ax.actualLogger, 'SaveFormat', 'Timeseries');
        summary = local_check_param(summary, ax.actualLogger, 'LimitDataPoints', 'off');
        summary = local_check_signal_connection(summary, ax.psConverter, 1, ax.actualLogger, 1, [upper(ax.axis) ' actual logger input']);
    end

    if local_block_exists(ax.velocityLogger)
        summary = local_check_param(summary, ax.velocityLogger, 'VariableName', ax.velocityVar);
        summary = local_check_param(summary, ax.velocityLogger, 'SaveFormat', 'Timeseries');
        summary = local_check_param(summary, ax.velocityLogger, 'LimitDataPoints', 'off');
        summary = local_check_signal_connection(summary, ax.velocityConverter, 1, ax.velocityLogger, 1, [upper(ax.axis) ' velocity logger input']);
    end

    if local_block_exists(ax.errorLogger)
        summary = local_check_param(summary, ax.errorLogger, 'VariableName', ax.errorVar);
        summary = local_check_param(summary, ax.errorLogger, 'SaveFormat', 'Timeseries');
        summary = local_check_param(summary, ax.errorLogger, 'LimitDataPoints', 'off');
        summary = local_check_signal_connection(summary, ax.sum, 1, ax.errorLogger, 1, [upper(ax.axis) ' tracking-error logger input']);
    end

    if local_block_exists(ax.refLogger)
        summary = local_check_param(summary, ax.refLogger, 'VariableName', ax.refLogVar);
        summary = local_check_param(summary, ax.refLogger, 'SaveFormat', 'Timeseries');
        summary = local_check_param(summary, ax.refLogger, 'LimitDataPoints', 'off');
        summary = local_check_signal_connection(summary, ax.refBlock, 1, ax.refLogger, 1, [upper(ax.axis) ' reference logger input']);
    end

    if local_block_exists(ax.forceLogger)
        summary = local_check_param(summary, ax.forceLogger, 'VariableName', ax.forceVar);
        summary = local_check_param(summary, ax.forceLogger, 'SaveFormat', 'Timeseries');
        summary = local_check_param(summary, ax.forceLogger, 'LimitDataPoints', 'off');
        summary = local_check_signal_connection(summary, ax.pid, 1, ax.forceLogger, 1, [upper(ax.axis) ' force logger input']);
    end
end

gripper = [subsys '/Gripper'];
summary = local_check_block(summary, gripper, 'Gripper solid');
if local_block_exists(gripper)
    summary = local_check_numeric_param(summary, gripper, 'Mass', cfg.task2.gripperMassKg, 1e-9);
end

oldBlocks = local_old_project1_blocks(model);
oldExisting = oldBlocks(cellfun(@local_block_exists, oldBlocks));
oldActive = oldExisting(~cellfun(@local_is_commented_block, oldExisting));

if isempty(oldExisting)
    local_print_ok('Old Project 1 root blocks removed.');
elseif isempty(oldActive)
    local_print_ok(sprintf('Old Project 1 root blocks still exist but are commented: %d blocks.', numel(oldExisting)));
else
    local_print_warn(sprintf('Old Project 1 root blocks still active: %d blocks. They must not feed Task 2 RMSE.', numel(oldActive)));
end

if summary.pass
    fprintf('\nTask 2 setup check: PASS\n\n');
else
    fprintf('\nTask 2 setup check: NEEDS ATTENTION\n\n');
end
end

function summary = local_check_task2_constants(summary, cfg, axisMap)
    local_print_header('Task 2 assignment constants');

    summary = local_check_numeric_value(summary, 'PPP prismatic joint count', numel(axisMap), 3, 0);
    summary = local_check_numeric_value(summary, 'Stop time [s]', str2double(cfg.stopTime), 10, 1e-12);
    summary = local_check_numeric_value(summary, 'Workspace volume [m^3]', cfg.task2.workspaceVolumeM3, 3, 1e-12);
    summary = local_check_numeric_value(summary, 'Workspace stroke cubed [m^3]', cfg.task2.strokeM^3, cfg.task2.workspaceVolumeM3, 1e-10);
    summary = local_check_numeric_value(summary, 'Reference experiment count', numel(cfg.task2.experiments), 3, 0);
    summary = local_check_numeric_value(summary, 'Random parameter variation fraction', cfg.task2.randomVariationFraction, 0.05, 1e-12);

    nominalMass = 3*cfg.task2.rodMassKg + 3*cfg.task2.carriageMassKg + cfg.task2.gripperMassKg;
    summary = local_check_numeric_value(summary, 'Nominal total mass [kg]', nominalMass, cfg.task2.totalMassKg, 1e-12);
    summary = local_check_numeric_value(summary, 'Required total mass [kg]', cfg.task2.totalMassKg, 15, 1e-12);
end

function axisMap = local_axis_map(subsys)
    nl = sprintf('\n');

    axisMap = struct([]);

    axisMap(1).axis = 'x';
    axisMap(1).joint = [subsys '/x_prismatic'];
    axisMap(1).pid = [subsys '/PID Controller2'];
    axisMap(1).sum = [subsys '/Sum'];
    axisMap(1).rod = [subsys '/X-axis-rod'];
    axisMap(1).carriage = [subsys '/X_Joint'];
    axisMap(1).refVar = 'xd_ref';
    axisMap(1).refBlock = local_source_block_for_port(axisMap(1).sum, 1, local_find_from_workspace(subsys, axisMap(1).refVar, [subsys '/From' nl 'Workspace']));
    axisMap(1).psConverter = local_source_block_for_port(axisMap(1).sum, 2, [subsys '/PS-Simulink' nl 'Converter']);
    axisMap(1).forceConverter = local_destination_block_for_port(axisMap(1).pid, 1, [subsys '/Simulink-PS' nl 'Converter'], 'Simulink-PS');
    axisMap(1).actualVar = 'x_actual';
    axisMap(1).velocityVar = 'x_velocity';
    axisMap(1).errorVar = 'x_error';
    axisMap(1).refLogVar = 'x_ref_log';
    axisMap(1).forceVar = 'x_force_cmd';
    axisMap(1).actualLogger = [subsys '/Task2_x_actual_log'];
    axisMap(1).velocityConverter = [subsys '/Task2_x_velocity_converter'];
    axisMap(1).velocityLogger = [subsys '/Task2_x_velocity_log'];
    axisMap(1).errorLogger = [subsys '/Task2_x_error_log'];
    axisMap(1).refLogger = [subsys '/Task2_x_ref_log'];
    axisMap(1).forceLogger = [subsys '/Task2_x_force_log'];

    axisMap(2).axis = 'y';
    axisMap(2).joint = [subsys '/y_prismatic'];
    axisMap(2).pid = [subsys '/PID Controller1'];
    axisMap(2).sum = [subsys '/Sum2'];
    axisMap(2).rod = [subsys '/Y_axis_rod'];
    axisMap(2).carriage = [subsys '/Y_joint'];
    axisMap(2).refVar = 'yd_ref';
    axisMap(2).refBlock = local_source_block_for_port(axisMap(2).sum, 1, local_find_from_workspace(subsys, axisMap(2).refVar, [subsys '/From' nl 'Workspace2']));
    axisMap(2).psConverter = local_source_block_for_port(axisMap(2).sum, 2, [subsys '/PS-Simulink' nl 'Converter2']);
    axisMap(2).forceConverter = local_destination_block_for_port(axisMap(2).pid, 1, [subsys '/Simulink-PS' nl 'Converter1'], 'Simulink-PS');
    axisMap(2).actualVar = 'y_actual';
    axisMap(2).velocityVar = 'y_velocity';
    axisMap(2).errorVar = 'y_error';
    axisMap(2).refLogVar = 'y_ref_log';
    axisMap(2).forceVar = 'y_force_cmd';
    axisMap(2).actualLogger = [subsys '/Task2_y_actual_log'];
    axisMap(2).velocityConverter = [subsys '/Task2_y_velocity_converter'];
    axisMap(2).velocityLogger = [subsys '/Task2_y_velocity_log'];
    axisMap(2).errorLogger = [subsys '/Task2_y_error_log'];
    axisMap(2).refLogger = [subsys '/Task2_y_ref_log'];
    axisMap(2).forceLogger = [subsys '/Task2_y_force_log'];

    axisMap(3).axis = 'z';
    axisMap(3).joint = [subsys '/z_prismatic'];
    axisMap(3).pid = [subsys '/PID Controller3'];
    axisMap(3).sum = [subsys '/Sum1'];
    axisMap(3).rod = [subsys '/Z_axis_rod'];
    axisMap(3).carriage = [subsys '/Z_joint'];
    axisMap(3).refVar = 'zd_ref';
    axisMap(3).refBlock = local_source_block_for_port(axisMap(3).sum, 1, local_find_from_workspace(subsys, axisMap(3).refVar, [subsys '/From' nl 'Workspace1']));
    axisMap(3).psConverter = local_source_block_for_port(axisMap(3).sum, 2, [subsys '/PS-Simulink' nl 'Converter1']);
    axisMap(3).forceConverter = local_destination_block_for_port(axisMap(3).pid, 1, [subsys '/Simulink-PS' nl 'Converter3'], 'Simulink-PS');
    axisMap(3).actualVar = 'z_actual';
    axisMap(3).velocityVar = 'z_velocity';
    axisMap(3).errorVar = 'z_error';
    axisMap(3).refLogVar = 'z_ref_log';
    axisMap(3).forceVar = 'z_force_cmd';
    axisMap(3).actualLogger = [subsys '/Task2_z_actual_log'];
    axisMap(3).velocityConverter = [subsys '/Task2_z_velocity_converter'];
    axisMap(3).velocityLogger = [subsys '/Task2_z_velocity_log'];
    axisMap(3).errorLogger = [subsys '/Task2_z_error_log'];
    axisMap(3).refLogger = [subsys '/Task2_z_ref_log'];
    axisMap(3).forceLogger = [subsys '/Task2_z_force_log'];
end

function summary = local_check_block(summary, blockPath, label)
    if local_block_exists(blockPath)
        local_print_ok([label ' exists.']);
    else
        summary.pass = false;
        msg = [label ' missing: ' blockPath];
        summary.messages{end+1} = msg;
        local_print_fail(msg);
    end
end

function summary = local_check_param(summary, blockPath, paramName, expected)
    try
        actual = get_param(blockPath, paramName);
        if strcmp(actual, expected)
            local_print_ok(sprintf('%s/%s = %s.', blockPath, paramName, expected));
        else
            summary.pass = false;
            msg = sprintf('%s/%s expected %s, found %s.', blockPath, paramName, expected, actual);
            summary.messages{end+1} = msg;
            local_print_fail(msg);
        end
    catch ME
        summary.pass = false;
        msg = sprintf('Could not read %s on %s: %s', paramName, blockPath, ME.message);
        summary.messages{end+1} = msg;
        local_print_fail(msg);
    end
end

function summary = local_check_numeric_param(summary, blockPath, paramName, expected, tol)
    try
        actualText = get_param(blockPath, paramName);
        actual = str2double(actualText);
        if isfinite(actual) && abs(actual - expected) <= tol
            local_print_ok(sprintf('%s/%s = %.6g.', blockPath, paramName, actual));
        else
            summary.pass = false;
            msg = sprintf('%s/%s expected %.6g, found %s.', blockPath, paramName, expected, actualText);
            summary.messages{end+1} = msg;
            local_print_fail(msg);
        end
    catch ME
        summary.pass = false;
        msg = sprintf('Could not read %s on %s: %s', paramName, blockPath, ME.message);
        summary.messages{end+1} = msg;
        local_print_fail(msg);
    end
end

function summary = local_check_numeric_value(summary, label, actual, expected, tol)
    if isfinite(actual) && abs(actual - expected) <= tol
        local_print_ok(sprintf('%s = %.12g.', label, actual));
    else
        summary.pass = false;
        msg = sprintf('%s expected %.12g, found %.12g.', label, expected, actual);
        summary.messages{end+1} = msg;
        local_print_fail(msg);
    end
end

function summary = local_check_vector_param(summary, blockPath, paramName, expected, tol)
    try
        actualText = get_param(blockPath, paramName);
        actual = local_parse_numeric_vector(actualText);

        if numel(actual) == numel(expected) && all(abs(actual(:)' - expected(:)') <= tol)
            local_print_ok(sprintf('%s/%s = %s.', blockPath, paramName, mat2str(actual(:)', 6)));
        else
            summary.pass = false;
            msg = sprintf('%s/%s expected %s, found %s.', blockPath, paramName, mat2str(expected), actualText);
            summary.messages{end+1} = msg;
            local_print_fail(msg);
        end
    catch ME
        summary.pass = false;
        msg = sprintf('Could not read %s on %s: %s', paramName, blockPath, ME.message);
        summary.messages{end+1} = msg;
        local_print_fail(msg);
    end
end

function summary = local_check_input_connected(summary, blockPath, inputIndex, label)
    try
        port = local_input_port(blockPath, inputIndex);
        if isempty(port)
            summary.pass = false;
            msg = [label ' has no readable input port.'];
            summary.messages{end+1} = msg;
            local_print_fail(msg);
            return;
        end

        if get_param(port, 'Line') ~= -1
            local_print_ok([label ' is connected.']);
        else
            summary.pass = false;
            msg = [label ' is not connected.'];
            summary.messages{end+1} = msg;
            local_print_fail(msg);
        end
    catch ME
        summary.pass = false;
        msg = sprintf('Could not check %s: %s', label, ME.message);
        summary.messages{end+1} = msg;
        local_print_fail(msg);
    end
end

function summary = local_check_signal_connection(summary, srcBlock, srcPortIndex, dstBlock, dstPortIndex, label)
    if ~local_block_exists(srcBlock) || ~local_block_exists(dstBlock)
        return;
    end

    try
        dstPort = local_input_port(dstBlock, dstPortIndex);
        if isempty(dstPort)
            summary.pass = false;
            msg = [label ' has no readable destination port.'];
            summary.messages{end+1} = msg;
            local_print_fail(msg);
            return;
        end

        lineHandle = get_param(dstPort, 'Line');
        if lineHandle == -1
            summary.pass = false;
            msg = [label ' is not connected.'];
            summary.messages{end+1} = msg;
            local_print_fail(msg);
            return;
        end

        srcHandle = get_param(lineHandle, 'SrcBlockHandle');
        actualSrcPort = local_line_source_port(lineHandle);
        expectedSrcPort = local_output_port(srcBlock, srcPortIndex);

        sourceBlockMatches = srcHandle ~= -1 && strcmp(getfullname(srcHandle), srcBlock);
        sourcePortMatches = isempty(actualSrcPort) || isempty(expectedSrcPort) || actualSrcPort == expectedSrcPort;

        if sourceBlockMatches && sourcePortMatches
            local_print_ok([label ' is connected.']);
        else
            summary.pass = false;
            msg = sprintf('%s expected source %s/%d.', label, srcBlock, srcPortIndex);
            summary.messages{end+1} = msg;
            local_print_fail(msg);
        end
    catch ME
        summary.pass = false;
        msg = sprintf('Could not check %s: %s', label, ME.message);
        summary.messages{end+1} = msg;
        local_print_fail(msg);
    end
end

function summary = local_check_output_connected_to_block(summary, srcBlock, dstBlock, label)
    if ~local_block_exists(srcBlock) || ~local_block_exists(dstBlock)
        return;
    end

    try
        if local_any_output_reaches_block(srcBlock, dstBlock)
            local_print_ok([label ' is connected.']);
        else
            summary.pass = false;
            msg = [label ' is not connected.'];
            summary.messages{end+1} = msg;
            local_print_fail(msg);
        end
    catch ME
        summary.pass = false;
        msg = sprintf('Could not check %s: %s', label, ME.message);
        summary.messages{end+1} = msg;
        local_print_fail(msg);
    end
end

function connected = local_any_output_reaches_block(srcBlock, dstBlock)
    connected = false;
    srcPorts = local_candidate_output_ports(srcBlock);

    for i = 1:numel(srcPorts)
        try
            lineHandle = get_param(srcPorts(i), 'Line');
            if lineHandle == -1
                continue;
            end

            dstHandles = get_param(lineHandle, 'DstBlockHandle');
            for j = 1:numel(dstHandles)
                if dstHandles(j) ~= -1 && strcmp(getfullname(dstHandles(j)), dstBlock)
                    connected = true;
                    return;
                end
            end
        catch
        end
    end
end

function port = local_input_port(blockPath, inputIndex)
    port = [];
    ports = get_param(blockPath, 'PortHandles');

    candidateFields = {'Inport', 'LConn'};
    for i = 1:numel(candidateFields)
        fieldName = candidateFields{i};
        if isfield(ports, fieldName) && numel(ports.(fieldName)) >= inputIndex
            port = ports.(fieldName)(inputIndex);
            return;
        end
    end
end

function port = local_output_port(blockPath, outputIndex)
    port = [];
    ports = get_param(blockPath, 'PortHandles');

    candidateFields = {'Outport', 'RConn', 'LConn'};
    for i = 1:numel(candidateFields)
        fieldName = candidateFields{i};
        if isfield(ports, fieldName) && numel(ports.(fieldName)) >= outputIndex
            port = ports.(fieldName)(outputIndex);
            return;
        end
    end
end

function port = local_line_source_port(lineHandle)
    port = [];

    try
        port = get_param(lineHandle, 'SrcPortHandle');
    catch
    end
end

function portsOut = local_candidate_output_ports(blockPath)
    portsOut = [];
    ports = get_param(blockPath, 'PortHandles');

    candidateFields = {'Outport', 'RConn', 'LConn'};
    for i = 1:numel(candidateFields)
        fieldName = candidateFields{i};
        if isfield(ports, fieldName) && ~isempty(ports.(fieldName))
            portsOut = [portsOut ports.(fieldName)]; %#ok<AGROW>
        end
    end
end

function values = local_parse_numeric_vector(text)
    text = char(text);
    text = regexprep(text, '[\[\],;]', ' ');
    values = sscanf(text, '%f')';
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

function blocks = local_old_project1_blocks(model)
    names = {sprintf('From\nWorkspace'), sprintf('From\nWorkspace1'), sprintf('From\nWorkspace2'), ...
        'Saturation', 'Saturation1', 'Saturation2', ...
        'constant1', 'constant2', 'constant3', ...
        'q1_ddot', 'q2_ddot', 'q3_ddot', ...
        'velocity_1', 'velocity_2', 'velocity_3', ...
        'position_1', 'position_2', 'position_3', ...
        'q1', 'q2', 'q3', 'x', 'y', 'z', 'roll', 'pitch', 'yaw'};

    blocks = cell(size(names));
    for i = 1:numel(names)
        blocks{i} = [model '/' names{i}];
    end
end

function tf = local_is_commented_block(blockPath)
    try
        tf = strcmp(get_param(blockPath, 'Commented'), 'on');
    catch
        tf = false;
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

function local_print_ok(msg)
    fprintf('[OK] %s\n', msg);
end

function local_print_header(msg)
    fprintf('\n%s\n', msg);
end

function local_print_warn(msg)
    fprintf('[WARN] %s\n', msg);
end

function local_print_fail(msg)
    fprintf('[FAIL] %s\n', msg);
end
