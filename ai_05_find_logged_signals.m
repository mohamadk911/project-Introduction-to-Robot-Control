%% ai_05_find_logged_signals.m
% Inspects available logged simulation signals.

cfg = ai_config();

resultFile = fullfile(cfg.resultsDir, 'last_simulation_output.mat');
reportFile = fullfile(cfg.reportsDir, 'logged_signals_report.txt');

fid = fopen(reportFile,'w');

fprintf(fid,'LOGGED SIGNALS REPORT\n');
fprintf(fid,'Generated: %s\n\n', datestr(now));

if ~exist(resultFile,'file')
    fprintf(fid,'No simulation output found. Run ai_04_run_simulation first.\n');
    fclose(fid);
    error('No simulation output found. Run ai_04_run_simulation first.');
end

load(resultFile,'simOut');

fprintf(fid,'simOut class: %s\n\n', class(simOut));

try
    vars = simOut.who;
    fprintf(fid,'simOut variables:\n');
    for i = 1:numel(vars)
        fprintf(fid,'  %s\n', vars{i});
    end
    fprintf(fid,'\n');
catch
    fprintf(fid,'Could not list simOut variables using who.\n\n');
end

try
    logsout = simOut.logsout;
    fprintf(fid,'logsout found.\n');
    fprintf(fid,'Number of elements: %d\n\n', logsout.numElements);

    for i = 1:logsout.numElements
        sig = logsout.get(i);
        fprintf(fid,'Signal %d:\n', i);
        fprintf(fid,'  Name: %s\n', sig.Name);
        fprintf(fid,'  BlockPath: %s\n', sig.BlockPath.convertToCell{1});
        fprintf(fid,'\n');
    end
catch ME
    fprintf(fid,'No logsout found or could not read logsout.\n');
    fprintf(fid,'Reason: %s\n\n', ME.message);
end

try
    yout = simOut.yout;
    fprintf(fid,'yout found.\n');
    fprintf(fid,'Class: %s\n\n', class(yout));
catch ME
    fprintf(fid,'No yout found.\n');
    fprintf(fid,'Reason: %s\n\n', ME.message);
end

task2Names = { ...
    'x_actual', 'y_actual', 'z_actual', ...
    'x_velocity', 'y_velocity', 'z_velocity', ...
    'x_error', 'y_error', 'z_error', ...
    'x_ref_log', 'y_ref_log', 'z_ref_log', ...
    'x_force_cmd', 'y_force_cmd', 'z_force_cmd' ...
};

fprintf(fid,'Task 2 To Workspace signal check:\n');
for i = 1:numel(task2Names)
    name = task2Names{i};
    try
        value = simOut.get(name);
        fprintf(fid,'  %s: found in simOut as %s\n', name, class(value));
    catch
        try
            value = evalin('base', name);
            fprintf(fid,'  %s: found in base workspace as %s\n', name, class(value));
        catch
            fprintf(fid,'  %s: missing\n', name);
        end
    end
end
fprintf(fid,'\n');

fclose(fid);

fprintf('Logged signals report saved to:\n%s\n', reportFile);
