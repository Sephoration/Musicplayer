#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>
#include <QQuickWindow>
#include <QStyle>
#include "app/AppModel.h"

int main(int argc, char* argv[]) {
    // ---- 应用程序基础设置 ----
    QApplication app(argc, argv);
    app.setOrganizationName("MusicPlayer");
    app.setApplicationName("MusicPlayer");
    app.setApplicationVersion("1.0.0");

    // ---- 将 AppModel 暴露给 QML ----
    // QML 中所有文件都可以直接访问 AppModel.xxx
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("AppModel", AppModel::instance());

    // ---- 加载主 QML ----
    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    // 获取主窗口指针（后续托盘操作会用到）
    const auto rootObjs = engine.rootObjects();
    QObject* rootObj = rootObjs.isEmpty() ? nullptr : rootObjs.first();
    QWindow* mainWin = rootObj ? qobject_cast<QQuickWindow*>(rootObj) : nullptr;

    // ---- 系统托盘 ----
    QSystemTrayIcon* trayIcon = new QSystemTrayIcon(&app);
    trayIcon->setToolTip("MusicPlayer");
    // 无法加载自定义图标时使用系统默认图标
    trayIcon->setIcon(app.style()->standardIcon(QStyle::SP_MediaPlay));

    // 托盘右键菜单
    QMenu* trayMenu = new QMenu();

    QAction* showAction = trayMenu->addAction("显示/隐藏主窗口");
    QObject::connect(showAction, &QAction::triggered, [mainWin]() {
        if (!mainWin) return;
        if (mainWin->isVisible()) {
            mainWin->hide();
        } else {
            mainWin->show();
            mainWin->raise();
            mainWin->requestActivate();
        }
    });

    QAction* playAction = trayMenu->addAction("播放 / 暂停");
    QObject::connect(playAction, &QAction::triggered, []() {
        AppModel::instance()->requestPlay();
    });

    QAction* nextAction = trayMenu->addAction("下一首");
    QObject::connect(nextAction, &QAction::triggered, []() {
        AppModel::instance()->playNext();
    });

    QAction* prevAction = trayMenu->addAction("上一首");
    QObject::connect(prevAction, &QAction::triggered, []() {
        AppModel::instance()->playPrev();
    });

    trayMenu->addSeparator();

    QAction* quitAction = trayMenu->addAction("退出程序");
    QObject::connect(quitAction, &QAction::triggered, &app, &QApplication::quit);

    trayIcon->setContextMenu(trayMenu);

    // 左键点击托盘图标 → 切换显示/隐藏
    QObject::connect(trayIcon, &QSystemTrayIcon::activated,
        [mainWin](QSystemTrayIcon::ActivationReason reason) {
            if (!mainWin) return;
            if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick) {
                if (mainWin->isVisible()) {
                    mainWin->hide();
                } else {
                    mainWin->show();
                    mainWin->raise();
                    mainWin->requestActivate();
                }
            }
        });

    trayIcon->show();

    return app.exec();
}
