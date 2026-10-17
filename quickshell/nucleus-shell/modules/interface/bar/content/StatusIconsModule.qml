import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.modules.components
import qs.modules.functions
import qs.services

Item {
    id: statusIconsContainer

    property bool isVertical: (ConfigResolver.bar(screen?.name ?? "").position === "left" || ConfigResolver.bar(screen?.name ?? "").position === "right")

    Layout.alignment: Qt.AlignVCenter
    visible: ConfigResolver.bar(screen?.name ?? "").modules.statusIcons.enabled
    implicitWidth: bgRect.implicitWidth
    implicitHeight: bgRect.implicitHeight

    StyledRect {
        id: bgRect

        color: ColorUtils.transparentize(Appearance.m3colors.m3paddingContainer, 0.88)
        radius: ConfigResolver.bar(screen?.name ?? "").modules.radius * Config.runtime.appearance.rounding.factor
        implicitWidth: isVertical ? contentRow.implicitWidth + Appearance.margin.large - 8 : contentRow.implicitWidth + Appearance.margin.large
        implicitHeight: ConfigResolver.bar(screen?.name ?? "").modules.height

        RowLayout {
            id: contentRow

            anchors.centerIn: parent
            spacing: isVertical ? 2 : 8

            MaterialSymbol {
                id: themeIcon

                visible: ConfigResolver.bar(screen?.name ?? "").modules.statusIcons.themeStatusEnabled
                rotation: isVertical ? 270 : 0
                fill: 1
                icon: Config.runtime.appearance.theme === "light" ? "light_mode" : "dark_mode"
                iconSize: Appearance.font.size.huge
                opacity: SystemTheme.busy ? 0.5 : 1
                ToolTip.visible: statusMouse.containsMouse && statusMouse.overTheme
                ToolTip.delay: 400
                ToolTip.text: SystemTheme.error || (SystemTheme.busy ? "テーマを切り替え中…"
                    : Config.runtime.appearance.theme === "dark" ? "Catppuccin Latteへ切り替え" : "Catppuccin Mochaへ切り替え")
            }

            MaterialSymbol {
                id: wifi

                visible: ConfigResolver.bar(screen?.name ?? "").modules.statusIcons.networkStatusEnabled
                rotation: isVertical ? 270 : 0
                icon: Network.icon
                iconSize: Appearance.font.size.huge
            }

            MaterialSymbol {
                id: btIcon

                visible: ConfigResolver.bar(screen?.name ?? "").modules.statusIcons.bluetoothStatusEnabled
                rotation: isVertical ? 270 : 0
                icon: Bluetooth.icon
                iconSize: Appearance.font.size.huge
            }

            StyledText {
                id: keyboardLayoutIcon

                visible: ConfigResolver.bar(screen?.name ?? "").modules.statusIcons.keyboardLayoutStatusEnabled
                rotation: isVertical ? 270 : 0
                text: StringUtils.shortText(SystemDetails.keyboardLayout, 5)
                font.pixelSize: Appearance.font.size.huge - 4
                Layout.leftMargin: isVertical ? 0 : -3
            }

        }

        MouseArea {
            id: statusMouse
            anchors.fill: parent
            hoverEnabled: true
            readonly property bool overTheme: {
                const point = themeIcon.mapFromItem(statusMouse, mouseX, mouseY)
                return themeIcon.visible && point.x >= -4 && point.y >= -4
                    && point.x <= themeIcon.width + 4 && point.y <= themeIcon.height + 4
            }
            cursorShape: overTheme ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: mouse => {
                statusHover.stop()
                if (overTheme) {
                    SystemTheme.toggle()
                    return
                }
                if (Globals.visiblility.sidebarLeft)
                    return
                Globals.visiblility.sidebarRight = !Globals.visiblility.sidebarRight
            }
        }

        HoverIntent {
            id: statusHover
            hovered: statusMouse.containsMouse && !statusMouse.overTheme
            onTriggered: DesktopHub.openSidebar("right")
        }

    }

}
