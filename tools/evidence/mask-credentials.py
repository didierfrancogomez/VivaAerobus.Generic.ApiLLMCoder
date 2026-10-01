# -*- coding: utf-8 -*-
"""Mask credentials in an evidence folder before it is versioned (this repo is public).

    python tools/evidence/mask-credentials.py <dir>                      mask in place
    python tools/evidence/mask-credentials.py --from <src> --to <dst>    copy the tree, masking on the way
    python tools/evidence/mask-credentials.py --check [--git] <dir>      exit 1 if anything is still unmasked

Only CREDENTIALS are masked: bearer/basic tokens, JWTs, password/secret/token/api-key values,
cookies, card number/CVV. Everything else stays exactly as captured (requests, responses, headers,
PNR, names): the classic evidence stays complete, only the secret VALUE becomes "<redacted>".
--check never prints a value, only file:line and the rule. --git limits the scan to the files git
would version (tracked + untracked, minus .gitignore). Images are not scanned: they come out of
tools/evidence already redacted, and a manual capture must be reviewed by eye.
"""
import argparse
import bisect
import io
import os
import re
import shutil
import subprocess
import sys

MASK = "<redacted>"
BINARY_EXT = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".ico", ".pdf", ".zip", ".gz", ".7z",
              ".woff", ".woff2", ".ttf", ".eot", ".mp4", ".webm", ".mov", ".xlsx", ".docx", ".pptx"}
PLACEHOLDER = re.compile(r"^(|<[^>]*>?|\{\{.*|\$.*|\*+|•+|\**REDACTED\**|redacted|null|none|true|false|x+)$", re.I)

SECRET_KEY = (r"[A-Za-z_]*[Pp]ass(?:word|wd)|pwd|[A-Za-z_]*[Ss]ecret|[A-Za-z_]*[Tt]oken|api_?[Kk]ey|apiKey|"
              r"subscription_?[Kk]ey|private_?[Kk]ey|cvv|cvc|securityCode|cardNumber|storedPaymentKey")
HEADER_KEY = r"x-api-key|ocp-apim-subscription-key|x-functions-key|api-key"

RULES = [
    ("json-secret", re.compile(
        r'(?P<q1>\\*")(?P<key>' + SECRET_KEY + r')(?P=q1)(?P<sep>\s*:\s*)(?P<q2>\\*")(?P<val>[^\r\n]*?)(?P=q2)'),
     lambda m: None if PLACEHOLDER.match(m["val"]) else
        f'{m["q1"]}{m["key"]}{m["q1"]}{m["sep"]}{m["q2"]}{MASK}{m["q2"]}'),
    ("card-number", re.compile(r'(?P<q1>\\*")number(?P=q1)(?P<sep>\s*:\s*)(?P<q2>\\*")(?P<val>\d{13,19})(?P=q2)'),
     lambda m: f'{m["q1"]}number{m["q1"]}{m["sep"]}{m["q2"]}{MASK}{m["q2"]}'),
    ("postman-variable", re.compile(
        r'(?P<head>"value"\s*:\s*")(?P<val>[^"]*)(?P<tail>"\s*,\s*"key"\s*:\s*"(?:' + SECRET_KEY + r')")'),
     lambda m: None if PLACEHOLDER.match(m["val"]) else f'{m["head"]}{MASK}{m["tail"]}'),
    ("postman-variable", re.compile(
        r'(?P<head>"key"\s*:\s*"(?:' + SECRET_KEY + r')"\s*,\s*(?:"type"\s*:\s*"[^"]*"\s*,\s*)?"value"\s*:\s*")(?P<val>[^"]*)'),
     lambda m: None if PLACEHOLDER.match(m["val"]) else f'{m["head"]}{MASK}'),
    ("postman-header", re.compile(
        r'(?P<head>"key"\s*:\s*"(?:' + HEADER_KEY + r')"\s*,\s*"value"\s*:\s*")(?P<val>[^"]+)', re.I),
     lambda m: None if PLACEHOLDER.match(m["val"]) else f'{m["head"]}{MASK}'),
    ("api-key-header", re.compile(r'(?P<head>(?:' + HEADER_KEY + r')["\']?\s*[:=]\s*["\']?)(?P<val>[^\s"\'\\,;}]{6,})', re.I),
     lambda m: None if PLACEHOLDER.match(m["val"]) else f'{m["head"]}{MASK}'),
    ("assignment", re.compile(
        r'(?P<head>(?<![A-Za-z0-9_])\$?(?:[A-Za-z_]*[Pp]assword|client_?secret|clientSecret|api_?key|apiKey|secret)\s*=\s*)'
        r'(?P<q>["\'])(?P<val>[^"\'\r\n]*)(?P=q)'),
     lambda m: None if PLACEHOLDER.match(m["val"]) else f'{m["head"]}{m["q"]}{MASK}{m["q"]}'),
    ("form-field", re.compile(
        r'(?P<head>(?:^|(?<=[?&\s\'"]))(?:password|client_secret|api_key|apikey|access_token|refresh_token|token)=)'
        r'(?P<val>[^&\s\'"\\\r\n]+)', re.I | re.M),
     lambda m: None if PLACEHOLDER.match(m["val"]) else f'{m["head"]}{MASK}'),
    ("cookie", re.compile(r'(?P<head>(?<![-.\w])(?:Set-)?Cookie\s*:\s*)(?!(?:before|after)\b)(?P<val>[^\r\n\'"\\]{8,})', re.I),
     lambda m: None if PLACEHOLDER.match(m["val"].strip()) else f'{m["head"]}{MASK}'),
    ("bearer", re.compile(r'(?P<head>\b(?:Bearer|Basic)\s+)(?P<val>[A-Za-z0-9._~+/=-]{8,})'),
     lambda m: None if len(m["val"]) < 16 and not re.search(r"[0-9=._+/-]", m["val"]) else f'{m["head"]}{MASK}'),
    ("jwt", re.compile(r'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'),
     lambda m: MASK),
]


def mask_text(text):
    hits = []
    for name, pattern, replace in RULES:
        newlines = [m.start() for m in re.finditer("\n", text)]

        def sub(m, name=name, replace=replace, newlines=newlines):
            new = replace(m)
            if new is None or new == m.group(0):
                return m.group(0)
            hits.append((name, bisect.bisect_left(newlines, m.start()) + 1))
            return new
        text = pattern.sub(sub, text)
    return text, hits


def read_text(path):
    raw = open(path, "rb").read()
    for bom, enc in ((b"\xef\xbb\xbf", "utf-8-sig"), (b"\xff\xfe", "utf-16"), (b"\xfe\xff", "utf-16")):
        if raw.startswith(bom):
            return raw.decode(enc), enc
    if b"\x00" in raw:
        return None, None
    try:
        return raw.decode("utf-8"), "utf-8"
    except UnicodeDecodeError:
        return raw.decode("cp1252", errors="replace"), "cp1252"


def write_text(path, text, encoding):
    with io.open(path, "w", encoding=encoding, newline="") as handle:
        handle.write(text)


def walk(root):
    if os.path.isfile(root):
        yield root
        return
    for folder, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in (".git", "node_modules", ".runs", ".auth")]
        for name in sorted(files):
            yield os.path.join(folder, name)


def git_files(root):
    top = subprocess.run(["git", "-C", os.path.dirname(os.path.abspath(root)) or ".", "rev-parse", "--show-toplevel"],
                         capture_output=True, text=True)
    if top.returncode != 0:
        return list(walk(root))
    listed = subprocess.run(["git", "-C", top.stdout.strip(), "ls-files", "-z", "--cached", "--others",
                             "--exclude-standard", "--", os.path.abspath(root)], capture_output=True)
    names = [n for n in listed.stdout.decode("utf-8", "replace").split("\0") if n]
    return [os.path.join(top.stdout.strip(), n) for n in names if os.path.isfile(os.path.join(top.stdout.strip(), n))]


def is_binary_name(path):
    return os.path.splitext(path)[1].lower() in BINARY_EXT


def check(root, use_git):
    files = git_files(root) if use_git else list(walk(root))
    findings, images = [], 0
    for path in files:
        if is_binary_name(path):
            images += 1
            continue
        text, _ = read_text(path)
        if text is None:
            continue
        _, hits = mask_text(text)
        findings += [(path, line, rule) for rule, line in hits]
    for path, line, rule in findings:
        print(f"✖ {os.path.relpath(path)}:{line}  unmasked {rule}")
    status = "✖" if findings else "✔"
    print(f"{status} {len(files)} file(s) scanned · {len(findings)} unmasked credential(s) · {images} image(s) not scanned (review them by eye)")
    return 1 if findings else 0


def mask_in_place(root):
    changed = total = 0
    for path in walk(root):
        if is_binary_name(path):
            continue
        text, encoding = read_text(path)
        if text is None:
            continue
        masked, hits = mask_text(text)
        if hits:
            write_text(path, masked, encoding)
            changed += 1
            total += len(hits)
            print(f"✔ {os.path.relpath(path)}: {len(hits)} credential(s) masked")
    print(f"✔ {changed} file(s) changed · {total} credential(s) masked")
    return 0


def copy_masked(src, dst, force):
    copied = total = 0
    for path in walk(src):
        target = os.path.join(dst, os.path.relpath(path, src))
        if os.path.exists(target) and not force:
            sys.exit(f"✖ {target} already exists — pass --force to overwrite")
        os.makedirs(os.path.dirname(target), exist_ok=True)
        text, encoding = (None, None) if is_binary_name(path) else read_text(path)
        if text is None:
            shutil.copy2(path, target)
        else:
            masked, hits = mask_text(text)
            write_text(target, masked, encoding)
            total += len(hits)
        copied += 1
    print(f"✔ {copied} file(s) copied to {dst} · {total} credential(s) masked")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("path", nargs="?")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--git", action="store_true")
    parser.add_argument("--from", dest="src")
    parser.add_argument("--to", dest="dst")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    if args.src or args.dst:
        if not (args.src and args.dst):
            parser.error("--from and --to go together")
        return copy_masked(args.src, args.dst, args.force)
    if not args.path:
        parser.error("a folder is required")
    if not os.path.exists(args.path):
        sys.exit(f"✖ {args.path} does not exist")
    return check(args.path, args.git) if args.check else mask_in_place(args.path)


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.exit(main())
