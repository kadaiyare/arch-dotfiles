import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.modules.components

Item {
    id: root
    property bool compact: false
    property bool followOutput: true
    readonly property var request: Codex.requests.length ? Codex.requests[0] : null
    property var answers: ({})
    onRequestChanged: answers = ({})
    Component.onCompleted: Codex.connect()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: "Codex"
                font.pixelSize: 24
                font.bold: true
            }
            StyledText {
                text: Codex.requests.length ? "確認待ち" : Codex.status
                Layout.fillWidth: true
                elide: Text.ElideRight
                color: Appearance.m3colors.m3onSurfaceVariant
            }
            StyledButton {
                visible: root.compact
                icon: "open_in_full"
                onClicked: { Codex.windowOpen = true; Globals.visiblility.sidebarLeft = false; }
            }
            StyledButton {
                text: "新規"
                enabled: Codex.ready && !Codex.busy
                onClicked: Codex.command({action: "new"})
            }
        }
        RowLayout {
            Layout.fillWidth: true
            ComboBox {
                id: history
                Layout.fillWidth: true
                model: [{id: "", title: "最近の会話を再開…"}].concat(Codex.threads)
                textRole: "title"
                enabled: Codex.ready && !Codex.busy
                displayText: currentText.replace(/\n/g, " ").slice(0, 65)
                onActivated: index => {
                    if (index > 0) Codex.command({action: "resume", threadId: model[index].id});
                    currentIndex = 0;
                }
            }
            StyledButton {
                icon: "refresh"
                enabled: !Codex.busy
                onClicked: {
                    if (Codex.ready) Codex.command({action: "history"});
                    else Codex.connect();
                }
            }
        }
        StyledTextField {
            Layout.fillWidth: true
            implicitHeight: 44
            padding: 8
            fieldPadding: 12
            text: Codex.cwd
            placeholderText: "作業フォルダ（絶対パス）"
            enabled: !Codex.busy && !Codex.threadId
            onTextEdited: Codex.cwd = text
        }
        StyledTextField {
            Layout.fillWidth: true
            implicitHeight: 40
            padding: 8
            fieldPadding: 12
            text: Codex.modelName
            placeholderText: "モデル（空欄でCodexの設定を使用）"
            enabled: !Codex.busy
            onTextEdited: Codex.modelName = text
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 16
            color: root.compact ? GlassStyle.tint(Appearance.m3colors.m3surfaceContainerLow) : Appearance.m3colors.m3surfaceContainerLow
            ListView {
                id: chat
                anchors.fill: parent
                anchors.margins: 12
                clip: true
                spacing: 16
                model: Codex.messages
                ScrollBar.vertical: ScrollBar {}
                onMovementEnded: root.followOutput = atYEnd
                delegate: Column {
                    required property string kind
                    required property string body
                    required property string itemStatus
                    width: chat.width
                    spacing: 4
                    StyledText {
                        text: (kind === "userMessage" ? "You" : kind === "agentMessage" ? "Codex" : kind) + (itemStatus ? " · " + itemStatus : "")
                        font.bold: true
                        color: Appearance.m3colors.m3primary
                    }
                    TextEdit {
                        width: parent.width
                        text: body
                        readOnly: true
                        selectByMouse: true
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.PlainText
                        color: Appearance.m3colors.m3onSurface
                        font.pixelSize: 14
                        font.family: kind === "commandExecution" || kind === "fileChange" ? "monospace" : Appearance.font.family.main
                    }
                }
                StyledText {
                    anchors.centerIn: parent
                    width: parent.width - 20
                    visible: chat.count === 0
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "作業フォルダを指定して依頼を入力\nファイル編集・コマンド実行・会話の継続ができます"
                    color: Appearance.m3colors.m3onSurfaceVariant
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.min(300, requestColumn.implicitHeight + 24)
            visible: root.request !== null
            radius: 12
                color: root.compact ? GlassStyle.tint(Appearance.m3colors.m3secondaryContainer, 0.30) : Appearance.m3colors.m3secondaryContainer
            ScrollView {
                anchors.fill: parent
                anchors.margins: 12
                clip: true
                ColumnLayout {
                    id: requestColumn
                    width: parent.width
                    StyledText {
                        text: "Codexからの確認"
                        font.bold: true
                    }
                    TextEdit {
                        Layout.fillWidth: true
                        text: root.request ? root.request.detail : ""
                        color: Appearance.m3colors.m3onSurface
                        readOnly: true
                        selectByMouse: true
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.PlainText
                    }
                    Repeater {
                        model: root.request ? root.request.params.questions || [] : []
                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.question
                                wrapMode: Text.WordWrap
                            }
                            ComboBox {
                                Layout.fillWidth: true
                                visible: (modelData.options || []).length > 0
                                model: [{label: "選択…"}].concat(modelData.options || [])
                                textRole: "label"
                                onActivated: index => {
                                    if (index > 0) answer.text = model[index].label;
                                }
                            }
                            StyledTextField {
                                id: answer
                                Layout.fillWidth: true
                                placeholderText: "回答を入力"
                                echoMode: modelData.isSecret ? TextInput.Password : TextInput.Normal
                                onTextChanged: root.answers[modelData.id] = text
                            }
                        }
                    }
                    RowLayout {
                        StyledButton {
                            text: root.request && root.request.method === "item/tool/requestUserInput" ? "回答" : "今回許可"
                            visible: !root.request || root.request.method !== "mcpServer/elicitation/request"
                            onClicked: Codex.respond(root.request.requestId, true, root.answers)
                        }
                        StyledButton {
                            text: "拒否 / 停止"
                            secondary: true
                            onClicked: {
                                if (root.request.method === "item/tool/requestUserInput") Codex.command({action: "stop"});
                                else Codex.respond(root.request.requestId, false);
                            }
                        }
                    }
                }
            }
        }
        StyledText {
            Layout.fillWidth: true
            visible: Codex.error !== ""
            text: Codex.error
            wrapMode: Text.Wrap
            color: Appearance.m3colors.m3error
        }
        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 86
            TextArea {
                id: input
                text: Codex.draft
                placeholderText: "Codexに依頼…（Enterで送信・Shift+Enterで改行）"
                color: Appearance.m3colors.m3onSurface
                placeholderTextColor: Appearance.m3colors.m3onSurfaceVariant
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                enabled: !Codex.busy
                onTextChanged: Codex.draft = text
            background: Rectangle { color: root.compact ? GlassStyle.tint(Appearance.m3colors.m3surfaceContainer, 0.30) : Appearance.m3colors.m3surfaceContainer; radius: 12 }
                Keys.onReturnPressed: event => {
                    if (!(event.modifiers & Qt.ShiftModifier)) { Codex.send(); event.accepted = true; }
                    else event.accepted = false;
                }
                Keys.onEnterPressed: event => {
                    if (!(event.modifiers & Qt.ShiftModifier)) { Codex.send(); event.accepted = true; }
                    else event.accepted = false;
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                Layout.fillWidth: true
                text: Codex.busy ? "画面を閉じても実行を継続します" : "フォルダ変更は「新規」から"
                font.pixelSize: 12
                color: Appearance.m3colors.m3onSurfaceVariant
            }
            StyledButton {
                text: Codex.busy ? "停止" : Codex.ready ? "送信" : "接続"
                onClicked: {
                    if (Codex.busy) Codex.command({action: "stop"});
                    else if (!Codex.ready) Codex.connect();
                    else { root.followOutput = true; Codex.send(); }
                }
            }
        }
    }
    Connections {
        target: Codex
        function onUpdated() {
            if (root.followOutput) Qt.callLater(() => chat.positionViewAtEnd());
        }
    }
}
