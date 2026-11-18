#!/usr/bin/env python3

import argparse
import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parent
PUBSPEC = ROOT / "pubspec.yaml"
VERSION_PATTERN = re.compile(r"^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+\d+)?\s*$", re.MULTILINE)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build the Flutter web app with a temporary, traceable version."
    )
    parser.add_argument(
        "--build-number",
        type=int,
        help="Build number to stamp into pubspec.yaml for this build.",
    )
    parser.add_argument("--base-href", default="/", help="Flutter web base href.")
    return parser.parse_args()


def get_build_number() -> int:
    output = subprocess.check_output(
        ["git", "rev-list", "--count", "HEAD"], cwd=ROOT, text=True
    )
    return int(output.strip())


def main() -> None:
    args = parse_args()
    original_pubspec = PUBSPEC.read_text()
    match = VERSION_PATTERN.search(original_pubspec)
    if match is None:
        raise SystemExit("pubspec.yaml does not contain a three-part version.")

    build_number = (
        args.build_number if args.build_number is not None else get_build_number()
    )
    if build_number < 1:
        raise SystemExit("The build number must be a positive integer.")

    build_name = match.group(1)
    build_version = f"{build_name}+{build_number}"
    stamped_pubspec = VERSION_PATTERN.sub(
        f"version: {build_version}", original_pubspec, count=1
    )
    PUBSPEC.write_text(stamped_pubspec)
    print(f"Building SwaraGuru v{build_version}")

    try:
        subprocess.run(
            [
                "flutter",
                "build",
                "web",
                "--release",
                "--build-name",
                build_name,
                "--build-number",
                str(build_number),
                "--base-href",
                args.base_href,
                "--dart-define",
                f"APP_VERSION={build_version}",
            ],
            cwd=ROOT,
            check=True,
        )
    finally:
        PUBSPEC.write_text(original_pubspec)
        print("Restored pubspec.yaml; the build version was not committed.")


if __name__ == "__main__":
    main()
