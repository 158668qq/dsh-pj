# RikkaHub Recovery Lessons

This case established the family workflow. It is evidence, not a patch profile.

## What Worked

1. The original root `classes.dex` was treated as a shell control layer: it had very few class definitions, shell callbacks, protected assets, and native loader evidence.
2. The original process was run before changing the APK. Anonymous runtime DEX images became the source of truth and yielded 76,839 unique recovered classes after validation.
3. Manifest components and runtime class definitions were correlated before choosing the real application/entry path. This exposed the normal outer route and a hidden inner activity reached through the app's settings/about/version navigation.
4. The first working build used full managed multidex rehydration and retained uncertain native/assets. It did not start by stripping every protector file.
5. Lifecycle failure was fixed only after proving a code-less native wrapper had a concrete `*Core` direct superclass with a matching lifecycle method. The repair delegated to that superclass instead of stubbing business APIs.
6. Completion evidence included APK signature verification, clean install, process/top-activity checks, UI evidence for the outer and inner routes, and logcat review.

## General Rules Extracted

- Runtime load order and class reachability outweigh static filename guesses.
- Use a hash-bound plan to prevent accidental rebuilds from stale DEX captures.
- Preserve unknown entries for the compatibility build. Shell cleanup is a later, independently tested change.
- Replace only the layer proven to be a shell boundary: manifest routing, root delegation, or lifecycle bridge. Avoid broad native mutation.
- Treat each fatal signal, `JNI_ERR`, `ClassNotFoundException`, `VerifyError`, and missing native implementation as a route-selection signal, not an invitation to patch branches blindly.
- Keep product authentication, entitlement, and remote protocol behavior outside the recovery mechanism.

## Remaining Diagnostic Rule

A successfully signed APK can still fail on a device-specific native path. For example, a MediaCodec/SoundDecoder SIGSEGV is a real smoke-test failure even when ZIP, DEX, manifest, and signatures are valid. Preserve the device log, PID/activity evidence, architecture/Android-version details, and reproduce against the original application before attributing that class of failure to the rehydration plan.
