import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

// ============================================================
//  迷你播放器 —— 紧凑型窗口，始终置顶
//  只显示：封面图 + 歌名歌手 + 当前歌词 + 三个播放按钮 + 展开按钮
//  整个窗口可拖拽
// ============================================================

ApplicationWindow {
    id: miniWindow
    visible: AppModel.miniMode
    width: 350
    height: 70
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Window
    color: "#0a0a0ff2"

    // 拖拽移动
    MouseArea {
        anchors.fill: parent
        property point lastPos: Qt.point(0, 0)
        onPressed: { lastPos = Qt.point(mouseX, mouseY) }
        onPositionChanged: {
            miniWindow.x += (mouseX - lastPos.x)
            miniWindow.y += (mouseY - lastPos.y)
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#14141ee6"

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            // 封面（带阴影）
            Rectangle {
                id: miniCover
                width: 45; height: 45; radius: 8
                color: AppModel.accentColor || "#6366f1"
                Layout.alignment: Qt.AlignVCenter
                clip: true

                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 8
                    samples: 17
                    color: Qt.rgba(0.39, 0.4, 0.95, 0.3)
                    source: miniCover
                }

                Image {
                    anchors.fill: parent
                    source: AppModel.coverUrl || ""
                    fillMode: Image.PreserveAspectCrop
                    visible: source != ""
                }
            }

            // 歌名 + 当前歌词
            Column {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: AppModel.currentSongTitle || "未播放"
                    color: "#d9d9d9"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    width: parent.width
                }
                Text {
                    text: {
                        var st = AppModel.syncState
                        if (st && st.hasLyrics && st.currentLine) {
                            return st.currentLine.text || "♪"
                        }
                        return "♪"
                    }
                    color: "#737373"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            // 播放控制
            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                // 上一首
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: hovered ? "#ffffff10" : "transparent"
                    property bool hovered: false
                    Text {
                        anchors.centerIn: parent
                        text: "⏮"; color: "#ffffff88"; font.pixelSize: 12
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: AppModel.playPrev()
                    }
                }

                // 播放/暂停（渐变按钮）
                Rectangle {
                    id: miniPlayBtn
                    width: 32; height: 32; radius: 16
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.lighter(AppModel.accentColor || "#6366f1", 1.3) }
                        GradientStop { position: 1.0; color: AppModel.accentColor || "#6366f1" }
                    }
                    layer.enabled: true
                    layer.effect: DropShadow {
                        radius: 8
                        samples: 17
                        color: Qt.rgba(0.39, 0.4, 0.95, 0.3)
                        source: miniPlayBtn
                    }
                    Text {
                        anchors.centerIn: parent
                        text: AppModel.playing ? "⏸" : "▶"
                        color: "#ffffff"; font.pixelSize: 14
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: AppModel.requestPlay()
                    }
                }

                // 下一首
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: hovered ? "#ffffff10" : "transparent"
                    property bool hovered: false
                    Text {
                        anchors.centerIn: parent
                        text: "⏭"; color: "#ffffff88"; font.pixelSize: 12
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: AppModel.playNext()
                    }
                }
            }

            // 展开按钮（退出迷你模式）
            Rectangle {
                width: 28; height: 28; radius: 4
                color: hovered ? "#ffffff10" : "transparent"
                border.width: 1; border.color: "#ffffff1a"
                property bool hovered: false
                Text {
                    anchors.centerIn: parent
                    text: "⤢"; color: "#ffffff80"; font.pixelSize: 14
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                    onClicked: AppModel.setMiniMode(false)
                }
            }
        }
    }
}
