import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.components
import qs.modules.interface.codex
import qs.services

Item {
    id: root
    anchors.fill: parent

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 12
            StyledButton {
                text: "Overview"
                secondary: DesktopHub.page !== "overview"
                base_bg: secondary ? GlassStyle.tint(Appearance.m3colors.m3secondaryContainer, 0.24) : Appearance.m3colors.m3primary
                id: overviewButton
                onClicked: { overviewHover.stop(); DesktopHub.page = "overview"; }
                HoverIntent {
                    id: overviewHover
                    hovered: overviewButton.beingHovered
                    onTriggered: DesktopHub.page = "overview"
                }
            }
            StyledButton {
                text: "Codex"
                icon: "terminal"
                secondary: DesktopHub.page !== "codex"
                base_bg: secondary ? GlassStyle.tint(Appearance.m3colors.m3secondaryContainer, 0.24) : Appearance.m3colors.m3primary
                id: codexButton
                onClicked: { codexHover.stop(); DesktopHub.page = "codex"; }
                HoverIntent {
                    id: codexHover
                    hovered: codexButton.beingHovered
                    onTriggered: DesktopHub.page = "codex"
                }
            }
            StyledButton {
                text: "背景"
                icon: "wallpaper"
                secondary: DesktopHub.page !== "wallpapers"
                base_bg: secondary ? GlassStyle.tint(Appearance.m3colors.m3secondaryContainer, 0.24) : Appearance.m3colors.m3primary
                onClicked: DesktopHub.page = "wallpapers"
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            SystemOverview {
                anchors.fill: parent
                visible: DesktopHub.page === "overview"
            }
            Loader {
                anchors.fill: parent
                active: DesktopHub.page === "wallpapers"
                sourceComponent: WallpapersPage { }
            }
            Loader {
                anchors.fill: parent
                active: DesktopHub.page === "codex"
                sourceComponent: CodexPanel { compact: true }
            }
        }
    }
}
