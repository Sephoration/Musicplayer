import QtQuick

Rectangle {
    id: root
    property string label: ""
    property string viewId: ""
    property bool active: AppModel.currentView === viewId
    property bool hovered: false

    width: labelText.implicitWidth + 30
    height: 30
    radius: 15
    color: active ? Qt.rgba(1, 1, 1, 0.82) : (hovered ? Qt.rgba(1, 1, 1, 0.56) : "transparent")
    border.width: active ? 1 : 0
    border.color: Qt.rgba(0.10, 0.12, 0.18, 0.08)

    Text {
        id: labelText
        anchors.centerIn: parent
        text: label
        color: active ? "#171b2a" : "#667085"
        font.pixelSize: 13
        font.weight: active ? Font.DemiBold : Font.Normal
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        width: active ? 18 : 0
        height: 2
        radius: 1
        color: mainWindow.accentColor
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: AppModel.setCurrentView(viewId)
    }
}
