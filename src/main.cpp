#include <QDir>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QSurfaceFormat>
#include <QUrl>
#include "models.h"
#include "realvideosurface.h"

int main(int argc, char *argv[]) {
    // libvlc finds its plugins next to libvlc.dll by default; set it explicitly so it also works from any cwd.
    const QString appDir = QCoreApplication::applicationDirPath();
    if (qEnvironmentVariableIsEmpty("VLC_PLUGIN_PATH"))
        qputenv("VLC_PLUGIN_PATH", QDir::toNativeSeparators(appDir + "/plugins").toUtf8());

    QGuiApplication app(argc, argv);
    app.setOrganizationName("0xcl");
    app.setApplicationName("0xcl Modern VLC");
    app.setWindowIcon(QIcon(":/icons/0xcl.png"));
    QQuickStyle::setStyle("Basic");   // the QML fully custom-styles its controls

    PlayerController controller;
    PlaybackStatsModel stats;
    AudioVisualizerModel visualizer;
    AmbientSampler ambient;
    MediaLibraryModel library;
    NetworkServerModel servers;
    RealVideoSurface::s_stats = &stats;
    MediaLibraryModel::instance = &library;
    qmlRegisterType<RealVideoSurface>("VlcModern", 1, 0, "RealVideoSurface");

    QQmlApplicationEngine engine;
    QQmlContext *ctx = engine.rootContext();
    ctx->setContextProperty("playerController", &controller);
    ctx->setContextProperty("playbackStats", &stats);
    ctx->setContextProperty("audioVisualizer", &visualizer);
    ctx->setContextProperty("ambientSampler", &ambient);
    ctx->setContextProperty("mediaLibraryModel", &library);
    ctx->setContextProperty("networkServerModel", &servers);

    // "0xcl.exe movie.mkv" / "Open with"
    const QStringList args = app.arguments();
    if (args.size() > 1) controller.openFile(QUrl::fromUserInput(args.at(1), QDir::currentPath(), QUrl::AssumeLocalFile));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/qml/MainPlaybackWindow.qml")));
    return app.exec();
}
