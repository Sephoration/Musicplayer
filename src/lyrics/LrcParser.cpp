#include "LrcParser.h"
#include <QRegularExpression>
#include <QMap>

static double parseTimestamp(const QString& ts) {
    static QRegularExpression rx(R"((\d+):(\d+)[:.](\d+))");
    auto m = rx.match(ts);
    if (!m.hasMatch()) return 0;
    return m.captured(1).toInt() * 60.0 +
           m.captured(2).toInt() +
           m.captured(3).toInt() / 100.0;
}

static void extractWordTimestamps(const QString& text, QString& cleanText, QVector<LrcWord>& words) {
    static QRegularExpression wordRx(R"(<(\d+:\d+[\.:]\d+)>([^<]*))");
    cleanText = text;
    words.clear();

    auto it = wordRx.globalMatch(text);
    while (it.hasNext()) {
        auto m = it.next();
        double startTime = parseTimestamp(m.captured(1));
        QString word = m.captured(2).trimmed();
        if (!word.isEmpty())
            words.append({word, startTime, startTime});
    }

    // Remove word timestamps from clean text
    cleanText.replace(QRegularExpression(R"(<\d+:\d+[\.:]\d+>)"), "");

    // Set end times
    for (int i = 0; i < words.size() - 1; i++)
        words[i].endTime = words[i + 1].startTime;
    if (!words.isEmpty())
        words.last().endTime = words.last().startTime + 1.0;
}

LrcData LrcParser::parse(const QString& lrcContent, const QString& translationContent) {
    LrcData data;

    static QRegularExpression metaRx(R"(\[(\w+):(.+?)\])");
    static QRegularExpression lineRx(R"(\[(\d+:\d+[\.:]\d+)\](.*))");
    static QSet<QString> metaKeys = {
        "ti", "ar", "al", "offset", "title", "artist", "album",
        "by", "re", "ve", "length", "language", "tool", "author"
    };

    // Parse translation map first
    QMap<double, QString> transMap;
    if (!translationContent.isEmpty()) {
        for (const QString& tl : translationContent.split('\n')) {
            auto tm = lineRx.match(tl.trimmed());
            if (tm.hasMatch())
                transMap[parseTimestamp(tm.captured(1))] = tm.captured(2).trimmed();
        }
    }

    for (const QString& rawLine : lrcContent.split('\n')) {
        QString line = rawLine.trimmed();
        if (line.isEmpty()) continue;

        // Try meta tag
        auto metaMatch = metaRx.match(line);
        if (metaMatch.hasMatch()) {
            QString key = metaMatch.captured(1).toLower();
            if (metaKeys.contains(key)) {
                QString val = metaMatch.captured(2).trimmed();
                if (key == "offset") data.offset = val.toDouble();
                else if (key == "ti" || key == "title") data.title = val;
                else if (key == "ar" || key == "artist") data.artist = val;
                else if (key == "al" || key == "album") data.album = val;
            }
            continue;
        }

        // Try timestamp line
        auto lineMatch = lineRx.match(line);
        if (lineMatch.hasMatch()) {
            double startTime = parseTimestamp(lineMatch.captured(1));
            QString rawText = lineMatch.captured(2).trimmed();
            QString cleanText;
            QVector<LrcWord> words;
            extractWordTimestamps(rawText, cleanText, words);

            if (words.isEmpty() && !cleanText.isEmpty())
                words.append({cleanText, startTime, startTime + 4.0});

            LrcLine lrcLine;
            lrcLine.text = cleanText.isEmpty() ? rawText : cleanText;
            lrcLine.translation = transMap.value(startTime);
            lrcLine.startTime = startTime;
            lrcLine.endTime = startTime + 4.0;
            lrcLine.words = words;
            data.lines.append(lrcLine);
        }
    }

    // Set line end times
    for (int i = 0; i < data.lines.size() - 1; i++)
        data.lines[i].endTime = data.lines[i + 1].startTime;

    return data;
}

LrcLine* LrcParser::findCurrentLine(LrcData& data, double time) {
    for (int i = data.lines.size() - 1; i >= 0; i--) {
        if (time >= data.lines[i].startTime)
            return &data.lines[i];
    }
    return nullptr;
}

int LrcParser::findCurrentWord(const LrcLine& line, double time) {
    for (int i = line.words.size() - 1; i >= 0; i--) {
        if (time >= line.words[i].startTime)
            return i;
    }
    return -1;
}

double LrcParser::getWordProgress(const LrcWord& word, double time) {
    double duration = word.endTime - word.startTime;
    if (duration <= 0) return time >= word.startTime ? 1.0 : 0.0;
    return std::min(1.0, std::max(0.0, (time - word.startTime) / duration));
}
