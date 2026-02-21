# Drop this file into the branch to trigger the Generate golden images workflow on GitHub Actions.
# Usage: git add ci/generate-goldens.trigger && git commit -m "ci: trigger golden generation" && git push origin responsive/layout-fixes
# The workflow will run and upload generated PNGs as the "golden-images" artifact. Inspect then commit manually.