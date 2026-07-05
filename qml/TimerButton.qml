import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: timerRow.implicitWidth

    Row {
        id: timerRow
        spacing: 4

        Rectangle {
            width: 34
            height: 34
            radius: 12
            color: hovered ? Qt.rgba(0.10, 0.12, 0.18, 0.08) : Qt.rgba(1, 1, 1, 0.62)
            border.width: 1
            border.color: Qt.rgba(0.10, 0.12, 0.18, 0.07)
            anchors.verticalCenter: parent.verticalCenter
            property bool hovered: false

            Text {
                anchors.centerIn: parent
                text: "⏱"
                color: AppModel.sleepTimerEnd > 0 ? (AppModel.accentColor || "#7c3aed") : "#596174"
                font.pixelSize: 14
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: parent.hovered = true
                onExited: parent.hovered = false
                onClicked: AppModel.sleepTimerEnd > 0 ? AppModel.clearSleepTimer() : timerPopup.open()
            }
        }

        Text {
            visible: AppModel.sleepTimerRemaining >= 0
            anchors.verticalCenter: parent.verticalCenter
            text: {
                var ms = AppModel.sleepTimerRemaining
                if (ms < 0) return ""
                var totalSec = Math.ceil(ms / 1000)
                var m = Math.floor(totalSec / 60)
                var s = totalSec % 60
                return m + ":" + (s < 10 ? "0" : "") + s
            }
            color: AppModel.accentColor || "#7c3aed"
            font.pixelSize: 11
            font.family: "Consolas"
        }
    }

    Popup {
        id: timerPopup
        x: -width + root.width
        y: -height - 8
        width: 150
        padding: 8
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: Qt.rgba(1, 1, 1, 0.96)
            radius: 14
            border.width: 1
            border.color: Qt.rgba(0.10, 0.12, 0.18, 0.08)
        }

        Column {
            spacing: 2
            width: parent.width

            Text { text: "睡眠定时器"; color: "#667085"; font.pixelSize: 11; leftPadding: 8; topPadding: 2; bottomPadding: 6 }

            Repeater {
                model: [{ label: "15 分钟", value: 15 }, { label: "30 分钟", value: 30 }, { label: "45 分钟", value: 45 }, { label: "60 分钟", value: 60 }, { label: "90 分钟", value: 90 }]
                delegate: Rectangle {
                    width: parent.width - 8
                    height: 28
                    radius: 9
                    color: hovered ? Qt.rgba(0.10, 0.12, 0.18, 0.07) : "transparent"
                    anchors.horizontalCenter: parent.horizontalCenter
                    property bool hovered: false
                    Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8; text: modelData.label; color: "#344054"; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: parent.hovered = true; onExited: parent.hovered = false; onClicked: { AppModel.setSleepTimer(modelData.value); timerPopup.close() } }
                }
            }

            Rectangle { width: parent.width - 8; height: 1; color: Qt.rgba(0.10, 0.12, 0.18, 0.08); anchors.horizontalCenter: parent.horizontalCenter }

            Rectangle {
                width: parent.width - 8
                height: 28
                radius: 9
                color: hovered ? Qt.rgba(0.10, 0.12, 0.18, 0.07) : "transparent"
                anchors.horizontalCenter: parent.horizontalCenter
                property bool hovered: false
                Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8; text: "取消定时"; color: "#667085"; font.pixelSize: 12 }
                MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: parent.hovered = true; onExited: parent.hovered = false; onClicked: { AppModel.clearSleepTimer(); timerPopup.close() } }
            }
        }
    }
}
