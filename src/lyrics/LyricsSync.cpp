#include "LyricsSync.h"

LyricsSync::LyricsSync(QObject* parent) : QObject(parent) {
    // Initialize empty state
    QVariantMap st;
    st["currentLine"] = QVariant();
    st["currentLineIndex"] = -1;
    st["currentWordIndex"] = -1;
    st["wordProgress"] = 0.0;
    st["lines"] = QVariantList();
    st["hasLyrics"] = false;
    m_state = st;
}

bool LyricsSync::hasLyrics() const {
    return !m_data.lines.isEmpty();
}

void LyricsSync::load(const QString& lrcContent, const QString& translationContent) {
    m_data = LrcParser::parse(lrcContent, translationContent);
    if (hasLyrics()) emit hasLyricsChanged();
}

void LyricsSync::update(double timeSeconds) {
    QVariantMap st;

    if (!hasLyrics()) {
        st["currentLine"] = QVariant();
        st["currentLineIndex"] = -1;
        st["currentWordIndex"] = -1;
        st["wordProgress"] = 0.0;
        st["lines"] = QVariantList();
        st["hasLyrics"] = false;
    } else {
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

        st["currentLine"] = currentLine ? QVariant::fromValue(currentLine->toMap()) : QVariant();
        st["currentLineIndex"] = lineIndex;
        st["currentWordIndex"] = wordIndex;
        st["wordProgress"] = wordProgress;

        QVariantList lineList;
        for (const auto& l : m_data.lines)
            lineList.append(l.toMap());
        st["lines"] = lineList;
        st["hasLyrics"] = true;
    }

    m_state = st;
    emit syncStateChanged();
}

void LyricsSync::clear() {
    m_data = LrcData();
    QVariantMap st;
    st["currentLine"] = QVariant();
    st["currentLineIndex"] = -1;
    st["currentWordIndex"] = -1;
    st["wordProgress"] = 0.0;
    st["lines"] = QVariantList();
    st["hasLyrics"] = false;
    m_state = st;
    emit syncStateChanged();
    emit hasLyricsChanged();
}
