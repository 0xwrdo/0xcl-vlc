#include "realvideosurface.h"
#include "models.h"
#include <QDir>
#include <QFileInfo>
#include <QQuickWindow>
#include <QSGSimpleTextureNode>
#include <QSGTexture>
#include <cmath>
#include <cstring>
#include <memory>

PlaybackStatsModel *RealVideoSurface::s_stats = nullptr;

namespace {
struct VideoNode : QSGSimpleTextureNode {
    std::unique_ptr<QSGTexture> tex;   // we own it so replacing the frame never leaks
};
QUrl toUrl(const QVariant &v) {
    if (v.metaType().id() == QMetaType::QUrl) return v.toUrl();
    const QString s = v.toString();
    return s.contains("://") || s.startsWith("file:") ? QUrl(s) : QUrl::fromLocalFile(s);
}
}

QString RealVideoSurface::localOrMrl(const QUrl &u, bool *isPath) {
    *isPath = u.isLocalFile();
    return u.isLocalFile() ? QDir::toNativeSeparators(u.toLocalFile()) : u.toString(QUrl::FullyEncoded);
}

RealVideoSurface::RealVideoSurface(QQuickItem *parent) : QQuickItem(parent) {
    setFlag(ItemHasContents, true);
    const char *args[] = {"--no-video-title-show", "--avcodec-hw=none", "--avcodec-threads=0", "--avcodec-fast",
                          "--file-caching=3000", "--network-caching=3000", "--live-caching=2000",
                          "--disc-caching=3000", "--drop-late-frames", "--skip-frames"};
    m_vlc = libvlc_new(int(sizeof(args) / sizeof(args[0])), args);
    if (!m_vlc) { qCritical("libvlc_new failed - are libvlc.dll / libvlccore.dll / plugins\\ next to the .exe?"); return; }
    m_mp = libvlc_media_player_new(m_vlc);
    libvlc_video_set_format_callbacks(m_mp, &RealVideoSurface::formatCb, &RealVideoSurface::cleanupCb);
    libvlc_video_set_callbacks(m_mp, &RealVideoSurface::lockCb, &RealVideoSurface::unlockCb, &RealVideoSurface::displayCb, this);
    libvlc_audio_set_volume(m_mp, int(m_volume * 100));
    m_eq = libvlc_audio_equalizer_new();
    m_sampleClock.start();
    m_timer.setInterval(100);
    connect(&m_timer, &QTimer::timeout, this, &RealVideoSurface::tick);
    m_timer.start();
    refreshAudioDevices();
}

RealVideoSurface::~RealVideoSurface() {
    m_timer.stop();
    if (m_mp) { libvlc_media_player_stop(m_mp); libvlc_media_player_release(m_mp); }
    if (m_media) libvlc_media_release(m_media);
    if (m_eq) libvlc_audio_equalizer_release(m_eq);
    if (m_vlc) libvlc_release(m_vlc);
}

// ---------- libvlc callbacks ----------
unsigned RealVideoSurface::formatCb(void **opaque, char *chroma, unsigned *w, unsigned *h, unsigned *pitches, unsigned *lines) {
    auto *s = static_cast<RealVideoSurface *>(*opaque);
    std::memcpy(chroma, "RV32", 4);              // B,G,R,X in memory == QImage::Format_RGB32 on little endian
    pitches[0] = *w * 4; lines[0] = *h;
    QMutexLocker l(&s->m_frameMutex);
    s->m_vw = *w; s->m_vh = *h;
    s->m_buf.fill(0, int(*w * *h * 4));
    return 1;
}
void RealVideoSurface::cleanupCb(void *) {}
void *RealVideoSurface::lockCb(void *opaque, void **planes) {
    auto *s = static_cast<RealVideoSurface *>(opaque);
    s->m_frameMutex.lock();
    *planes = s->m_buf.data();
    return nullptr;
}
void RealVideoSurface::unlockCb(void *opaque, void *, void *const *) {
    static_cast<RealVideoSurface *>(opaque)->m_frameMutex.unlock();
}
void RealVideoSurface::displayCb(void *opaque, void *) {
    auto *s = static_cast<RealVideoSurface *>(opaque);
    QColor sampled; bool doSample = false;
    {
        QMutexLocker l(&s->m_frameMutex);
        s->m_dirty = true;
        if (s->m_sampleClock.elapsed() > 800 && s->m_vw && s->m_vh) {
            s->m_sampleClock.restart(); doSample = true;
            long r = 0, g = 0, b = 0, n = 0;
            const uchar *p = reinterpret_cast<const uchar *>(s->m_buf.constData());
            for (unsigned y = s->m_vh / 28; y < s->m_vh; y += s->m_vh / 14 + 1)
                for (unsigned x = s->m_vw / 48; x < s->m_vw; x += s->m_vw / 24 + 1) {
                    const uchar *px = p + (size_t(y) * s->m_vw + x) * 4;
                    b += px[0]; g += px[1]; r += px[2]; ++n;
                }
            if (n) sampled = QColor(int(r / n), int(g / n), int(b / n));
        }
    }
    QMetaObject::invokeMethod(s, "requestRepaint", Qt::QueuedConnection);
    if (doSample && sampled.isValid())
        QMetaObject::invokeMethod(s, "dominantColorSampled", Qt::QueuedConnection, Q_ARG(QColor, sampled));
}

// ---------- scene graph ----------
void RealVideoSurface::geometryChange(const QRectF &n, const QRectF &o) {
    QQuickItem::geometryChange(n, o); update();
}

QSGNode *RealVideoSurface::updatePaintNode(QSGNode *old, UpdatePaintNodeData *) {
    auto *node = static_cast<VideoNode *>(old);
    QImage img; unsigned vw = 0, vh = 0;
    {
        QMutexLocker l(&m_frameMutex);
        vw = m_vw; vh = m_vh;
        if (!m_hasMedia || !vw || !vh) { delete node; return nullptr; }
        if (m_dirty || !node) {
            img = QImage(reinterpret_cast<const uchar *>(m_buf.constData()), int(vw), int(vh), int(vw * 4), QImage::Format_RGB32).copy();
            m_dirty = false;
        }
    }
    if (!node) { node = new VideoNode; node->setFiltering(QSGTexture::Linear); }
    if (!img.isNull() && window()) {
        std::unique_ptr<QSGTexture> t(window()->createTextureFromImage(img));
        node->setTexture(t.get());
        node->tex = std::move(t);
    }
    if (!node->tex) { delete node; return nullptr; }

    const QRectF item(0, 0, width(), height());
    const qreal va = m_customAspect > 0 ? m_customAspect : qreal(vw) / qreal(vh);
    const qreal ia = item.height() > 0 ? item.width() / item.height() : va;
    QRectF dst = item, src(0, 0, vw, vh);
    if (m_fillMode == 0) {                       // Fit
        if (va > ia) { qreal h = item.width() / va; dst = QRectF(0, (item.height() - h) / 2, item.width(), h); }
        else         { qreal w = item.height() * va; dst = QRectF((item.width() - w) / 2, 0, w, item.height()); }
    } else if (m_fillMode == 1) {                // Fill (crop)
        if (va > ia) { qreal f = ia / va; src = QRectF(vw * (1 - f) / 2, 0, vw * f, vh); }
        else         { qreal f = va / ia; src = QRectF(0, vh * (1 - f) / 2, vw, vh * f); }
    }                                            // 2 = Stretch
    node->setRect(dst);
    node->setSourceRect(src);
    return node;
}

// ---------- playback ----------
void RealVideoSurface::openFile(const QVariant &v) {
    if (!m_mp) return;
    const QUrl u = toUrl(v);
    if (u.isEmpty()) return;
    if (u == m_url && m_hasMedia && libvlc_media_player_get_state(m_mp) != libvlc_Ended) return;  // QML calls this several times
    m_url = u;
    m_title = u.isLocalFile() ? QFileInfo(u.toLocalFile()).completeBaseName() : u.fileName();
    bool isPath = false; const QString loc = localOrMrl(u, &isPath);
    libvlc_media_t *media = isPath ? libvlc_media_new_path(m_vlc, loc.toUtf8().constData())
                                   : libvlc_media_new_location(m_vlc, loc.toUtf8().constData());
    if (!media) return;
    libvlc_media_player_set_media(m_mp, media);
    if (m_media) libvlc_media_release(m_media);
    m_media = media;
    m_hasMedia = true; m_audioNames.clear(); m_subNames.clear(); m_audioIds.clear(); m_subIds.clear(); m_curSub = -1;
    m_videoCodec = m_audioCodec = m_res = m_fps = "-";
    libvlc_media_player_play(m_mp);
    libvlc_audio_set_volume(m_mp, int(m_volume * 100));
    libvlc_media_player_set_rate(m_mp, float(m_rate));
    if (m_eq) libvlc_media_player_set_equalizer(m_mp, m_eq);
    applyVideoAdjust();
    m_playing = true;
    emit stateChanged(); emit tracksChanged(); update();
}

void RealVideoSurface::togglePlayPause() {
    if (!m_mp || !m_hasMedia) return;
    const libvlc_state_t st = libvlc_media_player_get_state(m_mp);
    if (st == libvlc_Ended || st == libvlc_Stopped || st == libvlc_Error) { libvlc_media_player_stop(m_mp); libvlc_media_player_play(m_mp); m_playing = true; }
    else { libvlc_media_player_set_pause(m_mp, m_playing ? 1 : 0); m_playing = !m_playing; }
    emit stateChanged();
}
void RealVideoSurface::skipRelative(int ms) {
    if (!m_mp) return;
    qint64 t = qBound<qint64>(0, libvlc_media_player_get_time(m_mp) + ms, m_lengthMs > 0 ? m_lengthMs : Q_INT64_C(1) << 40);
    libvlc_media_player_set_time(m_mp, t);
}
void RealVideoSurface::seek(qreal p) { if (m_mp) libvlc_media_player_set_position(m_mp, float(qBound(0.0, p, 1.0))); }
void RealVideoSurface::setVolume(qreal v) {
    m_volume = qBound(0.0, v, 1.25);
    if (m_mp) libvlc_audio_set_volume(m_mp, int(m_volume * 100));
    emit stateChanged();
}
void RealVideoSurface::toggleMute() { m_muted = !m_muted; if (m_mp) libvlc_audio_set_mute(m_mp, m_muted ? 1 : 0); emit stateChanged(); }
void RealVideoSurface::setPlaybackRate(qreal r) { m_rate = r; if (m_mp) libvlc_media_player_set_rate(m_mp, float(r)); emit stateChanged(); }
void RealVideoSurface::setFillMode(int m) { m_fillMode = m; emit stateChanged(); update(); }
void RealVideoSurface::setCustomAspect(qreal a) { m_customAspect = a; update(); }

void RealVideoSurface::applyVideoAdjust() {
    if (!m_mp) return;
    libvlc_video_set_adjust_int(m_mp, libvlc_adjust_Enable, 1);
    libvlc_video_set_adjust_float(m_mp, libvlc_adjust_Brightness, float(m_brightness));
    libvlc_video_set_adjust_float(m_mp, libvlc_adjust_Contrast, float(m_contrast));
    libvlc_video_set_adjust_float(m_mp, libvlc_adjust_Gamma, float(m_gamma));
    libvlc_video_set_adjust_float(m_mp, libvlc_adjust_Saturation, float(m_saturation));
}
void RealVideoSurface::setBrightness(qreal v) { if (qFuzzyCompare(m_brightness, v)) return; m_brightness = v; applyVideoAdjust(); emit stateChanged(); }
void RealVideoSurface::setContrast(qreal v)   { m_contrast = v;   applyVideoAdjust(); emit stateChanged(); }
void RealVideoSurface::setGamma(qreal v)      { m_gamma = v;      applyVideoAdjust(); emit stateChanged(); }
void RealVideoSurface::setSaturation(qreal v) { m_saturation = v; applyVideoAdjust(); emit stateChanged(); }

void RealVideoSurface::setAudioTrack(int i) {
    if (!m_mp) return;
    libvlc_audio_set_track(m_mp, (i >= 0 && i < m_audioIds.size()) ? m_audioIds[i] : -1);
    m_curAudio = i; emit tracksChanged();
}
void RealVideoSurface::setSubtitleTrack(int i) {
    if (!m_mp) return;
    libvlc_video_set_spu(m_mp, (i >= 0 && i < m_subIds.size()) ? m_subIds[i] : -1);
    m_curSub = i; emit tracksChanged();
}
void RealVideoSurface::addSubtitleFile(const QVariant &v) {
    const QUrl u = toUrl(v);
    if (m_mp && u.isLocalFile()) { libvlc_video_set_subtitle_file(m_mp, QDir::toNativeSeparators(u.toLocalFile()).toUtf8().constData()); m_tickCount = 0; }
}
void RealVideoSurface::setSubtitleDelay(int ms) { if (m_mp) libvlc_video_set_spu_delay(m_mp, int64_t(ms) * 1000); }
void RealVideoSurface::setEqualizerBand(int band, qreal gainDb) {
    if (!m_eq || !m_mp || band < 0 || band >= int(libvlc_audio_equalizer_get_band_count())) return;
    libvlc_audio_equalizer_set_amp_at_index(m_eq, float(qBound(-20.0, gainDb, 20.0)), unsigned(band));
    libvlc_media_player_set_equalizer(m_mp, m_eq);
}

// ---------- audio devices ----------
void RealVideoSurface::refreshAudioDevices() {
    if (!m_mp) return;
    m_devices.clear();
    libvlc_audio_output_device_t *list = libvlc_audio_output_device_enum(m_mp);
    for (auto *d = list; d; d = d->p_next) {
        const QString name = QString::fromUtf8(d->psz_description), lower = name.toLower();
        QString type = "speaker";
        if (lower.contains("head") || lower.contains("kopf")) type = "headphones";
        else if (lower.contains("hdmi") || lower.contains("display") || lower.contains("monitor")) type = "hdmi";
        else if (lower.contains("bluetooth") || lower.contains("bt ")) type = "bluetooth";
        m_devices.append(QVariantMap{{"id", QString::fromUtf8(d->psz_device)}, {"name", name}, {"type", type}});
    }
    if (list) libvlc_audio_output_device_list_release(list);
    if (char *cur = libvlc_audio_output_device_get(m_mp)) {
        m_curDeviceId = QString::fromUtf8(cur); libvlc_free(cur);
    }
    for (const QVariant &v : std::as_const(m_devices)) {
        const QVariantMap m = v.toMap();
        if (m["id"].toString() == m_curDeviceId) { m_curDeviceName = m["name"].toString(); m_curDeviceType = m["type"].toString(); }
    }
    if (m_curDeviceId.isEmpty() && !m_devices.isEmpty()) {
        const QVariantMap m = m_devices.first().toMap();
        m_curDeviceId = m["id"].toString(); m_curDeviceName = m["name"].toString(); m_curDeviceType = m["type"].toString();
    }
    emit devicesChanged();
}
void RealVideoSurface::setAudioOutputDevice(const QString &id) {
    if (!m_mp) return;
    libvlc_audio_output_device_set(m_mp, nullptr, id.toUtf8().constData());
    refreshAudioDevices();
}

// ---------- polling ----------
void RealVideoSurface::refreshTracks() {
    auto grab = [](libvlc_track_description_t *l, QStringList &names, QList<int> &ids) {
        names.clear(); ids.clear();
        for (auto *t = l; t; t = t->p_next) { if (t->i_id < 0) continue; names << QString::fromUtf8(t->psz_name); ids << t->i_id; }
        if (l) libvlc_track_description_list_release(l);
    };
    grab(libvlc_audio_get_track_description(m_mp), m_audioNames, m_audioIds);
    grab(libvlc_video_get_spu_description(m_mp), m_subNames, m_subIds);
    m_curAudio = m_audioIds.indexOf(libvlc_audio_get_track(m_mp));
    m_curSub = m_subIds.indexOf(libvlc_video_get_spu(m_mp));
    emit tracksChanged();
}

void RealVideoSurface::refreshStats() {
    if (!m_media || !s_stats) return;
    libvlc_media_track_t **tracks = nullptr;
    const unsigned n = libvlc_media_tracks_get(m_media, &tracks);
    for (unsigned i = 0; i < n; ++i) {
        const libvlc_media_track_t *t = tracks[i];
        const char *desc = libvlc_media_get_codec_description(t->i_type, t->i_codec);
        if (t->i_type == libvlc_track_video) {
            m_videoCodec = desc ? QString::fromUtf8(desc) : "-";
            m_res = QString("%1x%2").arg(t->video->i_width).arg(t->video->i_height);
            if (t->video->i_frame_rate_den > 0)
                m_fps = QString("%1 fps").arg(double(t->video->i_frame_rate_num) / t->video->i_frame_rate_den, 0, 'f', 2);
        } else if (t->i_type == libvlc_track_audio && m_audioCodec == "-") {
            m_audioCodec = desc ? QString::fromUtf8(desc) : "-";
        }
    }
    if (tracks) libvlc_media_tracks_release(tracks, n);
    libvlc_media_stats_t st{};
    int decoded = 0, lost = 0; double mbps = 0;
    if (libvlc_media_get_stats(m_media, &st)) { decoded = st.i_decoded_video; lost = st.i_lost_pictures; mbps = double(st.f_input_bitrate) * 8.0; }
    const double buffer = m_lengthMs > 0 ? qMin(5.0, double(m_lengthMs - m_timeMs) / 1000.0) : 0.0;   // approximation
    const QString cs = m_vh >= 720 ? "BT.709 (assumed)" : "BT.601 (assumed)";
    s_stats->update(m_videoCodec, m_audioCodec, m_res, m_fps, cs, decoded, lost, buffer, mbps);
    if (MediaLibraryModel::instance) MediaLibraryModel::instance->updateCurrentInfo(m_lengthMs, m_vh >= 2000 ? "4K UHD" : "HD", m_videoCodec == "-" ? QString() : m_videoCodec);
}

void RealVideoSurface::tick() {
    if (!m_mp || !m_hasMedia) return;
    const libvlc_state_t st = libvlc_media_player_get_state(m_mp);
    const bool playing = (st == libvlc_Playing || st == libvlc_Opening || st == libvlc_Buffering);
    const qint64 t = qMax<qint64>(0, libvlc_media_player_get_time(m_mp));
    const qint64 len = qMax<qint64>(0, libvlc_media_player_get_length(m_mp));
    qreal pos = qBound<qreal>(0, libvlc_media_player_get_position(m_mp), 1);
    if (st == libvlc_Ended) { pos = 1.0; }
    const bool changed = (playing != m_playing) || t != m_timeMs || len != m_lengthMs || !qFuzzyCompare(pos + 1, m_position + 1);
    const bool ended = (st == libvlc_Ended && m_playing);
    m_playing = playing && st != libvlc_Paused; m_timeMs = t; m_lengthMs = len; m_position = pos;
    if (st == libvlc_Paused) m_playing = false;
    if (changed) emit stateChanged();
    if (ended) { m_playing = false; emit stateChanged(); emit mediaEnded(); }
    if (m_tickCount % 5 == 0 && (st == libvlc_Playing || st == libvlc_Paused)) refreshTracks();
    if (m_tickCount % 10 == 0 && st == libvlc_Playing) refreshStats();
    ++m_tickCount;
}
