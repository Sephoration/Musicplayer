import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 设置页面行：标签 + 控件
RowLayout {
    property string label: ""
    property alias controlItem: controlContainer.children

    spacing: 12
    height: 32

    Text {
        text: label
        color: "#aaaaaa"
        font.pixelSize: 12
        Layout.preferredWidth: 100
        Layout.alignment: Qt.AlignVCenter
    }

    Item {
        id: controlContainer
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: childrenRect.width
        Layout.preferredHeight: childrenRect.height
    }
}
