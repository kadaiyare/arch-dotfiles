import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.modules.components
import qs.services

Item {
    id: root

    anchors.fill: parent
    property bool singleColumn: width < 460
    readonly property string networkValue: {
        const label = Network.active ? Network.active.name : Network.label
        if (SystemDetails.ipAddress !== "—")
            return `${label} (${SystemDetails.ipAddress})`
        return label
    }
    readonly property string batteryValue: UPower.batteryPresent
        ? `${Math.round(UPower.percentage)}% (${UPower.acOnline ? "AC" : "Battery"})`
        : "Not present"

    readonly property var overviewEntries: [{
        label: "OS",
        value: SystemDetails.osName
    }, {
        label: "Host",
        value: `${SystemDetails.username}@${SystemDetails.hostname}`
    }, {
        label: "Kernel",
        value: SystemDetails.kernelVersion
    }, {
        label: "Uptime",
        value: SystemDetails.uptime
    }, {
        label: "Session Type",
        value: SystemDetails.sessionType
    }, {
        label: "Packages",
        value: SystemDetails.packageCount
    }, {
        label: "Shell",
        value: SystemDetails.shellName
    }, {
        label: "WM",
        value: SystemDetails.wmName
    }, {
        label: "Theme",
        value: SystemDetails.themeName
    }, {
        label: "Icons",
        value: SystemDetails.iconsName
    }, {
        label: "Font",
        value: SystemDetails.fontName
    }, {
        label: "CPU",
        value: SystemDetails.cpuLoad !== "—"
            ? `${SystemDetails.cpuModel} (load ${SystemDetails.cpuLoad})`
            : SystemDetails.cpuModel
    }, {
        label: "GPU",
        value: SystemDetails.gpuName
    }, {
        label: "Memory",
        value: SystemDetails.ramUsage
    }, {
        label: "Disk",
        value: SystemDetails.diskUsage
    }, {
        label: "Network",
        value: root.networkValue
    }, {
        label: "Battery",
        value: root.batteryValue
    }, {
        label: "Node",
        value: SystemDetails.nodeVersion
    }, {
        label: "Rust",
        value: SystemDetails.rustVersion
    }, {
        label: "OCaml",
        value: SystemDetails.ocamlVersion
    }]

    ScrollView {
        id: scroll
        anchors.fill: parent
        anchors.margins: Appearance.margin.normal
        clip: true

        ColumnLayout {
            width: scroll.availableWidth
            spacing: Appearance.margin.normal

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.margin.small

                StyledText {
                    text: SystemDetails.osIcon
                    font.family: Appearance.font.family.nerdIcons
                    font.pixelSize: 44
                    color: Appearance.colors.colPrimary
                }

                ColumnLayout {
                    spacing: 2

                    StyledText {
                        text: "Overview"
                        font.pixelSize: Appearance.font.size.big
                        font.weight: Font.DemiBold
                        color: Appearance.m3colors.m3onSurface
                    }

                    StyledText {
                        text: "fastfetch-style system snapshot"
                        font.pixelSize: Appearance.font.size.small
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: root.singleColumn ? 1 : 2
                rowSpacing: Appearance.margin.small
                columnSpacing: Appearance.margin.small

                Repeater {
                    model: root.overviewEntries
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: Math.max(64, contentLayout.implicitHeight + Appearance.margin.small * 2)
                        radius: Appearance.rounding.normal
                        color: GlassStyle.tint(Appearance.colors.colLayer2)

                        ColumnLayout {
                            id: contentLayout
                            anchors.fill: parent
                            anchors.margins: Appearance.margin.small
                            spacing: 4

                            StyledText {
                                text: modelData.label
                                font.pixelSize: Appearance.font.size.small
                                color: Appearance.colors.colSubtext
                            }

                            StyledText {
                                text: modelData.value && String(modelData.value).length > 0 ? modelData.value : "—"
                                font.pixelSize: Appearance.font.size.small
                                color: Appearance.m3colors.m3onSurface
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
}
