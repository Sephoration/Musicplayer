import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ScrollView {
    id: settingsRoot
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    Item {
        width: settingsRoot.availableWidth
        height: settingsColumn.implicitHeight + 36

        ColumnLayout {
            id: settingsColumn
            width: Math.min(parent.width - 56, 760)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 18
            spacing: 18

            Column {
                Layout.fillWidth: true
                spacing: 4
                Text { text: "偏好设置"; color: "#171b2a"; font.pixelSize: 26; font.weight: Font.Bold }
                Text { text: "调整播放器的颜色、歌词、可视化和播放体验"; color: "#667085"; font.pixelSize: 12 }
            }

            SettingsGroup { title: "主题色" }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: 22
                color: Qt.rgba(1, 1, 1, 0.72)
                border.width: 1
                border.color: Qt.rgba(0.10, 0.12, 0.18, 0.08)
                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    Repeater {
                        model: ["#7c3aed","#ec4899","#f59e0b","#10b981","#3b82f6","#ef4444","#6366f1","#06b6d4"]
                        delegate: Rectangle {
                            width: 38; height: 38; radius: 19
                            color: modelData
                            border.width: AppModel.accentColor === modelData ? 4 : 2
                            border.color: AppModel.accentColor === modelData ? "#ffffff" : Qt.rgba(0.10, 0.12, 0.18, 0.16)
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: AppModel.setAccentColor(modelData) }
                        }
                    }
                }
            }

            SettingsGroup { title: "歌词设置" }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: lyricGrid.implicitHeight + 32
                radius: 22
                color: Qt.rgba(1, 1, 1, 0.72)
                border.width: 1
                border.color: Qt.rgba(0.10, 0.12, 0.18, 0.08)
                GridLayout {
                    id: lyricGrid
                    anchors.fill: parent
                    anchors.margins: 16
                    columns: 2
                    rowSpacing: 14
                    columnSpacing: 18
                    SettingRow { label: "字体大小"; SpinBox { from: 10; to: 30; value: AppModel.fontSize; onValueChanged: AppModel.setFontSize(value) } }
                    SettingRow { label: "显示翻译"; Switch { checked: AppModel.showTranslation; onCheckedChanged: AppModel.setShowTranslation(checked) } }
                    SettingRow { label: "已激活字颜色"; Rectangle { width: 42; height: 26; radius: 8; color: AppModel.lyricsActiveWordColor; border.width: 1; border.color: Qt.rgba(0.10, 0.12, 0.18, 0.12); MouseArea { anchors.fill: parent; onClicked: colorDialog.open() } } }
                    SettingRow { label: "未激活字颜色"; Rectangle { width: 42; height: 26; radius: 8; color: AppModel.lyricsInactiveColor; border.width: 1; border.color: Qt.rgba(0.10, 0.12, 0.18, 0.12); MouseArea { anchors.fill: parent; onClicked: colorDialogInactive.open() } } }
                    SettingRow { label: "背景透明度"; Slider { from: 0; to: 100; value: AppModel.lyricsOpacity; width: 130; onValueChanged: AppModel.setLyricsOpacity(value) } }
                    SettingRow { label: "背景颜色"; Rectangle { width: 42; height: 26; radius: 8; color: AppModel.lyricsBgColor; border.width: 1; border.color: Qt.rgba(0.10, 0.12, 0.18, 0.12); MouseArea { anchors.fill: parent; onClicked: colorDialogBg.open() } } }
                }
            }

            SettingsGroup { title: "可视化" }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 76
                radius: 22
                color: Qt.rgba(1, 1, 1, 0.72)
                border.width: 1
                border.color: Qt.rgba(0.10, 0.12, 0.18, 0.08)
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 18
                    spacing: 24
                    SettingRow { label: "频谱颜色"; Rectangle { width: 42; height: 26; radius: 8; color: AppModel.visualizerColor; border.width: 1; border.color: Qt.rgba(0.10, 0.12, 0.18, 0.12); MouseArea { anchors.fill: parent; onClicked: colorDialogVis.open() } } }
                    SettingRow {
                        label: "可视化模式"
                        Row {
                            spacing: 6
                            Repeater {
                                model: [{ label: "关闭", value: "off" }, { label: "2D 频谱", value: "2d" }]
                                delegate: Rectangle {
                                    width: 76; height: 30; radius: 12
                                    color: AppModel.visualizerMode === modelData.value ? Qt.rgba(0.10, 0.12, 0.18, 0.08) : Qt.rgba(1, 1, 1, 0.56)
                                    border.width: 1
                                    border.color: AppModel.visualizerMode === modelData.value ? mainWindow.accentColor : Qt.rgba(0.10, 0.12, 0.18, 0.08)
                                    Text { anchors.centerIn: parent; text: modelData.label; color: AppModel.visualizerMode === modelData.value ? "#171b2a" : "#667085"; font.pixelSize: 11 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: AppModel.setVisualizerMode(modelData.value) }
                                }
                            }
                        }
                    }
                }
            }

            SettingsGroup { title: "播放设置" }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: playGrid.implicitHeight + 32
                radius: 22
                color: Qt.rgba(1, 1, 1, 0.72)
                border.width: 1
                border.color: Qt.rgba(0.10, 0.12, 0.18, 0.08)
                GridLayout {
                    id: playGrid
                    anchors.fill: parent
                    anchors.margins: 16
                    columns: 2
                    rowSpacing: 14
                    columnSpacing: 18
                    SettingRow { label: "淡入淡出"; Switch { checked: AppModel.crossfade; onCheckedChanged: AppModel.setCrossfade(checked) } }
                    SettingRow { label: "淡入淡出时长"; SpinBox { from: 1; to: 10; value: AppModel.crossfadeDuration; enabled: AppModel.crossfade; onValueChanged: AppModel.setCrossfadeDuration(value) } }
                    SettingRow { label: "恢复播放"; Switch { checked: AppModel.resumePlayback; onCheckedChanged: AppModel.setResumePlayback(checked) } }
                }
            }

            SettingsGroup { title: "自定义背景" }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 74
                radius: 22
                color: Qt.rgba(1, 1, 1, 0.72)
                border.width: 1
                border.color: Qt.rgba(0.10, 0.12, 0.18, 0.08)
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 18
                    spacing: 12
                    Rectangle {
                        width: 110; height: 36; radius: 14
                        color: Qt.rgba(1, 1, 1, 0.62)
                        border.width: 1; border.color: Qt.rgba(0.10, 0.12, 0.18, 0.08)
                        Text { anchors.centerIn: parent; text: "选择背景图"; color: "#475467"; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bgFileDialog.open() }
                    }
                    Rectangle {
                        width: 90; height: 36; radius: 14
                        color: "#fee2e2"
                        border.width: 1; border.color: "#fecaca"
                        Text { anchors.centerIn: parent; text: "清除背景"; color: "#dc2626"; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: AppModel.clearBackgroundImagePath() }
                    }
                    Text { text: "暗色叠加: " + AppModel.backgroundOverlay + "%"; color: "#667085"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }

    ColorDialog { id: colorDialog; onAccepted: AppModel.setLyricsActiveWordColor(selectedColor.toString()) }
    ColorDialog { id: colorDialogInactive; onAccepted: AppModel.setLyricsInactiveColor(selectedColor.toString()) }
    ColorDialog { id: colorDialogBg; onAccepted: AppModel.setLyricsBgColor(selectedColor.toString()) }
    ColorDialog { id: colorDialogVis; onAccepted: AppModel.setVisualizerColor(selectedColor.toString()) }
    FileDialog { id: bgFileDialog; title: "选择背景图片"; nameFilters: ["图片文件 (*.jpg *.jpeg *.png *.bmp)"]; onAccepted: AppModel.setBackgroundImagePath(selectedFile.toString()) }
}
