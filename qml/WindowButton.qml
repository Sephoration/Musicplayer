import QtQuick

Rectangle {
    id: root
    property string btnText: ""
    property bool isClose: false
    property bool hovered: false

    signal clicked()

    width: 32
    height: 28
    radius: 9
    color: hovered ? (isClose ? Qt.rgba(0.94, 0.27, 0.27, 0.12) : Qt.rgba(0.10, 0.12, 0.18, 0.08)) : "transparent"

    Text {
        anchors.centerIn: parent
        text: btnText
        color: isClose && hovered ? "#dc2626" : "#6b7280"
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
