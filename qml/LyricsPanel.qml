import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

// ============================================================
//  歌词面板 —— 核心展示区
//  上半部分：封面图（圆形）+ 歌曲标题/歌手
//  下半部分：歌词逐句滚动 + 逐字高亮（卡拉OK风格）
//  如果这首歌没有歌词，显示"暂无歌词"
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
    Rectangle {
        id: noLyricsPanel
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.65, 560)
        height: noLyricsCol.implicitHeight + 72
        radius: 18
        color: Qt.rgba(1, 1, 1, AppModel.lyricsOpacity / 100 * 0.06)
        border.width: 1; border.color: "#ffffff0f"
        visible: !hasLyrics && AppModel.currentSongTitle !== ""

        layer.enabled: true
        layer.effect: DropShadow {
            radius: 16
            samples: 25
            color: Qt.rgba(0, 0, 0, 0.4)
            source: noLyricsPanel
        }

        Column {
            id: noLyricsCol
            anchors.centerIn: parent
            spacing: 8
            width: parent.width - 88

            // 封面圆圈（带发光阴影）
            Rectangle {
                id: coverNoLyrics
                width: 130; height: 130; radius: 65
                color: mainWindow.accentColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 20
                clip: true

                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 24
                    samples: 33
                    color: Qt.rgba(0.39, 0.4, 0.95, 0.35)
                    source: coverNoLyrics
                }

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
                color: "#e6e6e6"
                font.pixelSize: 20
                font.weight: Font.SemiBold
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: AppModel.currentSongArtist || ""
                color: "#595959"
                font.pixelSize: 12
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "暂无歌词"
                color: "#333333"
                font.pixelSize: 12
                topPadding: 20
            }
        }
    }

    // =====================================================
    //  有歌词状态：显示当前行及上下各几行的歌词
    // =====================================================
    Rectangle {
        id: lyricsPanel
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.65, 560)
        height: lyricsCol.implicitHeight + 72
        radius: 18
        color: Qt.rgba(1, 1, 1, AppModel.lyricsOpacity / 100 * 0.06)
        border.width: 1; border.color: "#ffffff0f"
        visible: hasLyrics

        layer.enabled: true
        layer.effect: DropShadow {
            radius: 16
            samples: 25
            color: Qt.rgba(0, 0, 0, 0.4)
            source: lyricsPanel
        }

        Column {
            id: lyricsCol
            anchors.centerIn: parent
            spacing: 6
            width: parent.width - 88

            // 歌名 + 歌手
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: AppModel.currentSongTitle || ""
                color: "#e6e6e6"
                font.pixelSize: 20
                font.weight: Font.SemiBold
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: AppModel.currentSongArtist || ""
                color: "#595959"
                font.pixelSize: 12
            }

            // 封面（小圆图）
            Rectangle {
                id: coverLyrics
                width: 100; height: 100; radius: 50
                color: mainWindow.accentColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 10
                clip: true

                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 20
                    samples: 33
                    color: Qt.rgba(0.39, 0.4, 0.95, 0.3)
                    source: coverLyrics
                }

                Image {
                    anchors.fill: parent
                    source: AppModel.coverUrl || ""
                    fillMode: Image.PreserveAspectCrop
                    visible: source != ""
                }
            }

            // 歌词行显示区（最多显示当前行 + 上下各2行）
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

                    // 动态取当前行前后各 2 行
                    property int startIdx: Math.max(0, currentLineIndex - 2)
                    property int endIdx: Math.min(lines.length, currentLineIndex + 3)

                    // 用 Repeater 生成可见歌词行
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
                            height: lineContent.implicitHeight

                            property bool isCurrentLine: modelData.isCurrent
                            property var lineData: modelData.line
                            property int lineIdx: modelData.idx

                            Column {
                                id: lineContent
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width

                                // ---- 歌词文字（逐字高亮） ----
                                // 如果是当前行且有逐字时间戳，则逐个字渲染
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: lyricRow.implicitWidth + 12
                                    height: lyricRow.implicitHeight + 4
                                    radius: 6
                                    color: isCurrentLine ? Qt.rgba(1, 1, 1, 0.03) : "transparent"

                                    Row {
                                        id: lyricRow
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 0

                                        // 使用 Loader 动态生成逐字高亮
                                        // 如果当前行且 words 数组存在，逐个渲染
                                        property var words: lineData ? (lineData.words || []) : []
                                        property bool showWords: isCurrentLine && words.length > 0

                                        Component {
                                            id: wordHighlight
                                            Item {
                                                property int wi: 0
                                                property var word: null
                                                property int activeWordIdx: currentWordIndex
                                                property real wordProg: wordProgress
                                                property bool highlight: showWords && wi <= activeWordIdx

                                                implicitWidth: wordText.implicitWidth
                                                implicitHeight: wordText.implicitHeight

                                                Text {
                                                    id: wordText
                                                    text: word ? (word.word + " ") : ""
                                                    font.pixelSize: AppModel.fontSize
                                                    font.letterSpacing: 1
                                                    color: highlight
                                                           ? AppModel.lyricsActiveWordColor
                                                           : (isCurrentLine
                                                              ? AppModel.lyricsActiveLineColor
                                                              : AppModel.lyricsInactiveColor)
                                                    // 发光效果（需要 Qt5Compat.GraphicalEffects，暂跳过）
                                                    layer.enabled: highlight
                                                }
                                            }
                                        }

                                        // 简化实现：直接渲染所有字
                                        Repeater {
                                            model: lyricRow.showWords ? lyricRow.words : [lineData ? (lineData.text || " ") : " "]
                                            // 如果 showWords，model 是 words 数组；否则是单行文本
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
                                                    // 逐字高亮
                                                    return (index <= currentWordIndex)
                                                           ? AppModel.lyricsActiveWordColor
                                                           : AppModel.lyricsActiveLineColor
                                                }
                                                // 已高亮字发光效果
                                                property bool isActiveWord: lyricRow.showWords && index <= currentWordIndex
                                                layer.enabled: isActiveWord
                                                layer.effect: Glow {
                                                    radius: 6
                                                    samples: 13
                                                    color: AppModel.lyricsActiveWordColor
                                                    transparentBorder: true
                                                }
                                            }
                                        }
                                    }
                                }

                                // ---- 翻译 ----
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: (lineData && lineData.translation) || ""
                                    visible: text !== "" && isCurrentLine && AppModel.showTranslation
                                    color: AppModel.lyricsInactiveColor
                                    font.pixelSize: AppModel.fontSize - 3
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
