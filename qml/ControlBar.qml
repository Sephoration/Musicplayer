import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Rectangle {
    id: controlBar
    color: Qt.rgba(1, 1, 1, 0.78)
    height: 96

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(0.10, 0.12, 0.18, 0.08)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 32
        anchors.rightMargin: 32
        anchors.topMargin: 8
        anchors.bottomMargin: 10
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            spacing: 14

            Text {
                text: AppModel.formatTime(AppModel.currentTime)
                color: "#667085"
                font.pixelSize: 11
                font.family: "Consolas"
                Layout.preferredWidth: 42
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                radius: 3
                color: Qt.rgba(0.10, 0.12, 0.18, 0.08)

                Rectangle {
                    height: parent.height
                    radius: 3
                    width: AppModel.duration > 0 ? parent.width * (AppModel.currentTime / AppModel.duration) : 0
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.lighter(mainWindow.accentColor, 1.18) }
                        GradientStop { position: 1.0; color: mainWindow.accentColor }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        radius: 8
                        color: "white"
                        border.width: 4
                        border.color: mainWindow.accentColor
                        visible: AppModel.duration > 0
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) { AppModel.seek(mouse.x / parent.width * AppModel.duration) }
                }

                DragHandler {
                    target: null
                    onActiveChanged: {
                        if (active) {
                            var pct = centroid.position.x / parent.width
                            AppModel.seek(Math.max(0, Math.min(1, pct)) * AppModel.duration)
                        }
                    }
                }
            }

            Text {
                text: AppModel.formatTime(AppModel.duration)
                color: "#667085"
                font.pixelSize: 11
                font.family: "Consolas"
                Layout.preferredWidth: 42
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 18

            Row {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 290
                spacing: 14

                Rectangle {
                    width: 46
                    height: 46
                    radius: 14
                    color: mainWindow.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.lighter(mainWindow.accentColor, 1.25) }
                        GradientStop { position: 1.0; color: Qt.darker(mainWindow.accentColor, 1.08) }
                    }
                    Image { anchors.fill: parent; source: AppModel.coverUrl || ""; fillMode: Image.PreserveAspectCrop; visible: source != "" }
                    Text { anchors.centerIn: parent; text: "♪"; color: Qt.rgba(1, 1, 1, 0.48); font.pixelSize: 20; visible: !(AppModel.coverUrl && AppModel.coverUrl !== "") }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    width: 210

                    Text {
                        text: AppModel.currentSongTitle || "未选择歌曲"
                        color: "#171b2a"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    Text {
                        text: AppModel.currentSongArtist || "MusicPlayer"
                        color: "#667085"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Row {
                    anchors.centerIn: parent
                    spacing: 14

                    ControlButton { text: "→"; size: 17; anchors.verticalCenter: parent.verticalCenter; onClicked: AppModel.togglePlayMode() }
                    ControlButton { text: "⏮"; size: 18; anchors.verticalCenter: parent.verticalCenter; onClicked: AppModel.playPrev() }

                    Rectangle {
                        id: playButton
                        width: 54
                        height: 54
                        radius: 27
                        anchors.verticalCenter: parent.verticalCenter
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.lighter(mainWindow.accentColor, 1.32) }
                            GradientStop { position: 1.0; color: mainWindow.accentColor }
                        }
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.72)

                        Text {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: AppModel.playing ? 0 : 2
                            text: AppModel.playing ? "⏸" : "▶"
                            color: "white"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                        }

                        Rectangle {
                            visible: AppModel.error !== ""
                            anchors.bottom: parent.top
                            anchors.bottomMargin: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: errorText.implicitWidth + 18
                            height: 28
                            radius: 12
                            color: "#fee2e2"
                            border.width: 1
                            border.color: "#fecaca"
                            Text { id: errorText; anchors.centerIn: parent; text: AppModel.error; color: "#dc2626"; font.pixelSize: 11 }
                        }

                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: AppModel.requestPlay() }
                    }

                    ControlButton { text: "⏭"; size: 18; anchors.verticalCenter: parent.verticalCenter; onClicked: AppModel.playNext() }

                    Item {
                        width: 34
                        height: 34
                        anchors.verticalCenter: parent.verticalCenter

                        ControlButton {
                            anchors.fill: parent
                            text: AppModel.muted ? "🔇" : "🔊"
                            size: 14
                            onClicked: volumePopup.open()
                        }

                        Popup {
                            id: volumePopup
                            x: -18
                            y: -150
                            width: 70
                            height: 140
                            padding: 10
                            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                            background: Rectangle {
                                radius: 20
                                color: Qt.rgba(1, 1, 1, 0.94)
                                border.width: 1
                                border.color: Qt.rgba(0.10, 0.12, 0.18, 0.10)
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: AppModel.muted ? "0" : AppModel.volume
                                    color: "#475467"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }

                                Rectangle {
                                    width: 8
                                    height: 82
                                    radius: 4
                                    color: Qt.rgba(0.10, 0.12, 0.18, 0.08)
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: AppModel.muted ? 0 : parent.height * (AppModel.volume / 100)
                                        radius: 4
                                        color: mainWindow.accentColor
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: function(mouse) {
                                            var vol = 100 - mouse.y / parent.height * 100
                                            AppModel.setVolume(Math.max(0, Math.min(100, Math.round(vol))))
                                            if (AppModel.muted) AppModel.setMuted(false)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Row {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 290
                spacing: 10
                layoutDirection: Qt.RightToLeft

                ControlButton { text: "⤡"; size: 13; anchors.verticalCenter: parent.verticalCenter; onClicked: AppModel.toggleMiniMode() }

                Rectangle {
                    width: 42
                    height: 28
                    radius: 10
                    color: visMouse.containsMouse ? Qt.rgba(0.10, 0.12, 0.18, 0.08) : Qt.rgba(1, 1, 1, 0.62)
                    border.width: 1
                    border.color: Qt.rgba(0.10, 0.12, 0.18, 0.08)
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: AppModel.visualizerMode === "2d" ? "2D" : "关"
                        color: AppModel.visualizerMode === "2d" ? mainWindow.accentColor : "#596174"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    MouseArea { id: visMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: AppModel.setVisualizerMode(AppModel.visualizerMode === "2d" ? "off" : "2d") }
                }

                ControlButton { text: "☰"; size: 15; anchors.verticalCenter: parent.verticalCenter; onClicked: AppModel.setPlaylistOpen(!AppModel.playlistOpen) }
                TimerButton { anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
