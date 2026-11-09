#pragma once
#ifdef _MSC_VER
#  include <BaseTsd.h>
typedef SSIZE_T ssize_t;   // vlc.h needs ssize_t, MSVC doesn't have it
#endif
#include <vlc/vlc.h>
#include <QByteArray>
#include <QColor>
#include <QElapsedTimer>
#include <QMutex>
#include <QQuickItem>
#include <QTimer>
#include <QUrl>
#include <QVariantList>

class PlaybackStatsModel;

// QML type "RealVideoSurface" (import VlcModern 1.0).
// Plays through libvlc with video callbacks (RV32 frames) and draws them as a scene-graph texture.
// The same code path works on Windows, Linux and macOS - no X11/HWND dependency.
class RealVideoSurface : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(bool hasVideo READ hasVideo NOTIFY stateChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY stateChanged)
    Q_PROPERTY(bool isMuted READ isMuted NOTIFY stateChanged)
    Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY stateChanged)
    Q_PROPERTY(qreal position READ position NOTIFY stateChanged)
    Q_PROPERTY(qint64 currentTimeMs READ currentTimeMs NOTIFY stateChanged)
    Q_PROPERTY(qint64 durationMs READ durationMs NOTIFY stateChanged)
    Q_PROPERTY(qreal playbackRate READ playbackRate WRITE setPlaybackRate NOTIFY stateChanged)
    Q_PROPERTY(int fillMode READ fillMode WRITE setFillMode NOTIFY stateChanged)
    Q_PROPERTY(qreal brightness READ brightness WRITE setBrightness NOTIFY stateChanged)
    Q_PROPERTY(qreal contrast READ contrast WRITE setContrast NOTIFY stateChanged)
    Q_PROPERTY(qreal gamma READ gamma WRITE setGamma NOTIFY stateChanged)
    Q_PROPERTY(qreal saturation READ saturation WRITE setSaturation NOTIFY stateChanged)
    Q_PROPERTY(QString mediaTitle READ mediaTitle NOTIFY stateChanged)
    Q_PROPERTY(QStringList audioTracks READ audioTracks NOTIFY tracksChanged)
    Q_PROPERTY(QStringList subtitleTracks READ subtitleTracks NOTIFY tracksChanged)
    Q_PROPERTY(int currentAudioTrack READ currentAudioTrack NOTIFY tracksChanged)
    Q_PROPERTY(int currentSubtitleTrack READ currentSubtitleTrack NOTIFY tracksChanged)
    Q_PROPERTY(QVariantList audioDevices READ audioDevices NOTIFY devicesChanged)
    Q_PROPERTY(QString currentAudioDevice READ currentAudioDevice NOTIFY devicesChanged)
    Q_PROPERTY(QString currentDeviceName READ currentDeviceName NOTIFY devicesChanged)
    Q_PROPERTY(QString currentDeviceType READ currentDeviceType NOTIFY devicesChanged)
public:
    explicit RealVideoSurface(QQuickItem *parent = nullptr);
    ~RealVideoSurface() override;

    static PlaybackStatsModel *s_stats;   // set from main()

    bool hasVideo() const { return m_hasMedia; }
    bool isPlaying() const { return m_playing; }
    bool isMuted() const { return m_muted; }
    qreal volume() const { return m_volume; }
    qreal position() const { return m_position; }
    qint64 currentTimeMs() const { return m_timeMs; }
    qint64 durationMs() const { return m_lengthMs; }
    qreal playbackRate() const { return m_rate; }
    int fillMode() const { return m_fillMode; }
    qreal brightness() const { return m_brightness; }
    qreal contrast() const { return m_contrast; }
    qreal gamma() const { return m_gamma; }
    qreal saturation() const { return m_saturation; }
    QString mediaTitle() const { return m_title; }
    QStringList audioTracks() const { return m_audioNames; }
    QStringList subtitleTracks() const { return m_subNames; }
    int currentAudioTrack() const { return m_curAudio; }
    int currentSubtitleTrack() const { return m_curSub; }
    QVariantList audioDevices() const { return m_devices; }
    QString currentAudioDevice() const { return m_curDeviceId; }
    QString currentDeviceName() const { return m_curDeviceName; }
    QString currentDeviceType() const { return m_curDeviceType; }

public slots:
    void openFile(const QVariant &urlOrPath);
    void togglePlayPause();
    void skipRelative(int ms);
    void seek(qreal position01);
    void setVolume(qreal v);
    void toggleMute();
    void setPlaybackRate(qreal r);
    void setFillMode(int mode);
    void setCustomAspect(qreal aspect);
    void setBrightness(qreal v);
    void setContrast(qreal v);
    void setGamma(qreal v);
    void setSaturation(qreal v);
    void setAudioTrack(int index);
    void setSubtitleTrack(int index);
    void addSubtitleFile(const QVariant &urlOrPath);
    void setSubtitleDelay(int ms);
    void setEqualizerBand(int band, qreal gainDb);
    void refreshAudioDevices();
    void setAudioOutputDevice(const QString &id);

signals:
    void stateChanged();
    void tracksChanged();
    void devicesChanged();
    void dominantColorSampled(const QColor &color);
    void mediaEnded();

protected:
    QSGNode *updatePaintNode(QSGNode *old, UpdatePaintNodeData *) override;
    void geometryChange(const QRectF &n, const QRectF &o) override;

private slots:
    void tick();
    void requestRepaint() { update(); }

private:
    // libvlc video callbacks (called from VLC threads)
    static unsigned formatCb(void **opaque, char *chroma, unsigned *w, unsigned *h, unsigned *pitches, unsigned *lines);
    static void cleanupCb(void *opaque);
    static void *lockCb(void *opaque, void **planes);
    static void unlockCb(void *opaque, void *picture, void *const *planes);
    static void displayCb(void *opaque, void *picture);

    void applyVideoAdjust();
    void refreshTracks();
    void refreshStats();
    static QString localOrMrl(const QUrl &u, bool *isPath);

    libvlc_instance_t *m_vlc = nullptr;
    libvlc_media_player_t *m_mp = nullptr;
    libvlc_media_t *m_media = nullptr;
    libvlc_equalizer_t *m_eq = nullptr;
    QTimer m_timer;
    int m_tickCount = 0;

    // frame buffer (guarded by m_frameMutex)
    QMutex m_frameMutex;
    QByteArray m_buf;
    unsigned m_vw = 0, m_vh = 0;
    bool m_dirty = false;
    QElapsedTimer m_sampleClock;

    // state (GUI thread)
    QUrl m_url; QString m_title;
    bool m_hasMedia = false, m_playing = false, m_muted = false;
    qreal m_volume = 0.85, m_position = 0, m_rate = 1.0, m_customAspect = 0.0;
    qreal m_brightness = 1.0, m_contrast = 1.0, m_gamma = 1.0, m_saturation = 1.0;
    qint64 m_timeMs = 0, m_lengthMs = 0; int m_fillMode = 0;
    QStringList m_audioNames, m_subNames; QList<int> m_audioIds, m_subIds; int m_curAudio = 0, m_curSub = -1;
    QVariantList m_devices; QString m_curDeviceId, m_curDeviceName = "Default", m_curDeviceType = "speaker";
    QString m_videoCodec = "-", m_audioCodec = "-", m_res = "-", m_fps = "-";
    QList<int> m_eqGains;
};
