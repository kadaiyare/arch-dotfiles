import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import Quickshell.Io
import qs.config
import qs.modules.functions
import qs.modules.components
import qs.services

Item {
    id: mediaPlayer

    property bool isVertical: (ConfigResolver.bar(screen?.name ?? "").position === "left" || ConfigResolver.bar(screen?.name ?? "").position === "right")
    property string lastFmUser: ""
    property string lastFmApiKey: ""
    property bool lastFmFetching: false
    property string lastFmStatus: "Not configured"
    property string lastFmTrackTitle: ""
    property string lastFmTrackArtist: ""
    property string lastFmTrackUrl: ""
    property bool lastFmEnvTriedInteractive: false
    readonly property bool lastFmConfigured: lastFmUser.trim() !== "" && lastFmApiKey.trim() !== ""

    Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
    implicitWidth: bgRect.implicitWidth
    implicitHeight: bgRect.implicitHeight

    function formatTime(seconds) {
        const safe = Number(seconds)
        if (isNaN(safe) || safe < 0)
            return "0:00"

        const mins = Math.floor(safe / 60)
        const secs = Math.floor(safe % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    function toggleMusicTab() {
        if (musicPopout.isVisible)
            musicPopout.hide()
        else
            musicPopout.show()
    }

    function openUrl(url) {
        if (!url || url.trim() === "")
            return
        Quickshell.execDetached(["xdg-open", url])
    }

    function sanitizeLastFmPath(value) {
        return encodeURIComponent(value || "").replace(/%20/g, "+")
    }

    function buildLastFmEnvQuery() {
        return "set -a; "
            + "for f in \"$HOME\"/.config/environment.d/*.conf; do [ -r \"$f\" ] && . \"$f\"; done; "
            + "set +a; "
            + "printf '__LASTFM_USER__=%s\\n__LASTFM_API_KEY__=%s\\n' \"${LASTFM_USER:-${LAST_FM_USER:-}}\" \"${LASTFM_API_KEY:-${LASTFM_APIKEY:-${LAST_FM_API_KEY:-}}}\""
    }

    function updateLastFmStatus() {
        if (!lastFmConfigured) {
            lastFmStatus = "Set LASTFM_USER / LASTFM_API_KEY"
            return
        }
        if (lastFmFetching) {
            lastFmStatus = "Syncing..."
            return
        }
        if (lastFmTrackTitle !== "")
            lastFmStatus = "Linked"
        else
            lastFmStatus = "No recent track"
    }

    function refreshLastFm() {
        if (lastFmFetchProc.running)
            return
        if (!lastFmConfigured) {
            lastFmTrackTitle = ""
            lastFmTrackArtist = ""
            lastFmTrackUrl = ""
            updateLastFmStatus()
            return
        }
        const endpoint = "https://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks"
            + "&user=" + encodeURIComponent(lastFmUser)
            + "&api_key=" + encodeURIComponent(lastFmApiKey)
            + "&format=json&limit=1"
        lastFmFetching = true
        updateLastFmStatus()
        lastFmFetchProc.exec(["curl", "-fsS", "--max-time", "6", endpoint])
    }

    function handleLastFmResponse(text) {
        try {
            const data = JSON.parse(text || "{}")
            const recent = data.recenttracks && data.recenttracks.track
            const track = Array.isArray(recent) ? recent[0] : recent
            if (track) {
                lastFmTrackTitle = track.name || ""
                if (typeof track.artist === "object")
                    lastFmTrackArtist = track.artist["#text"] || ""
                else
                    lastFmTrackArtist = ""
                lastFmTrackUrl = track.url || ""
            } else {
                lastFmTrackTitle = ""
                lastFmTrackArtist = ""
                lastFmTrackUrl = ""
            }
        } catch (e) {
            lastFmTrackTitle = ""
            lastFmTrackArtist = ""
            lastFmTrackUrl = ""
        }
        updateLastFmStatus()
    }

    function openLastFmProfile() {
        if (lastFmUser.trim() !== "") {
            openUrl("https://www.last.fm/user/" + sanitizeLastFmPath(lastFmUser))
            return
        }
        openUrl("https://www.last.fm")
    }

    function openLastFmTrack() {
        if (lastFmTrackUrl.trim() !== "") {
            openUrl(lastFmTrackUrl)
            return
        }
        const artist = Mpris.artist ? Mpris.artist.trim() : ""
        const title = Mpris.title ? Mpris.title.trim() : ""
        if (artist !== "" && title !== "") {
            openUrl("https://www.last.fm/music/" + sanitizeLastFmPath(artist) + "/_/" + sanitizeLastFmPath(title))
            return
        }
        openLastFmProfile()
    }

    function loadLastFmEnv() {
        const directUser = (Quickshell.env("LASTFM_USER") || Quickshell.env("LAST_FM_USER") || "").trim()
        const directApiKey = (Quickshell.env("LASTFM_API_KEY") || Quickshell.env("LASTFM_APIKEY") || Quickshell.env("LAST_FM_API_KEY") || "").trim()
        lastFmEnvTriedInteractive = false
        if (directUser !== "" && directApiKey !== "") {
            lastFmUser = directUser
            lastFmApiKey = directApiKey
            refreshLastFm()
            return
        }
        lastFmUser = ""
        lastFmApiKey = ""
        const shellPath = (Quickshell.env("SHELL") || "/bin/sh").trim()
        const resolvedShell = shellPath !== "" ? shellPath : "/bin/sh"
        const query = buildLastFmEnvQuery()
        lastFmEnvProc.exec([resolvedShell, "-lc", query])
    }

    Rectangle {
        id: bgRect

        color: ColorUtils.transparentize(Appearance.m3colors.m3paddingContainer, 0.88)
        radius: ConfigResolver.bar(screen?.name ?? "").modules.radius * Config.runtime.appearance.rounding.factor
        implicitWidth: isVertical ? row.implicitWidth + Appearance.margin.large - 10 : row.implicitWidth + Appearance.margin.large
        implicitHeight: ConfigResolver.bar(screen?.name ?? "").modules.height

    }

        Row {
            id: row

            spacing: Appearance.margin.small
            anchors.centerIn: parent

        // Icon button with rounded background
        ClippingRectangle {
            id: iconButton

            width: 24
            height: 24
            radius: ConfigResolver.bar(screen?.name ?? "").modules.radius / 1.2
            color: Appearance.colors.colLayer1Hover
            opacity: 1
            clip: true
            layer.enabled: true

                Image {
                    id: art

                    anchors.fill: parent
                    source: (Mpris.artUrl !== "") ? Mpris.artUrl : Directories.assetsPath + "/svgs/music.svg"
                layer.enabled: true

                layer.effect: ColorOverlay {
                    color: Mpris.artUrl === "" ? Config.runtime.appearance.theme === "dark" ? '#b1a4a4' : "grey" : "transparent"
                    source: art
                }

                }

                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 4000
                loops: Animation.Infinite
                running: Mpris.isPlaying && Config.runtime.appearance.animations.enabled
            }

        }


        StyledText {
            id: textItem

            text: StringUtils.shortText(Mpris.title, 16)
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 0.2
            visible: !isVertical
        }

        StyledText {
            text: Mpris.artist ? " - " + StringUtils.shortText(Mpris.artist, 12) : ""
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 0.2
            visible: !isVertical
            color: Appearance.colors.colSubtext
        }

    }

    HoverHandler {
        id: mediaHover
    }

    StyledPopout {
        id: musicPopout
        hoverTarget: mediaHover
        interactable: true
        requiresHover: true
        hCenterOnItem: true

        Component {
            Item {
                implicitWidth: 500
                implicitHeight: mainColumn.implicitHeight

                ColumnLayout {
                    id: mainColumn
                    width: 500
                    spacing: Appearance.margin.normal

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.margin.small
                        visible: Mpris.playerList.length > 1

                        Repeater {
                            model: Mpris.playerList

                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool selected: Mpris.activePlayer === modelData.player

                                radius: 14
                                height: 30
                                implicitWidth: Math.min(160, playerName.implicitWidth + 30)
                                color: selected ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surface
                                border.color: Appearance.m3colors.m3primary
                                border.width: 1

                                StyledText {
                                    id: playerName
                                    anchors.centerIn: parent
                                    text: StringUtils.shortText(modelData.identity || "Unknown", 12)
                                    color: selected ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface
                                    font.bold: selected
                                    font.pixelSize: Appearance.font.size.small
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Mpris.selectPlayer(modelData.player)
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.margin.normal

                        ClippingRectangle {
                            Layout.preferredWidth: 112
                            Layout.preferredHeight: 112
                            radius: 56
                            color: Appearance.m3colors.m3surfaceVariant
                            clip: true
                            layer.enabled: true

                            Image {
                                id: popupArt
                                anchors.fill: parent
                                source: Mpris.artUrl !== "" ? Mpris.artUrl : ""
                                fillMode: Image.PreserveAspectCrop
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                icon: "music_note"
                                iconSize: 36
                                color: Appearance.m3colors.m3onSurfaceVariant
                                visible: popupArt.status !== Image.Ready
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.margin.small

                            StyledText {
                                text: StringUtils.shortText(Mpris.title || "No Media", 36)
                                font.pixelSize: Appearance.font.size.large
                                font.bold: true
                                color: Appearance.m3colors.m3onSurface
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: StringUtils.shortText(Mpris.artist || "", 28)
                                font.pixelSize: Appearance.font.size.normal
                                color: Appearance.m3colors.m3onSurfaceVariant
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignLeft
                                spacing: Appearance.margin.normal

                                MaterialSymbol {
                                    icon: "skip_previous"
                                    iconSize: 26
                                    color: Mpris.activePlayer && Mpris.activePlayer.canGoPrevious ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3outline

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: Mpris.previous()
                                    }
                                }

                                MaterialSymbol {
                                    icon: Mpris.isPlaying ? "pause_circle" : "play_circle"
                                    iconSize: 42
                                    color: Mpris.activePlayer && Mpris.activePlayer.canTogglePlaying ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: Mpris.playPause()
                                    }
                                }

                                MaterialSymbol {
                                    icon: "skip_next"
                                    iconSize: 26
                                    color: Mpris.activePlayer && Mpris.activePlayer.canGoNext ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3outline

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: Mpris.next()
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            id: sliderTrack
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: Appearance.m3colors.m3surfaceVariant

                            Rectangle {
                                width: Mpris.length > 0 ? parent.width * Math.min(1, Mpris.position / Mpris.length) : 0
                                height: parent.height
                                radius: 3
                                color: Appearance.m3colors.m3primary
                            }

                            Rectangle {
                                width: 12
                                height: 12
                                radius: 6
                                color: Appearance.m3colors.m3primary
                                anchors.verticalCenter: parent.verticalCenter
                                x: Mpris.length > 0 ? Math.max(-width / 2, Math.min(parent.width - width / 2, parent.width * Math.min(1, Mpris.position / Mpris.length) - width / 2)) : -width / 2
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -8

                                function seek(mouse) {
                                    if (Mpris.length <= 0)
                                        return
                                    const ratio = Math.max(0, Math.min(1, mouse.x / width))
                                    Mpris.setPosition(ratio * Mpris.length)
                                }

                                onPressed: seek(mouse)
                                onPositionChanged: {
                                    if (pressed)
                                        seek(mouse)
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            StyledText {
                                text: mediaPlayer.formatTime(Mpris.position)
                                color: Appearance.m3colors.m3onSurfaceVariant
                                font.pixelSize: Appearance.font.size.small
                            }

                            Item { Layout.fillWidth: true }

                            StyledText {
                                text: mediaPlayer.formatTime(Mpris.length)
                                color: Appearance.m3colors.m3onSurfaceVariant
                                font.pixelSize: Appearance.font.size.small
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Appearance.m3colors.m3outlineVariant
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.margin.verysmall

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            StyledText {
                                text: "LAST.FM"
                                color: Appearance.m3colors.m3onSurfaceVariant
                                font.pixelSize: Appearance.font.size.small
                                font.bold: true
                            }

                            StyledText {
                                text: mediaPlayer.lastFmStatus
                                Layout.fillWidth: true
                                color: Appearance.m3colors.m3onSurfaceVariant
                                font.pixelSize: Appearance.font.size.small
                                elide: Text.ElideRight
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                radius: 10
                                color: Appearance.m3colors.m3surfaceVariant
                                border.color: Appearance.m3colors.m3outlineVariant
                                border.width: 1
                                implicitWidth: 74
                                implicitHeight: 30

                                StyledText {
                                    anchors.centerIn: parent
                                    text: "PROFILE"
                                    font.pixelSize: Appearance.font.size.small
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: mediaPlayer.openLastFmProfile()
                                }
                            }

                            Rectangle {
                                radius: 10
                                color: Appearance.m3colors.m3surfaceVariant
                                border.color: Appearance.m3colors.m3outlineVariant
                                border.width: 1
                                implicitWidth: 58
                                implicitHeight: 30

                                StyledText {
                                    anchors.centerIn: parent
                                    text: "TRACK"
                                    font.pixelSize: Appearance.font.size.small
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: mediaPlayer.openLastFmTrack()
                                }
                            }

                            Rectangle {
                                radius: 10
                                color: Appearance.m3colors.m3surfaceVariant
                                border.color: Appearance.m3colors.m3outlineVariant
                                border.width: 1
                                implicitWidth: 56
                                implicitHeight: 30

                                StyledText {
                                    anchors.centerIn: parent
                                    text: "SYNC"
                                    font.pixelSize: Appearance.font.size.small
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: mediaPlayer.loadLastFmEnv()
                                }
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: mediaPlayer.lastFmTrackTitle !== ""
                                ? StringUtils.shortText((mediaPlayer.lastFmTrackArtist !== "" ? mediaPlayer.lastFmTrackArtist + " - " : "") + mediaPlayer.lastFmTrackTitle, 62)
                                : "No recent track data"
                            color: Appearance.m3colors.m3onSurfaceVariant
                            font.pixelSize: Appearance.font.size.small
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    Process {
        id: lastFmEnvProc
        stdout: StdioCollector {
            onStreamFinished: {
                const userMatch = text.match(/__LASTFM_USER__=(.*)/)
                const keyMatch = text.match(/__LASTFM_API_KEY__=(.*)/)
                mediaPlayer.lastFmUser = userMatch ? userMatch[1].trim() : ""
                mediaPlayer.lastFmApiKey = keyMatch ? keyMatch[1].trim() : ""
                if (!mediaPlayer.lastFmConfigured && !mediaPlayer.lastFmEnvTriedInteractive) {
                    mediaPlayer.lastFmEnvTriedInteractive = true
                    const shellPath = (Quickshell.env("SHELL") || "/bin/sh").trim()
                    const resolvedShell = shellPath !== "" ? shellPath : "/bin/sh"
                    const query = mediaPlayer.buildLastFmEnvQuery()
                    const interactiveFlag = resolvedShell.endsWith("zsh") || resolvedShell.endsWith("bash") ? "-ic" : "-lc"
                    lastFmEnvProc.exec([resolvedShell, interactiveFlag, query])
                    return
                }
                mediaPlayer.refreshLastFm()
            }
        }
    }

    Process {
        id: lastFmFetchProc
        stdout: StdioCollector {
            onStreamFinished: mediaPlayer.handleLastFmResponse(text)
        }
        onExited: (exitCode, exitStatus) => {
            mediaPlayer.lastFmFetching = false
            if (exitCode !== 0 && mediaPlayer.lastFmConfigured)
                mediaPlayer.lastFmStatus = "Last.fm unavailable"
            else
                mediaPlayer.updateLastFmStatus()
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: mediaPlayer.refreshLastFm()
    }

    Component.onCompleted: {
        mediaPlayer.loadLastFmEnv()
        mediaPlayer.updateLastFmStatus()
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: mediaPlayer.toggleMusicTab()
        onEntered: iconButton.opacity = 1
        onExited: iconButton.opacity = 0.9
    }

}
