#pragma once

#include <QObject>
#include <QVariantMap>
#include <QVariantList>
#include <QTimer>
#include "audio/AudioEngine.h"
#include "audio/AudioAnalyzer.h"
#include "lyrics/LyricsSync.h"
#include "library/LibraryManager.h"
#include "app/Settings.h"

class AppModel : public QObject {
    Q_OBJECT

    // --- Player state ---
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(double currentTime READ currentTime NOTIFY currentTimeChanged)
    Q_PROPERTY(double duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool muted READ muted WRITE setMuted NOTIFY mutedChanged)
    Q_PROPERTY(QString playMode READ playMode WRITE setPlayMode NOTIFY playModeChanged)
    Q_PROPERTY(int currentSongId READ currentSongId NOTIFY currentSongChanged)
    Q_PROPERTY(QString currentSongTitle READ currentSongTitle NOTIFY currentSongChanged)
    Q_PROPERTY(QString currentSongArtist READ currentSongArtist NOTIFY currentSongChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(QString coverUrl READ coverUrl NOTIFY coverUrlChanged)

    // --- Queue ---
    Q_PROPERTY(QVariantList queue READ queue NOTIFY queueChanged)
    Q_PROPERTY(int queueIndex READ queueIndex NOTIFY queueIndexChanged)

    // --- Visualizer ---
    Q_PROPERTY(QString visualizerColor READ visualizerColor WRITE setVisualizerColor NOTIFY visualizerColorChanged)
    Q_PROPERTY(QString visualizerMode READ visualizerMode WRITE setVisualizerMode NOTIFY visualizerModeChanged)
    Q_PROPERTY(QVariantList spectrumData READ spectrumData NOTIFY spectrumDataChanged)

    // --- Lyrics ---
    Q_PROPERTY(QVariantMap syncState READ syncState NOTIFY syncStateChanged)
    Q_PROPERTY(int fontSize READ fontSize WRITE setFontSize NOTIFY fontSizeChanged)
    Q_PROPERTY(bool showTranslation READ showTranslation WRITE setShowTranslation NOTIFY showTranslationChanged)
    Q_PROPERTY(QString lyricsActiveWordColor READ lyricsActiveWordColor WRITE setLyricsActiveWordColor NOTIFY lyricsActiveWordColorChanged)
    Q_PROPERTY(QString lyricsActiveLineColor READ lyricsActiveLineColor WRITE setLyricsActiveLineColor NOTIFY lyricsActiveLineColorChanged)
    Q_PROPERTY(QString lyricsInactiveColor READ lyricsInactiveColor WRITE setLyricsInactiveColor NOTIFY lyricsInactiveColorChanged)
    Q_PROPERTY(int lyricsOpacity READ lyricsOpacity WRITE setLyricsOpacity NOTIFY lyricsOpacityChanged)
    Q_PROPERTY(QString lyricsBgColor READ lyricsBgColor WRITE setLyricsBgColor NOTIFY lyricsBgColorChanged)

    // --- Background ---
    Q_PROPERTY(QString backgroundImage READ backgroundImage WRITE setBackgroundImage NOTIFY backgroundImageChanged)
    Q_PROPERTY(int backgroundOverlay READ backgroundOverlay WRITE setBackgroundOverlay NOTIFY backgroundOverlayChanged)

    // --- Crossfade ---
    Q_PROPERTY(bool crossfade READ crossfade WRITE setCrossfade NOTIFY crossfadeChanged)
    Q_PROPERTY(int crossfadeDuration READ crossfadeDuration WRITE setCrossfadeDuration NOTIFY crossfadeDurationChanged)

    // --- Resume ---
    Q_PROPERTY(bool resumePlayback READ resumePlayback WRITE setResumePlayback NOTIFY resumePlaybackChanged)

    // --- Sleep timer ---
    Q_PROPERTY(qint64 sleepTimerEnd READ sleepTimerEnd NOTIFY sleepTimerEndChanged)
    Q_PROPERTY(qint64 sleepTimerRemaining READ sleepTimerRemaining NOTIFY sleepTimerRemainingChanged)

    // --- Accent ---
    Q_PROPERTY(QString accentColor READ accentColor WRITE setAccentColor NOTIFY accentColorChanged)

    // --- Library ---
    Q_PROPERTY(QVariantList songs READ songs NOTIFY songsChanged)
    Q_PROPERTY(QVariantList categories READ categories NOTIFY categoriesChanged)
    Q_PROPERTY(QString activeCategoryId READ activeCategoryId WRITE setActiveCategoryId NOTIFY activeCategoryIdChanged)
    Q_PROPERTY(QString libraryFilter READ libraryFilter WRITE setLibraryFilter NOTIFY libraryFilterChanged)
    Q_PROPERTY(QString librarySearch READ librarySearch WRITE setLibrarySearch NOTIFY librarySearchChanged)
    Q_PROPERTY(bool libraryLoading READ libraryLoading NOTIFY libraryLoadingChanged)

    // --- View ---
    Q_PROPERTY(QString currentView READ currentView WRITE setCurrentView NOTIFY currentViewChanged)
    Q_PROPERTY(bool playlistOpen READ playlistOpen WRITE setPlaylistOpen NOTIFY playlistOpenChanged)
    Q_PROPERTY(bool miniMode READ miniMode WRITE setMiniMode NOTIFY miniModeChanged)
    Q_PROPERTY(bool settingsOpen READ settingsOpen NOTIFY settingsOpenChanged)

    // --- Toast ---
    Q_PROPERTY(QString toastMessage READ toastMessage NOTIFY toastMessageChanged)
    Q_PROPERTY(bool toastVisible READ toastVisible NOTIFY toastVisibleChanged)

public:
    static AppModel* instance();

    // --- Player state accessors ---
    bool playing() const { return m_playing; }
    double currentTime() const { return m_currentTime; }
    double duration() const { return m_duration; }
    int volume() const { return m_volume; }
    bool muted() const { return m_muted; }
    QString playMode() const { return m_playMode; }
    int currentSongId() const { return m_currentSongId; }
    QString currentSongTitle() const { return m_currentSongTitle; }
    QString currentSongArtist() const { return m_currentSongArtist; }
    QString error() const { return m_error; }
    QString coverUrl() const { return m_coverUrl; }

    QVariantList queue() const { return m_queue; }
    int queueIndex() const { return m_queueIndex; }

    QString visualizerColor() const { return m_visualizerColor; }
    QString visualizerMode() const { return m_visualizerMode; }
    QVariantList spectrumData() const { return m_spectrumData; }

    QVariantMap syncState() const { return m_syncState; }
    int fontSize() const { return m_fontSize; }
    bool showTranslation() const { return m_showTranslation; }
    QString lyricsActiveWordColor() const { return m_lyricsActiveWordColor; }
    QString lyricsActiveLineColor() const { return m_lyricsActiveLineColor; }
    QString lyricsInactiveColor() const { return m_lyricsInactiveColor; }
    int lyricsOpacity() const { return m_lyricsOpacity; }
    QString lyricsBgColor() const { return m_lyricsBgColor; }

    QString backgroundImage() const { return m_backgroundImage; }
    int backgroundOverlay() const { return m_backgroundOverlay; }

    bool crossfade() const { return m_crossfade; }
    int crossfadeDuration() const { return m_crossfadeDuration; }

    bool resumePlayback() const { return m_resumePlayback; }

    qint64 sleepTimerEnd() const { return m_sleepTimerEnd; }
    qint64 sleepTimerRemaining() const;

    QString accentColor() const { return m_accentColor; }

    QVariantList songs() const { return m_songs; }
    QVariantList categories() const { return m_categories; }
    QString activeCategoryId() const { return m_activeCategoryId; }
    QString libraryFilter() const { return m_libraryFilter; }
    QString librarySearch() const { return m_librarySearch; }
    bool libraryLoading() const { return m_libraryLoading; }

    QString currentView() const { return m_currentView; }
    bool playlistOpen() const { return m_playlistOpen; }
    bool miniMode() const { return m_miniMode; }
    bool settingsOpen() const { return m_settingsOpen; }

    QString toastMessage() const { return m_toastMessage; }
    bool toastVisible() const { return m_toastVisible; }

    // --- Q_INVOKABLE methods ---
    Q_INVOKABLE void playSong(int songId, const QString& title, const QString& artist);
    Q_INVOKABLE void playNext();
    Q_INVOKABLE void playPrev();
    Q_INVOKABLE void requestPlay();
    Q_INVOKABLE void seek(double seconds);
    Q_INVOKABLE void setVolume(int vol);
    Q_INVOKABLE void setMuted(bool muted);
    Q_INVOKABLE void togglePlayMode();
    Q_INVOKABLE void toggleMiniMode();
    Q_INVOKABLE void setSleepTimer(int minutes);
    Q_INVOKABLE void clearSleepTimer();
    Q_INVOKABLE void loadLibrary();
    Q_INVOKABLE void importFolder(const QString& folderPath);
    Q_INVOKABLE void importFiles(const QStringList& filePaths);
    Q_INVOKABLE void deleteSong(int songId);
    Q_INVOKABLE void toggleFavorite(int songId);
    Q_INVOKABLE void addToQueue(int songId, const QString& title, const QString& artist);
    Q_INVOKABLE void removeFromQueue(int index);
    Q_INVOKABLE void addToPlayNext(int songId, const QString& title, const QString& artist);
    Q_INVOKABLE void replaceQueueAndPlay(const QVariantList& items, int playIndex);
    Q_INVOKABLE void clearQueue();
    Q_INVOKABLE void setBackgroundImage(const QString& path);
    Q_INVOKABLE void setBackgroundImagePath(const QString& path);
    Q_INVOKABLE void clearBackgroundImagePath();
    Q_INVOKABLE void importLyrics(int songId, const QString& content);
    Q_INVOKABLE void importCover(int songId, const QString& path);
    Q_INVOKABLE void createCategory(const QString& name, const QString& icon);
    Q_INVOKABLE void deleteCategory(const QString& id);
    Q_INVOKABLE void renameCategory(const QString& id, const QString& name);
    Q_INVOKABLE void addToCategory(const QString& categoryId, int songId);
    Q_INVOKABLE void removeFromCategory(const QString& categoryId, int songId);
    Q_INVOKABLE void setCurrentView(const QString& view);
    Q_INVOKABLE void setPlaylistOpen(bool open);
    Q_INVOKABLE void setMiniMode(bool mini);
    Q_INVOKABLE void setVisualizerColor(const QString& color);
    Q_INVOKABLE void setVisualizerMode(const QString& mode);
    Q_INVOKABLE void setFontSize(int size);
    Q_INVOKABLE void setShowTranslation(bool show);
    Q_INVOKABLE void setLyricsActiveWordColor(const QString& c);
    Q_INVOKABLE void setLyricsActiveLineColor(const QString& c);
    Q_INVOKABLE void setLyricsInactiveColor(const QString& c);
    Q_INVOKABLE void setLyricsOpacity(int v);
    Q_INVOKABLE void setLyricsBgColor(const QString& c);
    Q_INVOKABLE void setBackgroundOverlay(int v);
    Q_INVOKABLE void setCrossfade(bool v);
    Q_INVOKABLE void setCrossfadeDuration(int d);
    Q_INVOKABLE void setResumePlayback(bool v);
    Q_INVOKABLE void setAccentColor(const QString& c);
    Q_INVOKABLE void setActiveCategoryId(const QString& id);
    Q_INVOKABLE void setLibraryFilter(const QString& f);
    Q_INVOKABLE void setLibrarySearch(const QString& s);
    Q_INVOKABLE void setPlayMode(const QString& mode);
    Q_INVOKABLE void showToast(const QString& message);
    Q_INVOKABLE void toggleSettings();
    Q_INVOKABLE QString formatTime(double seconds) const;
    Q_INVOKABLE QString getCoverPath(int songId) const;

signals:
    void playingChanged();
    void currentTimeChanged();
    void durationChanged();
    void volumeChanged();
    void mutedChanged();
    void playModeChanged();
    void currentSongChanged();
    void errorChanged();
    void coverUrlChanged();
    void queueChanged();
    void queueIndexChanged();
    void visualizerColorChanged();
    void visualizerModeChanged();
    void spectrumDataChanged();
    void syncStateChanged();
    void fontSizeChanged();
    void showTranslationChanged();
    void lyricsActiveWordColorChanged();
    void lyricsActiveLineColorChanged();
    void lyricsInactiveColorChanged();
    void lyricsOpacityChanged();
    void lyricsBgColorChanged();
    void backgroundImageChanged();
    void backgroundOverlayChanged();
    void crossfadeChanged();
    void crossfadeDurationChanged();
    void resumePlaybackChanged();
    void sleepTimerEndChanged();
    void sleepTimerRemainingChanged();
    void accentColorChanged();
    void songsChanged();
    void categoriesChanged();
    void activeCategoryIdChanged();
    void libraryFilterChanged();
    void librarySearchChanged();
    void libraryLoadingChanged();
    void currentViewChanged();
    void playlistOpenChanged();
    void miniModeChanged();
    void settingsOpenChanged();
    void toastMessageChanged();
    void toastVisibleChanged();

private:
    explicit AppModel(QObject* parent = nullptr);
    static AppModel* s_instance;

    void loadSongInternal(int songId, const QString& title, const QString& artist);
    int ensureSongInQueue(int songId, const QString& title, const QString& artist);
    void setErrorAutoClear(const QString& msg);
    void saveState();
    void loadState();
    void updateSpectrum();
    void applyAccentColor();
    void rebuildCategories();

    AudioEngine* m_audioEngine;
    AudioAnalyzer* m_audioAnalyzer;
    LyricsSync* m_lyricsSync;
    LibraryManager* m_library;
    Settings* m_settings;

    // Player state
    bool m_playing = false;
    double m_currentTime = 0;
    double m_duration = 0;
    int m_volume = 65;
    bool m_muted = false;
    QString m_playMode = "sequential";
    int m_currentSongId = 0;
    QString m_currentSongTitle;
    QString m_currentSongArtist;
    QString m_error;
    QString m_coverUrl;

    // Queue
    QVariantList m_queue;
    int m_queueIndex = -1;

    // Visualizer
    QString m_visualizerColor = "#6366f1";
    QString m_visualizerMode = "2d";
    QVariantList m_spectrumData;

    // Lyrics
    QVariantMap m_syncState;
    int m_fontSize = 15;
    bool m_showTranslation = true;
    QString m_lyricsActiveWordColor = "#a78bfa";
    QString m_lyricsActiveLineColor = "#e8e8e8";
    QString m_lyricsInactiveColor = "#888888";
    int m_lyricsOpacity = 60;
    QString m_lyricsBgColor = "#ffffff";

    // Background
    QString m_backgroundImage;
    int m_backgroundOverlay = 30;

    // Crossfade
    bool m_crossfade = false;
    int m_crossfadeDuration = 2;

    // Resume
    bool m_resumePlayback = true;

    // Sleep timer
    qint64 m_sleepTimerEnd = 0;
    QTimer* m_sleepTimerTick = nullptr;

    // Accent
    QString m_accentColor = "#6366f1";

    // Library
    QVariantList m_songs;
    QVariantList m_categories;
    QString m_activeCategoryId = "all";
    QString m_libraryFilter = "all";
    QString m_librarySearch;
    bool m_libraryLoading = false;

    // View
    QString m_currentView = "player";
    bool m_playlistOpen = false;
    bool m_miniMode = false;
    bool m_settingsOpen = false;
    bool m_loadingState = false;

    // Toast
    QString m_toastMessage;
    bool m_toastVisible = false;

    // Internal
    QTimer* m_errorTimer = nullptr;
    QTimer* m_spectrumTimer = nullptr;

    // Library internal state (not exposed as Q_PROPERTY, used internally)
    QVector<SongInfo> m_internalSongs;
    QVector<int> m_internalFavorites;
    QVector<int> m_internalRecents;
    QVector<CategoryInfo> m_internalCategories;
};
