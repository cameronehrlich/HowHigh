#!/usr/bin/env python3
"""Extract UI test screenshots from .xcresult bundles into fastlane directories.

Usage examples:
    python scripts/export_screenshots.py ScreenshotResults.xcresult ScreenshotResults_iPad.xcresult
    python scripts/export_screenshots.py --clean ScreenshotResults*.xcresult

The script expects screenshot attachments named with the pattern
    <locale>-<device>-<label>
matching the convention used in ScreenshotUITests (e.g. en-US-iPhone 17 Pro-barometer).
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple

XCRESULT_TOOL = Path("/usr/bin/xcrun")
SUPPORTED_LOCALES = [
    "en-US",
    "en-GB",
    "es-ES",
    "es-MX",
    "zh-Hans",
    "ja",
    "ko",
    "de-DE",
    "fr-FR",
    "pt-BR",
    "ru",
    "ar-SA",
]



def run_xcresulttool(args: Sequence[str]) -> bytes:
    """Run xcresulttool with the provided arguments and return stdout."""
    cmd = [str(XCRESULT_TOOL), "xcresulttool", *args]
    try:
        completed = subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as exc:  # pragma: no cover
        sys.stderr.write(exc.stderr.decode() or str(exc))
        raise
    return completed.stdout


def xcresult_get(path: Path, object_id: Optional[str] = None) -> dict:
    args = ["get", "object", "--legacy", "--path", str(path)]
    if object_id:
        args.extend(["--id", object_id])
    args.extend(["--format", "json"])
    return json.loads(run_xcresulttool(args))


def xcresult_export_file(path: Path, object_id: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    args = [
        "export",
        "object",
        "--legacy",
        "--path",
        str(path),
        "--id",
        object_id,
        "--type",
        "file",
        "--output-path",
        str(destination),
    ]
    run_xcresulttool(args)


def collect_summary_ids(plan: dict) -> List[str]:
    ids: List[str] = []
    stack: List = [plan]
    while stack:
        node = stack.pop()
        if isinstance(node, dict):
            summary_ref = node.get("summaryRef")
            if summary_ref and isinstance(summary_ref, dict):
                ref_id = summary_ref.get("id", {}).get("_value")
                if ref_id:
                    ids.append(ref_id)
            stack.extend(v for v in node.values() if isinstance(v, (dict, list)))
        elif isinstance(node, list):
            stack.extend(node)
    return ids


def collect_attachments_from_summary(summary: dict) -> List[Tuple[str, str]]:
    """Return list of (filename, payload_id)."""
    results: List[Tuple[str, str]] = []

    def visit(activity: dict) -> None:
        attachments = activity.get("attachments", {})
        if isinstance(attachments, dict):
            for item in attachments.get("_values", []) or []:
                filename = item.get("filename", {}).get("_value")
                uti = item.get("uniformTypeIdentifier", {}).get("_value")
                payload_id = item.get("payloadRef", {}).get("id", {}).get("_value")
                if filename and payload_id and uti == "public.png":
                    results.append((filename, payload_id))
        subacts = activity.get("subactivities", {})
        if isinstance(subacts, dict):
            for sub in subacts.get("_values", []) or []:
                visit(sub)

    activities = summary.get("activitySummaries", {})
    if isinstance(activities, dict):
        for act in activities.get("_values", []) or []:
            visit(act)
    return results


def slugify(value: str) -> str:
    value = value.strip()
    value = re.sub(r"[\s/]+", "_", value)
    value = re.sub(r"[^A-Za-z0-9_()+-]", "", value)
    return value


def parse_attachment_name(filename: str) -> Tuple[str, str, str]:
    base = filename.rsplit(".", 1)[0]
    if "_0_" in base:
        base = base.split("_0_", 1)[0]

    detected_locale = None
    remainder = ""
    for locale in sorted(SUPPORTED_LOCALES, key=len, reverse=True):
        if base == locale or base.startswith(f"{locale}-"):
            detected_locale = locale
            remainder = base[len(locale):]
            if remainder.startswith("-"):
                remainder = remainder[1:]
            break

    if detected_locale is None and "-" in base:
        detected_locale, remainder = base.split("-", 1)
    if detected_locale is None:
        detected_locale = "en-US"
        remainder = base

    remainder = remainder.strip()
    if remainder:
        if "-" in remainder:
            device, label = remainder.rsplit("-", 1)
        else:
            device, label = remainder, "screenshot"
    else:
        device, label = "device", "screenshot"

    return detected_locale, device.strip(), label.strip()


def copy_attachment(result_path: Path, filename: str, payload_id: str, output: Path, counters: Dict[Tuple[str, str], int]) -> Path:
    locale, device, label = parse_attachment_name(filename)
    counters_key = (locale, device)
    counters[counters_key] += 1
    index = counters[counters_key]

    device_slug = slugify(device)
    label_slug = slugify(label) or "screenshot"
    dest_dir = output / locale
    dest_dir.mkdir(parents=True, exist_ok=True)
    destination = dest_dir / f"{index:02d}_{device_slug}_{label_slug}.png"

    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
        tmp_path = Path(tmp.name)
    xcresult_export_file(result_path, payload_id, tmp_path)
    shutil.move(str(tmp_path), destination)
    return destination


def export_from_xcresult(path: Path, output: Path, counters: Dict[Tuple[str, str], int]) -> List[Path]:
    exported: List[Path] = []
    root = xcresult_get(path)
    actions = root.get("actions", {}).get("_values", []) or []
    for action in actions:
        tests_ref = (
            action.get("actionResult", {})
            .get("testsRef", {})
            .get("id", {})
            .get("_value")
        )
        if not tests_ref:
            continue
        plan = xcresult_get(path, tests_ref)
        for summary_id in collect_summary_ids(plan):
            summary = xcresult_get(path, summary_id)
            attachments = collect_attachments_from_summary(summary)
            for filename, payload_id in attachments:
                try:
                    exported.append(copy_attachment(path, filename, payload_id, output, counters))
                except subprocess.CalledProcessError:
                    continue
    return exported



def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Export UI test screenshots into fastlane directories")
    parser.add_argument("results", nargs="+", type=Path, help="Paths to .xcresult bundles")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("fastlane/screenshots"),
        help="Destination root for fastlane screenshots",
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="Remove existing PNG files beneath the output directory before exporting",
    )
    args = parser.parse_args(argv)

    output_root = args.output
    if args.clean:
        for png in output_root.glob("**/*.png"):
            png.unlink()
    output_root.mkdir(parents=True, exist_ok=True)

    counters: Dict[Tuple[str, str], int] = defaultdict(int)
    exported_total: List[Path] = []
    for result in args.results:
        if not result.exists():
            sys.stderr.write(f"Warning: {result} not found, skipping\n")
            continue
        exported = export_from_xcresult(result, output_root, counters)
        exported_total.extend(exported)
        print(f"Exported {len(exported)} screenshots from {result}")

    if not exported_total:
        print("No screenshots were exported. Ensure your tests produced attachments with the expected naming pattern.")
        return 1

    print("Saved screenshots:")
    for path in exported_total:
        print(f"  {path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
