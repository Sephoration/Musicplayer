import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: miniWindow
    visible: AppModel.miniMode
    width: 380
    height: 78
    minimumWidth: 320
    minimumHeight: 72
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Window
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: 24
        color: Qt.rgba(1, 1, 1, 0.90)
        border.width: 1
        border.color: Qt.rgba(0.10, 0.12, 0.18, 0.10)
    }

    MouseArea {
        anchors.fill: parent
        onPressed: function(mouse) {
            if (mouse.button === Qt.LeftButton) miniWindow.startSystemMove()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Rectangle {
            width: 50
            height: 50
            radius: 16
            color: AppModel.accentColor || "#7c3aed"
            Layout.alignment: Qt.AlignVCenter
            clip: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.lighter(AppModel.accentColor || "#7c3aed", 1.24) }
                GradientStop { position: 1.0; color: AppModel.accentColor || "#7c3aed" }
            }
            Image { anchors.fill: parent; source: AppModel.coverUrl || ""; fillMode: Image.PreserveAspectCrop; visible: source != "" }
            Text { anchors.centerIn: parent; text: "♪"; color: Qt.rgba(1, 1, 1, 0.48); font.pixelSize: 20; visible: !(AppModel.coverUrl && AppModel.coverUrl !== "") }
        }

        Column {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            spacing: 3

            Text {
                text: AppModel.currentSongTitle || "未播放"
                color: "#171b2a"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                text: {
                    var st = AppModel.syncState
                    if (st && st.hasLyrics && st.currentLine) return st.currentLine.text || "♪"
                    return AppModel.currentSongArtist || "MusicPlayer"
                }
                color: "#667085"
                font.pixelSize: 11
                elide: Text.ElideRight
                width: parent.width
            }
        }

        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            ControlButton { text: "⏮"; size: 13; onClicked: AppModel.playPrev() }

            Rectangle {
                width: 36
                height: 36
                radius: 18
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(AppModel.accentColor || "#7c3aed", 1.28) }
                    GradientStop { position: 1.0; color: AppModel.accentColor || "#7c3aed" }
                }
                Text { anchors.centerIn: parent; anchors.horizontalCenterOffset: AppModel.playing ? 0 : 1; text: AppModel.playing ? "⏸" : "▶"; color: "white"; font.pixelSize: 14; font.weight: Font.Bold }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: AppModel.requestPlay() }
            }

            ControlButton { text: "⏭"; size: 13; onClicked: AppModel.playNext() }
            ControlButton { text: "⤢"; size: 13; onClicked: AppModel.setMiniMode(false) }
        }
    }
}
