#pragma once
#include <QAbstractListModel>
#include <QColor>
#include <QTimer>
#include <QUrl>
#include <QVariantList>

// ---------------- PlayerController (context property "playerController") ----------------
class PlayerController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QUrl mediaUrl READ mediaUrl NOTIFY mediaUrlChanged)
    Q_PROPERTY(QString mediaTitle READ mediaTitle NOTIFY mediaUrlChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY stateChanged)
    Q_PROPERTY(bool isMuted READ isMuted NOTIFY stateChanged)
    Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY stateChanged)
    Q_PROPERTY(qreal brightness READ brightness WRITE setBrightness NOTIFY stateChanged)
    Q_PROPERTY(qreal playbackRate READ playbackRate WRITE setPlaybackRate NOTIFY stateChanged)
    Q_PROPERTY(qreal position READ position WRITE setPosition NOTIFY stateChanged)
    Q_PROPERTY(qint64 currentTimeMs READ currentTimeMs NOTIFY stateChanged)
    Q_PROPERTY(qint64 durationMs READ durationMs NOTIFY stateChanged)
    Q_PROPERTY(int subtitleDelayMs READ subtitleDelayMs WRITE setSubtitleDelayMs NOTIFY stateChanged)
    Q_PROPERTY(QVariantList audioDevices READ audioDevices NOTIFY stateChanged)
    Q_PROPERTY(QString currentAudioDevice READ currentAudioDevice NOTIFY stateChanged)
    Q_PROPERTY(QString currentDeviceName READ currentDeviceName NOTIFY stateChanged)
    Q_PROPERTY(QString currentDeviceType READ currentDeviceType NOTIFY stateChanged)
public:
    using QObject::QObject;
    QUrl mediaUrl() const { return m_url; }
    QString mediaTitle() const { return m_title; }
    bool isPlaying() const { return m_playing; }
    bool isMuted() const { return m_muted; }
    qreal volume() const { return m_volume; }
    qreal brightness() const { return m_brightness; }
    qreal playbackRate() const { return m_rate; }
    qreal position() const { return m_position; }
    qint64 currentTimeMs() const { return m_time; }
    qint64 durationMs() const { return m_duration; }
    int subtitleDelayMs() const { return m_subDelay; }
    QVariantList audioDevices() const { return {}; }
    QString currentAudioDevice() const { return m_device; }
    QString currentDeviceName() const { return m_device.isEmpty() ? QStringLiteral("Default") : m_device; }
    QString currentDeviceType() const { return QStringLiteral("speaker"); }
public slots:
    void setVolume(qreal v) { m_volume = qBound(0.0, v, 1.25); emit stateChanged(); }
    void setBrightness(qreal v) { m_brightness = v; emit stateChanged(); }
    void setPlaybackRate(qreal v) { m_rate = v; emit stateChanged(); }
    void setPosition(qreal v) { m_position = v; if (m_duration > 0) m_time = qint64(v * m_duration); emit stateChanged(); }
    void setSubtitleDelayMs(int v) { m_subDelay = v; emit stateChanged(); }
    void openFile(const QVariant &v);
    void togglePlayPause() { m_playing = !m_playing; emit stateChanged(); }
    void skipRelative(int ms) { m_time = qMax<qint64>(0, m_time + ms); emit stateChanged(); }
    void refreshAudioDevices() {}
    void setAudioOutputDevice(const QString &id) { m_device = id; emit stateChanged(); }
signals:
    void mediaUrlChanged();
    void mediaOpened(const QString &title);
    void stateChanged();
private:
    QUrl m_url; QString m_title, m_device;
    bool m_playing = false, m_muted = false;
    qreal m_volume = 0.85, m_brightness = 1.0, m_rate = 1.0, m_position = 0.0;
    qint64 m_time = 0, m_duration = 0; int m_subDelay = 0;
};

// ---------------- PlaybackStatsModel (context property "playbackStats") ----------------
class PlaybackStatsModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString videoCodec MEMBER m_videoCodec NOTIFY statsUpdated)
    Q_PROPERTY(QString audioCodec MEMBER m_audioCodec NOTIFY statsUpdated)
    Q_PROPERTY(QString hardwareDecoder MEMBER m_hw NOTIFY statsUpdated)
    Q_PROPERTY(QString resolution MEMBER m_resolution NOTIFY statsUpdated)
    Q_PROPERTY(QString frameRate MEMBER m_frameRate NOTIFY statsUpdated)
    Q_PROPERTY(QString colorSpace MEMBER m_colorSpace NOTIFY statsUpdated)
    Q_PROPERTY(int decodedFrames MEMBER m_decoded NOTIFY statsUpdated)
    Q_PROPERTY(int droppedFrames MEMBER m_dropped NOTIFY statsUpdated)
    Q_PROPERTY(double bufferHealth MEMBER m_buffer NOTIFY statsUpdated)
    Q_PROPERTY(double currentBitrateMbps MEMBER m_mbps NOTIFY statsUpdated)
    Q_PROPERTY(QVariantList bitrateHistory MEMBER m_history NOTIFY statsUpdated)
public:
    using QObject::QObject;
    void update(const QString &vc, const QString &ac, const QString &res, const QString &fps,
                const QString &cs, int decoded, int dropped, double buffer, double mbps);
signals:
    void statsUpdated();
private:
    QString m_videoCodec = "-", m_audioCodec = "-", m_hw = "Software (CPU)", m_resolution = "-", m_frameRate = "-", m_colorSpace = "-";
    int m_decoded = 0, m_dropped = 0; double m_buffer = 0, m_mbps = 0; QVariantList m_history;
};

// ---------------- AudioVisualizerModel (context property "audioVisualizer") ----------------
class AudioVisualizerModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList spectrumBars READ spectrumBars NOTIFY spectrumChanged)
public:
    explicit AudioVisualizerModel(QObject *parent = nullptr);
    QVariantList spectrumBars() const { return m_bars; }
signals:
    void spectrumChanged();
private:
    QVariantList m_bars; QTimer m_timer;
};

// ---------------- AmbientSampler (context property "ambientSampler") ----------------
class AmbientSampler : public QObject {
    Q_OBJECT
    Q_PROPERTY(QColor dominantColor READ dominantColor NOTIFY dominantColorChanged)
public:
    using QObject::QObject;
    QColor dominantColor() const { return m_color; }
public slots:
    void setDominantColor(const QColor &c);
signals:
    void dominantColorChanged();
private:
    QColor m_color = QColor(10, 10, 14);
};

// ---------------- MediaLibraryModel (context property "mediaLibraryModel") ----------------
class MediaLibraryModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
public:
    enum Roles { TitleRole = Qt::UserRole + 1, FileUrlRole, ThumbnailUrlRole, DurationStrRole, FileSizeRole, CodecRole, ResolutionRole };
    explicit MediaLibraryModel(QObject *parent = nullptr) : QAbstractListModel(parent) {}
    int rowCount(const QModelIndex &p = {}) const override { return p.isValid() ? 0 : m_items.size(); }
    QVariant data(const QModelIndex &i, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int count() const { return m_items.size(); }
    static MediaLibraryModel *instance;
public slots:
    void setCurrentMedia(const QVariant &url);
    void playItem(int index) { if (index >= 0 && index < m_items.size()) m_current = index; }
    QString getNextUrl() const;
    QString getPreviousUrl() const;
    void clear();
    void removeIndex(int index);
    void updateCurrentInfo(qint64 durationMs, const QString &resolution, const QString &codec);
signals:
    void countChanged();
private:
    struct Item { QUrl url; QString title, duration = "--:--", size, codec, resolution = "HD"; };
    QList<Item> m_items; int m_current = -1;
};

// ---------------- NetworkServerModel (context property "networkServerModel") ----------------
class NetworkServerModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles { NameRole = Qt::UserRole + 1, ProtocolRole, ServerUrlRole, DescriptionRole, IsOnlineRole, MediaCountRole };
    explicit NetworkServerModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &p = {}) const override { return p.isValid() ? 0 : m_items.size(); }
    QVariant data(const QModelIndex &i, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
public slots:
    void addServer(const QString &name, const QString &protocol, const QString &url, const QString &desc);
    void connectServer(int index);
private:
    struct Item { QString name, protocol, url, desc; bool online = true; int count = 0; };
    void save() const;
    QList<Item> m_items;
};
