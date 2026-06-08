import QtQuick
import QtQuick.Controls

// ============================================================
//  睡眠定时器按钮 —— 点击显示预设时间选择弹窗
// ============================================================

Item {
    id: root
    width: timerRow.implicitWidth

    Row {
        id: timerRow
        spacing: 4

        // 定时器图标按钮
        Rectangle {
            width: 30; height: 30; radius: 6
            color: hovered ? "#ffffff10" : "transparent"
            anchors.verticalCenter: parent.verticalCenter

            property bool hovered: false

            Text {
                anchors.centerIn: parent
                text: "⏱"
                color: AppModel.sleepTimerEnd > 0 ? "#a78bfa" : "#ffffff80"
                font.pixelSize: 14
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onEntered: parent.hovered = true
                onExited: parent.hovered = false
                onClicked: {
                    if (AppModel.sleepTimerEnd > 0) {
                        AppModel.clearSleepTimer()
                    } else {
                        timerPopup.visible = !timerPopup.visible
                    }
                }
            }
        }

        // 剩余时间显示
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
            color: "#a78bfa"
            font.pixelSize: 11
            font.family: "Consolas, monospace"
        }
    }

    // 定时器弹窗
    Popup {
        id: timerPopup
        x: -width + root.width
        y: -height - 8
        width: 140
        padding: 8
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#1a1a28"
            radius: 12
            border.width: 1; border.color: "#ffffff0f"
        }

        Column {
            spacing: 2
            width: parent.width

            Text {
                text: "睡眠定时器"
                color: "#ffffff59"
                font.pixelSize: 11
                leftPadding: 8; topPadding: 2; bottomPadding: 6
            }

            Repeater {
                model: [
                    { label: "15 分钟", value: 15 },
                    { label: "30 分钟", value: 30 },
                    { label: "45 分钟", value: 45 },
                    { label: "60 分钟", value: 60 },
                    { label: "90 分钟", value: 90 }
                ]
                delegate: Rectangle {
                    width: parent.width - 8
                    height: 28; radius: 6
                    color: hovered ? "#a78bfa26" : "transparent"
                    anchors.horizontalCenter: parent.horizontalCenter

                    property bool hovered: false

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        text: modelData.label
                        color: "#ffffffcc"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: {
                            AppModel.setSleepTimer(modelData.value)
                            timerPopup.close()
                        }
                    }
                }
            }

            // 分隔线
            Rectangle {
                width: parent.width - 8; height: 1; radius: 0.5
                color: "#ffffff0f"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 4; anchors.bottomMargin: 4
            }

            // 取消定时
            Rectangle {
                width: parent.width - 8
                height: 28; radius: 6
                color: hovered ? "#ffffff10" : "transparent"
                anchors.horizontalCenter: parent.horizontalCenter

                property bool hovered: false

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    text: "取消定时"
                    color: "#ffffff66"
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                    onClicked: {
                        AppModel.clearSleepTimer()
                        timerPopup.close()
                    }
                }
            }
        }
    }
}
