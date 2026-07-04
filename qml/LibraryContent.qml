import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: content
    color: "transparent"

    property var filteredSongs: {
        var all = AppModel.songs || []
        var result = []
        var catSongs = []
        var cats = AppModel.categories || []
        for (var ci = 0; ci < cats.length; ci++) {
            if (cats[ci].id === AppModel.activeCategoryId) {
                catSongs = cats[ci].songIds || []
                break
            }
        }

        var search = (AppModel.librarySearch || "").toLowerCase()
        for (var i = 0; i < all.length; i++) {
            var song = all[i]
            if (AppModel.activeCategoryId !== "all" && !catSongs.includes(song.id)) continue
            if (AppModel.libraryFilter === "hasLyrics" && !song.hasLyrics) continue
            if (AppModel.libraryFilter === "noLyrics" && song.hasLyrics) continue

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

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: "#0d0d18"

            Row {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 0

                Text { width: 40; text: "#"; color: "#555555"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                Text { width: parent.width * 0.35; text: "标题"; color: "#555555"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                Text { width: parent.width * 0.2; text: "艺术家"; color: "#555555"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight }
                Text { width: parent.width * 0.2; text: "专辑"; color: "#555555"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight }
                Text { width: 60; text: "时长"; color: "#555555"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                Text { width: 40; text: "格式"; color: "#555555"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: songList
                anchors.fill: parent
                clip: true
                model: content.filteredSongs
                spacing: 1
                reuseItems: true
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    id: songRow
                    width: songList.width
                    height: 42
                    color: rowHovered ? "#ffffff08" : (index % 2 === 0 ? "transparent" : "#ffffff03")
                    radius: 4

                    property bool rowHovered: false
                    property var songData: modelData
                    property bool isFav: {
                        var favCats = AppModel.categories || []
                        for (var ci = 0; ci < favCats.length; ci++) {
                            if (favCats[ci].id === "favorites" && favCats[ci].songIds)
                                return favCats[ci].songIds.includes(songData.id)
                        }
                        return false
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 0

                        Text { width: 40; anchors.verticalCenter: parent.verticalCenter; text: isFav ? "❤️" : (index + 1); color: isFav ? "#ef4444" : "#666666"; font.pixelSize: 12 }
                        Text { width: parent.width * 0.35; anchors.verticalCenter: parent.verticalCenter; text: songData.title || "未知"; color: "#d9d9d9"; font.pixelSize: 13; elide: Text.ElideRight }
                        Text { width: parent.width * 0.2; anchors.verticalCenter: parent.verticalCenter; text: songData.artist || "未知艺术家"; color: "#888888"; font.pixelSize: 12; elide: Text.ElideRight }
                        Text { width: parent.width * 0.2; anchors.verticalCenter: parent.verticalCenter; text: songData.album || "-"; color: "#777777"; font.pixelSize: 12; elide: Text.ElideRight }
                        Text { width: 60; anchors.verticalCenter: parent.verticalCenter; text: songData.duration || "0:00"; color: "#666666"; font.pixelSize: 12 }
                        Text { width: 40; anchors.verticalCenter: parent.verticalCenter; text: songData.format || ""; color: "#555555"; font.pixelSize: 11 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onEntered: songRow.rowHovered = true
                        onExited: songRow.rowHovered = false
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                contextMenu.songId = songData.id
                                contextMenu.songTitle = songData.title
                                contextMenu.songArtist = songData.artist
                                contextMenu.popup()
                            } else {
                                AppModel.setCurrentView("player")
                                AppModel.playSong(songData.id, songData.title, songData.artist)
                            }
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 60
                text: AppModel.libraryLoading ? "加载中..." : "没有找到歌曲，请导入音乐文件"
                color: "#555555"
                font.pixelSize: 13
                visible: content.filteredSongs.length === 0
            }
        }
    }

    Menu {
        id: contextMenu
        property int songId: 0
        property string songTitle: ""
        property string songArtist: ""

        MenuItem {
            text: "播放"
            onTriggered: {
                AppModel.setCurrentView("player")
                AppModel.playSong(contextMenu.songId, contextMenu.songTitle, contextMenu.songArtist)
            }
        }
        MenuItem {
            text: "添加到播放队列"
            onTriggered: AppModel.addToQueue(contextMenu.songId, contextMenu.songTitle, contextMenu.songArtist)
        }
        MenuItem {
            text: "下一首播放"
            onTriggered: AppModel.addToPlayNext(contextMenu.songId, contextMenu.songTitle, contextMenu.songArtist)
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
