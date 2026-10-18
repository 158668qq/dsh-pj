# Evidence gates

Use these gates for claims about protected features or authorization states.

| Claim | Minimum direct evidence |
|---|---|
| Packer identified | Multiple structural indicators or confirmed unpacked output; a string alone is insufficient. |
| Unpacked artifact is usable | Re-triage and stable copied-process execution. |
| Feature is available | Functional feature observed on the original-hash behavior or a documented copy. |
| State survives restart | Reproduce after application restart and verify the same feature. |
| State is permanent | Repeat after clearing the documented temporary state and across a meaningful elapsed interval. |
| State is cross-machine | Verify on an independent machine without importing unstated state. |

Do not conflate a visual message, return code, branch coverage, injected runtime state, or a modified executable with these claims.
