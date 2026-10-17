import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.functions
import qs.config
import qs.modules.components

Item {
    id: clockContainer

    property string format: isVertical ? "MM/dd\nHH:mm" : "MM/dd HH:mm"
    property bool isVertical: (ConfigResolver.bar(screen?.name ?? "").position === "left" || ConfigResolver.bar(screen?.name ?? "").position === "right")
    property var weekLabels: ["日", "月", "火", "水", "木", "金", "土"]
    property date calendarDate: Time.date
    readonly property int calendarYear: calendarDate.getFullYear()
    readonly property int calendarMonth: calendarDate.getMonth()
    readonly property int calendarFirstWeekday: new Date(calendarYear, calendarMonth, 1).getDay()
    readonly property int calendarDaysInMonth: new Date(calendarYear, calendarMonth + 1, 0).getDate()
    readonly property int calendarWeekRows: Math.ceil((calendarFirstWeekday + calendarDaysInMonth) / 7)

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: bgRect.implicitWidth
    implicitHeight: bgRect.implicitHeight

    function calendarCellText(index) {
        const day = index - calendarFirstWeekday + 1
        return day >= 1 && day <= calendarDaysInMonth ? String(day) : ""
    }

    function isToday(day) {
        if (day <= 0)
            return false
        const now = Time.date
        return now.getFullYear() === calendarYear
            && now.getMonth() === calendarMonth
            && now.getDate() === day
    }

    function toggleCalendarTab() {
        if (calendarPopout.isVisible)
            calendarPopout.hide()
        else
            calendarPopout.show()
    }

    Rectangle {
        id: bgRect

        color: isVertical ? "transparent" : ColorUtils.transparentize(Appearance.m3colors.m3paddingContainer, 0.88)
        radius: ConfigResolver.bar(screen?.name ?? "").modules.radius * Config.runtime.appearance.rounding.factor
        // Padding around the text
        implicitWidth: isVertical ? textItem.implicitWidth + 40 : textItem.implicitWidth + Metrics.margin("large")
        implicitHeight: ConfigResolver.bar(screen?.name ?? "").modules.height
    }

    StyledText {
        id: textItem
        anchors.centerIn: parent
        animate: false
        text: Time.format(clockContainer.format)
    }

    HoverHandler {
        id: clockHover
    }

    StyledPopout {
        id: calendarPopout
        hoverTarget: clockHover
        interactable: true
        requiresHover: true
        hCenterOnItem: true

        Component {
            Rectangle {
                color: Appearance.m3colors.m3surfaceContainer
                radius: ConfigResolver.bar(screen?.name ?? "").modules.radius * Config.runtime.appearance.rounding.factor
                implicitWidth: 260
                implicitHeight: 230 + Math.max(0, clockContainer.calendarWeekRows - 5) * 28

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.margin.normal
                    spacing: Appearance.margin.small

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Time.format("yyyy年M月")
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: clockContainer.weekLabels
                            delegate: StyledText {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                color: Appearance.m3colors.m3onSurfaceVariant
                                font.pixelSize: Appearance.font.size.small
                            }
                        }
                    }

                    GridLayout {
                        columns: 7
                        columnSpacing: 4
                        rowSpacing: 4
                        Layout.fillWidth: true

                        Repeater {
                            model: clockContainer.calendarWeekRows * 7
                            delegate: Rectangle {
                                required property int index
                                readonly property string dayText: clockContainer.calendarCellText(index)
                                readonly property int dayNumber: dayText === "" ? -1 : parseInt(dayText)
                                color: dayText !== "" && clockContainer.isToday(dayNumber)
                                    ? Appearance.m3colors.m3primaryContainer
                                    : "transparent"
                                radius: 8
                                Layout.fillWidth: true
                                implicitHeight: 24

                                StyledText {
                                    anchors.centerIn: parent
                                    text: parent.dayText
                                    color: parent.dayText === ""
                                        ? "transparent"
                                        : (clockContainer.isToday(parent.dayNumber)
                                            ? Appearance.m3colors.m3onPrimaryContainer
                                            : Appearance.m3colors.m3onSurface)
                                    font.pixelSize: Appearance.font.size.small
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: clockContainer.toggleCalendarTab()
    }

}
