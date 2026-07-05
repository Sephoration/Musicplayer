import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Particles

ApplicationWindow {
    id: mainWindow
    width: 1040
    height: 740
    minimumWidth: 920
    minimumHeight: 620
    color: "#f4f6fb"
    flags: Qt.FramelessWindowHint | Qt.Window

    property string accentColor: AppModel.accentColor || "#7c3aed"
    property color surfaceColor: Qt.rgba(1, 1, 1, 0.78)
    property color borderColor: Qt.rgba(0.10, 0.12, 0.18, 0.08)

    visible: !AppModel.miniMode

    Connections {
        target: AppModel
        function onMiniModeChanged() {
            mainWindow.visible = !AppModel.miniMode
        }
    }

    onClosing: function(close) {
        close.accepted = false
        mainWindow.hide()
        AppModel.showToast("已最小化到托盘")
    }

    Item {
        anchors.fill: parent
        z: -10

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#fbfcff" }
                GradientStop { position: 0.48; color: "#f3f6fb" }
                GradientStop { position: 1.0; color: "#e9eef7" }
            }
        }

        Rectangle {
            x: -parent.width * 0.12
            y: -parent.height * 0.22
            width: parent.width * 0.62
            height: width
            radius: width / 2
            color: Qt.rgba(0.49, 0.23, 0.93, 0.13)
        }

        Rectangle {
            x: parent.width * 0.58
            y: parent.height * 0.04
            width: parent.width * 0.45
            height: width
            radius: width / 2
            color: Qt.rgba(0.06, 0.72, 0.86, 0.12)
        }

        Rectangle {
            x: parent.width * 0.22
            y: parent.height * 0.68
            width: parent.width * 0.64
            height: width * 0.45
            radius: height / 2
            color: Qt.rgba(0.96, 0.45, 0.63, 0.09)
        }

        Image {
            anchors.fill: parent
            source: AppModel.backgroundImage || ""
            fillMode: Image.PreserveAspectCrop
            visible: source != ""
            opacity: 0.22
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(1, 1, 1, Math.min(0.72, AppModel.backgroundOverlay / 100))
            visible: AppModel.backgroundImage && AppModel.backgroundImage !== ""
        }
    }

    Visualizer2D {
        anchors.fill: parent
        visible: AppModel.currentView === "player" && AppModel.visualizerMode === "2d"
        z: -2
        opacity: 0.18
    }

    ParticleSystem {
        anchors.fill: parent
        running: AppModel.playing && AppModel.currentView === "player"
        z: -1

        Emitter {
            anchors.fill: parent
            lifeSpan: 6400
            size: 3
            sizeVariation: 3
            emitRate: 4
            velocity: PointDirection { y: [-22, -48]; x: [-14, 14] }
            acceleration: PointDirection { y: 4 }
        }

        Wander { xVariance: 20; yVariance: 10 }

        ImageParticle {
            source: "qrc:/particle.svg"
            color: mainWindow.accentColor
            colorVariation: 0.24
            alpha: 0.16
            alphaVariation: 0.10
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            z: 10
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 18
            Layout.rightMargin: 18
            Layout.topMargin: 12
            Layout.bottomMargin: 12
            spacing: 14

            PlaylistSidebar {
                Layout.preferredWidth: 292
                Layout.fillHeight: true
                visible: AppModel.playlistOpen
            }

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

                Item {
                    LyricsPanel {
                        anchors.centerIn: parent
                        width: Math.min(parent.width * 0.82, 760)
                        height: Math.min(parent.height * 0.88, 520)
                    }
                }

                MediaLibrary {}
                SettingsPanel {}
            }
        }

        ControlBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 96
        }
    }

    Item {
        anchors.fill: parent
        z: 80
        visible: mainWindow.visibility !== Window.Maximized

        MouseArea { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 6; cursorShape: Qt.SizeHorCursor; onPressed: mainWindow.startSystemResize(Qt.LeftEdge) }
        MouseArea { anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 6; cursorShape: Qt.SizeHorCursor; onPressed: mainWindow.startSystemResize(Qt.RightEdge) }
        MouseArea { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 6; cursorShape: Qt.SizeVerCursor; onPressed: mainWindow.startSystemResize(Qt.TopEdge) }
        MouseArea { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 6; cursorShape: Qt.SizeVerCursor; onPressed: mainWindow.startSystemResize(Qt.BottomEdge) }
        MouseArea { anchors.left: parent.left; anchors.top: parent.top; width: 12; height: 12; cursorShape: Qt.SizeFDiagCursor; onPressed: mainWindow.startSystemResize(Qt.LeftEdge | Qt.TopEdge) }
        MouseArea { anchors.right: parent.right; anchors.top: parent.top; width: 12; height: 12; cursorShape: Qt.SizeBDiagCursor; onPressed: mainWindow.startSystemResize(Qt.RightEdge | Qt.TopEdge) }
        MouseArea { anchors.left: parent.left; anchors.bottom: parent.bottom; width: 12; height: 12; cursorShape: Qt.SizeBDiagCursor; onPressed: mainWindow.startSystemResize(Qt.LeftEdge | Qt.BottomEdge) }
        MouseArea { anchors.right: parent.right; anchors.bottom: parent.bottom; width: 12; height: 12; cursorShape: Qt.SizeFDiagCursor; onPressed: mainWindow.startSystemResize(Qt.RightEdge | Qt.BottomEdge) }
    }

    Toast {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 112
        z: 100
    }

    Loader {
        active: AppModel.miniMode
        sourceComponent: Component { MiniPlayer {} }
    }
}
