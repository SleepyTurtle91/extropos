Generating golden images for large breakpoints
===========================================

This folder contains golden test scaffolding and instructions for generating baseline images for large breakpoints (2K and 4K).

How to generate locally
-----------------------

1. Make sure you have Flutter installed and set up on your machine.
2. From the repository root run:

```bash
flutter pub get

# Generate baselines (retail + kitchen screens; requires a headless environment that can capture images)

flutter test --update-goldens test/goldens/large_breakpoints_golden_test.dart


# Verify the newly created baselines by running tests normally

flutter test

```

How to generate in CI
---------------------

A GitHub Actions workflow is provided: `.github/workflows/generate-goldens.yml`.
Run it manually from the Actions tab to generate goldens and download them as an artifact.

Notes
-----

- The workflow will upload generated PNGs as a downloadable artifact named `golden-images`.

- If you want the workflow to auto-commit images back to the branch, set `commit_back: true` when triggering the workflow and ensure the runner has permission to push to the repository.
