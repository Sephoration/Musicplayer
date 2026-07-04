#include "LibraryManager.h"
#include <QDir>
#include <QFile>
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
    if (!f.open(QIODevice::ReadOnly)) return {};
    QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
    f.close();
    QVector<SongInfo> songs;
    QJsonArray arr = doc.object().value("songs").toArray();
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

    QFile f(metadataPath());
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        f.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
        f.close();
    }
}

// ---- Metadata reading ----

void LibraryManager::readMetadata(const QString& filePath, QString& title, QString& artist,
                                   QString& album, int& durationSec) {
    // Use QMediaPlayer synchronously to read tags
    QMediaPlayer* probe = new QMediaPlayer;
    // We only need duration — tags are limited in QMediaPlayer
    // Use file name as fallback
    QFileInfo fi(filePath);
    title = fi.completeBaseName();
    artist = QStringLiteral("未知艺术家");
    album = "-";
    durationSec = 0;

    // 尝试通过 QMediaPlayer 获取时长（仅时长，不用 QMediaMetaData）
    // Qt 6.11 中 QMediaMetaData API 变动大，元数据改用文件名解析
    QEventLoop loop;
    QTimer::singleShot(1200, &loop, &QEventLoop::quit);

    QObject::connect(probe, &QMediaPlayer::durationChanged, probe, [&](qint64 dur) {
        if (dur > 0) {
            durationSec = static_cast<int>(dur / 1000);
        }
    });

    QObject::connect(probe, &QMediaPlayer::mediaStatusChanged, probe,
        [&](QMediaPlayer::MediaStatus s) {
            if (s == QMediaPlayer::LoadedMedia || s == QMediaPlayer::InvalidMedia)
                loop.quit();
        });

    probe->setSource(QUrl::fromLocalFile(filePath));
    loop.exec();

    // 从文件名解析：尝试 "艺术家 - 标题" 格式
    if (title.contains(" - ")) {
        QStringList parts = title.split(" - ");
        if (parts.size() >= 2) {
            artist = parts[0].trimmed();
            title = parts[1].trimmed();
        }
    }

    probe->deleteLater();
}

// ---- Import ----

bool LibraryManager::importLyricsFromSource(const QString& srcPath, const QString& stem) {
    QFileInfo srcInfo(srcPath);
    QString parent = srcInfo.absolutePath();
    QStringList candidates = {
        stem + ".lrc",
        stem + QStringLiteral("-歌词.lrc"),
        stem + QStringLiteral("歌词.lrc"),
    };
    for (const QString& name : candidates) {
        QString lrcPath = parent + "/" + name;
        if (QFile::exists(lrcPath)) {
            QFile f(lrcPath);
            if (f.open(QIODevice::ReadOnly)) {
                QByteArray content = f.readAll();
                f.close();
                QString dest = lyricsDir() + "/" + stem + ".lrc";
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
    QString filename = srcInfo.fileName();

    // Check duplicate
    for (const auto& s : songs) {
        if (s.filename == filename)
            return s; // already imported
    }

    // Copy file
    QString dest = songsDir() + "/" + filename;
    QFile::copy(sourcePath, dest);

    QString format = srcInfo.suffix().toUpper();
    QString stem = srcInfo.completeBaseName();

    // Lyrics
    bool hasLrc = importLyricsFromSource(sourcePath, stem);

    // Cover
    int newId = 1;
    for (const auto& s : songs)
        if (s.id >= newId) newId = s.id + 1;

    bool hasCover = importCoverFromSource(sourcePath, stem, newId);

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

    QDir dir(folderPath);
    for (const QFileInfo& entry : dir.entryInfoList(QDir::Files)) {
        QString ext = entry.suffix().toLower();
        if (audioExts.contains(ext)) {
            SongInfo meta = importSongInternal(entry.absoluteFilePath(), songs);
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
        if (songs.size() == before) continue;
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
            return songsDir() + "/" + s.filename;
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
    cat.id = "cat_" + QString::number(QDateTime::currentMSecsSinceEpoch());
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

void LibraryManager::importLyrics(int songId, const QString& content,
                                   QVector<SongInfo>& songs) {
    for (auto& song : songs) {
        if (song.id == songId) {
            QString stem = QFileInfo(song.filename).completeBaseName();
            QString path = lyricsDir() + "/" + stem + ".lrc";
            QFile f(path);
            if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
                f.write(content.toUtf8());
                f.close();
                song.hasLyrics = true;
            }
            break;
        }
    }
}

void LibraryManager::importCover(int songId, const QString& imagePath,
                                  QVector<SongInfo>& songs) {
    QFileInfo fi(imagePath);
    QString ext = fi.suffix().toLower();
    if (ext != "jpg" && ext != "jpeg" && ext != "png") return;
    if (ext == "jpeg") ext = "jpg";
    QString dest = coversDir() + "/" + QString::number(songId) + "." + ext;
    if (QFile::copy(imagePath, dest)) {
        for (auto& song : songs) {
            if (song.id == songId) { song.hasCover = true; break; }
        }
    }
}

// ---- Background ----

QString LibraryManager::setBackgroundImage(const QString& sourcePath) {
    QFileInfo fi(sourcePath);
    QString ext = fi.suffix();
    if (ext.isEmpty()) return {};
    QString dest = m_basePath + "/background." + ext;
    // Remove old backgrounds
    QDir dir(m_basePath);
    for (const QString& name : dir.entryList({"background.*"}, QDir::Files)) {
        if (dir.absoluteFilePath(name) != dest)
            QFile::remove(dir.absoluteFilePath(name));
    }
    if (QFile::copy(sourcePath, dest))
        return dest;
    return {};
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
