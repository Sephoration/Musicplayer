import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// ============================================================
//  播放队列侧栏 —— 从右侧滑出
//  显示当前播放队列，支持点击播放、移除
// ============================================================

Rectangle {
    id: sidebar
    color: "#0f0f1a"
    border.color: "#1a1a2e"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 标题行
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 8

                Text {
                    text: "播放队列 (" + AppModel.queue.length + ")"
                    color: "#ffffff88"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                // 清空队列
                Rectangle {
                    Layout.preferredWidth: 28; height: 28; radius: 6
                    color: hovered ? "#ffffff10" : "transparent"
                    property bool hovered: false
                    Text {
                        anchors.centerIn: parent
                        text: "🗑"; color: "#ffffff66"; font.pixelSize: 12
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: AppModel.clearQueue()
                    }
                }

                // 关闭
                Rectangle {
                    Layout.preferredWidth: 28; height: 28; radius: 6
                    color: hovered ? "#ffffff10" : "transparent"
                    property bool hovered: false
                    Text {
                        anchors.centerIn: parent
                        text: "✕"; color: "#ffffff66"; font.pixelSize: 13
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: AppModel.setPlaylistOpen(false)
                    }
                }
            }
        }

        // 播放模式提示
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            color: "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    var m = AppModel.playMode
                    if (m === "sequential") return "📜 顺序播放"
                    if (m === "repeat") return "🔂 单曲循环"
                    if (m === "shuffle") return "🔀 随机播放"
                    return ""
                }
                color: "#666666"
                font.pixelSize: 11
            }
        }

        // 队列列表
        ListView {
            id: queueList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: AppModel.queue
            spacing: 1

            delegate: Rectangle {
                width: queueList.width - 8
                height: 44
                radius: 6
                anchors.horizontalCenter: parent.horizontalCenter
                color: index === AppModel.queueIndex ? "#1a1a33" : "transparent"

                property bool hovered: false
                property var itemData: modelData

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8

                    // 正在播放指示器
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: index === AppModel.queueIndex ? "▶" : (index + 1)
                        color: index === AppModel.queueIndex ? mainWindow.accentColor : "#555555"
                        font.pixelSize: 11
                        width: 20
                    }

                    // 歌名
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: itemData.title || ""
                        color: index === AppModel.queueIndex ? "#d9d9d9" : "#aaaaaa"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        width: 120
                    }

                    // 歌手
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: itemData.artist || ""
                        color: index === AppModel.queueIndex ? "#888888" : "#666666"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        width: 80
                    }

                    // 移除按钮
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24; height: 24; radius: 4
                        color: removeHovered ? "#ef444422" : "transparent"
                        visible: parent.parent.hovered || removeHovered
                        property bool removeHovered: false

                        Text {
                            anchors.centerIn: parent
                            text: "✕"; color: "#ef444488"; font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: parent.removeHovered = true
                            onExited: parent.removeHovered = false
                            onClicked: AppModel.removeFromQueue(index)
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                    onClicked: {
                        if (itemData) {
                            AppModel.setCurrentView("player")
                            AppModel.playSong(itemData.id, itemData.title, itemData.artist)
                        }
                    }
                }
            }
        }
    }
}
