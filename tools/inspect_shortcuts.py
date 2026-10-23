"""Read the action names in locally exported Apple Shortcuts files.

Requires python-aea for signed AEA1 files. This tool never writes the input.
"""

from __future__ import annotations

import argparse
import plistlib
import re
import struct
import sys
from pathlib import Path
from urllib.parse import urlsplit

sys.path.insert(0, str(Path(__file__).with_name("shortcut-inspect-deps")))
sys.stdout.reconfigure(encoding="utf-8")


def read_workflow(path: Path) -> dict:
    data = path.read_bytes()
    if not data.startswith(b"AEA1"):
        return plistlib.loads(data)

    import aea
    from cryptography import x509
    from cryptography.hazmat.primitives import serialization

    auth_size = struct.unpack_from("<I", data, 8)[0]
    auth = plistlib.loads(data[12 : 12 + auth_size])
    certificate = x509.load_der_x509_certificate(auth["SigningCertificateChain"][0])
    public_key = certificate.public_key().public_bytes(
        serialization.Encoding.PEM,
        serialization.PublicFormat.SubjectPublicKeyInfo,
    )
    payload = aea.decode(data, signature_pub=public_key)
    start = payload.find(b"bplist00")
    if start < 0:
        raise ValueError("No shortcut plist found in Apple Archive")
    return plistlib.loads(payload[start:])


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", type=Path, nargs="+")
    parser.add_argument("--details", action="store_true")
    parser.add_argument("--indices", help="Comma-separated 1-based action indexes")
    args = parser.parse_args()
    selected = {int(value) for value in args.indices.split(",")} if args.indices else None
    for path in args.paths:
        workflow = read_workflow(path)
        actions = workflow.get("WFWorkflowActions", [])
        print(f"{path.name}: {len(actions)} actions")
        for index, action in enumerate(actions, 1):
            if selected and index not in selected:
                continue
            identifier = action.get("WFWorkflowActionIdentifier", "unknown")
            params = action.get("WFWorkflowActionParameters", {})
            keys = ", ".join(k for k in params if k != "UUID")
            print(f"{index:02d}. {identifier} [{keys}]")
            if args.details:
                for key, value in params.items():
                    if key == "UUID":
                        continue
                    print(f"    {key}: {safe_value(key, value)}")


def safe_value(key: str, value: object) -> str:
    if re.search(r"authorization|credential|secret|password|token|httpheaders", key, re.I):
        return "<redacted>"
    if isinstance(value, bytes):
        return f"<bytes {len(value)}>"
    if isinstance(value, dict):
        return "{" + ", ".join(f"{k}: {safe_value(k, v)}" for k, v in value.items()) + "}"
    if isinstance(value, list):
        return "[" + ", ".join(safe_value(key, item) for item in value) + "]"
    if isinstance(value, str):
        value = re.sub(r"(?i)\b(?:ntn|secret|sk)_[A-Za-z0-9_-]{8,}", "<redacted>", value)
        value = re.sub(r"https?://[^\s\"']+", lambda match: safe_url(match.group()), value)
        return repr(value[:500] + ("…" if len(value) > 500 else ""))
    return repr(value)


def safe_url(url: str) -> str:
    parsed = urlsplit(url)
    return f"{parsed.scheme}://{parsed.netloc}{parsed.path}"


if __name__ == "__main__":
    main()
