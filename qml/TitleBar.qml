import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Rectangle {
    id: titleBar
    color: Qt.rgba(1, 1, 1, 0.56)
    height: 56

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Qt.rgba(0.10, 0.12, 0.18, 0.07)
    }

    MouseArea {
        anchors.fill: parent
        onDoubleClicked: mainWindow.visibility === Window.Maximized ? mainWindow.showNormal() : mainWindow.showMaximized()
        onPressed: function(mouse) {
            if (mouse.button === Qt.LeftButton && mainWindow.visibility !== Window.Maximized) {
                mainWindow.startSystemMove()
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 22
        anchors.rightMargin: 10
        spacing: 0

        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 12

            Rectangle {
                width: 30
                height: 30
                radius: 10
                anchors.verticalCenter: parent.verticalCenter
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(mainWindow.accentColor, 1.22) }
                    GradientStop { position: 1.0; color: mainWindow.accentColor }
                }

                Text {
                    anchors.centerIn: parent
                    text: "♪"
                    color: "white"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: "MusicPlayer"
                    color: "#171b2a"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                Text {
                    text: {
                        var v = AppModel.currentView
                        if (v === "player") return "正在播放"
                        if (v === "library") return "媒体库"
                        if (v === "settings") return "偏好设置"
                        return "音乐空间"
                    }
                    color: "#667085"
                    font.pixelSize: 11
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.centerIn: parent
                width: tabs.implicitWidth + 10
                height: 38
                radius: 19
                color: Qt.rgba(0.10, 0.12, 0.18, 0.055)
                border.width: 1
                border.color: Qt.rgba(0.10, 0.12, 0.18, 0.06)

                Row {
                    id: tabs
                    anchors.centerIn: parent
                    spacing: 4
                    ViewTab { viewId: "player"; label: "播放" }
                    ViewTab { viewId: "library"; label: "媒体库" }
                    ViewTab { viewId: "settings"; label: "设置" }
                }
            }
        }

        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 6
            WindowButton { btnText: "━"; onClicked: mainWindow.showMinimized() }
            WindowButton { btnText: "□"; onClicked: mainWindow.visibility === Window.Maximized ? mainWindow.showNormal() : mainWindow.showMaximized() }
            WindowButton { btnText: "✕"; isClose: true; onClicked: mainWindow.hide() }
        }
    }
}
