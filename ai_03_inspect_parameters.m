%% ai_03_inspect_parameters.m
% Exports important block parameters for AI/Codex.

cfg = ai_config();
model = cfg.model;

load_system(model);

reportFile = fullfile(cfg.reportsDir, 'model_parameters_report.txt');
fid = fopen(reportFile,'w');

fprintf(fid,'MODEL PARAMETER REPORT\n');
fprintf(fid,'Model: %s\n', model);
fprintf(fid,'Generated: %s\n\n', datestr(now));

blocks = find_system(model,'LookUnderMasks','all','FollowLinks','on','Type','Block');

keywords = {
    'pid'
    'prismatic'
    'joint'
    'solid'
    'body'
    'rod'
    'gripper'
    'end'
    'workspace'
    'converter'
    'from workspace'
    'sum'
    'scope'
    'to workspace'
};

for i = 1:numel(blocks)
    blk = blocks{i};
    blkLower = lower(blk);

    try
        bt = lower(get_param(blk,'BlockType'));
    catch
        bt = '';
    end

    selected = false;

    for k = 1:numel(keywords)
        if contains(blkLower, keywords{k}) || contains(bt, keywords{k})
            selected = true;
        end
    end

    if ~selected
        continue;
    end

    fprintf(fid,'--------------------------------------------------\n');
    fprintf(fid,'BLOCK: %s\n', blk);

    try
        fprintf(fid,'BlockType: %s\n', get_param(blk,'BlockType'));
    catch
    end

    try
        fprintf(fid,'MaskType: %s\n', get_param(blk,'MaskType'));
    catch
    end

    try
        dlg = get_param(blk,'DialogParameters');
        names = fieldnames(dlg);

        fprintf(fid,'PARAMETERS:\n');

        for n = 1:numel(names)
            pname = names{n};
            try
                pval = get_param(blk,pname);
                if ischar(pval) || isstring(pval) || isnumeric(pval) || islogical(pval)
                    fprintf(fid,'  %s = %s\n', pname, mat2str_or_char(pval));
                end
            catch
            end
        end
    catch ME
        fprintf(fid,'Could not read DialogParameters: %s\n', ME.message);
    end

    fprintf(fid,'\n');
end

fclose(fid);

fprintf('Important parameters exported to:\n%s\n', reportFile);

function out = mat2str_or_char(x)
    if ischar(x)
        out = x;
    elseif isstring(x)
        out = char(x);
    elseif isnumeric(x) || islogical(x)
        out = mat2str(x);
    else
        out = '<unsupported>';
    end
end