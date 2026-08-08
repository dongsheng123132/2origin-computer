# Example: Portable Action (C4)

> The same action, different drivers, identical result. This is the minimum demo of **ActionParity 影核** — the action layer does not depend on the underlying implementation.

## Run it

```bash
# CLI driver
node document-save.js --driver cli

# API driver
node document-save.js --driver api
```

## What it proves

| Conformance item | Demonstrated |
|---|---|
| Portable actions (C4) | `document.save` produces byte-identical output via CLI and API drivers — same sha256 |
| Northbridge role | `northbridge()` picks the driver (know-what); the action core doesn't care |

## The point

In the real system, an action like `document.save` may be executed by:

- an API (Word/WPS COM)
- a CLI tool
- a GUI automation (OCR + clicks)
- a device

The **action intent** is the same; only the driver differs. A 2Origin-compatible action must be executable by any driver with identical observable results.
