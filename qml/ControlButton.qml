import QtQuick

// ============================================================
//  通用控制按钮 —— 带 hover 效果的图标按钮
// ============================================================

Rectangle {
    id: root
    property string text: ""
    property int size: 14

    signal clicked()

    width: 30; height: 30; radius: 6
    color: hovered ? "#ffffff10" : "transparent"

    property bool hovered: false

    Text {
        anchors.centerIn: parent
        text: root.text
        color: "#ffffff88"
        font.pixelSize: root.size
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onEntered: parent.hovered = true
        onExited: parent.hovered = false
        onClicked: root.clicked()
    }
}
