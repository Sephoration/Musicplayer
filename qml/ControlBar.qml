import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// ============================================================
//  底部控制栏 —— 整个播放器的核心操作区
//  分两行：第一行是进度条，第二行是控制按钮
//  左边：播放模式 + 封面 + 歌名/歌手
//  中间：上一首 / 播放暂停 / 下一首
//  右边：音量 + 睡眠定时器 + 播放队列 + 可视化切换 + 迷你模式
// ============================================================

Rectangle {
    id: controlBar
    color: "#0f0f1a"
    height: 80

    // 半透明顶部渐变毛边（取代硬边分割线）
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: "#ffffff12"
    }

    // 微弱的顶部光晕
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 20
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(0.39, 0.4, 0.95, 0.03) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        spacing: 0

        // ---- 第一行：进度条 ----
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            spacing: 14

            // 当前时间
            Text {
                text: AppModel.formatTime(AppModel.currentTime)
                color: "#777777"
                font.pixelSize: 11
                font.family: "Consolas, monospace"
                Layout.preferredWidth: 38
            }

            // 进度条
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                radius: 2
                color: "#1a1a33"

                Rectangle {
                    id: progressFill
                    height: parent.height
                    radius: 2
                    width: AppModel.duration > 0
                           ? parent.width * (AppModel.currentTime / AppModel.duration)
                           : 0

                    // 渐变色进度条
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.darker(mainWindow.accentColor, 1.2) }
                        GradientStop { position: 1.0; color: mainWindow.accentColor }
                    }

                    // 进度拖拽小球（带发光）
                    Rectangle {
                        id: progressHandle
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 14; radius: 7
                        color: Qt.lighter(mainWindow.accentColor, 1.3)
                        border.width: 2
                        border.color: Qt.rgba(1, 1, 1, 0.25)
                        x: 7
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        var pct = mouse.x / parent.width
                        AppModel.seek(pct * AppModel.duration)
                    }
                }

                // 拖拽进度
                DragHandler {
                    target: null
                    onActiveChanged: {
                        if (active) {
                            var pct = centroid.position.x / parent.width
                            AppModel.seek(Math.max(0, Math.min(1, pct)) * AppModel.duration)
                        }
                    }
                }
            }

            // 总时长
            Text {
                text: AppModel.formatTime(AppModel.duration)
                color: "#777777"
                font.pixelSize: 11
                font.family: "Consolas, monospace"
                Layout.preferredWidth: 38
            }
        }

        // ---- 第二行：控制按钮 ----
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ----- 左侧：模式 + 封面 + 歌名 -----
            Row {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 220
                spacing: 14

                // 播放模式按钮
                Rectangle {
                    width: 30; height: 30; radius: 6
                    color: hovered ? "#ffffff10" : "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    property bool hovered: false

                    Text {
                        anchors.centerIn: parent
                        text: {
                            var m = AppModel.playMode
                            if (m === "sequential") return "→"
                            if (m === "repeat") return "↻"
                            if (m === "shuffle") return "⇄"
                            return "→"
                        }
                        color: "#ffffff66"
                        font.pixelSize: 16
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: AppModel.togglePlayMode()
                    }
                }

                // 封面（小方图）
                Rectangle {
                    width: 36; height: 36; radius: 4
                    color: mainWindow.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: AppModel.coverUrl || ""
                        fillMode: Image.PreserveAspectCrop
                        visible: source != ""
                    }
                }

                // 歌名 + 歌手
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    width: 110

                    Text {
                        text: AppModel.currentSongTitle || "未选择歌曲"
                        color: "#e8e8e8"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    Text {
                        text: AppModel.currentSongArtist || ""
                        color: "#999999"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
            }

            // ----- 中间：播放控制 -----
            Row {
                Layout.alignment: Qt.AlignCenter
                spacing: 20

                // 上一首
                ControlButton {
                    text: "⏮"
                    size: 18
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: AppModel.playPrev()
                }

                // 播放/暂停（大圆按钮 + 渐变 + 发光）
                Rectangle {
                    id: playButton
                    width: 44; height: 44; radius: 22
                    anchors.verticalCenter: parent.verticalCenter
                    property bool hovered: false

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.lighter(mainWindow.accentColor, 1.3) }
                        GradientStop { position: 1.0; color: mainWindow.accentColor }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: AppModel.playing ? "⏸" : "▶"
                        color: "#ffffff"
                        font.pixelSize: 18
                    }

                    // 错误提示气泡
                    Rectangle {
                        visible: AppModel.error !== ""
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: errorText.implicitWidth + 16
                        height: 26; radius: 8
                        color: "#ef444426"
                        border.width: 1; border.color: "#ef44444d"

                        Text {
                            id: errorText
                            anchors.centerIn: parent
                            text: AppModel.error
                            color: "#f87171"
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: AppModel.requestPlay()
                    }
                }

                // 下一首
                ControlButton {
                    text: "⏭"
                    size: 18
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: AppModel.playNext()
                }
            }

            // ----- 右侧：音量 + 功能按钮 -----
            Row {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                spacing: 10
                layoutDirection: Qt.RightToLeft

                // 迷你模式
                ControlButton {
                    text: "⤡"
                    size: 12
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: AppModel.toggleMiniMode()
                }

                // 可视化切换
                Rectangle {
                    width: 36; height: 22; radius: 4
                    color: hovered ? "#ffffff10" : "transparent"
                    border.width: 1; border.color: "#ffffff1a"
                    anchors.verticalCenter: parent.verticalCenter
                    property bool hovered: false

                    Text {
                        anchors.centerIn: parent
                        text: {
                            var m = AppModel.visualizerMode
                            if (m === "off") return "关"
                            if (m === "2d") return "2D"
                            return m
                        }
                        color: "#ffffff66"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: {
                            if (AppModel.visualizerMode === "2d") AppModel.setVisualizerMode("off")
                            else AppModel.setVisualizerMode("2d")
                        }
                    }
                }

                // 播放队列
                ControlButton {
                    text: "📋"
                    size: 14
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: AppModel.setPlaylistOpen(!AppModel.playlistOpen)
                }

                // 分隔线
                Rectangle {
                    width: 1; height: 20
                    color: "#ffffff0f"
                    anchors.verticalCenter: parent.verticalCenter
                }

                // 睡眠定时器
                TimerButton {
                    anchors.verticalCenter: parent.verticalCenter
                }

                // 音量控制
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    // 静音按钮
                    ControlButton {
                        text: AppModel.muted ? "🔇" : "🔊"
                        size: 14
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: AppModel.setMuted(!AppModel.muted)
                    }

                    // 音量条
                    Rectangle {
                        width: 64; height: 4; radius: 2
                        color: "#1a1a33"
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            height: parent.height; radius: 2
                            color: "#ffffff59"
                            width: AppModel.muted ? 0 : parent.width * (AppModel.volume / 100)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: function(mouse) {
                                var vol = mouse.x / parent.width * 100
                                AppModel.setVolume(Math.round(vol))
                            }
                        }
                    }
                }
            }
        }
    }
}
