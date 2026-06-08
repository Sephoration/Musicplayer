import QtQuick

// ============================================================
//  视图标签按钮 —— 标题栏中间的三个标签（播放/媒体库/设置）
// ============================================================

Rectangle {
    id: root
    property string label: ""
    property string viewId: ""
    property bool active: AppModel.currentView === viewId

    width: labelText.implicitWidth + 24
    height: 32
    radius: 6
    color: hovered && !active ? "#15152e" : (active ? "#1a1a33" : "transparent")

    property bool hovered: false

    Text {
        id: labelText
        anchors.centerIn: parent
        text: label
        color: active ? "#d9d9d9" : "#999999"
        font.pixelSize: 13
    }

    // 底部激活指示条
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.6
        height: 2
        color: active ? mainWindow.accentColor : "transparent"
        radius: 1
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onEntered: parent.hovered = true
        onExited: parent.hovered = false
        onClicked: AppModel.setCurrentView(viewId)
    }
}
