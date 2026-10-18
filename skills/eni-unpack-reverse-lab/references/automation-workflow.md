# Automated workflow

Use the wrapper for a local native artifact:

```powershell
python <skill>\scripts\cold_coffee_native_workflow.py <artifact.exe> --case-dir <case-dir> --dynamic
```

The wrapper only creates a timestamped run directory. It records source hashes before and after, copies the artifact's parent directory before dynamic work, hides the copied process, terminates it after each bounded probe, and writes a manifest with individual return codes.

Use the static-only form by omitting `--dynamic` when executable launch is not needed.
