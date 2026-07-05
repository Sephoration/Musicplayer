import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var syncState: AppModel.syncState
    property var currentLine: syncState ? syncState.currentLine : null
    property var lines: syncState ? syncState.lines : []
    property int currentLineIndex: syncState ? (syncState.currentLineIndex || -1) : -1
    property int currentWordIndex: syncState ? (syncState.currentWordIndex || -1) : -1
    property real wordProgress: syncState ? (syncState.wordProgress || 0) : 0
    property bool hasLyrics: syncState ? (syncState.hasLyrics || false) : false

    Connections {
        target: AppModel
        function onSyncStateChanged() {
            root.syncState = AppModel.syncState
            root.currentLine = root.syncState ? root.syncState.currentLine : null
            root.lines = root.syncState ? root.syncState.lines : []
            root.currentLineIndex = root.syncState ? (root.syncState.currentLineIndex || -1) : -1
            root.currentWordIndex = root.syncState ? (root.syncState.currentWordIndex || -1) : -1
            root.wordProgress = root.syncState ? (root.syncState.wordProgress || 0) : 0
            root.hasLyrics = root.syncState ? (root.syncState.hasLyrics || false) : false
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 34
        color: Qt.rgba(1, 1, 1, 0.76)
        border.width: 1
        border.color: Qt.rgba(0.10, 0.12, 0.18, 0.08)
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: parent.height * 0.52
        radius: 34
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.72) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 44
        anchors.topMargin: 28
        width: 170
        height: 170
        radius: 85
        color: Qt.rgba(0.49, 0.23, 0.93, 0.08)
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 96, 620)
        spacing: 18

        Rectangle {
            width: hasLyrics ? 124 : 156
            height: width
            radius: width / 2
            anchors.horizontalCenter: parent.horizontalCenter
            color: mainWindow.accentColor
            border.width: 8
            border.color: Qt.rgba(1, 1, 1, 0.72)
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(mainWindow.accentColor, 1.28) }
                    GradientStop { position: 1.0; color: Qt.darker(mainWindow.accentColor, 1.10) }
                }
            }

            Image { anchors.fill: parent; source: AppModel.coverUrl || ""; fillMode: Image.PreserveAspectCrop; visible: source != "" }
            Text { anchors.centerIn: parent; text: "♪"; color: Qt.rgba(1, 1, 1, 0.48); font.pixelSize: hasLyrics ? 40 : 52; font.weight: Font.Bold; visible: !(AppModel.coverUrl && AppModel.coverUrl !== "") }
        }

        Column {
            width: parent.width
            spacing: 5

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: AppModel.currentSongTitle || "未选择歌曲"
                color: "#171b2a"
                font.pixelSize: 25
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: AppModel.currentSongArtist || "准备好播放你的音乐"
                color: "#667085"
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }

        Item {
            width: parent.width
            height: hasLyrics ? lyricsArea.implicitHeight : 96

            Text {
                anchors.centerIn: parent
                text: AppModel.currentSongTitle === "" ? "从媒体库导入歌曲后开始播放" : "暂无歌词"
                color: "#667085"
                font.pixelSize: 14
                visible: !hasLyrics
            }

            Column {
                id: lyricsArea
                width: parent.width
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter
                visible: hasLyrics

                Repeater {
                    model: {
                        var result = []
                        if (!lines || lines.length === 0) return result
                        var start = Math.max(0, currentLineIndex - 2)
                        var end = Math.min(lines.length, currentLineIndex + 3)
                        for (var i = start; i < end; i++) result.push({ line: lines[i], idx: i, isCurrent: i === currentLineIndex })
                        return result
                    }

                    delegate: Item {
                        width: lyricsArea.width
                        height: lineContent.implicitHeight + 4
                        property bool isCurrentLine: modelData.isCurrent
                        property var lineData: modelData.line

                        Column {
                            id: lineContent
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            spacing: 4

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.min(lyricRow.implicitWidth + 28, parent.width)
                                height: lyricRow.implicitHeight + 12
                                radius: 14
                                color: isCurrentLine ? Qt.rgba(0.10, 0.12, 0.18, 0.06) : "transparent"
                                border.width: isCurrentLine ? 1 : 0
                                border.color: Qt.rgba(0.10, 0.12, 0.18, 0.07)

                                Row {
                                    id: lyricRow
                                    anchors.centerIn: parent
                                    spacing: 0
                                    property var words: lineData ? (lineData.words || []) : []
                                    property bool showWords: isCurrentLine && words.length > 0

                                    Repeater {
                                        model: lyricRow.showWords ? lyricRow.words : [lineData ? (lineData.text || " ") : " "]
                                        Text {
                                            text: lyricRow.showWords ? (modelData.word || "") + " " : (lineData ? (lineData.text || " ") : " ")
                                            font.pixelSize: isCurrentLine ? AppModel.fontSize + 2 : AppModel.fontSize - 1
                                            font.weight: isCurrentLine ? Font.DemiBold : Font.Normal
                                            font.letterSpacing: isCurrentLine ? 1.2 : 0.6
                                            color: {
                                                if (!lyricRow.showWords) return isCurrentLine ? "#171b2a" : "#8a94a8"
                                                return index <= currentWordIndex ? mainWindow.accentColor : "#171b2a"
                                            }
                                            opacity: isCurrentLine ? 1.0 : 0.58
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: (lineData && lineData.translation) || ""
                                visible: text !== "" && isCurrentLine && AppModel.showTranslation
                                color: "#667085"
                                font.pixelSize: AppModel.fontSize - 2
                                font.italic: true
                                opacity: 0.78
                            }
                        }
                    }
                }
            }
        }
    }
}
