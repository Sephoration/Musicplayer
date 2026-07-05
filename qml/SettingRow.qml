import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    property string label: ""
    property alias controlItem: controlContainer.children

    spacing: 12
    height: 34

    Text {
        text: label
        color: "#475467"
        font.pixelSize: 12
        Layout.preferredWidth: 110
        Layout.alignment: Qt.AlignVCenter
    }

    Item {
        id: controlContainer
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: childrenRect.width
        Layout.preferredHeight: childrenRect.height
    }
}
