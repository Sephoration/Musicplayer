import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: sidebar
    radius: 28
    color: Qt.rgba(1, 1, 1, 0.72)
    border.width: 1
    border.color: Qt.rgba(0.10, 0.12, 0.18, 0.08)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Column {
            Layout.fillWidth: true
            spacing: 3
            Text { text: "分类"; color: "#171b2a"; font.pixelSize: 18; font.weight: Font.Bold }
            Text { text: "整理你的声音收藏"; color: "#667085"; font.pixelSize: 11 }
        }

        ListView {
            id: catList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: AppModel.categories
            spacing: 6

            delegate: Rectangle {
                width: catList.width
                height: 42
                radius: 15
                color: AppModel.activeCategoryId === modelData.id ? Qt.rgba(0.10, 0.12, 0.18, 0.075) : (hovered ? Qt.rgba(0.10, 0.12, 0.18, 0.045) : "transparent")
                border.width: AppModel.activeCategoryId === modelData.id ? 1 : 0
                border.color: Qt.rgba(0.10, 0.12, 0.18, 0.07)

                property bool hovered: false
                property var catData: modelData

                Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: 3; height: 18; radius: 2; color: AppModel.activeCategoryId === catData.id ? mainWindow.accentColor : "transparent" }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 10

                    Text { anchors.verticalCenter: parent.verticalCenter; text: catData.icon || "🎵"; font.pixelSize: 15 }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: catData.name || ""
                        color: AppModel.activeCategoryId === catData.id ? "#171b2a" : "#475467"
                        font.pixelSize: 13
                        font.weight: AppModel.activeCategoryId === catData.id ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                        width: parent.width - 72
                    }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: catData.songIds ? catData.songIds.length : "0"; color: "#98a2b3"; font.pixelSize: 11 }
                }

                MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: parent.hovered = true; onExited: parent.hovered = false; onClicked: AppModel.setActiveCategoryId(catData.id) }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 15
            color: addMouse.containsMouse ? Qt.rgba(0.10, 0.12, 0.18, 0.08) : Qt.rgba(1, 1, 1, 0.62)
            border.width: 1
            border.color: Qt.rgba(0.10, 0.12, 0.18, 0.08)
            Text { anchors.centerIn: parent; text: "+ 新建分类"; color: "#475467"; font.pixelSize: 12; font.weight: Font.Medium }
            MouseArea {
                id: addMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var name = "新分类"
                    var icons = ["🎵","🎸","🎹","🎧","💿","📀","🎼"]
                    var icon = icons[Math.floor(Math.random() * icons.length)]
                    AppModel.createCategory(name, icon)
                }
            }
        }
    }
}
