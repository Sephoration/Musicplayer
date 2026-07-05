import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: sidebar
    radius: 28
    color: Qt.rgba(1, 1, 1, 0.74)
    border.width: 1
    border.color: Qt.rgba(0.10, 0.12, 0.18, 0.08)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42

            Column {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "播放队列"; color: "#171b2a"; font.pixelSize: 17; font.weight: Font.Bold }
                Text { text: AppModel.queue.length + " 首待播放"; color: "#667085"; font.pixelSize: 11 }
            }

            ControlButton { text: "×"; size: 16; onClicked: AppModel.setPlaylistOpen(false) }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 13
            color: Qt.rgba(0.10, 0.12, 0.18, 0.045)
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    var m = AppModel.playMode
                    if (m === "sequential") return "顺序播放"
                    if (m === "repeat") return "单曲循环"
                    if (m === "shuffle") return "随机播放"
                    return "播放模式"
                }
                color: "#667085"
                font.pixelSize: 11
            }
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 8
                width: 24
                height: 24
                radius: 9
                color: clearMouse.containsMouse ? "#fee2e2" : "transparent"
                Text { anchors.centerIn: parent; text: "🗑"; color: "#dc2626"; font.pixelSize: 11 }
                MouseArea { id: clearMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: AppModel.clearQueue() }
            }
        }

        ListView {
            id: queueList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: AppModel.queue
            spacing: 6

            delegate: Rectangle {
                width: queueList.width
                height: 50
                radius: 16
                color: index === AppModel.queueIndex ? Qt.rgba(0.10, 0.12, 0.18, 0.075) : (hovered ? Qt.rgba(0.10, 0.12, 0.18, 0.045) : Qt.rgba(1, 1, 1, 0.42))
                border.width: index === AppModel.queueIndex ? 1 : 0
                border.color: Qt.rgba(0.10, 0.12, 0.18, 0.07)

                property bool hovered: false
                property var itemData: modelData

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 8

                    Text { anchors.verticalCenter: parent.verticalCenter; text: index === AppModel.queueIndex ? "▶" : (index + 1); color: index === AppModel.queueIndex ? mainWindow.accentColor : "#667085"; font.pixelSize: 11; width: 24 }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        width: 158
                        Text { text: itemData.title || ""; color: "#171b2a"; font.pixelSize: 12; font.weight: Font.Medium; elide: Text.ElideRight; width: parent.width }
                        Text { text: itemData.artist || ""; color: "#667085"; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26
                        height: 26
                        radius: 9
                        color: removeHovered ? "#fee2e2" : "transparent"
                        visible: parent.parent.hovered || removeHovered
                        property bool removeHovered: false
                        Text { anchors.centerIn: parent; text: "×"; color: "#dc2626"; font.pixelSize: 14 }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: parent.removeHovered = true; onExited: parent.removeHovered = false; onClicked: AppModel.removeFromQueue(index) }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
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
