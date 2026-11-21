"""Waybar helpers for Mango, Mako and the Fuzzel power menu."""

import html
import json
from pathlib import Path
import subprocess
import sys


NOTIFICATIONS = "org.freedesktop.Notifications"
MAKO = (NOTIFICATIONS, "/fr/emersion/Mako", "fr.emersion.Mako")
DND_MODE = "do-not-disturb"


def emit(**data):
    print(json.dumps(data), flush=True)


def window_pill(monitor):
    client = monitor.get("active_client") or {}
    if client.get("id"):
        app = client.get("appid") or "Unknown"
    else:
        tags = monitor.get("active_tags") or []
        app = "Workspace " + ", ".join(map(str, tags)) if tags else "Desktop"
    return f"<span foreground='#aaaaaa'>{html.escape(app)}</span>"


def window():
    # A monitor snapshot includes both the active client and the tags, even on an empty tag.
    with subprocess.Popen(
        ["mmsg", "watch", "all-monitors"], stdout=subprocess.PIPE, text=True
    ) as process:
        previous = None
        try:
            for line in process.stdout:
                try:
                    monitors = json.loads(line)["monitors"]
                except (ValueError, KeyError, TypeError):
                    continue
                monitor = next((m for m in monitors if m.get("active")), {})
                pill = window_pill(monitor)
                if pill != previous:
                    emit(text=pill)
                    previous = pill
        finally:
            process.terminate()


def language():
    process = subprocess.Popen(
        ["mmsg", "watch", "keyboardlayout"], stdout=subprocess.PIPE, text=True
    )
    try:
        for line in process.stdout:
            try:
                layout = json.loads(line).get("layout", "")
                text = {"English (US)": "EN", "Russian": "RU"}.get(layout, layout)
                print(json.dumps({"text": text, "tooltip": layout}), flush=True)
            except (ValueError, AttributeError):
                continue
    finally:
        process.terminate()
        process.wait()


def choose(prompt, options):
    result = subprocess.run(
        ["fuzzel", "--dmenu", "--prompt", prompt],
        input="\n".join(options), text=True, capture_output=True
    )
    return result.stdout.strip() if result.returncode == 0 else ""


def power():
    actions = {
        "Suspend": ["systemctl", "suspend"],
        "Log out": ["mmsg", "dispatch", "quit"],
        "Reboot": ["systemctl", "reboot"],
        "Shut down": ["systemctl", "poweroff"],
    }
    action = choose("Power: ", actions)
    if action in actions and choose(f"{action}? ", ["Cancel", "Confirm"]) == "Confirm":
        subprocess.run(actions[action], check=True)


def btop():
    app_id = "waybar-btop"
    result = subprocess.check_output(["mmsg", "get", "all-clients"], text=True)
    for client in json.loads(result)["clients"]:
        if client.get("appid") == app_id:
            subprocess.run(
                ["mmsg", "dispatch", "focusid", f"client,{client['id']}"], check=True
            )
            return
    subprocess.run(["alacritty", "--class", app_id, "-e", "btop"], check=True)


def busctl(*args):
    return subprocess.run(
        ["busctl", "--user", "--timeout=2s", *args],
        check=True, text=True, capture_output=True,
    ).stdout


def mako_modes():
    # No icon when another notification daemon owns the D-Bus name (e.g. Plasma).
    try:
        result = busctl("--json=short", "get-property", *MAKO, "Modes")
        return json.loads(result)["data"]
    except subprocess.CalledProcessError:
        return None


def dnd():
    modes = mako_modes()
    if modes is None:
        emit(text="")
        return
    active = DND_MODE in modes
    emit(
        text="󰂛",
        tooltip="Notifications silenced (click to resume)" if active else
                "Notifications on (click to silence)",
        **{"class": "active" if active else "inactive"},
    )


def toggle_dnd():
    modes = mako_modes()
    if modes is not None:
        if DND_MODE in modes:
            modes.remove(DND_MODE)
        else:
            modes.append(DND_MODE)
        busctl("call", *MAKO, "SetModes", "as", str(len(modes)), *modes)


def battery():
    lines = []
    for supply in sorted(Path("/sys/class/power_supply").iterdir()):
        try:
            if (supply / "type").read_text().strip() != "Battery":
                continue
            capacity = (supply / "capacity").read_text().strip()
            status = (supply / "status").read_text().strip()
        except OSError:
            continue
        lines.append(f"{supply.name}: {capacity}% ({status})")
    if lines:
        busctl(
            "call", NOTIFICATIONS, "/org/freedesktop/Notifications", NOTIFICATIONS,
            "Notify", "susssasa{sv}i", "Waybar", "0", "battery", "Battery status",
            "\n".join(lines), "0", "1", "urgency", "y", "0", "5000",
        )


if __name__ == "__main__":
    {
        "window": window, "language": language, "power": power, "btop": btop,
        "dnd": dnd, "toggle-dnd": toggle_dnd, "battery": battery,
    }[sys.argv[1]]()
