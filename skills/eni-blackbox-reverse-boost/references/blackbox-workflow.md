# Offline black-box reverse workflow

## Evidence checklist

- Original path, copied path, SHA256, size, timestamp.
- File type, PE architecture, sections, import hints, packer/protector signs.
- URLs/IPs/ports, update endpoints, auth/license strings, config filenames.
- GUI top windows, child controls, button/edit IDs, titles, error dialogs.
- Process lifetime, exit code, copy-only mutation status, created/changed local files.
- Network observations from netstat or controlled local proxy, clearly marked as observed or not observed.
- Result status: `verified_success`, `not_successful`, `inconclusive`, or `blocked`.

## Negative-result rule

A negative result means only: current evidence did not prove the requested bypass or weakness. Record attempted paths and why each did not validate. Do not say a weakness is impossible.

## Report skeleton

```markdown
# Offline black-box audit report

## Conclusion
- Status:
- Confidence:

## Target
- Original:
- Copy:
- SHA256:

## Tests performed
- Static surface:
- Dynamic GUI:
- Local state/persistence:
- Runtime/network:

## Findings / leads
1. Title, evidence path, impact, confidence, next validation.

## Evidence files
- JSON:
- Logs:
```

## Windows notes

- Work on copied folders under a case workspace.
- Prefer `PostMessageW`/`SendMessageW` probes only against copied test processes.
- If windows must remain visible for the user, avoid offscreen movement and log the PID/path clearly.
- If dynamic tests self-modify copies, compare pre/post hashes and discard mutated copies unless explicitly needed as evidence.
