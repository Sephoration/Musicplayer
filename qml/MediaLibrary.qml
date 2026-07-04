import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

// ============================================================
//  媒体库页面 —— 左侧分类栏 + 右侧歌曲列表
// ============================================================

Item {
    id: mediaLibrary

    // 文件选择对话框（用于导入文件夹）
    FolderDialog {
        id: folderDialog
        title: "选择音乐文件夹"
        onAccepted: {
            AppModel.importFolder(selectedFolder.toString())
        }
    }

    // 文件选择对话框（用于导入单个文件）
    FileDialog {
        id: fileDialog
        title: "选择音乐文件"
        nameFilters: ["音频文件 (*.mp3 *.flac *.wav *.aac *.ogg *.m4a *.wma)", "所有文件 (*.*)"]
        onAccepted: {
            var paths = []
            for (var i = 0; i < selectedFiles.length; i++) {
                paths.push(selectedFiles[i].toString())
            }
            AppModel.importFiles(paths)
        }
    }

    Component.onCompleted: {
        AppModel.loadLibrary()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---- 左侧：分类侧栏 ----
        LibrarySidebar {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
        }

        // ---- 分隔线 ----
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: "#1a1a2e"
        }

        // ---- 右侧：歌曲内容区 ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // 顶部操作栏
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 12

                    // 搜索框
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: 8
                        color: "#1a1a28"
                        border.width: 1; border.color: "#ffffff0f"

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: Text.AlignVCenter
                            color: "#d9d9d9"
                            font.pixelSize: 13
                            clip: true

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                verticalAlignment: Text.AlignVCenter
                                text: "搜索歌曲..."
                                color: "#555555"
                                font.pixelSize: 13
                                visible: !searchInput.text
                            }
                        }

                        Connections {
                            target: searchInput
                            function onTextChanged() {
                                AppModel.setLibrarySearch(searchInput.text)
                            }
                        }
                    }

                    // 过滤按钮
                    Rectangle {
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 32; radius: 8
                        color: "#1a1a28"
                        border.width: 1; border.color: "#ffffff0f"

                        Text {
                            anchors.centerIn: parent
                            text: AppModel.libraryFilter === "all" ? "全部"
                                  : (AppModel.libraryFilter === "hasLyrics" ? "有歌词" : "无歌词")
                            color: "#aaaaaa"
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (AppModel.libraryFilter === "all")
                                    AppModel.setLibraryFilter("hasLyrics")
                                else if (AppModel.libraryFilter === "hasLyrics")
                                    AppModel.setLibraryFilter("noLyrics")
                                else
                                    AppModel.setLibraryFilter("all")
                            }
                        }
                    }

                    // 导入文件夹按钮
                    Rectangle {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 32; radius: 8
                        color: "#1a1a28"
                        border.width: 1; border.color: "#ffffff1a"

                        Text {
                            anchors.centerIn: parent
                            text: "📁 导入"
                            color: "#aaaaaa"
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: folderDialog.open()
                        }
                    }
                }
            }

            // 歌曲列表
            LibraryContent {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // 底部统计
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                color: "#0d0d18"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: "共 " + AppModel.songs.length + " 首歌曲"
                    color: "#555555"
                    font.pixelSize: 11
                }
            }
        }
    }
}
