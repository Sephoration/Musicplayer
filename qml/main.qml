import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Particles

// ============================================================
//  主窗口 —— 整个应用的入口
//  布局：背景层（渐变+深度）→ 标题栏 → 内容区(歌词/媒体库/设置) → 控制栏 → Toast
//  同时加载迷你播放器窗口（在独立 Window 中）
// ============================================================

ApplicationWindow {
    id: mainWindow
    width: 1000
    height: 720
    minimumWidth: 900
    minimumHeight: 600
    color: "#0c0c14"
    flags: Qt.FramelessWindowHint | Qt.Window

    // ----- 主题色（从 AppModel 读取，默认紫色 #6366f1） -----
    property string accentColor: AppModel.accentColor || "#6366f1"

    // ----- 迷你模式时隐藏主窗口 -----
    visible: !AppModel.miniMode

    Connections {
        target: AppModel
        function onMiniModeChanged() {
            mainWindow.visible = !AppModel.miniMode
        }
    }

    // 关闭窗口时最小化到托盘
    onClosing: function(close) {
        close.accepted = false
        mainWindow.hide()
        AppModel.showToast("已最小化到托盘")
    }

    // =====================================================
    //  主容器
    // =====================================================
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ---- 背景图层 ----
        Rectangle {
            anchors.fill: parent
            color: "#0c0c14"
            z: -1

            // 微妙的径向渐变 — 中心偏亮，边缘暗，制造深度
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#080810" }
                    GradientStop { position: 0.5; color: "#0c0c14" }
                    GradientStop { position: 1.0; color: "#08080e" }
                }
            }

            // 顶部微光（营造环境光）
            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.8
                height: parent.height * 0.4
                radius: height
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(0.39, 0.4, 0.95, 0.04) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // 自定义背景图（半透明叠加）
            Image {
                id: bgImage
                anchors.fill: parent
                source: AppModel.backgroundImage || ""
                fillMode: Image.PreserveAspectCrop
                visible: source != ""
                opacity: 0.35
            }

            // 暗色遮罩
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, AppModel.backgroundOverlay / 100)
                visible: bgImage.visible
            }
        }

        // ---- 2D 频谱可视化（放在背景层上面，所有内容下面） ----
        Visualizer2D {
            anchors.fill: parent
            visible: AppModel.currentView === "player" && AppModel.visualizerMode === "2d"
            z: 0
        }

        // ---- 粒子背景（播放时浮动光点） ----
        ParticleSystem {
            id: particleSystem
            running: AppModel.playing && AppModel.currentView === "player"
            z: 0

            Emitter {
                anchors.fill: parent
                lifeSpan: 6000
                size: 3
                sizeVariation: 2
                emitRate: 4
                velocity: PointDirection {
                    y: [-30, -60]
                    x: [-20, 20]
                }
                acceleration: PointDirection {
                    y: 5
                }
            }

            Wander {
                xVariance: 20
                yVariance: 10
            }

            ImageParticle {
                source: "qrc:/particle.svg"
                color: mainWindow.accentColor
                colorVariation: 0.3
                alpha: 0.25
                alphaVariation: 0.15
            }
        }

        // ---- 标题栏 ----
        TitleBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            z: 10
        }

        // ---- 内容区 ----
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // 播放队列侧栏
            PlaylistSidebar {
                Layout.preferredWidth: 280
                Layout.fillHeight: true
                visible: AppModel.playlistOpen
            }

            // 分隔线
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: "#1a1a2e"
                visible: AppModel.playlistOpen
            }

            // 主内容：StackLayout 切换三个视图
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: {
                    var v = AppModel.currentView
                    if (v === "player") return 0
                    if (v === "library") return 1
                    if (v === "settings") return 2
                    return 0
                }

                // 0: 播放器视图 → 歌词面板居中
                Item {
                    LyricsPanel {
                        anchors.centerIn: parent
                        width: parent.width * 0.65
                        height: parent.height * 0.85
                    }
                }

                // 1: 媒体库视图
                MediaLibrary {
                    anchors.fill: parent
                }

                // 2: 设置视图
                SettingsPanel {
                    anchors.fill: parent
                }
            }
        }

        // ---- 底部控制栏 ----
        ControlBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
        }
    }

    // =====================================================
    //  Toast 提示
    // =====================================================
    Toast {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100
        z: 100
    }

    // =====================================================
    //  迷你播放器（独立窗口）
    //  当 AppModel.miniMode = true 时显示
    // =====================================================
    Loader {
        id: miniPlayerLoader
        active: AppModel.miniMode
        sourceComponent: miniPlayerComp
    }

    Component {
        id: miniPlayerComp
        MiniPlayer {}
    }
}
