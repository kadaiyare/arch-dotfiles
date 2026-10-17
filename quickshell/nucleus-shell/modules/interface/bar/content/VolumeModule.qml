import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.modules.components
import qs.services

Item {
    id: root
    implicitWidth: row.implicitWidth + 8
    implicitHeight: ConfigResolver.bar(screen?.name ?? "").modules.height

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 5

        MaterialSymbol {
            icon: Volume.muted ? "volume_off" : (Volume.volume > 0.5 ? "volume_up" : "volume_down")
            iconSize: 20
            color: Volume.muted ? Appearance.m3colors.m3error : Appearance.m3colors.m3onSurface
        }

        StyledText {
            animate: false
            text: Math.round(Volume.volume * 100) + "%"
            font.pixelSize: 14
            color: Appearance.m3colors.m3onSurface
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (Globals.visiblility.sidebarRight)
                Globals.visiblility.sidebarRight = false
            else
                DesktopHub.openSidebar("right")
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y !== 0) {
                Volume.setVolume(Volume.volume + (wheel.angleDelta.y > 0 ? 0.02 : -0.02))
                wheel.accepted = true
            }
        }
    }

    ToolTip.visible: mouse.containsMouse
    ToolTip.delay: 500
    ToolTip.text: "音量 · クリックで設定 / スクロールで調整"
}
