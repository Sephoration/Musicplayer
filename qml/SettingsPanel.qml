import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

// ============================================================
//  设置页面
//  主题色 / 歌词样式 / 可视化 / 背景 / 淡入淡出 / 恢复播放
// ============================================================

ScrollView {
    id: settingsRoot
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
        width: settingsRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 24

        // 页面标题
        Text {
            text: "设置"
            color: "#d9d9d9"
            font.pixelSize: 24
            font.weight: Font.Bold
            topPadding: 32
            Layout.alignment: Qt.AlignLeft
        }

        // ==================== 主题色 ====================
        SettingsGroup { title: "主题色" }
        Row {
            spacing: 8
            Layout.leftMargin: 8

            Repeater {
                model: ["#6366f1","#ec4899","#f59e0b","#10b981","#3b82f6","#ef4444","#8b5cf6","#06b6d4"]
                delegate: Rectangle {
                    width: 36; height: 36; radius: 18
                    color: modelData
                    border.width: AppModel.accentColor === modelData ? 3 : 0
                    border.color: "#ffffff"
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AppModel.setAccentColor(modelData)
                    }
                }
            }
        }

        // ==================== 歌词设置 ====================
        SettingsGroup { title: "歌词设置" }

        GridLayout {
            columns: 2; rowSpacing: 12; columnSpacing: 16
            Layout.leftMargin: 8

            SettingRow {
                label: "字体大小"
                SpinBox {
                    from: 10; to: 30; value: AppModel.fontSize
                    onValueChanged: AppModel.setFontSize(value)
                }
            }

            SettingRow {
                label: "显示翻译"
                Switch {
                    checked: AppModel.showTranslation
                    onCheckedChanged: AppModel.setShowTranslation(checked)
                }
            }

            SettingRow {
                label: "已激活字颜色"
                Rectangle {
                    width: 40; height: 24; radius: 4
                    color: AppModel.lyricsActiveWordColor
                    border.width: 1; border.color: "#ffffff1a"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: colorDialog.open()
                    }
                }
            }

            SettingRow {
                label: "未激活字颜色"
                Rectangle {
                    width: 40; height: 24; radius: 4
                    color: AppModel.lyricsInactiveColor
                    border.width: 1; border.color: "#ffffff1a"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: colorDialogInactive.open()
                    }
                }
            }

            SettingRow {
                label: "背景透明度"
                Slider {
                    from: 0; to: 100; value: AppModel.lyricsOpacity
                    width: 120
                    onValueChanged: AppModel.setLyricsOpacity(value)
                }
            }

            SettingRow {
                label: "背景颜色"
                Rectangle {
                    width: 40; height: 24; radius: 4
                    color: AppModel.lyricsBgColor
                    border.width: 1; border.color: "#ffffff1a"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: colorDialogBg.open()
                    }
                }
            }
        }

        // ==================== 可视化 ====================
        SettingsGroup { title: "可视化" }

        Row {
            spacing: 16
            Layout.leftMargin: 8

            SettingRow {
                label: "频谱颜色"
                Rectangle {
                    width: 40; height: 24; radius: 4
                    color: AppModel.visualizerColor
                    border.width: 1; border.color: "#ffffff1a"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: colorDialogVis.open()
                    }
                }
            }

            SettingRow {
                label: "可视化模式"
                Row {
                    spacing: 4
                    Repeater {
                        model: [
                            { label: "关闭", value: "off" },
                            { label: "2D 频谱", value: "2d" }
                        ]
                        delegate: Rectangle {
                            width: 70; height: 28; radius: 6
                            color: AppModel.visualizerMode === modelData.value ? "#1a1a33" : "transparent"
                            border.width: 1; border.color: AppModel.visualizerMode === modelData.value ? mainWindow.accentColor : "#ffffff0f"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: AppModel.visualizerMode === modelData.value ? mainWindow.accentColor : "#888888"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: AppModel.setVisualizerMode(modelData.value)
                            }
                        }
                    }
                }
            }
        }

        // ==================== 播放设置 ====================
        SettingsGroup { title: "播放设置" }

        GridLayout {
            columns: 2; rowSpacing: 12; columnSpacing: 16
            Layout.leftMargin: 8

            SettingRow {
                label: "淡入淡出"
                Switch {
                    checked: AppModel.crossfade
                    onCheckedChanged: AppModel.setCrossfade(checked)
                }
            }

            SettingRow {
                label: "淡入淡出时长 (秒)"
                SpinBox {
                    from: 1; to: 10; value: AppModel.crossfadeDuration
                    enabled: AppModel.crossfade
                    onValueChanged: AppModel.setCrossfadeDuration(value)
                }
            }

            SettingRow {
                label: "恢复播放"
                Switch {
                    checked: true  // always enabled
                    onCheckedChanged: {}  // no-op, just for display
                }
            }
        }

        // ==================== 背景图 ====================
        SettingsGroup { title: "自定义背景" }

        Row {
            spacing: 12
            Layout.leftMargin: 8

            Rectangle {
                width: 100; height: 32; radius: 8
                color: "#1a1a28"
                border.width: 1; border.color: "#ffffff1a"

                Text {
                    anchors.centerIn: parent
                    text: "选择背景图"
                    color: "#aaaaaa"
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bgFileDialog.open()
                }
            }

            Rectangle {
                width: 80; height: 32; radius: 8
                color: "#1a1a28"
                border.width: 1; border.color: "#ef444433"

                Text {
                    anchors.centerIn: parent
                    text: "清除背景"
                    color: "#ef4444"
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AppModel.clearBackgroundImagePath()
                }
            }

            // 暗色叠加
            Text {
                text: "暗色叠加: " + AppModel.backgroundOverlay + "%"
                color: "#888888"
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // 底部留白
        Item { Layout.preferredHeight: 40 }
    }

    // ----- 颜色选择对话框 -----
    ColorDialog {
        id: colorDialog
        onAccepted: AppModel.setLyricsActiveWordColor(selectedColor.toString())
    }
    ColorDialog {
        id: colorDialogInactive
        onAccepted: AppModel.setLyricsInactiveColor(selectedColor.toString())
    }
    ColorDialog {
        id: colorDialogBg
        onAccepted: AppModel.setLyricsBgColor(selectedColor.toString())
    }
    ColorDialog {
        id: colorDialogVis
        onAccepted: AppModel.setVisualizerColor(selectedColor.toString())
    }

    // 背景图文件对话框
    FileDialog {
        id: bgFileDialog
        title: "选择背景图片"
        nameFilters: ["图片文件 (*.jpg *.jpeg *.png *.bmp)"]
        onAccepted: {
            var path = selectedFile.toString().replace("file:///", "")
            AppModel.setBackgroundImagePath(path)
        }
    }
}
