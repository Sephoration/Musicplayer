#include "LibraryManager.h"
#include <QDir>
#include <QFile>
#include <QSaveFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QDateTime>
#include <QJsonObject>
#include <QJsonArray>
#include <QStandardPaths>
#include <QMediaPlayer>
#include <QMediaMetaData>
#include <QEventLoop>
#include <QTimer>
#include <QSet>
#include <QDirIterator>
#include <QUuid>
#include <QCryptographicHash>
#include <QImageReader>

// ---- Path helpers ----

QString LibraryManager::songsDir() const { return m_basePath + "/songs"; }
QString LibraryManager::lyricsDir() const { return m_basePath + "/lyrics"; }
QString LibraryManager::coversDir() const { return m_basePath + "/covers"; }
QString LibraryManager::metadataPath() const { return m_basePath + "/metadata.json"; }

void LibraryManager::ensureDirs() {
    QDir().mkpath(songsDir());
    QDir().mkpath(lyricsDir());
    QDir().mkpath(coversDir());
}

// ---- Index I/O ----

QVector<SongInfo> LibraryManager::loadIndex() {
    QFile f(metadataPath());
    m_indexValid = true;
    if (!f.exists()) return {};
    if (!f.open(QIODevice::ReadOnly)) {
        m_indexValid = false;
        emit storageError(QStringLiteral("无法读取媒体库索引：%1").arg(f.errorString()));
        return {};
    }
    QJsonParseError error;
    const QJsonDocument doc = QJsonDocument::fromJson(f.readAll(), &error);
    if (error.error != QJsonParseError::NoError || !doc.isObject() || !doc.object().value("songs").isArray()) {
        m_indexValid = false;
        emit storageError(QStringLiteral("媒体库索引损坏，已停止写入以保护原数据"));
        return {};
    }
    QVector<SongInfo> songs;
    const QJsonArray arr = doc.object().value("songs").toArray();
    QSet<int> ids;
    for (const QJsonValue& value : arr) {
        const QJsonObject item = value.toObject();
        const int id = item.value("id").toInt();
        const QString name = item.value("filename").toString();
        if (!value.isObject() || id <= 0 || ids.contains(id) || name.isEmpty() || name == "." || name == ".." || QFileInfo(name).fileName() != name || name.contains('/') || name.contains('\\')) {
            m_indexValid = false;
            emit storageError(QStringLiteral("媒体库索引包含无效记录，已停止写入以保护原数据"));
            return {};
        }
        ids.insert(id);
    }
    for (const QJsonValue& v : arr) {
        QJsonObject o = v.toObject();
        SongInfo s;
        s.id = o["id"].toInt();
        s.filename = o["filename"].toString();
        s.title = o["title"].toString();
        s.artist = o["artist"].toString();
        s.album = o["album"].toString();
        s.durationSec = o["durationSec"].toInt();
        s.duration = o["duration"].toString();
        s.format = o["format"].toString();
        s.hasLyrics = o["hasLyrics"].toBool();
        s.hasCover = o["hasCover"].toBool();
        s.playCount = o["playCount"].toInt();
        songs.append(s);
    }
    return songs;
}

void LibraryManager::saveIndex(const QVector<SongInfo>& songs,
                                const QVector<CategoryInfo>& categories,
                                const QVector<int>& favorites,
                                const QVector<int>& recentPlays) {
    if (!m_indexValid) { emit storageError(QStringLiteral("媒体库索引不可用，未保存更改")); return; }
    QJsonObject root;
    QJsonArray songArr;
    for (const auto& s : songs) {
        QJsonObject o;
        o["id"] = s.id;
        o["filename"] = s.filename;
        o["title"] = s.title;
        o["artist"] = s.artist;
        o["album"] = s.album;
        o["durationSec"] = s.durationSec;
        o["duration"] = s.duration;
        o["format"] = s.format;
        o["hasLyrics"] = s.hasLyrics;
        o["hasCover"] = s.hasCover;
        o["playCount"] = s.playCount;
        songArr.append(o);
    }
    root["songs"] = songArr;

    QJsonArray catArr;
    for (const auto& c : categories) {
        // Built-in views are rebuilt from the index, not user playlists.
        if (c.id == "all" || c.id == "favorites" || c.id == "recent") continue;
        QJsonObject co;
        co["id"] = c.id;
        co["name"] = c.name;
        co["icon"] = c.icon;
        QJsonArray ids;
        for (int sid : c.songIds) ids.append(sid);
        co["songIds"] = ids;
        catArr.append(co);
    }
    root["categories"] = catArr;

    QJsonArray favArr;
    for (int id : favorites) favArr.append(id);
    root["favorites"] = favArr;

    QJsonArray recArr;
    for (int id : recentPlays) recArr.append(id);
    root["recentPlays"] = recArr;

    QSaveFile f(metadataPath());
    const QByteArray data = QJsonDocument(root).toJson(QJsonDocument::Indented);
    if (!f.open(QIODevice::WriteOnly) || f.write(data) != data.size() || !f.commit())
        emit storageError(QStringLiteral("媒体库保存失败：%1").arg(f.errorString()));
}

// ---- Metadata reading ----

void LibraryManager::readMetadata(const QString& filePath, QString& title, QString& artist,
                                   QString& album, int& durationSec) {
    QFileInfo fi(filePath);
    title = fi.completeBaseName();
    artist = QStringLiteral("未知艺术家");
    album = "-";
    durationSec = 0;

    QMediaPlayer probe;
    QEventLoop loop;
    QTimer::singleShot(1200, &loop, &QEventLoop::quit);
    QObject::connect(&probe, &QMediaPlayer::durationChanged, &loop, [&](qint64 dur) {
        if (dur > 0) durationSec = static_cast<int>(dur / 1000);
    });
    QObject::connect(&probe, &QMediaPlayer::mediaStatusChanged, &loop,
        [&](QMediaPlayer::MediaStatus status) {
            if (status == QMediaPlayer::LoadedMedia || status == QMediaPlayer::InvalidMedia) loop.quit();
        });
    probe.setSource(QUrl::fromLocalFile(filePath));
    if (probe.mediaStatus() != QMediaPlayer::LoadedMedia && probe.mediaStatus() != QMediaPlayer::InvalidMedia)
        loop.exec();
    const QMediaMetaData metadata = probe.metaData();
    const QString tagTitle = metadata.stringValue(QMediaMetaData::Title).trimmed();
    const QString tagArtist = metadata.stringValue(QMediaMetaData::AlbumArtist).trimmed();
    const QString tagAlbum = metadata.stringValue(QMediaMetaData::AlbumTitle).trimmed();
    if (!tagTitle.isEmpty()) title = tagTitle;
    if (!tagArtist.isEmpty()) artist = tagArtist;
    if (!tagAlbum.isEmpty()) album = tagAlbum;
    if (tagTitle.isEmpty() && title.contains(" - ")) {
        const int separator = title.indexOf(" - ");
        if (tagArtist.isEmpty()) artist = title.left(separator).trimmed();
        title = title.mid(separator + 3).trimmed();
    }
}

// ---- Import ----

bool LibraryManager::importLyricsFromSource(const QString& srcPath, const QString& sourceStem, const QString& targetStem) {
    QFileInfo srcInfo(srcPath);
    QString parent = srcInfo.absolutePath();
    QStringList candidates = {
        sourceStem + ".lrc",
        sourceStem + QStringLiteral("-歌词.lrc"),
        sourceStem + QStringLiteral("歌词.lrc"),
    };
    for (const QString& name : candidates) {
        QString lrcPath = parent + "/" + name;
        if (QFile::exists(lrcPath)) {
            QFile f(lrcPath);
            if (f.open(QIODevice::ReadOnly)) {
                QByteArray content = f.readAll();
                f.close();
                QString dest = lyricsDir() + "/" + targetStem + ".lrc";
                QFile df(dest);
                if (df.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
                    df.write(content);
                    df.close();
                    return true;
                }
            }
        }
    }
    return false;
}

bool LibraryManager::importCoverFromSource(const QString& srcPath, const QString& stem, int songId) {
    QFileInfo srcInfo(srcPath);
    QString parent = srcInfo.absolutePath();
    QStringList candidates;
    for (const QString& ext : {"jpg", "jpeg", "png"}) {
        candidates.append(stem + "." + ext);
        candidates.append(stem + "-cover." + ext);
        candidates.append(QStringLiteral("cover.") + ext);
    }
    for (const QString& name : candidates) {
        QString imgPath = parent + "/" + name;
        if (!QFile::exists(imgPath)) continue;
        QString ext = QFileInfo(imgPath).suffix().toLower();
        if (ext == "jpeg") ext = "jpg";
        QString dest = coversDir() + "/" + QString::number(songId) + "." + ext;
        if (QFile::copy(imgPath, dest)) return true;
    }
    return false;
}

SongInfo LibraryManager::importSongInternal(const QString& sourcePath, QVector<SongInfo>& songs) {
    QFileInfo srcInfo(sourcePath);
    if (!m_indexValid || !srcInfo.isFile() || !srcInfo.isReadable()) return {};
    const QString sourceStem = srcInfo.completeBaseName();
    QString filename = srcInfo.fileName();
    QString stem = sourceStem;
    int suffix = 1;
    for (;;) {
        bool stemUsed = false;
        for (const auto& song : songs) {
            if (song.filename.compare(filename, Qt::CaseInsensitive) == 0) {
                QFile source(sourcePath), existing(songsDir() + "/" + song.filename);
                if (source.open(QIODevice::ReadOnly) && existing.open(QIODevice::ReadOnly) && source.size() == existing.size()) {
                    QCryptographicHash a(QCryptographicHash::Sha256), b(QCryptographicHash::Sha256);
                    if (a.addData(&source) && b.addData(&existing) && a.result() == b.result()) return song;
                }
            }
            if (QFileInfo(song.filename).completeBaseName().compare(stem, Qt::CaseInsensitive) == 0) stemUsed = true;
        }
        if (!stemUsed && !QFileInfo::exists(songsDir() + "/" + filename) && !QFileInfo::exists(lyricsDir() + "/" + stem + ".lrc")) break;
        stem = sourceStem + QStringLiteral(" (%1)").arg(++suffix);
        filename = stem + (srcInfo.suffix().isEmpty() ? QString() : "." + srcInfo.suffix());
    }
    const QString dest = songsDir() + "/" + filename;
    if (!QFile::copy(sourcePath, dest)) return {};
    const QString format = srcInfo.suffix().toUpper();

    // Lyrics
    bool hasLrc = importLyricsFromSource(sourcePath, sourceStem, stem);

    // Cover
    int newId = 1;
    for (const auto& s : songs)
        if (s.id >= newId) newId = s.id + 1;

    bool hasCover = importCoverFromSource(sourcePath, sourceStem, newId);

    // Metadata
    QString title, artist, album;
    int durationSec = 0;
    readMetadata(sourcePath, title, artist, album, durationSec);

    int m = durationSec / 60;
    int s = durationSec % 60;
    QString durStr = QString("%1:%2").arg(m).arg(s, 2, 10, QChar('0'));

    SongInfo meta;
    meta.id = newId;
    meta.filename = filename;
    meta.title = title;
    meta.artist = artist;
    meta.album = album;
    meta.durationSec = durationSec;
    meta.duration = durStr;
    meta.format = format;
    meta.hasLyrics = hasLrc;
    meta.hasCover = hasCover;
    meta.playCount = 0;

    songs.append(meta);
    return meta;
}

SongInfo LibraryManager::importSong(const QString& sourcePath) {
    ensureDirs();
    QVector<SongInfo> songs = loadIndex();
    if (!m_indexValid) return {};
    SongInfo meta = importSongInternal(sourcePath, songs);

    QVector<CategoryInfo> cats;
    QVector<int> favs, recents;
    // Read existing categories etc.
    QFile f(metadataPath());
    if (f.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
        f.close();
        for (const auto& v : doc.object().value("categories").toArray()) {
            QJsonObject co = v.toObject();
            CategoryInfo ci;
            ci.id = co["id"].toString();
            ci.name = co["name"].toString();
            ci.icon = co["icon"].toString();
            for (const auto& sv : co["songIds"].toArray())
                ci.songIds.append(sv.toInt());
            cats.append(ci);
        }
        for (const auto& v : doc.object().value("favorites").toArray())
            favs.append(v.toInt());
        for (const auto& v : doc.object().value("recentPlays").toArray())
            recents.append(v.toInt());
    }

    saveIndex(songs, cats, favs, recents);
    return meta;
}

LibraryManager::ImportResult LibraryManager::importFolder(
    const QString& folderPath,
    const QVector<SongInfo>& currentSongs,
    const QVector<int>& favorites,
    const QVector<int>& recentPlays) {

    ensureDirs();
    if (!m_indexValid) { ImportResult result; result.errors.append(QStringLiteral("媒体库索引不可用")); return result; }
    QVector<SongInfo> songs = currentSongs;
    QVector<CategoryInfo> cats;
    QVector<int> favs = favorites, recents = recentPlays;

    // Read existing categories
    QFile f(metadataPath());
    if (f.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
        f.close();
        for (const auto& v : doc.object().value("categories").toArray()) {
            QJsonObject co = v.toObject();
            CategoryInfo ci;
            ci.id = co["id"].toString();
            ci.name = co["name"].toString();
            ci.icon = co["icon"].toString();
            for (const auto& sv : co["songIds"].toArray())
                ci.songIds.append(sv.toInt());
            cats.append(ci);
        }
    }

    ImportResult result;
    QStringList audioExts = {"mp3", "flac", "wav", "aac", "ogg", "m4a", "wma"};

    if (!QFileInfo(folderPath).isDir() || !QFileInfo(folderPath).isReadable()) {
        result.errors.append(folderPath);
        return result;
    }
    QDirIterator it(folderPath, QDir::Files | QDir::Readable | QDir::NoSymLinks, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        it.next();
        const QFileInfo entry = it.fileInfo();
        QString ext = entry.suffix().toLower();
        if (audioExts.contains(ext)) {
            const int before = songs.size();
            SongInfo meta = importSongInternal(entry.absoluteFilePath(), songs);
            if (songs.size() == before) {
                if (meta.id == 0) result.errors.append(entry.absoluteFilePath());
                continue;
            }
            if (meta.hasLyrics) result.lyrics++;
            else result.noLyrics++;
            result.total++;
            // Add to "all" songs category
        }
    }

    saveIndex(songs, cats, favs, recents);
    return result;
}

LibraryManager::ImportResult LibraryManager::importFiles(
    const QStringList& filePaths,
    const QVector<SongInfo>& currentSongs,
    const QVector<int>& favorites,
    const QVector<int>& recentPlays) {

    ensureDirs();
    if (!m_indexValid) { ImportResult result; result.errors.append(QStringLiteral("媒体库索引不可用")); return result; }
    QVector<SongInfo> songs = currentSongs;
    QVector<CategoryInfo> cats;
    QVector<int> favs = favorites, recents = recentPlays;

    QFile f(metadataPath());
    if (f.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
        f.close();
        for (const auto& v : doc.object().value("categories").toArray()) {
            QJsonObject co = v.toObject();
            CategoryInfo ci;
            ci.id = co["id"].toString();
            ci.name = co["name"].toString();
            ci.icon = co["icon"].toString();
            for (const auto& sv : co["songIds"].toArray())
                ci.songIds.append(sv.toInt());
            cats.append(ci);
        }
    }

    ImportResult result;
    for (const QString& path : filePaths) {
        if (!QFileInfo::exists(path)) {
            result.errors.append(path);
            continue;
        }
        const int before = songs.size();
        SongInfo meta = importSongInternal(path, songs);
        if (songs.size() == before) {
            if (meta.id == 0) result.errors.append(path);
            continue;
        }
        if (meta.hasLyrics) result.lyrics++;
        else result.noLyrics++;
        result.total++;
    }

    saveIndex(songs, cats, favs, recents);
    return result;
}

// ---- Delete ----

void LibraryManager::deleteSong(int songId, QVector<SongInfo>& songs,
                                 QVector<int>& favorites, QVector<int>& recents,
                                 QVector<CategoryInfo>& categories) {
    if (!m_indexValid) { emit storageError(QStringLiteral("媒体库索引不可用，未删除歌曲")); return; }
    for (int i = 0; i < songs.size(); i++) {
        if (songs[i].id == songId) {
            // Remove files
            QFile::remove(songsDir() + "/" + songs[i].filename);
            QString stem = QFileInfo(songs[i].filename).completeBaseName();
            QFile::remove(lyricsDir() + "/" + stem + ".lrc");
            QFile::remove(coversDir() + "/" + QString::number(songId) + ".jpg");
            QFile::remove(coversDir() + "/" + QString::number(songId) + ".png");
            songs.removeAt(i);
            break;
        }
    }
    favorites.erase(std::remove(favorites.begin(), favorites.end(), songId), favorites.end());
    recents.erase(std::remove(recents.begin(), recents.end(), songId), recents.end());
    for (auto& cat : categories)
        cat.songIds.erase(std::remove(cat.songIds.begin(), cat.songIds.end(), songId), cat.songIds.end());

    saveIndex(songs, categories, favorites, recents);
}

// ---- Queries ----

QString LibraryManager::getAudioPath(int songId, const QVector<SongInfo>& songs) const {
    for (const auto& s : songs) {
        if (s.id == songId)
            {
                const QString path = songsDir() + "/" + s.filename;
                return QFileInfo::exists(path) ? path : QString();
            }
    }
    return {};
}

QString LibraryManager::getCoverPath(int songId) const {
    if (QFile::exists(coversDir() + "/" + QString::number(songId) + ".jpg"))
        return coversDir() + "/" + QString::number(songId) + ".jpg";
    if (QFile::exists(coversDir() + "/" + QString::number(songId) + ".png"))
        return coversDir() + "/" + QString::number(songId) + ".png";
    return {};
}

QString LibraryManager::readLyrics(const QString& songFilename) const {
    QString stem = QFileInfo(songFilename).completeBaseName();
    QString path = lyricsDir() + "/" + stem + ".lrc";
    QFile f(path);
    if (f.open(QIODevice::ReadOnly)) {
        QString content = QString::fromUtf8(f.readAll());
        f.close();
        return content;
    }
    return {};
}

// ---- Categories ----

CategoryInfo LibraryManager::createCategory(const QString& name, const QString& icon) {
    CategoryInfo cat;
    cat.id = "cat_" + QUuid::createUuid().toString(QUuid::WithoutBraces);
    cat.name = name;
    cat.icon = icon;
    // We need to persist this, but it requires passing all data
    // Caller will handle persistence
    return cat;
}

void LibraryManager::deleteCategory(const QString& categoryId, QVector<CategoryInfo>& categories) {
    categories.erase(std::remove_if(categories.begin(), categories.end(),
        [&](const CategoryInfo& c) { return c.id == categoryId; }), categories.end());
}

void LibraryManager::renameCategory(const QString& categoryId, const QString& name,
                                     QVector<CategoryInfo>& categories) {
    for (auto& c : categories)
        if (c.id == categoryId) { c.name = name; break; }
}

void LibraryManager::addToCategory(const QString& categoryId, int songId,
                                    QVector<CategoryInfo>& categories) {
    for (auto& c : categories) {
        if (c.id == categoryId && !c.songIds.contains(songId)) {
            c.songIds.append(songId);
            break;
        }
    }
}

void LibraryManager::removeFromCategory(const QString& categoryId, int songId,
                                         QVector<CategoryInfo>& categories) {
    for (auto& c : categories)
        if (c.id == categoryId)
            c.songIds.erase(std::remove(c.songIds.begin(), c.songIds.end(), songId), c.songIds.end());
}

// ---- Favorites & Play ----

bool LibraryManager::toggleFavorite(int songId, QVector<int>& favorites) {
    int idx = favorites.indexOf(songId);
    if (idx >= 0) {
        favorites.removeAt(idx);
        return false;
    } else {
        favorites.append(songId);
        return true;
    }
}

void LibraryManager::recordPlay(int songId, QVector<int>& recents, QVector<SongInfo>& songs) {
    recents.erase(std::remove(recents.begin(), recents.end(), songId), recents.end());
    recents.append(songId);
    if (recents.size() > 100) recents.removeFirst();
    for (auto& song : songs) {
        if (song.id == songId) { song.playCount++; break; }
    }
}

// ---- Lyrics & Cover Import ----

bool LibraryManager::importLyrics(int songId, const QString& content,
                                   QVector<SongInfo>& songs) {
    if (!m_indexValid) return false;
    for (auto& song : songs) {
        if (song.id != songId) continue;
        const QString stem = QFileInfo(song.filename).completeBaseName();
        QSaveFile file(lyricsDir() + "/" + stem + ".lrc");
        const QByteArray data = content.toUtf8();
        if (!file.open(QIODevice::WriteOnly) || file.write(data) != data.size() || !file.commit()) {
            emit storageError(QStringLiteral("保存歌词失败：%1").arg(file.errorString()));
            return false;
        }
        song.hasLyrics = true;
        return true;
    }
    return false;
}

bool LibraryManager::importCover(int songId, const QString& imagePath,
                                  QVector<SongInfo>& songs) {
    if (!m_indexValid) return false;
    auto song = std::find_if(songs.begin(), songs.end(), [songId](const SongInfo& s) { return s.id == songId; });
    if (song == songs.end()) return false;
    QFileInfo fi(imagePath);
    QString ext = fi.suffix().toLower();
    if (ext != "jpg" && ext != "jpeg" && ext != "png") return false;
    if (ext == "jpeg") ext = "jpg";
    QImageReader reader(imagePath);
    if (!reader.canRead() || fi.size() > 20 * 1024 * 1024) return false;
    QFile source(imagePath);
    if (!source.open(QIODevice::ReadOnly)) return false;
    const QByteArray data = source.readAll();
    if (source.error() != QFileDevice::NoError) return false;
    const QString dest = coversDir() + "/" + QString::number(songId) + "." + ext;
    QSaveFile target(dest);
    if (!target.open(QIODevice::WriteOnly) || target.write(data) != data.size() || !target.commit()) {
        emit storageError(QStringLiteral("保存封面失败：%1").arg(target.errorString()));
        return false;
    }
    QFile::remove(coversDir() + "/" + QString::number(songId) + (ext == "jpg" ? ".png" : ".jpg"));
    song->hasCover = true;
    return true;
}

// ---- Background ----

QString LibraryManager::setBackgroundImage(const QString& sourcePath) {
    QFileInfo fi(sourcePath);
    const QString ext = fi.suffix().toLower();
    if (ext.isEmpty() || fi.size() > 20 * 1024 * 1024 || !QImageReader(sourcePath).canRead()) return {};
    QFile source(sourcePath);
    if (!source.open(QIODevice::ReadOnly)) return {};
    const QByteArray data = source.readAll();
    if (source.error() != QFileDevice::NoError) return {};
    const QString dest = m_basePath + "/background." + ext;
    QSaveFile target(dest);
    if (!target.open(QIODevice::WriteOnly) || target.write(data) != data.size() || !target.commit()) {
        emit storageError(QStringLiteral("保存背景失败：%1").arg(target.errorString()));
        return {};
    }
    QDir dir(m_basePath);
    for (const QString& name : dir.entryList({"background.*"}, QDir::Files))
        if (dir.absoluteFilePath(name) != dest) QFile::remove(dir.absoluteFilePath(name));
    return dest;
}

void LibraryManager::clearBackgroundImage() {
    QDir dir(m_basePath);
    for (const QString& name : dir.entryList({"background.*"}, QDir::Files))
        QFile::remove(dir.absoluteFilePath(name));
}

// ---- Constructor ----

LibraryManager::LibraryManager(const QString& basePath, QObject* parent)
    : QObject(parent), m_basePath(basePath) {
    ensureDirs();
}
