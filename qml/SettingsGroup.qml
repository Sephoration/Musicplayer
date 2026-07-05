import QtQuick

Rectangle {
    id: root
    property string title: ""
    height: 30
    width: parent ? parent.width : 200
    color: "transparent"

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle { width: 4; height: 16; radius: 2; color: mainWindow.accentColor; anchors.verticalCenter: parent.verticalCenter }

        Text {
            text: title
            color: "#344054"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.letterSpacing: 0.8
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
