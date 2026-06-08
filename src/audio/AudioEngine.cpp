#include "AudioEngine.h"
#include <QTimer>

AudioEngine::AudioEngine(QObject* parent) : QObject(parent) {
    m_player = new QMediaPlayer(this);
    m_audioOutput = new QAudioOutput(this);
    m_audioOutput->setVolume(m_volume / 100.0);
    m_player->setAudioOutput(m_audioOutput);

    connect(m_player, &QMediaPlayer::positionChanged, this, [this](qint64 pos) {
        emit currentTimeChanged(pos / 1000.0);
    });
    connect(m_player, &QMediaPlayer::durationChanged, this, [this](qint64 dur) {
        if (dur > 0) emit durationChanged(dur / 1000.0);
    });
    connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this](QMediaPlayer::PlaybackState state) {
        bool p = (state == QMediaPlayer::PlayingState);
        if (p != m_playing) {
            m_playing = p;
            emit playingChanged(m_playing);
        }
    });
    connect(m_player, &QMediaPlayer::mediaStatusChanged, this, [this](QMediaPlayer::MediaStatus status) {
        if (status == QMediaPlayer::EndOfMedia) {
            m_playing = false;
            emit playingChanged(false);
            emit mediaEnded();
        }
    });
    connect(m_player, &QMediaPlayer::errorOccurred, this, [this](QMediaPlayer::Error err, const QString& msg) {
        Q_UNUSED(err)
        if (!msg.isEmpty())
            emit errorOccurred(msg);
    });
}

AudioEngine::~AudioEngine() {
    stop();
}

double AudioEngine::currentTime() const {
    return m_player ? m_player->position() / 1000.0 : 0;
}

double AudioEngine::duration() const {
    return m_player ? m_player->duration() / 1000.0 : 0;
}

bool AudioEngine::playing() const {
    return m_playing;
}

void AudioEngine::load(const QUrl& url) {
    stop();
    m_player->setSource(url);
    // duration will come via signal
}

void AudioEngine::play() {
    if (!m_player || m_player->source().isEmpty()) return;
    m_player->play();
}

void AudioEngine::pause() {
    if (!m_player) return;
    m_player->pause();
}

void AudioEngine::togglePlay() {
    if (m_playing) pause(); else play();
}

void AudioEngine::seek(double seconds) {
    if (!m_player) return;
    m_player->setPosition(static_cast<qint64>(seconds * 1000));
}

void AudioEngine::setVolume(int vol) {
    m_volume = vol;
    if (m_muted) return;
    if (m_audioOutput)
        m_audioOutput->setVolume(std::max(0.0, std::min(1.0, vol / 100.0)));
}

void AudioEngine::setMuted(bool muted) {
    m_muted = muted;
    if (m_audioOutput)
        m_audioOutput->setVolume(muted ? 0 : std::max(0.0, std::min(1.0, m_volume / 100.0)));
}

void AudioEngine::stop() {
    if (!m_player) return;
    m_player->stop();
    m_player->setSource(QUrl());
    m_playing = false;
}

void AudioEngine::fadeOut(int durationMs) {
    if (!m_audioOutput) return;
    double startVol = m_audioOutput->volume();
    int steps = 20;
    int interval = durationMs / steps;
    for (int i = 0; i < steps; i++) {
        QTimer::singleShot(i * interval, this, [this, startVol, steps, i]() {
            if (m_audioOutput) {
                double frac = 1.0 - (i + 1.0) / steps;
                m_audioOutput->setVolume(startVol * frac);
            }
        });
    }
}

void AudioEngine::fadeIn(int durationMs, int targetVolume) {
    if (!m_audioOutput) return;
    double target = targetVolume / 100.0;
    int steps = 20;
    int interval = durationMs / steps;
    m_audioOutput->setVolume(0);
    for (int i = 0; i < steps; i++) {
        QTimer::singleShot(i * interval, this, [this, target, steps, i]() {
            if (m_audioOutput) {
                double frac = (i + 1.0) / steps;
                m_audioOutput->setVolume(target * frac);
            }
        });
    }
}
