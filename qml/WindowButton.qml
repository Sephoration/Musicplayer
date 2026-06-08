import QtQuick

// ============================================================
//  窗口控制按钮 —— 最小化/最大化/关闭
// ============================================================

Rectangle {
    id: root
    property string btnText: ""
    property bool isClose: false

    signal clicked()

    width: 32; height: 28; radius: 6
    color: hovered ? (isClose ? "#ee444433" : "#ffffff15") : "transparent"

    property bool hovered: false

    Text {
        anchors.centerIn: parent
        text: btnText
        color: isClose && hovered ? "#ff6666" : "#ffffff99"
        font.pixelSize: 14
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
