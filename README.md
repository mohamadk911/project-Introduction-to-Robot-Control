# MATLAB/Simulink Robot Control

This repository contains a MATLAB and Simulink study of a three-axis prismatic (PPP) robot. It documents model setup, independent PID position control, reference trajectories, simulation logging, and tracking-error evaluation.

## What it demonstrates

- PPP robot modeling with Simscape frame transforms.
- Independent position-control loops for the X, Y, and Z axes.
- Smooth Lissajous, diagonal pick-and-place, and axis-sequential reference experiments.
- Logged position, velocity, reference, error, and force signals.
- Dry-run and approval-gated model changes before saving.
- RMSE-based tracking evaluation and optional parameter-variation campaigns.

## Main files

- robot_control_model.slx — Simulink/Simscape model.
- ai_config.m — model name, experiment settings, dimensions, masses, and PID gains.
- ai_00_task2_workflow.m — prints the recommended workflow.
- ai_01_init_signals.m — creates the configured reference signals.
- ai_02_inspect_model.m and ai_03_inspect_parameters.m — inspect the model.
- ai_04_run_simulation.m — runs the configured experiments.
- ai_05_find_logged_signals.m — checks required logged signals.
- ai_07_prepare_task2_model.m — previews model changes; use dry-run mode first.
- ai_09_compute_rmse.m — computes three-dimensional tracking RMSE.
- ai_10_randomize_task2_parameters.m and ai_12_run_task2_campaign.m — optional parameter studies.
- ai_11_check_task2_setup.m — validates the configured model.
- ai_13_apply_task2_after_approval.m — applies changes only after explicit confirmation.

The misspelled ai_01_init_signnals.m file is retained as a compatibility wrapper. New work should call ai_01_init_signals.m.

## Requirements

- MATLAB with Simulink and Simscape.
- A MATLAB installation that can open the included SLX model.

## Quick start

1. Open MATLAB and set this repository as the current folder.
2. Run ai_00_task2_workflow to print the configured sequence.
3. Run ai_01_init_signals to create the reference signals.
4. Run ai_07_prepare_task2_model('dry-run') and review the proposed changes.
5. Run ai_13_apply_task2_after_approval only after reviewing the dry run and confirming in MATLAB.
6. Run ai_11_check_task2_setup, then ai_04_run_simulation.
7. Use ai_05_find_logged_signals and ai_09_compute_rmse to verify the run and quantify tracking error.
8. Use ai_12_run_task2_campaign for the optional randomized campaign.

Generated MAT files, logs, Simulink cache files, and ai_results/ are excluded by .gitignore.

## Notes

The current configuration uses a 15 kg target mass, a 3 m³ workspace, 10-second experiments, and initial PID gains of P=500, I=50, D=80 with a derivative filter coefficient of 100. These values are documented in ai_config.m and can be adjusted for further experiments.

This repository is intended for study and demonstration. Review model changes and simulation results before using them in another system.
