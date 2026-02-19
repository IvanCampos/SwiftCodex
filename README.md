# SwiftCodex

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

## References

- https://developers.openai.com/codex/app-server/
- https://github.com/openai/codex/tree/main/codex-rs/app-server
