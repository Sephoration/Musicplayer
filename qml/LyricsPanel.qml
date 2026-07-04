import QtQuick
import QtQuick.Layouts

// ============================================================
//  歌词面板 —— 核心展示区
//  上半部分：封面图（圆形）+ 歌曲标题/歌手
//  下半部分：歌词逐句滚动 + 逐字高亮（卡拉OK风格）
//  背景采用多层半透明叠加 + 发光边框，实现通透的玻璃质感
// ============================================================

Item {
    id: root

    // 从 AppModel 读取同步状态
    property var syncState: AppModel.syncState
    property var currentLine: syncState ? syncState.currentLine : null
    property var lines: syncState ? syncState.lines : []
    property int currentLineIndex: syncState ? (syncState.currentLineIndex || -1) : -1
    property int currentWordIndex: syncState ? (syncState.currentWordIndex || -1) : -1
    property real wordProgress: syncState ? (syncState.wordProgress || 0) : 0
    property bool hasLyrics: syncState ? (syncState.hasLyrics || false) : false

    // 同步状态发生变化时自动刷新
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

    // =====================================================
    //  无歌词状态：显示封面 + 歌名 + 暂无歌词
    // =====================================================
    Item {
        id: noLyricsWrapper
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.65, 560)
        height: noLyricsCol.implicitHeight + 100
        visible: !hasLyrics && AppModel.currentSongTitle !== ""

        // ---- 玻璃背景层 ----
        // 亮色基底（微弱的白，形成半透明玻璃感）
        Rectangle {
            anchors.fill: parent
            radius: 18
            color: Qt.rgba(1, 1, 1, 0.04 + AppModel.lyricsOpacity / 100 * 0.08)
        }

        // 边框光晕
        Rectangle {
            anchors.fill: parent
            radius: 18
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.06 + AppModel.lyricsOpacity / 100 * 0.06)
        }

        // 顶部高光（模拟环境光反射）
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.7
            height: parent.height * 0.5
            radius: width / 2
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.06 + AppModel.lyricsOpacity / 100 * 0.04) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // ---- 内容 ----
        Column {
            id: noLyricsCol
            anchors.centerIn: parent
            spacing: 10
            width: parent.width - 88

            // 封面圆圈（带发光阴影）
            Rectangle {
                id: coverNoLyrics
                width: 130; height: 130; radius: 65
                color: mainWindow.accentColor
                anchors.horizontalCenter: parent.horizontalCenter
                clip: true

                Image {
                    anchors.fill: parent
                    source: AppModel.coverUrl || ""
                    fillMode: Image.PreserveAspectCrop
                    visible: source != ""
                }
                Text {
                    anchors.centerIn: parent
                    text: "♪"
                    color: "#ffffff4d"
                    font.pixelSize: 36
                    visible: !(AppModel.coverUrl && AppModel.coverUrl !== "")
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: AppModel.currentSongTitle || "未播放"
                color: "#f0f0f0"
                font.pixelSize: 20
                font.weight: Font.SemiBold
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: AppModel.currentSongArtist || ""
                color: "#999999"
                font.pixelSize: 12
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "暂无歌词"
                color: "#888888"
                font.pixelSize: 12
                topPadding: 20
            }
        }
    }

    // =====================================================
    //  有歌词状态 — 玻璃面板 + 逐字高亮
    // =====================================================
    Item {
        id: lyricsWrapper
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.65, 560)
        height: lyricsCol.implicitHeight + 100
        visible: hasLyrics

        // ---- 玻璃背景层 ----
        Rectangle {
            anchors.fill: parent
            radius: 18
            color: Qt.rgba(1, 1, 1, 0.04 + AppModel.lyricsOpacity / 100 * 0.08)
        }

        // 边框光晕
        Rectangle {
            anchors.fill: parent
            radius: 18
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.06 + AppModel.lyricsOpacity / 100 * 0.06)
        }

        // 顶部高光
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.7
            height: parent.height * 0.5
            radius: width / 2
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.06 + AppModel.lyricsOpacity / 100 * 0.04) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // ---- 内容 ----
        Column {
            id: lyricsCol
            anchors.centerIn: parent
            spacing: 6
            width: parent.width - 88

            // 歌名 + 歌手
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: AppModel.currentSongTitle || ""
                color: "#f0f0f0"
                font.pixelSize: 20
                font.weight: Font.SemiBold
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: AppModel.currentSongArtist || ""
                color: "#999999"
                font.pixelSize: 12
            }

            // 封面（小圆图）
            Rectangle {
                id: coverLyrics
                width: 100; height: 100; radius: 50
                color: mainWindow.accentColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 12
                clip: true

                Image {
                    anchors.fill: parent
                    source: AppModel.coverUrl || ""
                    fillMode: Image.PreserveAspectCrop
                    visible: source != ""
                }
            }

            // 歌词行显示区
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: lyricsArea.implicitHeight
                anchors.topMargin: 16

                Column {
                    id: lyricsArea
                    width: parent.width
                    spacing: 8
                    anchors.horizontalCenter: parent.horizontalCenter

                    Repeater {
                        model: {
                            var result = []
                            if (!lines || lines.length === 0) return result
                            var start = Math.max(0, currentLineIndex - 2)
                            var end = Math.min(lines.length, currentLineIndex + 3)
                            for (var i = start; i < end; i++) {
                                result.push({ line: lines[i], idx: i, isCurrent: i === currentLineIndex })
                            }
                            return result
                        }

                        delegate: Item {
                            width: lyricsArea.width
                            height: lineContent.implicitHeight + 4

                            property bool isCurrentLine: modelData.isCurrent
                            property var lineData: modelData.line
                            property int lineIdx: modelData.idx

                            Column {
                                id: lineContent
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width

                                // 歌词文字行
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: lyricRow.implicitWidth + 16
                                    height: lyricRow.implicitHeight + 6
                                    radius: 8
                                    color: isCurrentLine ? Qt.rgba(1, 1, 1, 0.04 + AppModel.lyricsOpacity / 100 * 0.06) : "transparent"

                                    Row {
                                        id: lyricRow
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 0

                                        property var words: lineData ? (lineData.words || []) : []
                                        property bool showWords: isCurrentLine && words.length > 0

                                        Repeater {
                                            model: lyricRow.showWords ? lyricRow.words : [lineData ? (lineData.text || " ") : " "]
                                            Text {
                                                text: {
                                                    if (lyricRow.showWords) {
                                                        return (modelData.word || "") + " "
                                                    } else {
                                                        return lineData ? (lineData.text || " ") : " "
                                                    }
                                                }
                                                font.pixelSize: AppModel.fontSize
                                                font.letterSpacing: 1
                                                color: {
                                                    if (!lyricRow.showWords) {
                                                        return isCurrentLine
                                                               ? AppModel.lyricsActiveLineColor
                                                               : AppModel.lyricsInactiveColor
                                                    }
                                                    return (index <= currentWordIndex)
                                                           ? AppModel.lyricsActiveWordColor
                                                           : AppModel.lyricsActiveLineColor
                                                }
                                                property bool isActiveWord: lyricRow.showWords && index <= currentWordIndex
                                            }
                                        }
                                    }
                                }

                                // 翻译
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: (lineData && lineData.translation) || ""
                                    visible: text !== "" && isCurrentLine && AppModel.showTranslation
                                    color: AppModel.lyricsInactiveColor
                                    font.pixelSize: AppModel.fontSize - 2
                                    font.italic: true
                                    topPadding: 4
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
