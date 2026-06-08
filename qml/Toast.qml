import QtQuick

// ============================================================
//  Toast 消息提示 —— 从底部浮出，2 秒后自动消失
// ============================================================

Rectangle {
    id: toast
    visible: AppModel.toastVisible
    width: toastText.implicitWidth + 32
    height: 36
    radius: 10
    color: "#1a1a28"
    border.width: 1; border.color: "#ffffff0f"

    // 动画透明度过渡
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300 } }
    Behavior on visible { NumberAnimation {} }

    Text {
        id: toastText
        anchors.centerIn: parent
        text: AppModel.toastMessage
        color: "#ffffffcc"
        font.pixelSize: 13
    }
}
