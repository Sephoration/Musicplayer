#pragma once

#include <QObject>
#include <QAudioDecoder>
#include <QAudioBuffer>
#include <QVector>
#include <QVariantList>
#include <QUrl>

class AudioAnalyzer : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(QVariantList spectrumData READ spectrumData NOTIFY spectrumDataChanged)

public:
    explicit AudioAnalyzer(QObject* parent = nullptr);
    ~AudioAnalyzer();

    bool ready() const { return m_ready; }
    QVariantList spectrumData() const { return m_spectrumData; }

    void loadFile(const QString& filePath);
    void update(double currentTimeSeconds);
    void reset();

    static constexpr int NUM_BINS = 96;

signals:
    void readyChanged();
    void spectrumDataChanged();

private:
    void onBufferReady();
    void onFinished();

    QVariantList computeSpectrum(double currentTimeSeconds);

    QAudioDecoder* m_decoder = nullptr;
    QVector<float> m_samples;
    int m_sampleRate = 0;
    bool m_ready = false;
    QVariantList m_spectrumData;

    static constexpr int TARGET_SAMPLE_RATE = 8000;
    static constexpr int WINDOW_SIZE = 1024;
    static constexpr double MIN_FREQ = 30.0;
    static constexpr double MAX_FREQ = 8000.0;
};
