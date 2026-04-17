import argparse
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path
import re


ADB = Path(r"C:\Users\KevinPenfield\AppData\Local\Android\Sdk\platform-tools\adb.exe")
TMP_UI = "/sdcard/mg_ui.xml"
TMP_SCREEN = "/sdcard/mg_screen.png"
BOUNDS_RE = re.compile(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]")


def adb(serial: str, *args: str, check: bool = True) -> str:
    command = [str(ADB), "-s", serial, *args]
    result = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
    )
    if check and result.returncode != 0:
        raise RuntimeError(
            f"adb failed ({' '.join(command)}):\n"
            f"stdout:\n{result.stdout}\n\nstderr:\n{result.stderr}"
        )
    return result.stdout


def shell(serial: str, command: str, check: bool = True) -> str:
    return adb(serial, "shell", command, check=check)


def wait(seconds: float = 1.0) -> None:
    time.sleep(seconds)


def launch(serial: str, package_name: str) -> None:
    shell(
        serial,
        f"monkey -p {package_name} -c android.intent.category.LAUNCHER 1",
    )
    wait(4.0)


def clear_package(serial: str, package_name: str) -> None:
    shell(serial, f"pm clear {package_name}", check=False)
    wait(1.0)


def screenshot(serial: str, target_path: Path) -> None:
    target_path.parent.mkdir(parents=True, exist_ok=True)
    shell(serial, f"screencap -p {TMP_SCREEN}")
    adb(serial, "pull", TMP_SCREEN, str(target_path))


def dump_ui(serial: str) -> ET.Element:
    shell(serial, f"uiautomator dump {TMP_UI} >/dev/null")
    xml_text = adb(serial, "shell", "cat", TMP_UI)
    return ET.fromstring(xml_text)


def node_matches(node: ET.Element, needles: list[str]) -> bool:
    haystacks = [
        (node.attrib.get("text") or "").strip().lower(),
        (node.attrib.get("content-desc") or "").strip().lower(),
        (node.attrib.get("resource-id") or "").strip().lower(),
    ]
    return any(
        needle.lower() in haystack
        for needle in needles
        for haystack in haystacks
        if haystack
    )


def find_node(serial: str, *needles: str) -> ET.Element:
    root = dump_ui(serial)
    for node in root.iter("node"):
        if node_matches(node, list(needles)):
            return node
    raise RuntimeError(f"Could not find node with any of: {needles}")


def find_node_optional(serial: str, *needles: str) -> ET.Element | None:
    root = dump_ui(serial)
    for node in root.iter("node"):
        if node_matches(node, list(needles)):
            return node
    return None


def find_nodes_by_class(serial: str, class_name: str) -> list[ET.Element]:
    root = dump_ui(serial)
    return [
        node
        for node in root.iter("node")
        if (node.attrib.get("class") or "") == class_name
    ]


def wait_for_node(serial: str, *needles: str, timeout_seconds: float = 12.0) -> None:
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        if find_node_optional(serial, *needles) is not None:
            return
        wait(0.5)
    raise RuntimeError(f"Timed out waiting for UI node: {needles}")


def parse_center(bounds: str) -> tuple[int, int]:
    match = BOUNDS_RE.fullmatch(bounds)
    if match is None:
        raise RuntimeError(f"Unexpected bounds string: {bounds}")
    left, top, right, bottom = (int(group) for group in match.groups())
    return ((left + right) // 2, (top + bottom) // 2)


def tap_node(serial: str, node: ET.Element) -> None:
    x, y = parse_center(node.attrib["bounds"])
    shell(serial, f"input tap {x} {y}")
    wait(1.0)


def tap_text(serial: str, *needles: str) -> None:
    tap_node(serial, find_node(serial, *needles))


def press_back(serial: str, count: int = 1) -> None:
    for _ in range(count):
        shell(serial, "input keyevent KEYCODE_BACK")
        wait(0.8)


def swipe_up(serial: str) -> None:
    shell(serial, "input swipe 540 1750 540 550 250")
    wait(1.0)


def swipe_down(serial: str) -> None:
    shell(serial, "input swipe 540 700 540 1650 250")
    wait(1.0)


def input_text(serial: str, text: str) -> None:
    escaped = (
        text.replace("%", "%25")
        .replace(" ", "%s")
        .replace("@", "%40")
        .replace("&", "\\&")
    )
    shell(serial, f"input text {escaped}")
    wait(0.8)


def set_portrait(serial: str) -> None:
    shell(serial, "settings put system accelerometer_rotation 0")
    shell(serial, "settings put system user_rotation 0")
    wait(1.0)


def set_landscape(serial: str) -> None:
    shell(serial, "settings put system accelerometer_rotation 0")
    shell(serial, "settings put system user_rotation 1")
    wait(1.0)


def restore_auto_rotate(serial: str) -> None:
    shell(serial, "settings put system accelerometer_rotation 1", check=False)


def sales_flow(serial: str, output_dir: Path) -> None:
    package_name = "com.asme.receiving.dev"
    clear_package(serial, package_name)
    set_portrait(serial)
    launch(serial, package_name)
    wait_for_node(serial, "Start Free Trial")
    screenshot(serial, output_dir / f"{serial}_sales_home_portrait.png")
    set_landscape(serial)
    wait_for_node(serial, "Start Free Trial")
    screenshot(serial, output_dir / f"{serial}_sales_home_landscape.png")
    set_portrait(serial)
    tap_text(serial, "Start Free Trial")
    wait_for_node(serial, "Send Trial Code")
    screenshot(serial, output_dir / f"{serial}_sales_auth_portrait.png")
    edit_fields = find_nodes_by_class(serial, "android.widget.EditText")
    if not edit_fields:
        raise RuntimeError("Could not find sales auth EditText fields.")
    tap_node(serial, edit_fields[0])
    input_text(serial, "qa.stress.materialguardian@example.com")
    press_back(serial)
    screenshot(serial, output_dir / f"{serial}_sales_auth_filled.png")
    tap_text(serial, "Send Trial Code")
    wait(4.0)
    screenshot(serial, output_dir / f"{serial}_sales_code_portrait.png")
    if find_node_optional(serial, "Verify and Continue") is not None:
      tap_text(serial, "Verify and Continue")
      wait(3.0)
      screenshot(serial, output_dir / f"{serial}_sales_signed_in_plans.png")
    restore_auto_rotate(serial)


def seeded_flow(serial: str, output_dir: Path) -> None:
    package_name = "com.asme.receiving.dev"
    clear_package(serial, package_name)
    set_portrait(serial)
    launch(serial, package_name)
    wait_for_node(serial, "Create Job", timeout_seconds=16.0)
    screenshot(serial, output_dir / f"{serial}_seeded_jobs_home_portrait.png")
    set_landscape(serial)
    wait_for_node(serial, "Create Job", timeout_seconds=16.0)
    screenshot(serial, output_dir / f"{serial}_seeded_jobs_home_landscape.png")
    set_portrait(serial)

    tap_text(serial, "Account")
    screenshot(serial, output_dir / f"{serial}_seeded_account_top.png")
    swipe_up(serial)
    screenshot(serial, output_dir / f"{serial}_seeded_account_lower.png")
    press_back(serial)

    tap_text(serial, "Customization")
    screenshot(serial, output_dir / f"{serial}_seeded_customization_top.png")
    node = find_node_optional(serial, "B16 Dropdown Preferences")
    if node is not None:
        tap_node(serial, node)
        wait(1.0)
        screenshot(serial, output_dir / f"{serial}_seeded_b16_preferences.png")
        press_back(serial)
    swipe_up(serial)
    screenshot(serial, output_dir / f"{serial}_seeded_customization_lower.png")
    press_back(serial)
    swipe_down(serial)
    swipe_down(serial)
    wait_for_node(serial, "Create Job", timeout_seconds=8.0)

    tap_text(serial, "Privacy Policy")
    screenshot(serial, output_dir / f"{serial}_seeded_privacy_top.png")
    swipe_up(serial)
    screenshot(serial, output_dir / f"{serial}_seeded_privacy_lower.png")
    press_back(serial)
    swipe_up(serial)

    tap_text(serial, "MG-24031")
    screenshot(serial, output_dir / f"{serial}_seeded_job_detail_top.png")
    swipe_up(serial)
    screenshot(serial, output_dir / f"{serial}_seeded_job_detail_lower.png")

    action_node = find_node_optional(serial, "Resume Draft", "Add Receiving Report")
    if action_node is not None:
        tap_node(serial, action_node)
        wait(2.0)
        screenshot(serial, output_dir / f"{serial}_seeded_form_top.png")
        swipe_up(serial)
        screenshot(serial, output_dir / f"{serial}_seeded_form_mid.png")
        swipe_up(serial)
        screenshot(serial, output_dir / f"{serial}_seeded_form_lower.png")
        swipe_up(serial)
        screenshot(serial, output_dir / f"{serial}_seeded_form_footer.png")
        press_back(serial)
        if find_node_optional(serial, "Keep Editing") is not None:
            tap_text(serial, "Keep Editing")
            wait(1.0)
            press_back(serial)
        if find_node_optional(serial, "Leave Draft Open") is not None:
            tap_text(serial, "Leave Draft Open")
            wait(1.0)

    if find_node_optional(serial, "Export Job") is not None:
        tap_text(serial, "Export Job")
        screenshot(serial, output_dir / f"{serial}_seeded_export_dialog.png")
        press_back(serial)

    restore_auto_rotate(serial)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--serial", required=True)
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--scenario", choices=["sales", "seeded"], required=True)
    args = parser.parse_args()

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    try:
        if args.scenario == "sales":
            sales_flow(args.serial, output_dir)
        else:
            seeded_flow(args.serial, output_dir)
    finally:
        restore_auto_rotate(args.serial)
    return 0


if __name__ == "__main__":
    sys.exit(main())
