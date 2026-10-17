import QtQuick
import QtQuick.Controls
import qs.config
import qs.modules.components
import qs.services

Item {
    id: root
    implicitWidth: 28
    implicitHeight: ConfigResolver.bar(screen?.name ?? "").modules.height

    MaterialSymbol {
        anchors.centerIn: parent
        icon: "monitor_heart"
        iconSize: 20
        color: Appearance.m3colors.m3onSurface
    }

    HoverHandler { id: hover }
    ToolTip.visible: hover.hovered
    ToolTip.delay: 350
    ToolTip.text: "CPU  " + SystemDetails.cpuLoad
        + "\nメモリ  " + SystemDetails.ramUsage
        + "\n温度  " + SystemDetails.cpuTemp
}
