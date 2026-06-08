import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// ============================================================
//  自定义标题栏
//  左边：图标 + 应用名 + 当前页面名
//  中间：三个视图标签按钮
//  右边：最小化 / 最大化 / 关闭 窗口按钮
// ============================================================

Rectangle {
    id: titleBar
    color: Qt.rgba(0.05, 0.05, 0.09, 0.85)
    height: 48

    // 底部分隔线（更淡）
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: "#ffffff12"
    }

    // 整体拖拽区域（用于移动无边框窗口）
    MouseArea {
        anchors.fill: parent
        property point lastPos: Qt.point(0, 0)
        onPressed: { lastPos = Qt.point(mouseX, mouseY) }
        onPositionChanged: {
            if (mainWindow.visibility !== Window.Maximized) {
                mainWindow.x += (mouseX - lastPos.x)
                mainWindow.y += (mouseY - lastPos.y)
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 8
        spacing: 0

        // ----- 左侧 -----
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 12

            Rectangle {
                width: 24; height: 24; radius: 6
                color: mainWindow.accentColor
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.centerIn: parent
                    text: "♪"; color: "#ffffff"; font.pixelSize: 14
                }
            }

            Text {
                text: "MusicPlayer"
                color: "#d9d9d9"
                font.pixelSize: 15
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "|"; color: "#555555"; font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: {
                    var v = AppModel.currentView
                    if (v === "player") return "正在播放"
                    if (v === "library") return "媒体库"
                    if (v === "settings") return "设置"
                    return ""
                }
                color: "#777777"; font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ----- 中间：视图标签 -----
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Row {
                anchors.centerIn: parent
                spacing: 2

                ViewTab { viewId: "player"; label: "播放" }
                ViewTab { viewId: "library"; label: "媒体库" }
                ViewTab { viewId: "settings"; label: "设置" }
            }
        }

        // ----- 右侧：窗口控制 -----
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            WindowButton { btnText: "━"; onClicked: mainWindow.showMinimized() }
            WindowButton {
                btnText: "□"
                onClicked: {
                    if (mainWindow.visibility === Window.Maximized)
                        mainWindow.showNormal()
                    else
                        mainWindow.showMaximized()
                }
            }
            WindowButton {
                btnText: "✕"
                isClose: true
                onClicked: mainWindow.hide()
            }
        }
    }
}
