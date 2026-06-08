#include "AudioAnalyzer.h"
#include <QAudioFormat>
#include <cmath>
#include <algorithm>

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
    m_ready = false;
    m_decoder->stop();
    m_decoder->setSource(filePath);
    m_decoder->start();
}

void AudioAnalyzer::onBufferReady() {
    QAudioBuffer buf = m_decoder->read();
    if (!buf.isValid()) return;

    const QAudioFormat& fmt = buf.format();
    int srcRate = fmt.sampleRate();
    if (m_sampleRate == 0) m_sampleRate = srcRate;

    int srcChannels = fmt.channelCount();
    const float* data = buf.constData<float>();
    if (!data && fmt.sampleFormat() == QAudioFormat::Int16) {
        // Convert int16 to float
        const qint16* idata = buf.constData<qint16>();
        int n = buf.frameCount() * srcChannels;
        for (int i = 0; i < n; i++)
            m_samples.append(idata[i] / 32768.0f);
        return;
    }
    if (!data) return;

    int n = buf.frameCount() * srcChannels;
    // Convert to mono, optionally downsample
    float downsampleRatio = (float)srcRate / TARGET_SAMPLE_RATE;
    for (int i = 0; i < buf.frameCount(); i++) {
        // Mono mix
        float sum = 0;
        for (int ch = 0; ch < srcChannels; ch++) {
            sum += data[i * srcChannels + ch];
        }
        float mono = sum / srcChannels;

        // Simple downsampling: only take every Nth sample
        int targetIdx = (int)(i / downsampleRatio);
        int currentSize = m_samples.size();
        if (targetIdx >= currentSize) {
            m_samples.resize(targetIdx + 1);
            m_samples[targetIdx] = mono;
        } else {
            m_samples[targetIdx] = (m_samples[targetIdx] + mono) * 0.5f;
        }
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
    m_ready = false;
    m_spectrumData.clear();
    for (int i = 0; i < NUM_BINS; i++)
        m_spectrumData.append(0.0);
}

QVariantList AudioAnalyzer::computeSpectrum(double currentTimeSeconds) {
    QVariantList result;

    int actualRate = (m_sampleRate > 0) ? TARGET_SAMPLE_RATE : 44100;
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
        float hann = 0.5f * (1.0f - std::cos(2.0f * M_PI * wi / (end - start - 1)));
        window[wi] = m_samples[i] * hann;
    }

    int windowLen = end - start;

    // Compute magnitudes at log-spaced frequencies
    for (int bin = 0; bin < NUM_BINS; bin++) {
        double freq = MIN_FREQ * std::pow(MAX_FREQ / MIN_FREQ, (double)bin / (NUM_BINS - 1.0));
        double re = 0, im = 0;
        for (int i = 0; i < windowLen; i++) {
            double phase = 2.0 * M_PI * freq * i / actualRate;
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
