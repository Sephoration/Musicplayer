import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: mediaLibrary

    FolderDialog { id: folderDialog; title: "选择音乐文件夹"; onAccepted: AppModel.importFolder(selectedFolder.toString()) }

    FileDialog {
        id: fileDialog
        title: "选择音乐文件"
        nameFilters: ["音频文件 (*.mp3 *.flac *.wav *.aac *.ogg *.m4a *.wma)", "所有文件 (*.*)"]
        onAccepted: {
            var paths = []
            for (var i = 0; i < selectedFiles.length; i++) paths.push(selectedFiles[i].toString())
            AppModel.importFiles(paths)
        }
    }

    Component.onCompleted: AppModel.loadLibrary()

    RowLayout {
        anchors.fill: parent
        spacing: 14

        LibrarySidebar { Layout.preferredWidth: 218; Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 28
            color: Qt.rgba(1, 1, 1, 0.74)
            border.width: 1
            border.color: Qt.rgba(0.10, 0.12, 0.18, 0.08)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    spacing: 12

                    Column {
                        Layout.preferredWidth: 150
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2
                        Text { text: "媒体库"; color: "#171b2a"; font.pixelSize: 20; font.weight: Font.Bold }
                        Text { text: "共 " + AppModel.songs.length + " 首歌曲"; color: "#667085"; font.pixelSize: 11 }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 16
                        color: Qt.rgba(0.10, 0.12, 0.18, 0.045)
                        border.width: 1
                        border.color: Qt.rgba(0.10, 0.12, 0.18, 0.07)

                        Text { anchors.left: parent.left; anchors.leftMargin: 15; anchors.verticalCenter: parent.verticalCenter; text: "⌕"; color: "#667085"; font.pixelSize: 15 }

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            anchors.leftMargin: 40
                            anchors.rightMargin: 16
                            verticalAlignment: Text.AlignVCenter
                            color: "#171b2a"
                            selectionColor: mainWindow.accentColor
                            font.pixelSize: 13
                            clip: true
                            Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; text: "搜索歌曲、艺术家或专辑"; color: "#98a2b3"; font.pixelSize: 13; visible: !searchInput.text }
                        }

                        Connections { target: searchInput; function onTextChanged() { AppModel.setLibrarySearch(searchInput.text) } }
                    }

                    Rectangle {
                        Layout.preferredWidth: 78
                        Layout.preferredHeight: 40
                        radius: 15
                        color: filterMouse.containsMouse ? Qt.rgba(0.10, 0.12, 0.18, 0.08) : Qt.rgba(1, 1, 1, 0.62)
                        border.width: 1
                        border.color: Qt.rgba(0.10, 0.12, 0.18, 0.08)
                        Text { anchors.centerIn: parent; text: AppModel.libraryFilter === "all" ? "全部" : (AppModel.libraryFilter === "hasLyrics" ? "有歌词" : "无歌词"); color: "#475467"; font.pixelSize: 12; font.weight: Font.Medium }
                        MouseArea {
                            id: filterMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (AppModel.libraryFilter === "all") AppModel.setLibraryFilter("hasLyrics")
                                else if (AppModel.libraryFilter === "hasLyrics") AppModel.setLibraryFilter("noLyrics")
                                else AppModel.setLibraryFilter("all")
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 96
                        Layout.preferredHeight: 40
                        radius: 15
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.lighter(mainWindow.accentColor, 1.2) }
                            GradientStop { position: 1.0; color: mainWindow.accentColor }
                        }
                        Text { anchors.centerIn: parent; text: "导入音乐"; color: "white"; font.pixelSize: 12; font.weight: Font.DemiBold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: folderDialog.open() }
                    }
                }

                LibraryContent { Layout.fillWidth: true; Layout.fillHeight: true }
            }
        }
    }
}
