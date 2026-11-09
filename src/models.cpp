#include "models.h"
#include <QFileInfo>
#include <QRandomGenerator>
#include <QSettings>
#include <QLocale>
#include <cmath>

static QUrl toUrl(const QVariant &v) {
    if (v.metaType().id() == QMetaType::QUrl) return v.toUrl();
    const QString s = v.toString();
    return s.contains("://") || s.startsWith("file:") ? QUrl(s) : QUrl::fromLocalFile(s);
}

void PlayerController::openFile(const QVariant &v) {
    const QUrl u = toUrl(v);
    if (u.isEmpty()) return;
    m_url = u;
    m_title = u.isLocalFile() ? QFileInfo(u.toLocalFile()).completeBaseName() : u.fileName();
    emit mediaUrlChanged();
    emit mediaOpened(m_title);
}

void PlaybackStatsModel::update(const QString &vc, const QString &ac, const QString &res, const QString &fps,
                                const QString &cs, int decoded, int dropped, double buffer, double mbps) {
    m_videoCodec = vc; m_audioCodec = ac; m_resolution = res; m_frameRate = fps; m_colorSpace = cs;
    m_decoded = decoded; m_dropped = dropped; m_buffer = buffer; m_mbps = mbps;
    m_history.append(mbps);
    while (m_history.size() > 60) m_history.removeFirst();
    emit statsUpdated();
}

AudioVisualizerModel::AudioVisualizerModel(QObject *parent) : QObject(parent) {
    // The original app also animated these bars with QRandomGenerator (no real FFT).
    for (int i = 0; i < 48; ++i) m_bars.append(0.05);
    m_timer.setInterval(50);
    connect(&m_timer, &QTimer::timeout, this, [this] {
        for (int i = 0; i < m_bars.size(); ++i) {
            double cur = m_bars[i].toDouble();
            double target = QRandomGenerator::global()->generateDouble() * (1.0 - double(i) / (m_bars.size() * 1.6));
            m_bars[i] = cur + (target - cur) * 0.35;
        }
        emit spectrumChanged();
    });
    m_timer.start();
}

void AmbientSampler::setDominantColor(const QColor &c) {
    // smooth towards the new colour
    m_color = QColor::fromRgbF(m_color.redF() * 0.6 + c.redF() * 0.4, m_color.greenF() * 0.6 + c.greenF() * 0.4,
                               m_color.blueF() * 0.6 + c.blueF() * 0.4);
    emit dominantColorChanged();
}

MediaLibraryModel *MediaLibraryModel::instance = nullptr;
QHash<int, QByteArray> MediaLibraryModel::roleNames() const {
    return {{TitleRole, "title"}, {FileUrlRole, "fileUrl"}, {ThumbnailUrlRole, "thumbnailUrl"},
            {DurationStrRole, "durationStr"}, {FileSizeRole, "fileSize"}, {CodecRole, "codec"}, {ResolutionRole, "resolution"}};
}
QVariant MediaLibraryModel::data(const QModelIndex &i, int role) const {
    if (!i.isValid() || i.row() >= m_items.size()) return {};
    const Item &it = m_items[i.row()];
    switch (role) {
    case TitleRole: return it.title;
    case FileUrlRole: return it.url.toString();
    case ThumbnailUrlRole: return QString();
    case DurationStrRole: return it.duration;
    case FileSizeRole: return it.size;
    case CodecRole: return it.codec;
    case ResolutionRole: return it.resolution;
    }
    return {};
}
void MediaLibraryModel::setCurrentMedia(const QVariant &v) {
    const QUrl u = toUrl(v);
    if (u.isEmpty()) return;
    for (int i = 0; i < m_items.size(); ++i)
        if (m_items[i].url == u) { m_current = i; return; }
    Item it; it.url = u;
    if (u.isLocalFile()) {
        QFileInfo fi(u.toLocalFile());
        it.title = fi.completeBaseName();
        it.size = QLocale().formattedDataSize(fi.size());
        it.codec = fi.suffix().toUpper();
    } else { it.title = u.fileName().isEmpty() ? u.toString() : u.fileName(); it.size = "stream"; it.codec = u.scheme().toUpper(); }
    beginInsertRows({}, m_items.size(), m_items.size());
    m_items.append(it); m_current = m_items.size() - 1;
    endInsertRows(); emit countChanged();
}
QString MediaLibraryModel::getNextUrl() const {
    return (m_current >= 0 && m_current + 1 < m_items.size()) ? m_items[m_current + 1].url.toString() : QString();
}
QString MediaLibraryModel::getPreviousUrl() const {
    return (m_current > 0 && m_current < m_items.size()) ? m_items[m_current - 1].url.toString() : QString();
}
void MediaLibraryModel::clear() {
    beginResetModel(); m_items.clear(); m_current = -1; endResetModel(); emit countChanged();
}
void MediaLibraryModel::removeIndex(int index) {
    if (index < 0 || index >= m_items.size()) return;
    beginRemoveRows({}, index, index); m_items.removeAt(index); endRemoveRows();
    if (m_current >= m_items.size()) m_current = m_items.size() - 1;
    emit countChanged();
}
void MediaLibraryModel::updateCurrentInfo(qint64 ms, const QString &res, const QString &codec) {
    if (m_current < 0 || m_current >= m_items.size()) return;
    Item &it = m_items[m_current];
    qint64 s = ms / 1000;
    it.duration = s >= 3600 ? QString("%1:%2:%3").arg(s / 3600).arg(s % 3600 / 60, 2, 10, QChar('0')).arg(s % 60, 2, 10, QChar('0'))
                            : QString("%1:%2").arg(s / 60).arg(s % 60, 2, 10, QChar('0'));
    if (!res.isEmpty()) it.resolution = res;
    if (!codec.isEmpty()) it.codec = codec;
    emit dataChanged(index(m_current), index(m_current));
}

NetworkServerModel::NetworkServerModel(QObject *parent) : QAbstractListModel(parent) {
    QSettings s;
    int n = s.beginReadArray("servers");
    for (int i = 0; i < n; ++i) {
        s.setArrayIndex(i);
        m_items.append({s.value("name").toString(), s.value("protocol").toString(), s.value("url").toString(), s.value("desc").toString(), true, 0});
    }
    s.endArray();
}
QHash<int, QByteArray> NetworkServerModel::roleNames() const {
    return {{NameRole, "name"}, {ProtocolRole, "protocol"}, {ServerUrlRole, "serverUrl"},
            {DescriptionRole, "description"}, {IsOnlineRole, "isOnline"}, {MediaCountRole, "mediaCount"}};
}
QVariant NetworkServerModel::data(const QModelIndex &i, int role) const {
    if (!i.isValid() || i.row() >= m_items.size()) return {};
    const Item &it = m_items[i.row()];
    switch (role) {
    case NameRole: return it.name; case ProtocolRole: return it.protocol; case ServerUrlRole: return it.url;
    case DescriptionRole: return it.desc; case IsOnlineRole: return it.online; case MediaCountRole: return it.count;
    }
    return {};
}
void NetworkServerModel::addServer(const QString &name, const QString &protocol, const QString &url, const QString &desc) {
    beginInsertRows({}, m_items.size(), m_items.size());
    m_items.append({name, protocol, url, desc, true, 0});
    endInsertRows(); save();
}
void NetworkServerModel::connectServer(int) { /* selection is handled in QML via serverSelected(url, name) */ }
void NetworkServerModel::save() const {
    QSettings s; s.beginWriteArray("servers");
    for (int i = 0; i < m_items.size(); ++i) {
        s.setArrayIndex(i); s.setValue("name", m_items[i].name); s.setValue("protocol", m_items[i].protocol);
        s.setValue("url", m_items[i].url); s.setValue("desc", m_items[i].desc);
    }
    s.endArray();
}
