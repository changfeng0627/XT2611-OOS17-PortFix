#!/usr/bin/env python3
import os
import re
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MOD_DIR = os.path.join(ROOT, "module")


def read_version() -> str:
    prop = os.path.join(MOD_DIR, "module.prop")
    with open(prop, "r", encoding="utf-8") as f:
        for line in f:
            m = re.match(r"^version=(.+)$", line.strip())
            if m:
                return m.group(1)
    return "v1.0.0"


def main() -> None:
    version = read_version()
    out_zip = os.path.join(ROOT, f"AVR_PortFix-{version}.zip")
    with zipfile.ZipFile(out_zip, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(MOD_DIR):
            dirs.sort()
            files.sort()
            for name in files:
                fp = os.path.join(root, name)
                rel = os.path.relpath(fp, MOD_DIR).replace(os.sep, "/")
                zi = zipfile.ZipInfo(rel)
                zi.compress_type = zipfile.ZIP_DEFLATED
                if rel.endswith(".sh") or "update-binary" in rel:
                    zi.external_attr = 0o755 << 16
                else:
                    zi.external_attr = 0o644 << 16
                with open(fp, "rb") as f:
                    zf.writestr(zi, f.read())
    with zipfile.ZipFile(out_zip, "r") as zf:
        assert zf.testzip() is None
    print(f"Built: {out_zip} ({os.path.getsize(out_zip)} bytes)")


if __name__ == "__main__":
    main()
