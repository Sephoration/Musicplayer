import QtQuick

Rectangle {
    id: root
    property string text: ""
    property int size: 14
    property bool hovered: false

    signal clicked()

    width: 34
    height: 34
    radius: 12
    color: hovered ? Qt.rgba(0.10, 0.12, 0.18, 0.08) : Qt.rgba(1, 1, 1, 0.62)
    border.width: 1
    border.color: hovered ? Qt.rgba(0.10, 0.12, 0.18, 0.12) : Qt.rgba(0.10, 0.12, 0.18, 0.07)

    Text {
        anchors.centerIn: parent
        text: root.text
        color: hovered ? "#151927" : "#596174"
        font.pixelSize: root.size
        font.weight: Font.Medium
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.clicked()
    }
}
