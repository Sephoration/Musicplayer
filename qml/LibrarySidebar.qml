import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// ============================================================
//  媒体库侧栏 —— 左侧分类列表
//  系统分类（全部音乐、我喜欢、最近播放）+ 用户自建分类
// ============================================================

Rectangle {
    id: sidebar
    color: "#0d0d18"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 标题
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: "音乐库"
                color: "#ffffff88"
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
        }

        // 分类列表
        ListView {
            id: catList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: AppModel.categories
            spacing: 2

            delegate: Rectangle {
                width: catList.width - 16
                height: 36
                radius: 8
                anchors.horizontalCenter: parent.horizontalCenter
                color: AppModel.activeCategoryId === modelData.id ? "#1a1a33" : "transparent"

                property bool hovered: false
                property var catData: modelData

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: catData.icon || "🎵"
                        font.pixelSize: 14
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: catData.name || ""
                        color: AppModel.activeCategoryId === catData.id ? "#d9d9d9" : "#999999"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        width: parent.width - 60
                    }

                    // 歌曲数量
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: catData.songIds ? catData.songIds.length : "0"
                        color: "#555555"
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                    onClicked: AppModel.setActiveCategoryId(catData.id)
                }
            }
        }

        // 底部：新建分类按钮
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "transparent"

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 16; height: 32; radius: 8
                color: hovered ? "#ffffff10" : "transparent"
                border.width: 1; border.color: "#ffffff0f"

                property bool hovered: false

                Text {
                    anchors.centerIn: parent
                    text: "+ 新建分类"
                    color: "#888888"
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                    onClicked: {
                        // 弹出命名对话框，简化处理直接用默认名
                        var name = "新分类"
                        var icons = ["🎵","🎸","🎹","🎧","💿","📀","🎼"]
                        var icon = icons[Math.floor(Math.random() * icons.length)]
                        AppModel.createCategory(name, icon)
                    }
                }
            }
        }
    }
}
