# SwiftCodex

<img width="1165" height="786" alt="image" src="https://github.com/user-attachments/assets/f1bc98bc-d36e-45c1-9291-250e3d52ec18" />

Before using the endpoint harness in `ContentView`, start the Codex app-server.

## Vision Pro Device (recommended)

Start the server on your Mac and listen on all interfaces:

```bash
codex app-server --listen ws://0.0.0.0:4500
```

In the app, use your Mac LAN IP as the websocket URL (current example):

```text
ws://10.0.0.8:4500
```

To find your current Mac LAN IP:

```bash
ipconfig getifaddr en0
```

If needed, check your default interface first:

```bash
route get default | grep interface
```

## visionOS Simulator on the same Mac

When running in Simulator on the same machine, localhost works:

```bash
codex app-server --listen ws://127.0.0.1:4500
```

Use this URL in the app:

```text
ws://127.0.0.1:4500
```

## SDK Packaging

`CodexAppServerSDK` is wired as a local Swift package at:

```text
Packages/CodexAppServerSDK
```

During development, `SwiftCodex` uses this local package source directly.

To switch to a remote package later:

1. Publish `CodexAppServerSDK` to a Git repository.
2. Tag a SemVer release (for example `0.1.0`).
3. In Xcode, remove the local package reference.
4. Add the remote package URL with a version rule (for example "Up to Next Major" from `0.1.0`).
5. Keep module/product name `CodexAppServerSDK` so app imports do not change.

## Package Reuse (macOS, iOS, iPadOS, visionOS)

`CodexAppServerSDK` is reusable by any Swift app target on supported platforms:

- macOS 13+
- iOS 16+ (includes iPadOS apps)
- visionOS 26+

To reuse it in another app:

1. In Xcode, open the app project/workspace.
2. Go to `File > Add Package Dependencies...`.
3. Add one of:
   - local path: `Packages/CodexAppServerSDK`
   - remote Git URL (after publishing)
4. Add product `CodexAppServerSDK` to the target(s) that need it.
5. Import in source files:

```swift
import CodexAppServerSDK
```

WebSocket sample integration now lives in:

```text
SwiftCodex/SDKSampleIntegrationView.swift
```

Open that file and run the `#Preview("SDK Sample")` preview to test:
- connect + initialize
- model/list request
- inbound notifications/requests/stderr logging
- disconnect

## References

- https://developers.openai.com/codex/app-server/
- https://github.com/openai/codex/tree/main/codex-rs/app-server
