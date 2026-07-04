#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVector>
#include <QVariantMap>
#include <QVariantList>

// ---- Data structures ----

struct SongInfo {
    int id = 0;
    QString filename;
    QString title = QStringLiteral("未知");
    QString artist = QStringLiteral("未知艺术家");
    QString album = "-";
    int durationSec = 0;
    QString duration;
    QString format = "MP3";
    bool hasLyrics = false;
    bool hasCover = false;
    int playCount = 0;

    QVariantMap toMap() const {
        QVariantMap m;
        m["id"] = id;
        m["title"] = title;
        m["artist"] = artist;
        m["album"] = album;
        m["durationSec"] = durationSec;
        m["duration"] = duration;
        m["format"] = format;
        m["hasLyrics"] = hasLyrics;
        m["hasCover"] = hasCover;
        m["playCount"] = playCount;
        return m;
    }

    static SongInfo fromMap(const QVariantMap& m) {
        SongInfo s;
        s.id = m.value("id").toInt();
        s.filename = m.value("filename").toString();
        s.title = m.value("title").toString();
        s.artist = m.value("artist").toString();
        s.album = m.value("album").toString();
        s.durationSec = m.value("durationSec").toInt();
        s.duration = m.value("duration").toString();
        s.format = m.value("format").toString();
        s.hasLyrics = m.value("hasLyrics").toBool();
        s.hasCover = m.value("hasCover").toBool();
        s.playCount = m.value("playCount").toInt();
        return s;
    }
};

struct CategoryInfo {
    QString id;
    QString name;
    QString icon;
    QVector<int> songIds;

    QVariantMap toMap() const {
        QVariantMap m;
        m["id"] = id;
        m["name"] = name;
        m["icon"] = icon;
        QVariantList ids;
        for (int sid : songIds) ids.append(sid);
        m["songIds"] = ids;
        return m;
    }
};

struct QueueItem {
    int id = 0;
    QString title;
    QString artist;
    QString duration;

    QVariantMap toMap() const {
        QVariantMap m;
        m["id"] = id;
        m["title"] = title;
        m["artist"] = artist;
        m["duration"] = duration;
        return m;
    }

    static QueueItem fromMap(const QVariantMap& m) {
        QueueItem item;
        item.id = m.value("id").toInt();
        item.title = m.value("title").toString();
        item.artist = m.value("artist").toString();
        item.duration = m.value("duration").toString();
        return item;
    }
};

// ---- Library Manager ----

class LibraryManager : public QObject {
    Q_OBJECT
public:
    explicit LibraryManager(const QString& basePath, QObject* parent = nullptr);

    const QString& basePath() const { return m_basePath; }
    QString songsDir() const;
    QString lyricsDir() const;
    QString coversDir() const;
    QString metadataPath() const;

    void ensureDirs();
    QVector<SongInfo> loadIndex();
    void saveIndex(const QVector<SongInfo>& songs,
                   const QVector<CategoryInfo>& categories,
                   const QVector<int>& favorites,
                   const QVector<int>& recentPlays);

    // Import
    SongInfo importSong(const QString& sourcePath);
    struct ImportResult {
        int total = 0, lyrics = 0, noLyrics = 0;
        QStringList errors;
    };
    ImportResult importFolder(const QString& folderPath,
                              const QVector<SongInfo>& currentSongs,
                              const QVector<int>& favorites,
                              const QVector<int>& recentPlays);
    ImportResult importFiles(const QStringList& filePaths,
                             const QVector<SongInfo>& currentSongs,
                             const QVector<int>& favorites,
                             const QVector<int>& recentPlays);

    // Delete
    void deleteSong(int songId, QVector<SongInfo>& songs,
                    QVector<int>& favorites, QVector<int>& recentPlays,
                    QVector<CategoryInfo>& categories);

    // Queries
    QString getAudioPath(int songId, const QVector<SongInfo>& songs) const;
    QString getCoverPath(int songId) const;
    QString readLyrics(const QString& songFilename) const;

    // Categories
    CategoryInfo createCategory(const QString& name, const QString& icon);
    void deleteCategory(const QString& categoryId, QVector<CategoryInfo>& categories);
    void renameCategory(const QString& categoryId, const QString& name, QVector<CategoryInfo>& categories);
    void addToCategory(const QString& categoryId, int songId, QVector<CategoryInfo>& categories);
    void removeFromCategory(const QString& categoryId, int songId, QVector<CategoryInfo>& categories);

    // Favorites & play count
    bool toggleFavorite(int songId, QVector<int>& favorites);
    void recordPlay(int songId, QVector<int>& recentPlays, QVector<SongInfo>& songs);

    // Lyrics & cover import
    void importLyrics(int songId, const QString& content,
                      QVector<SongInfo>& songs);
    void importCover(int songId, const QString& imagePath,
                     QVector<SongInfo>& songs);

    // Background image
    QString setBackgroundImage(const QString& sourcePath);
    void clearBackgroundImage();

    // Metadata reading (using QMediaPlayer)
    static void readMetadata(const QString& filePath, QString& title, QString& artist,
                             QString& album, int& durationSec);

private:
    QString m_basePath;

    bool importLyricsFromSource(const QString& srcPath, const QString& stem);
    bool importCoverFromSource(const QString& srcPath, const QString& stem, int songId);
    SongInfo importSongInternal(const QString& sourcePath, QVector<SongInfo>& songs);
};
