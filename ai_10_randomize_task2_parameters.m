function variation = ai_10_randomize_task2_parameters(mode, seed)
%AI_10_RANDOMIZE_TASK2_PARAMETERS Apply random +/-5% manipulator parameters.
%
% The workspace stroke and joint travel limits are intentionally kept fixed
% so the operative workspace remains 3 m^3. This varies physical
% manipulator parameters: rod masses, carriage masses, gripper mass, and
% non-stroke rod thicknesses.
%
% Modes:
%   'dry-run'        Preview randomized values. Default.
%   'apply-no-save'  Apply to the loaded model, do not save.
%   'apply-and-save' Apply to the loaded model and save the .slx.
%   'reset-no-save'  Restore nominal parameters, do not save.
%   'reset-and-save' Restore nominal parameters and save the .slx.

if nargin < 1 || isempty(mode)
    mode = 'dry-run';
end

if nargin < 2 || isempty(seed)
    seed = 'shuffle';
end

mode = validatestring(mode, {'dry-run', 'apply-no-save', 'apply-and-save', 'reset-no-save', 'reset-and-save'});
resetNominal = startsWith(mode, 'reset');
applyChanges = ~strcmp(mode, 'dry-run');
saveChanges = strcmp(mode, 'apply-and-save') || strcmp(mode, 'reset-and-save');

cfg = ai_config();
model = cfg.model;
subsys = [model '/Animation_Simscape'];

rng(seed);

axisMap = local_axis_map(subsys);
if resetNominal
    variation = local_make_nominal(cfg, axisMap);
else
    variation = local_make_variation(cfg, axisMap, seed);
end

fprintf('\nTASK 2 PARAMETER VARIATION\n');
fprintf('Mode: %s\n', mode);
fprintf('Variation range: +/-%.1f%%\n', 100*cfg.task2.randomVariationFraction);
fprintf('Workspace stroke is fixed at %.4f m.\n\n', cfg.task2.strokeM);

load_system(model);

if saveChanges && ~local_confirm_save(mode)
    fprintf('Save confirmation not received. No parameter changes applied or saved.\n\n');
    return;
end

for i = 1:numel(variation.axes)
    ax = variation.axes(i);
    fprintf('%s axis: rod mass %.4f kg, carriage mass %.4f kg, rod dimensions %s m\n', ...
        upper(ax.axis), ax.rodMassKg, ax.carriageMassKg, mat2str(ax.rodDimsM, 5));

    if applyChanges
        local_safe_set(ax.rodBlock, 'Mass', sprintf('%.12g', ax.rodMassKg));
        local_safe_set(ax.rodBlock, 'BrickDimensions', mat2str(ax.rodDimsM));
        local_safe_set(ax.carriageBlock, 'Mass', sprintf('%.12g', ax.carriageMassKg));
    end
end

fprintf('Gripper mass %.4f kg\n', variation.gripperMassKg);
fprintf('Total varied mass %.4f kg (nominal %.4f kg)\n', variation.totalMassKg, variation.nominalTotalMassKg);
if applyChanges
    local_safe_set([subsys '/Gripper'], 'Mass', sprintf('%.12g', variation.gripperMassKg));
end

if saveChanges
    save_system(model);
    fprintf('\nApplied parameters and saved model.\n\n');
elseif applyChanges
    fprintf('\nApplied parameters to the loaded model only. Not saved.\n\n');
else
    fprintf('\nDry run only. No model changes made.\n\n');
end
end

function variation = local_make_nominal(cfg, axisMap)
    L = cfg.task2.strokeM;
    th = cfg.task2.rodThicknessM;

    variation.seed = 'nominal';
    variation.range = 0;
    variation.axes = struct([]);

    for i = 1:numel(axisMap)
        ax = axisMap(i);
        variation.axes(i).axis = ax.axis;
        variation.axes(i).rodBlock = ax.rod;
        variation.axes(i).carriageBlock = ax.carriage;
        variation.axes(i).rodMassKg = cfg.task2.rodMassKg;
        variation.axes(i).carriageMassKg = cfg.task2.carriageMassKg;
        variation.axes(i).rodDimsM = local_nominal_rod_dims(ax.axis, L, th);
    end

    variation.gripperMassKg = cfg.task2.gripperMassKg;
    variation.nominalTotalMassKg = cfg.task2.totalMassKg;
    variation.totalMassKg = local_total_mass(variation);
end

function variation = local_make_variation(cfg, axisMap, seed)
    f = cfg.task2.randomVariationFraction;
    L = cfg.task2.strokeM;
    th = cfg.task2.rodThicknessM;

    variation.seed = seed;
    variation.range = f;
    variation.axes = struct([]);

    for i = 1:numel(axisMap)
        ax = axisMap(i);

        rodMassFactor = local_factor(f);
        carriageMassFactor = local_factor(f);
        thicknessFactorA = local_factor(f);
        thicknessFactorB = local_factor(f);

        dims = local_nominal_rod_dims(ax.axis, L, th);

        switch ax.axis
            case 'x'
                dims(2) = dims(2) * thicknessFactorA;
                dims(3) = dims(3) * thicknessFactorB;
            case {'y', 'z'}
                dims(1) = dims(1) * thicknessFactorA;
                dims(3) = dims(3) * thicknessFactorB;
        end

        variation.axes(i).axis = ax.axis;
        variation.axes(i).rodBlock = ax.rod;
        variation.axes(i).carriageBlock = ax.carriage;
        variation.axes(i).rodMassKg = cfg.task2.rodMassKg * rodMassFactor;
        variation.axes(i).carriageMassKg = cfg.task2.carriageMassKg * carriageMassFactor;
        variation.axes(i).rodDimsM = dims;
    end

    variation.gripperMassKg = cfg.task2.gripperMassKg * local_factor(f);
    variation.nominalTotalMassKg = cfg.task2.totalMassKg;
    variation.totalMassKg = local_total_mass(variation);
end

function totalMassKg = local_total_mass(variation)
    totalMassKg = variation.gripperMassKg;

    for i = 1:numel(variation.axes)
        totalMassKg = totalMassKg + variation.axes(i).rodMassKg + variation.axes(i).carriageMassKg;
    end
end

function dims = local_nominal_rod_dims(axisName, L, th)
    switch axisName
        case 'x'
            dims = [L th th];
        case 'y'
            dims = [th L th];
        case 'z'
            % Current model: Z rod is long in local +Y and rotated by frames.
            dims = [th L th];
        otherwise
            error('Unknown axis "%s".', axisName);
    end
end

function factor = local_factor(range)
    factor = 1 + range * (2*rand() - 1);
end

function axisMap = local_axis_map(subsys)
    axisMap = struct([]);

    axisMap(1).axis = 'x';
    axisMap(1).rod = [subsys '/X-axis-rod'];
    axisMap(1).carriage = [subsys '/X_Joint'];

    axisMap(2).axis = 'y';
    axisMap(2).rod = [subsys '/Y_axis_rod'];
    axisMap(2).carriage = [subsys '/Y_joint'];

    axisMap(3).axis = 'z';
    axisMap(3).rod = [subsys '/Z_axis_rod'];
    axisMap(3).carriage = [subsys '/Z_joint'];
end

function local_safe_set(blockPath, paramName, paramValue)
    try
        set_param(blockPath, paramName, paramValue);
    catch ME
        warning('Could not set %s on %s: %s', paramName, blockPath, ME.message);
    end
end

function confirmed = local_confirm_save(mode)
    confirmText = input(sprintf('Type SAVE_TASK2_PARAMETERS to run %s and save the .slx: ', mode), 's');
    confirmed = strcmp(confirmText, 'SAVE_TASK2_PARAMETERS');
end
