# Family Signatures

Classify an APK as YingAn/YingPo-like when several independent signals agree:

| Layer | Signals |
|---|---|
| Root DEX | Very few classes, `strEntryApplication`, `startApp`, `abcd655xx`, `abcdstr`, `System.load`, `System.exit`, reflective class loading. |
| Native | `libabcd.so`, `lib*_shellservice_dex.so`, ZIP-shaped `.so` entries containing DEX. |
| Assets | `assets/lib*Protect*`, `abcd/`, encrypted blobs with no normal resource role. |
| Runtime | DEX magic in anonymous/read-write mappings, delayed application/activity visibility, JNI registration failures after repacking. |
| Route | A normal-looking outer UI launches an inner real activity through an About/version/navigation path. |

Use at least two layers before choosing a shell-rehydration route. A string or filename alone can occur in unrelated products.

## Evidence Priority

1. Original-process runtime DEX and top-activity evidence.
2. Manifest and component resolution against that DEX set.
3. Original-process logs.
4. Static inner ZIP/ELF payloads.
5. Root-Dex strings and naming patterns.

Never make a destructive choice from a lower-priority signal when a higher-priority observation is available.
