#include "AppModel.h"
#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QDateTime>
#include <QRandomGenerator>
#include <algorithm>

AppModel* AppModel::s_instance = nullptr;

AppModel* AppModel::instance() {
    if (!s_instance)
        s_instance = new AppModel;
    return s_instance;
}

AppModel::AppModel(QObject* parent) : QObject(parent) {
    // --- 核心模块初始化 ---
    m_audioEngine = new AudioEngine(this);
    m_audioAnalyzer = new AudioAnalyzer(this);
    m_lyricsSync = new LyricsSync(this);

    // 数据目录：在用户文档目录下创建 MusicPlayer 文件夹
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
                       + "/MusicPlayer";
    m_library = new LibraryManager(dataPath, this);
    m_settings = new Settings(this);

    // --- 从持久化存储恢复状态 ---
    loadState();

    // --- 连接音频引擎信号 ---
    // 时间更新 → 同步歌词 + 频谱
    connect(m_audioEngine, &AudioEngine::currentTimeChanged, this, [this](double time) {
        m_currentTime = time;
        emit currentTimeChanged();

        // 歌词同步
        if (m_lyricsSync) {
            m_lyricsSync->update(time);
        }
    });

    // 时长变化
    connect(m_audioEngine, &AudioEngine::durationChanged, this, [this](double dur) {
        m_duration = dur;
        emit durationChanged();
    });

    // 播放状态变化
    connect(m_audioEngine, &AudioEngine::playingChanged, this, [this](bool playing) {
        m_playing = playing;
        emit playingChanged();
        saveState();
    });

    // 歌曲结束 → 自动播放下一首
    connect(m_audioEngine, &AudioEngine::mediaEnded, this, [this]() {
        playNext();
    });

    // 播放错误
    connect(m_audioEngine, &AudioEngine::errorOccurred, this, [this](const QString& msg) {
        setErrorAutoClear(msg);
    });

    // 歌词同步状态更新
    connect(m_lyricsSync, &LyricsSync::syncStateChanged, this, [this]() {
        m_syncState = m_lyricsSync->syncState();
        emit syncStateChanged();
    });

    // --- 频谱定时更新 ---
    m_spectrumTimer = new QTimer(this);
    m_spectrumTimer->setInterval(50); // 20fps
    connect(m_spectrumTimer, &QTimer::timeout, this, &AppModel::updateSpectrum);
    m_spectrumTimer->start();

    // --- 错误自动清除定时器 ---
    m_errorTimer = new QTimer(this);
    m_errorTimer->setSingleShot(true);
    connect(m_errorTimer, &QTimer::timeout, this, [this]() {
        m_error.clear();
        emit errorChanged();
    });

    // --- 睡眠定时器每秒刷新 ---
    m_sleepTimerTick = new QTimer(this);
    m_sleepTimerTick->setInterval(1000);
    connect(m_sleepTimerTick, &QTimer::timeout, this, [this]() {
        emit sleepTimerRemainingChanged();
        // 如果剩余时间为0，暂停播放
        if (m_sleepTimerEnd > 0 && sleepTimerRemaining() <= 0) {
            clearSleepTimer();
            m_audioEngine->pause();
        }
    });
    m_sleepTimerTick->start();
}

// =====================================================================
//  歌曲加载（内部）
// =====================================================================
void AppModel::loadSongInternal(int songId, const QString& title, const QString& artist) {
    m_errorTimer->stop();
    m_error.clear();

    // 获取音频文件路径
    QString path = m_library->getAudioPath(songId, m_internalSongs);
    if (path.isEmpty()) {
        setErrorAutoClear(QStringLiteral("找不到歌曲文件"));
        return;
    }

    // 加载到播放引擎
    m_audioEngine->load(QUrl::fromLocalFile(path));

    // 更新当前歌曲信息
    m_currentSongId = songId;
    m_currentSongTitle = title;
    m_currentSongArtist = artist;
    emit currentSongChanged();

    // 加载封面（如果有的话）
    QString coverPath = m_library->getCoverPath(songId);
    m_coverUrl = coverPath.isEmpty() ? "" : QUrl::fromLocalFile(coverPath).toString();
    emit coverUrlChanged();

    // 加载歌词
    QString lrcContent;
    for (const auto& s : m_internalSongs) {
        if (s.id == songId) {
            lrcContent = m_library->readLyrics(s.filename);
            break;
        }
    }
    if (!lrcContent.isEmpty()) {
        m_lyricsSync->load(lrcContent);
    } else {
        m_lyricsSync->clear();
    }

    // 加载频谱分析数据
    m_audioAnalyzer->loadFile(path);
}

// =====================================================================
//  确保歌曲在播放队列中，返回队列索引
// =====================================================================
int AppModel::ensureSongInQueue(int songId, const QString& title, const QString& artist) {
    // 检查是否已在队列中
    for (int i = 0; i < m_queue.size(); i++) {
        QVariantMap item = m_queue[i].toMap();
        if (item["id"].toInt() == songId)
            return i;
    }

    // 不在队列 → 添加到"下一首播放"
    QVariantMap item;
    item["id"] = songId;
    item["title"] = title;
    item["artist"] = artist;

    // 查找歌曲时长
    for (const auto& s : m_internalSongs) {
        if (s.id == songId) {
            item["duration"] = s.duration;
            break;
        }
    }

    if (m_queueIndex >= 0 && m_queueIndex < m_queue.size() - 1) {
        // 插入到当前歌曲之后
        m_queue.insert(m_queueIndex + 1, item);
        emit queueChanged();
        return m_queueIndex + 1;
    } else {
        // 追加到队尾
        m_queue.append(item);
        emit queueChanged();
        return m_queue.size() - 1;
    }
}

// =====================================================================
//  公共接口：播放控制
// =====================================================================
void AppModel::playSong(int songId, const QString& title, const QString& artist) {
    int idx = ensureSongInQueue(songId, title, artist);
    m_queueIndex = idx;
    emit queueIndexChanged();
    loadSongInternal(songId, title, artist);
    m_audioEngine->play();
    showToast(QStringLiteral("正在播放 ") + title);
    saveState();

    // 记录播放
    m_library->recordPlay(songId, m_internalRecents, m_internalSongs);
}

void AppModel::playNext() {
    QVector<SongInfo> songs = m_library->loadIndex();
    m_internalSongs = songs;

    if (m_queue.isEmpty()) return;

    int nextIdx;
    if (m_playMode == "repeat") {
        // 单曲循环：保持当前索引
        nextIdx = (m_queueIndex >= 0 && m_queueIndex < m_queue.size()) ? m_queueIndex : 0;
    } else if (m_playMode == "shuffle") {
        // 随机播放
        nextIdx = QRandomGenerator::global()->bounded(m_queue.size());
    } else {
        // 顺序播放
        nextIdx = (m_queueIndex >= 0 && m_queueIndex < m_queue.size() - 1)
                  ? m_queueIndex + 1 : -1;
    }

    if (nextIdx < 0 || nextIdx >= m_queue.size()) return;

    QVariantMap item = m_queue[nextIdx].toMap();
    int songId = item["id"].toInt();

    // 如果开启了淡入淡出
    if (m_crossfade && m_playing) {
        m_audioEngine->fadeOut(m_crossfadeDuration);
    }

    m_queueIndex = nextIdx;
    emit queueIndexChanged();
    loadSongInternal(songId, item["title"].toString(), item["artist"].toString());
    saveState();

    if (m_crossfade) {
        m_audioEngine->fadeIn(m_crossfadeDuration, m_volume);
    }
    m_audioEngine->play();
}

void AppModel::playPrev() {
    if (m_queue.isEmpty()) return;

    int prevIdx = (m_queueIndex > 0) ? m_queueIndex - 1 : m_queue.size() - 1;
    QVariantMap item = m_queue[prevIdx].toMap();

    if (m_crossfade && m_playing) {
        m_audioEngine->fadeOut(m_crossfadeDuration);
    }

    m_queueIndex = prevIdx;
    emit queueIndexChanged();
    loadSongInternal(item["id"].toInt(), item["title"].toString(), item["artist"].toString());
    saveState();

    if (m_crossfade) {
        m_audioEngine->fadeIn(m_crossfadeDuration, m_volume);
    }
    m_audioEngine->play();
}

void AppModel::requestPlay() {
    if (m_queue.isEmpty()) {
        showToast(QStringLiteral("播放队列为空，请先导入歌曲"));
        return;
    }
    if (m_playing) {
        m_audioEngine->pause();
        return;
    }

    m_error.clear();
    emit errorChanged();

    if (m_currentSongId > 0 && m_duration > 0) {
        // 继续播放
        m_audioEngine->play();
    } else if (m_queueIndex >= 0 && m_queueIndex < m_queue.size()) {
        QVariantMap item = m_queue[m_queueIndex].toMap();
        loadSongInternal(item["id"].toInt(), item["title"].toString(), item["artist"].toString());
        m_audioEngine->play();
    } else {
        // 从头开始
        m_queueIndex = 0;
        QVariantMap item = m_queue[0].toMap();
        loadSongInternal(item["id"].toInt(), item["title"].toString(), item["artist"].toString());
        m_audioEngine->play();
    }
}

void AppModel::seek(double seconds) {
    m_audioEngine->seek(seconds);
}

void AppModel::setVolume(int vol) {
    m_volume = std::max(0.0, std::min(100.0, (double)vol));
    m_audioEngine->setVolume(m_volume);
    emit volumeChanged();
    saveState();
}

void AppModel::setMuted(bool muted) {
    m_muted = muted;
    m_audioEngine->setMuted(muted);
    emit mutedChanged();
}

void AppModel::togglePlayMode() {
    if (m_playMode == "sequential")
        m_playMode = "repeat";
    else if (m_playMode == "repeat")
        m_playMode = "shuffle";
    else
        m_playMode = "sequential";
    emit playModeChanged();
    saveState();
}

// =====================================================================
//  迷你模式（独立的置顶小窗口）
// =====================================================================
void AppModel::toggleMiniMode() {
    m_miniMode = !m_miniMode;
    m_playlistOpen = false;
    emit miniModeChanged();
    emit playlistOpenChanged();
}

void AppModel::setMiniMode(bool mini) {
    if (m_miniMode != mini) {
        m_miniMode = mini;
        emit miniModeChanged();
    }
}

// =====================================================================
//  睡眠定时器
// =====================================================================
void AppModel::setSleepTimer(int minutes) {
    m_sleepTimerEnd = QDateTime::currentMSecsSinceEpoch() + (qint64)minutes * 60 * 1000;
    emit sleepTimerEndChanged();
    emit sleepTimerRemainingChanged();
    showToast(QStringLiteral("睡眠定时器：%1 分钟").arg(minutes));
}

void AppModel::clearSleepTimer() {
    m_sleepTimerEnd = 0;
    emit sleepTimerEndChanged();
    emit sleepTimerRemainingChanged();
}

qint64 AppModel::sleepTimerRemaining() const {
    if (m_sleepTimerEnd <= 0) return -1;
    qint64 remaining = m_sleepTimerEnd - QDateTime::currentMSecsSinceEpoch();
    return std::max((qint64)0, remaining);
}

// =====================================================================
//  媒体库管理
// =====================================================================
void AppModel::loadLibrary() {
    m_libraryLoading = true;
    emit libraryLoadingChanged();

    m_internalSongs = m_library->loadIndex();

    // 转换为 QML 可用的 QVariantList
    m_songs.clear();
    for (const auto& s : m_internalSongs)
        m_songs.append(s.toMap());
    emit songsChanged();

    // 构建分类列表
    rebuildCategories();

    m_libraryLoading = false;
    emit libraryLoadingChanged();
}

void AppModel::rebuildCategories() {
    QVector<int> allIds;
    for (const auto& s : m_internalSongs)
        allIds.append(s.id);

    // 先从 JSON 加载 收藏/最近播放/用户分类
    m_internalFavorites.clear();
    m_internalRecents.clear();
    m_internalCategories.clear();

    QFile f(m_library->metadataPath());
    if (f.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
        f.close();

        for (const auto& v : doc.object().value("favorites").toArray())
            m_internalFavorites.append(v.toInt());
        for (const auto& v : doc.object().value("recentPlays").toArray())
            m_internalRecents.append(v.toInt());
    }

    // 系统分类："全部音乐"
    CategoryInfo allCat;
    allCat.id = "all";
    allCat.name = QStringLiteral("全部音乐");
    allCat.icon = "🎵";
    allCat.songIds = allIds;
    m_internalCategories.append(allCat);

    // "我喜欢"（使用从 JSON 加载的数据）
    CategoryInfo favCat;
    favCat.id = "favorites";
    favCat.name = QStringLiteral("我喜欢");
    favCat.icon = "❤️";
    favCat.songIds = m_internalFavorites;
    m_internalCategories.append(favCat);

    // "最近播放"（倒序，最近的在前面）
    CategoryInfo recentCat;
    recentCat.id = "recent";
    recentCat.name = QStringLiteral("最近播放");
    recentCat.icon = "🎧";
    recentCat.songIds = QVector<int>(m_internalRecents.rbegin(), m_internalRecents.rend());
    m_internalCategories.append(recentCat);

    // 用户创建的分类（从同一个 JSON 再读一次）
    QFile f2(m_library->metadataPath());
    if (f2.open(QIODevice::ReadOnly)) {
        QJsonDocument doc2 = QJsonDocument::fromJson(f2.readAll());
        f2.close();
        for (const auto& v : doc2.object().value("categories").toArray()) {
            QJsonObject co = v.toObject();
            CategoryInfo ci;
            ci.id = co["id"].toString();
            ci.name = co["name"].toString();
            ci.icon = co["icon"].toString();
            for (const auto& sv : co["songIds"].toArray())
                ci.songIds.append(sv.toInt());
            m_internalCategories.append(ci);
        }
    }

    // 转换为 QVariantList 输出给 QML
    m_categories.clear();
    for (const auto& c : m_internalCategories)
        m_categories.append(c.toMap());
    emit categoriesChanged();
}

void AppModel::importFolder(const QString& folderPath) {
    if (folderPath.isEmpty()) return;

    m_libraryLoading = true;
    emit libraryLoadingChanged();

    auto result = m_library->importFolder(folderPath, m_internalSongs,
                                           m_internalFavorites, m_internalRecents);

    // 刷新
    loadLibrary();

    showToast(QStringLiteral("导入完成：%1 首歌曲（%2 首有歌词）")
              .arg(result.total).arg(result.lyrics));
}

void AppModel::importFiles(const QStringList& filePaths) {
    if (filePaths.isEmpty()) return;

    m_libraryLoading = true;
    emit libraryLoadingChanged();

    for (const QString& f : filePaths) {
        m_library->importSong(f);
    }

    loadLibrary();
    showToast(QStringLiteral("导入完成：%1 首歌曲").arg(filePaths.size()));
}

void AppModel::deleteSong(int songId) {
    m_library->deleteSong(songId, m_internalSongs, m_internalFavorites,
                          m_internalRecents, m_internalCategories);

    // 从队列中移除
    for (int i = m_queue.size() - 1; i >= 0; i--) {
        if (m_queue[i].toMap()["id"].toInt() == songId) {
            if (i == m_queueIndex) {
                // 正在播放这首歌 → 停止
                m_audioEngine->stop();
                m_playing = false;
                m_currentSongId = 0;
                emit playingChanged();
                emit currentSongChanged();
            }
            m_queue.removeAt(i);
            if (i <= m_queueIndex) m_queueIndex--;
        }
    }
    emit queueChanged();
    emit queueIndexChanged();

    loadLibrary();
    showToast(QStringLiteral("已删除"));
}

void AppModel::toggleFavorite(int songId) {
    bool isFav = m_library->toggleFavorite(songId, m_internalFavorites);
    m_library->saveIndex(m_internalSongs, m_internalCategories,
                         m_internalFavorites, m_internalRecents);
    rebuildCategories();
    showToast(isFav ? QStringLiteral("已添加到我喜欢") : QStringLiteral("已取消收藏"));
}

// =====================================================================
//  队列操作
// =====================================================================
void AppModel::addToQueue(int songId, const QString& title, const QString& artist) {
    QVariantMap item;
    item["id"] = songId;
    item["title"] = title;
    item["artist"] = artist;
    for (const auto& s : m_internalSongs) {
        if (s.id == songId) {
            item["duration"] = s.duration;
            break;
        }
    }
    m_queue.append(item);
    emit queueChanged();
    saveState();
}

void AppModel::removeFromQueue(int index) {
    if (index < 0 || index >= m_queue.size()) return;

    if (index == m_queueIndex) {
        // 移除当前播放的歌曲
        m_audioEngine->stop();
        m_playing = false;
        m_currentSongId = 0;
        emit playingChanged();
        emit currentSongChanged();
        m_lyricsSync->clear();
    }

    m_queue.removeAt(index);
    if (index < m_queueIndex) m_queueIndex--;
    emit queueChanged();
    emit queueIndexChanged();
    saveState();
}

void AppModel::addToPlayNext(int songId, const QString& title, const QString& artist) {
    QVariantMap item;
    item["id"] = songId;
    item["title"] = title;
    item["artist"] = artist;
    for (const auto& s : m_internalSongs) {
        if (s.id == songId) {
            item["duration"] = s.duration;
            break;
        }
    }
    int insertPos = (m_queueIndex >= 0 && m_queueIndex < m_queue.size())
                    ? m_queueIndex + 1 : m_queue.size();
    m_queue.insert(insertPos, item);
    emit queueChanged();
    saveState();
}

void AppModel::replaceQueueAndPlay(const QVariantList& items, int playIndex) {
    m_queue = items;
    m_queueIndex = (playIndex >= 0 && playIndex < items.size()) ? playIndex : -1;
    emit queueChanged();
    emit queueIndexChanged();

    if (!items.isEmpty() && playIndex >= 0) {
        QVariantMap item = items[playIndex].toMap();
        loadSongInternal(item["id"].toInt(), item["title"].toString(), item["artist"].toString());
        m_audioEngine->play();
    }
    saveState();
}

void AppModel::clearQueue() {
    m_queue.clear();
    m_queueIndex = -1;
    m_audioEngine->stop();
    m_playing = false;
    m_currentSongId = 0;
    m_currentSongTitle.clear();
    m_currentSongArtist.clear();
    emit queueChanged();
    emit queueIndexChanged();
    emit currentSongChanged();
    emit playingChanged();
    m_lyricsSync->clear();
    saveState();
}

// =====================================================================
//  背景图
// =====================================================================
void AppModel::setBackgroundImagePath(const QString& path) {
    QString dest = m_library->setBackgroundImage(path);
    if (!dest.isEmpty()) {
        m_backgroundImage = QUrl::fromLocalFile(dest).toString();
        emit backgroundImageChanged();
        saveState();
    }
}

void AppModel::clearBackgroundImagePath() {
    m_library->clearBackgroundImage();
    m_backgroundImage.clear();
    emit backgroundImageChanged();
    saveState();
}

// =====================================================================
//  歌词/封面导入
// =====================================================================
void AppModel::importLyrics(int songId, const QString& content) {
    m_library->importLyrics(songId, content, m_internalSongs);
    m_library->saveIndex(m_internalSongs, m_internalCategories,
                         m_internalFavorites, m_internalRecents);
    showToast(QStringLiteral("歌词已导入"));
}

void AppModel::importCover(int songId, const QString& path) {
    m_library->importCover(songId, path, m_internalSongs);
    m_library->saveIndex(m_internalSongs, m_internalCategories,
                         m_internalFavorites, m_internalRecents);
    // 如果是当前播放的歌曲，刷新封面
    if (songId == m_currentSongId) {
        m_coverUrl = QUrl::fromLocalFile(path).toString();
        emit coverUrlChanged();
    }
    showToast(QStringLiteral("封面已导入"));
}

// =====================================================================
//  分类管理
// =====================================================================
void AppModel::createCategory(const QString& name, const QString& icon) {
    CategoryInfo cat = m_library->createCategory(name, icon);
    m_internalCategories.append(cat);
    m_library->saveIndex(m_internalSongs, m_internalCategories,
                         m_internalFavorites, m_internalRecents);
    rebuildCategories();
    showToast(QStringLiteral("分类已创建"));
}

void AppModel::deleteCategory(const QString& id) {
    m_library->deleteCategory(id, m_internalCategories);
    m_library->saveIndex(m_internalSongs, m_internalCategories,
                         m_internalFavorites, m_internalRecents);
    rebuildCategories();
}

void AppModel::renameCategory(const QString& id, const QString& name) {
    m_library->renameCategory(id, name, m_internalCategories);
    m_library->saveIndex(m_internalSongs, m_internalCategories,
                         m_internalFavorites, m_internalRecents);
    rebuildCategories();
}

void AppModel::addToCategory(const QString& categoryId, int songId) {
    m_library->addToCategory(categoryId, songId, m_internalCategories);
    m_library->saveIndex(m_internalSongs, m_internalCategories,
                         m_internalFavorites, m_internalRecents);
    rebuildCategories();
}

void AppModel::removeFromCategory(const QString& categoryId, int songId) {
    m_library->removeFromCategory(categoryId, songId, m_internalCategories);
    m_library->saveIndex(m_internalSongs, m_internalCategories,
                         m_internalFavorites, m_internalRecents);
    rebuildCategories();
}

// =====================================================================
//  频谱更新
// =====================================================================
void AppModel::updateSpectrum() {
    if (m_playing && m_audioAnalyzer->ready()) {
        m_audioAnalyzer->update(m_currentTime);
        m_spectrumData = m_audioAnalyzer->spectrumData();
        emit spectrumDataChanged();
    }
}

// =====================================================================
//  状态持久化
// =====================================================================
void AppModel::saveState() {
    m_settings->saveQueue(m_queue, m_queueIndex, m_currentSongId,
                          m_currentSongTitle, m_currentSongArtist);
    m_settings->setVolume(m_volume);
    m_settings->setPlayMode(m_playMode);
    m_settings->setVisualizerColor(m_visualizerColor);
    m_settings->setVisualizerMode(m_visualizerMode);
    m_settings->setFontSize(m_fontSize);
    m_settings->setShowTranslation(m_showTranslation);
    m_settings->setLyricsActiveWordColor(m_lyricsActiveWordColor);
    m_settings->setLyricsActiveLineColor(m_lyricsActiveLineColor);
    m_settings->setLyricsInactiveColor(m_lyricsInactiveColor);
    m_settings->setLyricsOpacity(m_lyricsOpacity);
    m_settings->setLyricsBgColor(m_lyricsBgColor);
    m_settings->setBackgroundImage(m_backgroundImage);
    m_settings->setBackgroundOverlay(m_backgroundOverlay);
    m_settings->setCrossfade(m_crossfade);
    m_settings->setCrossfadeDuration(m_crossfadeDuration);
    m_settings->setAccentColor(m_accentColor);
    m_settings->setLastTime(m_currentTime);
    m_settings->setLastPlaying(m_playing);
}

void AppModel::loadState() {
    m_volume = m_settings->volume();
    m_playMode = m_settings->playMode();
    m_visualizerColor = m_settings->visualizerColor();
    m_visualizerMode = m_settings->visualizerMode();
    m_fontSize = m_settings->fontSize();
    m_showTranslation = m_settings->showTranslation();
    m_lyricsActiveWordColor = m_settings->lyricsActiveWordColor();
    m_lyricsActiveLineColor = m_settings->lyricsActiveLineColor();
    m_lyricsInactiveColor = m_settings->lyricsInactiveColor();
    m_lyricsOpacity = m_settings->lyricsOpacity();
    m_lyricsBgColor = m_settings->lyricsBgColor();
    m_backgroundImage = m_settings->backgroundImage();
    m_backgroundOverlay = m_settings->backgroundOverlay();
    m_crossfade = m_settings->crossfade();
    m_crossfadeDuration = m_settings->crossfadeDuration();
    m_accentColor = m_settings->accentColor();

    // 恢复队列
    m_queue = m_settings->savedQueue();
    m_queueIndex = m_settings->savedQueueIndex();
    m_currentSongId = m_settings->savedCurrentSongId();
    m_currentSongTitle = m_settings->savedCurrentSongTitle();
    m_currentSongArtist = m_settings->savedCurrentSongArtist();

    // 初始化音量
    m_audioEngine->setVolume(m_volume);

    // 初始化主题色
    applyAccentColor();
}

void AppModel::applyAccentColor() {
    // 通过设置 QML 的 context property 来应用主题色
    // 这里用 StyleHints 或者直接在 QML 里绑定 AppModel.accentColor
}

// =====================================================================
//  各种 setter（触发信号 + 持久化）
// =====================================================================
void AppModel::setVisualizerColor(const QString& color) {
    if (m_visualizerColor != color) {
        m_visualizerColor = color;
        emit visualizerColorChanged();
        saveState();
    }
}

void AppModel::setVisualizerMode(const QString& mode) {
    if (m_visualizerMode != mode) {
        m_visualizerMode = mode;
        emit visualizerModeChanged();
        saveState();
    }
}

void AppModel::setFontSize(int size) {
    if (m_fontSize != size) {
        m_fontSize = size;
        emit fontSizeChanged();
        saveState();
    }
}

void AppModel::setShowTranslation(bool show) {
    if (m_showTranslation != show) {
        m_showTranslation = show;
        emit showTranslationChanged();
        saveState();
    }
}

void AppModel::setLyricsActiveWordColor(const QString& c) { m_lyricsActiveWordColor = c; emit lyricsActiveWordColorChanged(); saveState(); }
void AppModel::setLyricsActiveLineColor(const QString& c) { m_lyricsActiveLineColor = c; emit lyricsActiveLineColorChanged(); saveState(); }
void AppModel::setLyricsInactiveColor(const QString& c) { m_lyricsInactiveColor = c; emit lyricsInactiveColorChanged(); saveState(); }
void AppModel::setLyricsOpacity(int v) { m_lyricsOpacity = v; emit lyricsOpacityChanged(); saveState(); }
void AppModel::setLyricsBgColor(const QString& c) { m_lyricsBgColor = c; emit lyricsBgColorChanged(); saveState(); }
void AppModel::setBackgroundOverlay(int v) { m_backgroundOverlay = v; emit backgroundOverlayChanged(); saveState(); }
void AppModel::setCrossfade(bool v) { m_crossfade = v; emit crossfadeChanged(); saveState(); }
void AppModel::setCrossfadeDuration(int d) { m_crossfadeDuration = d; emit crossfadeDurationChanged(); saveState(); }
void AppModel::setAccentColor(const QString& c) { m_accentColor = c; emit accentColorChanged(); saveState(); }
void AppModel::setPlayMode(const QString& mode) { m_playMode = mode; emit playModeChanged(); saveState(); }
void AppModel::setCurrentView(const QString& view) { m_currentView = view; emit currentViewChanged(); }
void AppModel::setPlaylistOpen(bool open) { m_playlistOpen = open; emit playlistOpenChanged(); }
void AppModel::setActiveCategoryId(const QString& id) { m_activeCategoryId = id; emit activeCategoryIdChanged(); }
void AppModel::setLibraryFilter(const QString& f) { m_libraryFilter = f; emit libraryFilterChanged(); }
void AppModel::setLibrarySearch(const QString& s) { m_librarySearch = s; emit librarySearchChanged(); }
void AppModel::setBackgroundImage(const QString& p) { m_backgroundImage = p; emit backgroundImageChanged(); }

// =====================================================================
//  工具方法
// =====================================================================
void AppModel::setErrorAutoClear(const QString& msg) {
    m_error = msg;
    emit errorChanged();
    m_errorTimer->start(3000); // 3秒后自动清除
}

void AppModel::showToast(const QString& message) {
    m_toastMessage = message;
    m_toastVisible = true;
    emit toastMessageChanged();
    emit toastVisibleChanged();

    // 2秒后自动隐藏
    QTimer::singleShot(2000, this, [this]() {
        m_toastVisible = false;
        emit toastVisibleChanged();
    });
}

QString AppModel::formatTime(double seconds) const {
    int m = (int)seconds / 60;
    int s = (int)seconds % 60;
    return QString("%1:%2").arg(m).arg(s, 2, 10, QChar('0'));
}

QString AppModel::getCoverPath(int songId) const {
    return m_library->getCoverPath(songId);
}

void AppModel::toggleSettings() {
    m_settingsOpen = !m_settingsOpen;
    emit settingsOpenChanged();
}
