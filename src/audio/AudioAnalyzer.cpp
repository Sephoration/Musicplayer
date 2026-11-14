#include "AudioAnalyzer.h"
#include <QAudioFormat>
#include <cmath>
#include <algorithm>
#include <vector>

static constexpr double Pi = 3.14159265358979323846;

AudioAnalyzer::AudioAnalyzer(QObject* parent) : QObject(parent) {
    m_decoder = new QAudioDecoder(this);

    connect(m_decoder, &QAudioDecoder::bufferReady, this, &AudioAnalyzer::onBufferReady);
    connect(m_decoder, &QAudioDecoder::finished, this, &AudioAnalyzer::onFinished);
    // Qt 6.11 已移除 errorOccurred，改在 onFinished 里通过 isDecoding() 判断错误

    // Initialize spectrum data to zeros
    for (int i = 0; i < NUM_BINS; i++)
        m_spectrumData.append(0.0);
}

AudioAnalyzer::~AudioAnalyzer() {
    m_decoder->stop();
}

void AudioAnalyzer::loadFile(const QString& filePath) {
    m_samples.clear();
    m_sampleRate = 0;
    m_outputRate = 0;
    m_inputFrames = 0;
    m_ready = false;
    m_decoder->stop();
    m_decoder->setSource(QUrl::fromLocalFile(filePath));
    m_decoder->start();
}

void AudioAnalyzer::onBufferReady() {
    QAudioBuffer buf = m_decoder->read();
    if (!buf.isValid()) return;

    const QAudioFormat& fmt = buf.format();
    const int srcRate = fmt.sampleRate();
    const int channels = fmt.channelCount();
    if (srcRate <= 0 || channels <= 0) return;
    if (m_sampleRate == 0) {
        m_sampleRate = srcRate;
        m_outputRate = std::min(srcRate, TARGET_SAMPLE_RATE);
    }
    if (srcRate != m_sampleRate) return;

    // Keep the input position across buffers so the waveform stays aligned.
    for (int frame = 0; frame < buf.frameCount(); ++frame, ++m_inputFrames) {
        const qint64 target = m_inputFrames * m_outputRate / m_sampleRate;
        if (target < m_samples.size()) continue;
        float sum = 0;
        for (int ch = 0; ch < channels; ++ch) {
            const int index = frame * channels + ch;
            switch (fmt.sampleFormat()) {
            case QAudioFormat::Float: sum += buf.constData<float>()[index]; break;
            case QAudioFormat::Int16: sum += buf.constData<qint16>()[index] / 32768.0f; break;
            case QAudioFormat::Int32: sum += buf.constData<qint32>()[index] / 2147483648.0f; break;
            case QAudioFormat::UInt8: sum += (buf.constData<quint8>()[index] - 128) / 128.0f; break;
            default: return;
            }
        }
        m_samples.append(sum / channels);
    }
}

void AudioAnalyzer::onFinished() {
    m_ready = true;
    emit readyChanged();
}

void AudioAnalyzer::update(double currentTimeSeconds) {
    if (!m_ready || m_samples.isEmpty()) return;
    m_spectrumData = computeSpectrum(currentTimeSeconds);
    emit spectrumDataChanged();
}

void AudioAnalyzer::reset() {
    m_decoder->stop();
    m_samples.clear();
    m_sampleRate = 0;
    m_outputRate = 0;
    m_inputFrames = 0;
    m_ready = false;
    m_spectrumData.clear();
    for (int i = 0; i < NUM_BINS; i++)
        m_spectrumData.append(0.0);
}

QVariantList AudioAnalyzer::computeSpectrum(double currentTimeSeconds) {
    QVariantList result;

    int actualRate = m_outputRate > 0 ? m_outputRate : TARGET_SAMPLE_RATE;
    int centerOffset = static_cast<int>(currentTimeSeconds * actualRate);
    int start = std::max(0, centerOffset - WINDOW_SIZE / 2);
    int end = std::min((int)m_samples.size(), start + WINDOW_SIZE);

    if (end - start < WINDOW_SIZE / 2) {
        // Not enough data — return zeros
        for (int i = 0; i < NUM_BINS; i++) result.append(0.0);
        return result;
    }

    // Extract window (with Hann window)
    std::vector<float> window(WINDOW_SIZE, 0);
    for (int i = start; i < end; i++) {
        int wi = i - start;
        float hann = 0.5f * (1.0f - std::cos(2.0f * Pi * wi / (end - start - 1)));
        window[wi] = m_samples[i] * hann;
    }

    int windowLen = end - start;

    // Compute magnitudes at log-spaced frequencies
    for (int bin = 0; bin < NUM_BINS; bin++) {
        double maxFreq = std::min(MAX_FREQ, actualRate / 2.0);
        double freq = MIN_FREQ * std::pow(maxFreq / MIN_FREQ, (double)bin / (NUM_BINS - 1.0));
        double re = 0, im = 0;
        for (int i = 0; i < windowLen; i++) {
            double phase = 2.0 * Pi * freq * i / actualRate;
            re += window[i] * std::cos(phase);
            im -= window[i] * std::sin(phase);
        }
        double mag = std::sqrt(re * re + im * im) / windowLen * 2;
        // Normalize to 0-255 range (roughly)
        double normalized = std::min(255.0, mag * 5000.0);
        result.append(normalized);
    }
    return result;
}
