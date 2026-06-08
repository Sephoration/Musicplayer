#pragma once

#include <QSettings>
#include <QString>
#include <QVariantList>

class Settings : public QObject {
    Q_OBJECT
public:
    explicit Settings(QObject* parent = nullptr);

    // Player settings
    int volume() const;
    void setVolume(int vol);
    QString playMode() const;
    void setPlayMode(const QString& mode);

    // Visual
    QString visualizerColor() const;
    void setVisualizerColor(const QString& color);
    QString visualizerMode() const;
    void setVisualizerMode(const QString& mode);

    // Lyrics
    int fontSize() const;
    void setFontSize(int size);
    bool showTranslation() const;
    void setShowTranslation(bool show);
    QString lyricsActiveWordColor() const;
    void setLyricsActiveWordColor(const QString& c);
    QString lyricsActiveLineColor() const;
    void setLyricsActiveLineColor(const QString& c);
    QString lyricsInactiveColor() const;
    void setLyricsInactiveColor(const QString& c);
    int lyricsOpacity() const;
    void setLyricsOpacity(int v);
    QString lyricsBgColor() const;
    void setLyricsBgColor(const QString& c);

    // Background
    QString backgroundImage() const;
    void setBackgroundImage(const QString& path);
    int backgroundOverlay() const;
    void setBackgroundOverlay(int v);
    int backgroundImageKey() const;
    void setBackgroundImageKey(int k);

    // Resume
    bool resumePlayback() const;
    void setResumePlayback(bool v);
    double lastTime() const;
    void setLastTime(double t);
    bool lastPlaying() const;
    void setLastPlaying(bool v);

    // Crossfade
    bool crossfade() const;
    void setCrossfade(bool v);
    int crossfadeDuration() const;
    void setCrossfadeDuration(int d);

    // Accent
    QString accentColor() const;
    void setAccentColor(const QString& c);

    // Queue persistence
    QVariantList savedQueue() const;
    void saveQueue(const QVariantList& queue, int queueIndex,
                   int currentSongId, const QString& title, const QString& artist);

    int savedQueueIndex() const;
    int savedCurrentSongId() const;
    QString savedCurrentSongTitle() const;
    QString savedCurrentSongArtist() const;

private:
    QSettings m_settings;
};
