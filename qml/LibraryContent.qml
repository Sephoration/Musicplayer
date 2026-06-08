import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// ============================================================
//  歌曲列表 —— 媒体库的右侧主内容区
//  显示筛选后的歌曲列表，支持双击播放、右键菜单
// ============================================================

Rectangle {
    id: content
    color: "transparent"

    // 根据当前分类和搜索词筛选歌曲
    property var filteredSongs: {
        var all = AppModel.songs || []
        var result = []

        // 获取当前分类的 songIds
        var catSongs = []
        var cats = AppModel.categories || []
        for (var ci = 0; ci < cats.length; ci++) {
            if (cats[ci].id === AppModel.activeCategoryId) {
                catSongs = cats[ci].songIds || []
                break
            }
        }

        // 搜索过滤
        var search = (AppModel.librarySearch || "").toLowerCase()
        for (var i = 0; i < all.length; i++) {
            var song = all[i]

            // 分类过滤
            if (AppModel.activeCategoryId !== "all") {
                if (!catSongs.includes(song.id)) continue
            }

            // 歌词过滤
            if (AppModel.libraryFilter === "hasLyrics" && !song.hasLyrics) continue
            if (AppModel.libraryFilter === "noLyrics" && song.hasLyrics) continue

            // 搜索过滤
            if (search) {
                var title = (song.title || "").toLowerCase()
                var artist = (song.artist || "").toLowerCase()
                var album = (song.album || "").toLowerCase()
                if (title.indexOf(search) < 0 && artist.indexOf(search) < 0 && album.indexOf(search) < 0)
                    continue
            }

            result.push(song)
        }
        return result
    }

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        Column {
            width: content.width
            spacing: 1

            // ---- 表头 ----
            Rectangle {
                width: parent.width
                height: 36
                color: "#0d0d18"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 0

                    Text {
                        width: 40; text: "#"; color: "#555555"; font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        width: parent.parent.width * 0.35; text: "标题"; color: "#555555"; font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        width: parent.parent.width * 0.2; text: "艺术家"; color: "#555555"; font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.parent.width * 0.2; text: "专辑"; color: "#555555"; font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                    }
                    Text {
                        width: 60; text: "时长"; color: "#555555"; font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        width: 40; text: "格式"; color: "#555555"; font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // ---- 歌曲行 ----
            Repeater {
                model: filteredSongs

                delegate: Rectangle {
                    id: songRow
                    width: content.width
                    height: 42
                    color: rowHovered ? "#ffffff08" : (index % 2 === 0 ? "transparent" : "#ffffff03")
                    radius: 4

                    property bool rowHovered: false
                    property var songData: modelData

                    // 收藏图标
                    property bool isFav: {
                        var favCats = AppModel.categories || []
                        for (var ci = 0; ci < favCats.length; ci++) {
                            if (favCats[ci].id === "favorites" && favCats[ci].songIds) {
                                return favCats[ci].songIds.includes(songData.id)
                            }
                        }
                        return false
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 0

                        // 序号/收藏
                        Text {
                            width: 40; anchors.verticalCenter: parent.verticalCenter
                            text: isFav ? "❤️" : (index + 1)
                            color: isFav ? "#ef4444" : "#666666"
                            font.pixelSize: 12
                        }

                        // 标题
                        Text {
                            width: parent.parent.width * 0.35; anchors.verticalCenter: parent.verticalCenter
                            text: songData.title || "未知"
                            color: "#d9d9d9"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }

                        // 艺术家
                        Text {
                            width: parent.parent.width * 0.2; anchors.verticalCenter: parent.verticalCenter
                            text: songData.artist || "未知艺术家"
                            color: "#888888"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        // 专辑
                        Text {
                            width: parent.parent.width * 0.2; anchors.verticalCenter: parent.verticalCenter
                            text: songData.album || "-"
                            color: "#777777"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        // 时长
                        Text {
                            width: 60; anchors.verticalCenter: parent.verticalCenter
                            text: songData.duration || "0:00"
                            color: "#666666"
                            font.pixelSize: 12
                        }

                        // 格式
                        Text {
                            width: 40; anchors.verticalCenter: parent.verticalCenter
                            text: songData.format || ""
                            color: "#555555"
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onEntered: songRow.rowHovered = true
                        onExited: songRow.rowHovered = false
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                contextMenu.songId = songData.id
                                contextMenu.songTitle = songData.title
                                contextMenu.popup()
                            } else {
                                AppModel.setCurrentView("player")
                                AppModel.playSong(songData.id, songData.title, songData.artist)
                            }
                        }
                    }
                }
            }

            // 空状态
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 60
                text: AppModel.libraryLoading ? "加载中..." : "没有找到歌曲，请导入音乐文件"
                color: "#555555"
                font.pixelSize: 13
                visible: filteredSongs.length === 0
                y: 60
            }
        }
    }

    // 右键菜单
    Menu {
        id: contextMenu
        property int songId: 0
        property string songTitle: ""

        MenuItem {
            text: "播放"
            onTriggered: {
                AppModel.setCurrentView("player")
                AppModel.playSong(contextMenu.songId, contextMenu.songTitle, "")
            }
        }
        MenuItem {
            text: "添加到播放队列"
            onTriggered: AppModel.addToQueue(contextMenu.songId, contextMenu.songTitle, "")
        }
        MenuItem {
            text: "下一首播放"
            onTriggered: AppModel.addToPlayNext(contextMenu.songId, contextMenu.songTitle, "")
        }
        MenuItem {
            text: "收藏 / 取消收藏"
            onTriggered: AppModel.toggleFavorite(contextMenu.songId)
        }
        MenuSeparator {}
        MenuItem {
            text: "删除"
            onTriggered: AppModel.deleteSong(contextMenu.songId)
        }
    }
}
