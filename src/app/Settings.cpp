#include "Settings.h"

Settings::Settings(QObject* parent)
    : QObject(parent), m_settings("MusicPlayer", "MusicPlayer") {}

int Settings::volume() const { return m_settings.value("player/volume", 65).toInt(); }
void Settings::setVolume(int vol) { m_settings.setValue("player/volume", vol); }

QString Settings::playMode() const { return m_settings.value("player/playMode", "sequential").toString(); }
void Settings::setPlayMode(const QString& mode) { m_settings.setValue("player/playMode", mode); }

QString Settings::visualizerColor() const { return m_settings.value("visual/color", "#6366f1").toString(); }
void Settings::setVisualizerColor(const QString& c) { m_settings.setValue("visual/color", c); }

QString Settings::visualizerMode() const { return m_settings.value("visual/mode", "2d").toString(); }
void Settings::setVisualizerMode(const QString& m) { m_settings.setValue("visual/mode", m); }

int Settings::fontSize() const { return m_settings.value("lyrics/fontSize", 15).toInt(); }
void Settings::setFontSize(int s) { m_settings.setValue("lyrics/fontSize", s); }

bool Settings::showTranslation() const { return m_settings.value("lyrics/showTranslation", true).toBool(); }
void Settings::setShowTranslation(bool s) { m_settings.setValue("lyrics/showTranslation", s); }

QString Settings::lyricsActiveWordColor() const { return m_settings.value("lyrics/activeWordColor", "#a78bfa").toString(); }
void Settings::setLyricsActiveWordColor(const QString& c) { m_settings.setValue("lyrics/activeWordColor", c); }

QString Settings::lyricsActiveLineColor() const { return m_settings.value("lyrics/activeLineColor", "#d4d4d4").toString(); }
void Settings::setLyricsActiveLineColor(const QString& c) { m_settings.setValue("lyrics/activeLineColor", c); }

QString Settings::lyricsInactiveColor() const { return m_settings.value("lyrics/inactiveColor", "#555555").toString(); }
void Settings::setLyricsInactiveColor(const QString& c) { m_settings.setValue("lyrics/inactiveColor", c); }

int Settings::lyricsOpacity() const { return m_settings.value("lyrics/opacity", 50).toInt(); }
void Settings::setLyricsOpacity(int v) { m_settings.setValue("lyrics/opacity", v); }

QString Settings::lyricsBgColor() const { return m_settings.value("lyrics/bgColor", "#ffffff").toString(); }
void Settings::setLyricsBgColor(const QString& c) { m_settings.setValue("lyrics/bgColor", c); }

QString Settings::backgroundImage() const { return m_settings.value("background/image", "").toString(); }
void Settings::setBackgroundImage(const QString& p) { m_settings.setValue("background/image", p); }

int Settings::backgroundOverlay() const { return m_settings.value("background/overlay", 40).toInt(); }
void Settings::setBackgroundOverlay(int v) { m_settings.setValue("background/overlay", v); }

int Settings::backgroundImageKey() const { return m_settings.value("background/key", 0).toInt(); }
void Settings::setBackgroundImageKey(int k) { m_settings.setValue("background/key", k); }

bool Settings::resumePlayback() const { return m_settings.value("player/resumePlayback", true).toBool(); }
void Settings::setResumePlayback(bool v) { m_settings.setValue("player/resumePlayback", v); }

double Settings::lastTime() const { return m_settings.value("player/lastTime", 0.0).toDouble(); }
void Settings::setLastTime(double t) { m_settings.setValue("player/lastTime", t); }

bool Settings::lastPlaying() const { return m_settings.value("player/lastPlaying", false).toBool(); }
void Settings::setLastPlaying(bool v) { m_settings.setValue("player/lastPlaying", v); }

bool Settings::crossfade() const { return m_settings.value("player/crossfade", false).toBool(); }
void Settings::setCrossfade(bool v) { m_settings.setValue("player/crossfade", v); }

int Settings::crossfadeDuration() const { return m_settings.value("player/crossfadeDuration", 2).toInt(); }
void Settings::setCrossfadeDuration(int d) { m_settings.setValue("player/crossfadeDuration", d); }

QString Settings::accentColor() const { return m_settings.value("theme/accentColor", "#6366f1").toString(); }
void Settings::setAccentColor(const QString& c) { m_settings.setValue("theme/accentColor", c); }

QVariantList Settings::savedQueue() const {
    return m_settings.value("state/queue").toList();
}
void Settings::saveQueue(const QVariantList& queue, int queueIndex,
                          int currentSongId, const QString& title, const QString& artist) {
    m_settings.setValue("state/queue", queue);
    m_settings.setValue("state/queueIndex", queueIndex);
    m_settings.setValue("state/currentSongId", currentSongId);
    m_settings.setValue("state/currentSongTitle", title);
    m_settings.setValue("state/currentSongArtist", artist);
}

int Settings::savedQueueIndex() const { return m_settings.value("state/queueIndex", -1).toInt(); }
int Settings::savedCurrentSongId() const { return m_settings.value("state/currentSongId", 0).toInt(); }
QString Settings::savedCurrentSongTitle() const { return m_settings.value("state/currentSongTitle").toString(); }
QString Settings::savedCurrentSongArtist() const { return m_settings.value("state/currentSongArtist").toString(); }
