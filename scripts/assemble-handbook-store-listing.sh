#!/usr/bin/env python3
"""Generate the handbook store-listing block from the Fastlane metadata.

The Fastlane metadata under ios/fastlane/metadata + android/fastlane/metadata
(and the screenshots) is the single source of truth for what ships to App
Store Connect / Play Console. The handbook section at handbook.realunit.app is
a *derived export* of those files — never hand-edited. This mirrors the
upstream/downstream relationship that docs/handbook/mails/ already has with
DFXswiss/api's mail templates.

Usage:
    scripts/assemble-handbook-store-listing.sh <output-dir>

Used by:
  - Dockerfile.handbook (store-listing-builder stage → /usr/share/nginx/html/store/)
  - .github/workflows/handbook-build-check.yaml (sync gate: re-run + git diff)
  - local previews (run it, then open docs/handbook/de/index.html)

What it does:
  1. Copies the store PNGs into <out>/{ios,android}/... (the layout the
     handbook HTML links to via ../store/...).
  2. Reads the metadata .txt files.
  3. Renders scripts/templates/store-listing.html.tmpl into
     <out>/store-listing.html.
  4. Substitutes the rendered block between the
     <!-- BEGIN:store-listing --> / <!-- END:store-listing --> markers in
     docs/handbook/de/index.html in place. This is what guarantees the page
     IS the export, not a separate copy. The operation is idempotent.
"""
import html
import shutil
import sys
from pathlib import Path

BEGIN = "<!-- BEGIN:store-listing -->"
END = "<!-- END:store-listing -->"


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <output-dir>", file=sys.stderr)
        return 2

    repo = Path(__file__).resolve().parent.parent
    out = Path(sys.argv[1])
    ios = repo / "ios/fastlane/metadata/de-DE"
    android = repo / "android/fastlane/metadata/android/de-DE"

    # 1) Copy PNGs into <out>/{ios,android}/...
    mappings = [
        (repo / "ios/fastlane/screenshots/de-DE/iPhone 6.9 Display", out / "ios/iphone-69"),
        (repo / "ios/fastlane/screenshots/de-DE/iPad Pro (13 inch) Display", out / "ios/ipad-13"),
        (android / "images/phoneScreenshots", out / "android/phone"),
        (android / "images/sevenInchScreenshots", out / "android/seven-inch"),
        (android / "images/tenInchScreenshots", out / "android/ten-inch"),
    ]
    for src, dst in mappings:
        if not src.is_dir():
            print(f"error: screenshot source missing: {src}", file=sys.stderr)
            return 1
        dst.mkdir(parents=True, exist_ok=True)
        for png in sorted(src.glob("*.png")):
            shutil.copy2(png, dst / png.name)

    (out / "android").mkdir(parents=True, exist_ok=True)
    shutil.copy2(android / "images/featureGraphic.png", out / "android/featureGraphic.png")
    shutil.copy2(android / "images/icon.png", out / "android/icon.png")

    # 2) Read text content (UTF-8 safe)
    def read(p: Path) -> str:
        return p.read_text(encoding="utf-8").strip()

    ctx = {
        "ios_name": html.escape(read(ios / "name.txt")),
        "ios_subtitle": html.escape(read(ios / "subtitle.txt")),
        "ios_description": html.escape(read(ios / "description.txt")),
        "ios_keywords": html.escape(read(ios / "keywords.txt")),
        "ios_marketing_url": html.escape(read(ios / "marketing_url.txt")),
        "ios_privacy_url": html.escape(read(ios / "privacy_url.txt")),
        "ios_support_url": html.escape(read(ios / "support_url.txt")),
        "ios_copyright": html.escape(read(ios / "copyright.txt")),
        "ios_release_notes": html.escape(read(ios / "release_notes.txt")),
        "android_title": html.escape(read(android / "title.txt")),
        "android_short": html.escape(read(android / "short_description.txt")),
        # NOT escaped — Google Play allows a subset of HTML in the long description.
        "android_full_html": read(android / "full_description.txt"),
        "android_changelog": html.escape(read(android / "changelogs/default.txt")),
    }

    # 3) Render the block from the template
    template = Path(__file__).parent / "templates/store-listing.html.tmpl"
    rendered = template.read_text(encoding="utf-8").strip("\n")
    for key, value in ctx.items():
        rendered = rendered.replace("{{ " + key + " }}", value)

    leftover = [k for k in ("{{ ", " }}") if k in rendered]
    if leftover:
        print("error: unresolved template placeholders remain in rendered output", file=sys.stderr)
        return 1

    out.mkdir(parents=True, exist_ok=True)
    (out / "store-listing.html").write_text(rendered + "\n", encoding="utf-8")

    # 4) Substitute the block in docs/handbook/de/index.html in place (idempotent)
    index = repo / "docs/handbook/de/index.html"
    content = index.read_text(encoding="utf-8")
    if BEGIN not in content or END not in content:
        print(
            f"error: {index} is missing the {BEGIN} / {END} markers — add them once "
            "(see the scope-extension comment on issue #634) before running this script.",
            file=sys.stderr,
        )
        return 1
    b = content.index(BEGIN)
    e = content.index(END) + len(END)
    new = content[:b] + BEGIN + "\n" + rendered + "\n" + END + content[e:]
    index.write_text(new, encoding="utf-8")

    pngs = sum(1 for _ in out.rglob("*.png"))
    print(f"rendered store-listing block + {pngs} PNGs into {out}; synced {index}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
