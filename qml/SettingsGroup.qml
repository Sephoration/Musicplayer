import QtQuick

// 设置页面分组标题
Rectangle {
    id: root
    property string title: ""
    height: 32; width: parent ? parent.width : 200
    color: "transparent"

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width; height: 1
        color: "#1a1a2e"
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: title
        color: "#ffffff66"
        font.pixelSize: 11
        font.weight: Font.Bold
        font.letterSpacing: 1
    }
}
