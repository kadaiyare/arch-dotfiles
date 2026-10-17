pragma Singleton
import QtQuick
import Quickshell
import qs.config

Singleton {
    // Match the bar's tint without changing global text or surface opacity.
    readonly property color background: Appearance.darkmode
        ? Qt.rgba(0.12, 0.12, 0.18, 0.70)
        : Qt.rgba(1, 1, 1, 0.60)
    readonly property color edge: Qt.rgba(1, 1, 1, Appearance.darkmode ? 0.16 : 0.60)

    function tint(color, alpha = 0.22) {
        const value = Qt.color(color)
        return Qt.rgba(value.r, value.g, value.b, alpha)
    }
}
