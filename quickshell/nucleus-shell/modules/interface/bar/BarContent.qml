import QtQuick
import QtQuick.Layouts
import Quickshell
import "content/"
import qs.config
import qs.services
import qs.modules.components

Item {
    id: root
    property string displayName: screen?.name ?? ""
    property bool isHorizontal: (ConfigResolver.bar(displayName).position === "top" || ConfigResolver.bar(displayName).position === "bottom")

    Row {
        id: hCenterRow
        visible: isHorizontal
        anchors.centerIn: parent
        spacing: Metrics.spacing(4)

        ClockModule {
            format: "MM/dd  HH:mm"
        }
    }

    RowLayout {
        id: hLeftRow

        visible: isHorizontal
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Metrics.spacing(10)
        anchors.leftMargin: ConfigResolver.bar(displayName).density * 0.3

        ToggleModule {
            icon: "menu"
            iconSize: Metrics.iconSize(22)
            iconColor: Appearance.m3colors.m3primary
            openOnHover: true
            onHoverOpened: DesktopHub.openSidebar("left")
            toggle: Globals.visiblility.sidebarLeft

            onToggled: function(value) {
                Globals.visiblility.sidebarLeft = value
            }
        }

        WorkspaceModule {}
        ToggleModule {
            icon: "terminal"
            iconSize: Metrics.iconSize(23)
            iconColor: Appearance.m3colors.m3primary
            openOnHover: true
            onHoverOpened: DesktopHub.openTerminal()
            onToggled: DesktopHub.toggleTerminal()
        }

        MediaPlayerModule {
            // Keep the clock fixed and avoid a placeholder when nothing is playing.
            visible: Mpris.isPlaying && root.width >= 1500
        }

    }

    RowLayout {
        id: hRightRow

        visible: isHorizontal
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Metrics.spacing(10)
        anchors.rightMargin: ConfigResolver.bar(displayName).density * 0.3

        SystemStatsModule {}

        VolumeModule {}

        BatteryIndicatorModule {}

        SystemTray {
            id: sysTray
            visible: items.count > 0
        }

        StatusIconsModule {}

        ToggleModule {
            icon: "power_settings_new"
            iconSize: Metrics.iconSize(22)
            iconColor: Appearance.m3colors.m3error
            openOnHover: true
            onHoverOpened: Globals.visiblility.powermenu = true
            toggle: Globals.visiblility.powermenu

            onToggled: function(value) {
                Globals.visiblility.powermenu = value
            }
        }
    }

    // Vertical Layout
    Item {
        visible: !isHorizontal
        anchors.top: parent.top
        anchors.topMargin: ConfigResolver.bar(displayName).density * 0.1
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: vRow.implicitHeight
        implicitHeight: vRow.implicitWidth

        Row {
            id: vRow
            anchors.centerIn: parent
            spacing: Metrics.spacing(8)
            rotation: 90

            ToggleModule {
                icon: "menu"
                iconSize: Metrics.iconSize(22)
                iconColor: Appearance.m3colors.m3error
                openOnHover: true
                onHoverOpened: DesktopHub.openSidebar("left")
                toggle: Globals.visiblility.sidebarLeft
                rotation: 270

                onToggled: function(value) {
                    Globals.visiblility.sidebarLeft = value
                }
            }

        ToggleModule {
            icon: "terminal"
            rotation: 270
            iconSize: Metrics.iconSize(23)
            iconColor: Appearance.m3colors.m3primary
            openOnHover: true
            onHoverOpened: DesktopHub.openTerminal()
            onToggled: DesktopHub.toggleTerminal()
        }
            BongoCat {}
            SystemUsageModule {}
            MediaPlayerModule {}

            SystemTray {
                rotation: 0
            }
        }
    }

    Item {
        visible: !isHorizontal
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 35
        implicitWidth: centerRow.implicitHeight
        implicitHeight: centerRow.implicitWidth

        Row {
            id: centerRow
            anchors.centerIn: parent

            WorkspaceModule {
                rotation: 90
            }
        }
    }

    Item {
        visible: !isHorizontal
        anchors.bottom: parent.bottom
        anchors.bottomMargin: ConfigResolver.bar(displayName).density * 0.1
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: row.implicitHeight
        implicitHeight: row.implicitWidth

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Metrics.spacing(6)
            rotation: 90

            ClockModule {
                rotation: 270
            }

            StatusIconsModule {}
            BatteryIndicatorModule {}

            ToggleModule {
                icon: "power_settings_new"
                iconSize: Metrics.iconSize(22)
                iconColor: Appearance.m3colors.m3error
                openOnHover: true
                onHoverOpened: Globals.visiblility.powermenu = true
                toggle: Globals.visiblility.powermenu
                rotation: 270

                onToggled: function(value) {
                    Globals.visiblility.powermenu = value
                }
            }
        }
    }
}
