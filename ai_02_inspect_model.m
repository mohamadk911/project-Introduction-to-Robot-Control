%% ai_02_inspect_model.m
% Exports full Simulink model structure for AI/Codex inspection.

cfg = ai_config();
model = cfg.model;

load_system(model);

reportFile = fullfile(cfg.reportsDir, 'model_structure_report.txt');
fid = fopen(reportFile,'w');

fprintf(fid,'MODEL STRUCTURE REPORT\n');
fprintf(fid,'Model: %s\n', model);
fprintf(fid,'Generated: %s\n\n', datestr(now));

blocks = find_system(model,'LookUnderMasks','all','FollowLinks','on','Type','Block');

fprintf(fid,'TOTAL BLOCKS: %d\n\n', numel(blocks));

for i = 1:numel(blocks)
    blk = blocks{i};

    fprintf(fid,'--------------------------------------------------\n');
    fprintf(fid,'BLOCK: %s\n', blk);

    try
        fprintf(fid,'BlockType: %s\n', get_param(blk,'BlockType'));
    catch
        fprintf(fid,'BlockType: ERROR\n');
    end

    try
        fprintf(fid,'Parent: %s\n', get_param(blk,'Parent'));
    catch
        fprintf(fid,'Parent: ERROR\n');
    end

    try
        fprintf(fid,'MaskType: %s\n', get_param(blk,'MaskType'));
    catch
        fprintf(fid,'MaskType: none\n');
    end

    try
        fprintf(fid,'Ports: %s\n', mat2str(get_param(blk,'Ports')));
    catch
        fprintf(fid,'Ports: ERROR\n');
    end

    try
        pos = get_param(blk,'Position');
        fprintf(fid,'Position: %s\n', mat2str(pos));
    catch
        fprintf(fid,'Position: ERROR\n');
    end

    fprintf(fid,'\n');
end

fprintf(fid,'\n\nCONNECTIONS / LINES\n\n');

lines = find_system(model,'FindAll','on','Type','Line');

for i = 1:numel(lines)
    ln = lines(i);

    try
        srcBlock = get_param(ln,'SrcBlockHandle');
        dstBlocks = get_param(ln,'DstBlockHandle');

        if srcBlock ~= -1
            srcName = getfullname(srcBlock);
        else
            srcName = 'NONE';
        end

        fprintf(fid,'LINE %d\n', i);
        fprintf(fid,'Source: %s\n', srcName);

        if isnumeric(dstBlocks)
            for j = 1:numel(dstBlocks)
                if dstBlocks(j) ~= -1
                    fprintf(fid,'Destination: %s\n', getfullname(dstBlocks(j)));
                end
            end
        end

        fprintf(fid,'\n');
    catch ME
        fprintf(fid,'LINE %d ERROR: %s\n\n', i, ME.message);
    end
end

fclose(fid);

fprintf('Model structure exported to:\n%s\n', reportFile);