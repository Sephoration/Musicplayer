#include "LyricsSync.h"

LyricsSync::LyricsSync(QObject* parent) : QObject(parent) {
    resetState();
}

bool LyricsSync::hasLyrics() const {
    return !m_data.lines.isEmpty();
}

void LyricsSync::load(const QString& lrcContent, const QString& translationContent) {
    bool hadLyrics = hasLyrics();
    m_data = LrcParser::parse(lrcContent, translationContent);
    rebuildLineCache();
    resetState();
    if (hadLyrics != hasLyrics()) emit hasLyricsChanged();
    emit syncStateChanged();
}

void LyricsSync::update(double timeSeconds) {
    if (!hasLyrics()) {
        if (m_state.value("hasLyrics").toBool()) {
            resetState();
            emit syncStateChanged();
        }
        return;
    }

    LrcLine* currentLine = LrcParser::findCurrentLine(m_data, timeSeconds);
    int lineIndex = currentLine
        ? static_cast<int>(currentLine - m_data.lines.data())
        : -1;

    int wordIndex = -1;
    double wordProgress = 0.0;
    if (currentLine) {
        wordIndex = LrcParser::findCurrentWord(*currentLine, timeSeconds);
        if (wordIndex >= 0 && wordIndex < currentLine->words.size())
            wordProgress = LrcParser::getWordProgress(currentLine->words[wordIndex], timeSeconds);
        else if (wordIndex >= currentLine->words.size())
            wordProgress = 1.0;
    }

    m_state["currentLine"] = currentLine ? QVariant::fromValue(currentLine->toMap()) : QVariant();
    m_state["currentLineIndex"] = lineIndex;
    m_state["currentWordIndex"] = wordIndex;
    m_state["wordProgress"] = wordProgress;
    m_state["lines"] = m_lineCache;
    m_state["hasLyrics"] = true;
    emit syncStateChanged();
}

void LyricsSync::clear() {
    bool hadLyrics = hasLyrics();
    m_data = LrcData();
    m_lineCache.clear();
    resetState();
    emit syncStateChanged();
    if (hadLyrics) emit hasLyricsChanged();
}

void LyricsSync::resetState() {
    QVariantMap st;
    st["currentLine"] = QVariant();
    st["currentLineIndex"] = -1;
    st["currentWordIndex"] = -1;
    st["wordProgress"] = 0.0;
    st["lines"] = m_lineCache;
    st["hasLyrics"] = hasLyrics();
    m_state = st;
}

void LyricsSync::rebuildLineCache() {
    m_lineCache.clear();
    for (const auto& line : m_data.lines)
        m_lineCache.append(line.toMap());
}
