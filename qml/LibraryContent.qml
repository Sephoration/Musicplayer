import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Rectangle {
    id: content
    radius: 22
    color: Qt.rgba(1, 1, 1, 0.54)
    border.width: 1
    border.color: Qt.rgba(0.10, 0.12, 0.18, 0.07)

    property string sortMode: "default"
    property var filteredSongs: {
        var all = AppModel.songs || []
        var result = []
        var catSongs = []
        var cats = AppModel.categories || []
        for (var ci = 0; ci < cats.length; ci++) {
            if (cats[ci].id === AppModel.activeCategoryId) { catSongs = cats[ci].songIds || []; break }
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
                if (title.indexOf(search) < 0 && artist.indexOf(search) < 0 && album.indexOf(search) < 0) continue
            }
            result.push(song)
        }
        if (sortMode === "title") result.sort(function(a, b) { return (a.title || "").localeCompare(b.title || "") })
        else if (sortMode === "artist") result.sort(function(a, b) { return (a.artist || "").localeCompare(b.artist || "") || (a.title || "").localeCompare(b.title || "") })
        else if (sortMode === "duration") result.sort(function(a, b) { return (a.durationSec || 0) - (b.durationSec || 0) })
        else if (AppModel.activeCategoryId === "recent") result.sort(function(a, b) { return catSongs.indexOf(a.id) - catSongs.indexOf(b.id) })
        return result
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 4

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 12
            color: Qt.rgba(0.10, 0.12, 0.18, 0.045)

            Row {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 0
                Text { width: 42; text: "#"; color: "#667085"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                Text { width: parent.width * 0.36; text: "标题"; color: "#667085"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                Text { width: parent.width * 0.2; text: "艺术家"; color: "#667085"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight }
                Text { width: parent.width * 0.2; text: "专辑"; color: "#667085"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight }
                Text { width: 58; text: "时长"; color: "#667085"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                Text { width: 42; text: "格式"; color: "#667085"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
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
                spacing: 5
                reuseItems: true
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    id: songRow
                    width: songList.width
                    height: 48
                    radius: 15
                    color: rowHovered ? Qt.rgba(0.10, 0.12, 0.18, 0.07) : (index % 2 === 0 ? Qt.rgba(1, 1, 1, 0.42) : "transparent")
                    border.width: rowHovered ? 1 : 0
                    border.color: Qt.rgba(0.10, 0.12, 0.18, 0.07)

                    property bool rowHovered: false
                    property var songData: modelData
                    property bool isFav: {
                        var favCats = AppModel.categories || []
                        for (var ci = 0; ci < favCats.length; ci++) {
                            if (favCats[ci].id === "favorites" && favCats[ci].songIds) return favCats[ci].songIds.includes(songData.id)
                        }
                        return false
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 0
                        Text { width: 42; anchors.verticalCenter: parent.verticalCenter; text: isFav ? "♥" : (index + 1); color: isFav ? "#e11d48" : "#667085"; font.pixelSize: 12; font.weight: isFav ? Font.Bold : Font.Normal }
                        Text { width: parent.width * 0.36; anchors.verticalCenter: parent.verticalCenter; text: songData.title || "未知"; color: "#171b2a"; font.pixelSize: 13; font.weight: Font.Medium; elide: Text.ElideRight }
                        Text { width: parent.width * 0.2; anchors.verticalCenter: parent.verticalCenter; text: songData.artist || "未知艺术家"; color: "#475467"; font.pixelSize: 12; elide: Text.ElideRight }
                        Text { width: parent.width * 0.2; anchors.verticalCenter: parent.verticalCenter; text: songData.album || "-"; color: "#667085"; font.pixelSize: 12; elide: Text.ElideRight }
                        Text { width: 58; anchors.verticalCenter: parent.verticalCenter; text: songData.duration || "0:00"; color: "#667085"; font.pixelSize: 12 }
                        Text { width: 42; anchors.verticalCenter: parent.verticalCenter; text: songData.format || ""; color: "#98a2b3"; font.pixelSize: 11 }
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
                                AppModel.replaceQueueAndPlay(content.filteredSongs, index)
                            }
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: content.filteredSongs.length === 0
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: AppModel.libraryLoading ? "加载中..." : "♪"; color: Qt.rgba(0.10, 0.12, 0.18, 0.18); font.pixelSize: 42 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: AppModel.libraryLoading ? "正在扫描音乐" : "没有找到歌曲，请导入音乐文件"; color: "#667085"; font.pixelSize: 13 }
            }
        }
    }

    FileDialog {
        id: lyricsDialog
        title: "选择歌词文件"
        nameFilters: ["LRC 歌词 (*.lrc)", "文本文件 (*.txt)"]
        onAccepted: AppModel.importLyricsFile(contextMenu.songId, selectedFile.toString())
    }
    FileDialog {
        id: coverDialog
        title: "选择封面图片"
        nameFilters: ["图片 (*.jpg *.jpeg *.png)"]
        onAccepted: AppModel.importCover(contextMenu.songId, selectedFile.toString())
    }
    Dialog {
        id: removeDialog
        title: "从媒体库移除歌曲？"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Ok | Dialog.Cancel
        Label {
            text: "将删除媒体库中的副本，原始文件不会受影响。"
            wrapMode: Text.WordWrap
        }
        onAccepted: AppModel.deleteSong(contextMenu.songId)
    }

    Menu {
        id: contextMenu
        property int songId: 0
        property string songTitle: ""
        property string songArtist: ""
        MenuItem { text: "播放"; onTriggered: { AppModel.setCurrentView("player"); AppModel.playSong(contextMenu.songId, contextMenu.songTitle, contextMenu.songArtist) } }
        MenuItem { text: "添加到播放队列"; onTriggered: AppModel.addToQueue(contextMenu.songId, contextMenu.songTitle, contextMenu.songArtist) }
        MenuItem { text: "下一首播放"; onTriggered: AppModel.addToPlayNext(contextMenu.songId, contextMenu.songTitle, contextMenu.songArtist) }
        MenuItem { text: "收藏 / 取消收藏"; onTriggered: AppModel.toggleFavorite(contextMenu.songId) }
        MenuItem { text: "导入歌词…"; onTriggered: lyricsDialog.open() }
        MenuItem { text: "更换封面…"; onTriggered: coverDialog.open() }
        Menu {
            id: addCategoryMenu
            title: "添加到分类"
            Instantiator {
                model: (AppModel.categories || []).filter(function(c) { return c.id !== "all" && c.id !== "favorites" && c.id !== "recent" })
                delegate: MenuItem {
                    required property var modelData
                    text: modelData.name
                    enabled: !(modelData.songIds || []).includes(contextMenu.songId)
                    onTriggered: AppModel.addToCategory(modelData.id, contextMenu.songId)
                }
                onObjectAdded: function(index, object) { addCategoryMenu.insertItem(index, object) }
                onObjectRemoved: function(index, object) { addCategoryMenu.removeItem(object) }
            }
        }
        MenuItem {
            text: "从当前分类移除"
            visible: AppModel.activeCategoryId !== "all" && AppModel.activeCategoryId !== "favorites" && AppModel.activeCategoryId !== "recent"
            onTriggered: AppModel.removeFromCategory(AppModel.activeCategoryId, contextMenu.songId)
        }
        MenuSeparator {}
        MenuItem { text: "从媒体库移除…"; onTriggered: removeDialog.open() }
    }
}
