pragma Singleton
import QtQuick
import Quickshell

// Mirrors the Niri layout theme (niri/settings.nix): Gruvbox dark, square
// corners, 2px borders with the pink active-border accent, 5px gaps.
Singleton {
    readonly property color bg: "#282828"
    readonly property color bg1: "#3c3836"
    readonly property color bg2: "#504945"
    readonly property color fg: "#ebdbb2"
    readonly property color muted: "#928374"
    readonly property color accent: "#d3869b"
    readonly property color border: "#3c3836"
    readonly property color green: "#b8bb26"
    readonly property color yellow: "#fabd2f"
    readonly property color red: "#fb4934"
    readonly property color orange: "#fe8019"
    readonly property color aqua: "#8ec07c"
    readonly property color blue: "#83a598"

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int iconSize: 16
    readonly property int barHeight: 28
    readonly property int borderWidth: 2
    readonly property int gap: 5
}
