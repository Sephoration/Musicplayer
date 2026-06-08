#pragma once

#include <QObject>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QUrl>

class AudioEngine : public QObject {
    Q_OBJECT
    Q_PROPERTY(double currentTime READ currentTime NOTIFY currentTimeChanged)
    Q_PROPERTY(double duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)

public:
    explicit AudioEngine(QObject* parent = nullptr);
    ~AudioEngine();

    double currentTime() const;
    double duration() const;
    bool playing() const;

    void load(const QUrl& url);
    void play();
    void pause();
    void togglePlay();
    void seek(double seconds);
    void setVolume(int vol);   // 0-100
    void setMuted(bool muted);
    void stop();

    // Crossfade support
    void fadeOut(int durationMs);
    void fadeIn(int durationMs, int targetVolume);

    // Expose player for audio probe connection
    QMediaPlayer* mediaPlayer() const { return m_player; }

signals:
    void currentTimeChanged(double time);
    void durationChanged(double duration);
    void playingChanged(bool playing);
    void mediaEnded();
    void errorOccurred(const QString& message);

private:
    QMediaPlayer* m_player = nullptr;
    QAudioOutput* m_audioOutput = nullptr;
    double m_volume = 65;
    bool m_muted = false;
    bool m_playing = false;
};
