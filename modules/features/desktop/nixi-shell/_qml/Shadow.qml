import QtQuick
import QtQuick.Effects

// Drop shadow matching the one niri gives windows. Give it the geometry of the
// box it shadows; the surface needs Theme.shadowReach of room around that box.
RectangularShadow {
    blur: Theme.shadowBlur
    spread: Theme.shadowSpread
    offset.y: Theme.shadowOffset
    color: Theme.shadowColor
}
