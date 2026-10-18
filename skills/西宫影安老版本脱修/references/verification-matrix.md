# Verification Matrix

Run the gates in order. Stop at the first failing gate and preserve the build/log evidence.

| Gate | Required evidence | Common diagnosis |
|---|---|---|
| ZIP | `zipfile.testzip` clean, no duplicate critical entries | Corrupt repack or stale signatures. |
| DEX | Header, file size, map bounds, SHA-1/Adler-32 report | Truncated capture or broken Smali rebuild. |
| Manifest | Application/components parse and resolve against output DEX | Wrong Application, missing DEX, bad AXML edit. |
| Signature | `apksigner verify --verbose --print-certs` passes | Incorrect keystore/signing order. |
| Install | Package manager accepts the APK | Signature mismatch; use an explicit clean install only when data loss is acceptable. |
| Cold launch | Three force-stop launches leave a PID alive | Entry/lifecycle/classloader failure. |
| Route | Expected activity appears and return navigation works | Wrong component mapping or hidden-route assumption. |
| Logs | No `FATAL EXCEPTION`, `JNI_ERR`, `ClassNotFoundException`, `VerifyError`, `UnsatisfiedLinkError`, `No implementation found`, or fatal signal | Return to the smallest compatible plan. |
| Product smoke | Owner-defined normal navigation/features work | Preserve shell assets or include omitted runtime DEX/resources. |

For `JNI_ERR`, do not repeatedly patch native branches. Rebuild from the last valid compatibility plan, retain unknown shell artifacts, and use the managed runtime DEX path. For `ClassNotFoundException`, compare the unresolved class against the validation/graph reports and add the missing observed runtime DEX rather than guessing a dependency.
