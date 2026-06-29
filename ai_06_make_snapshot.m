%% ai_06_make_snapshot.m
% Creates a snapshot of all block parameters for later comparison.

cfg = ai_config();
model = cfg.model;

load_system(model);

timestamp = datestr(now,'yyyymmdd_HHMMSS');
snapshotFile = fullfile(cfg.snapshotsDir, ['snapshot_' timestamp '.txt']);

fid = fopen(snapshotFile,'w');

fprintf(fid,'MODEL SNAPSHOT\n');
fprintf(fid,'Model: %s\n', model);
fprintf(fid,'Generated: %s\n\n', datestr(now));

blocks = find_system(model,'LookUnderMasks','all','FollowLinks','on','Type','Block');

for i = 1:numel(blocks)
    blk = blocks{i};

    fprintf(fid,'--------------------------------------------------\n');
    fprintf(fid,'BLOCK: %s\n', blk);

    try
        fprintf(fid,'BlockType: %s\n', get_param(blk,'BlockType'));
    catch
    end

    try
        dlg = get_param(blk,'DialogParameters');
        names = fieldnames(dlg);

        for n = 1:numel(names)
            pname = names{n};
            try
                pval = get_param(blk,pname);
                if ischar(pval) || isstring(pval) || isnumeric(pval) || islogical(pval)
                    fprintf(fid,'%s = %s\n', pname, mat2str_or_char(pval));
                end
            catch
            end
        end
    catch
    end

    fprintf(fid,'\n');
end

fclose(fid);

fprintf('Snapshot saved to:\n%s\n', snapshotFile);

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