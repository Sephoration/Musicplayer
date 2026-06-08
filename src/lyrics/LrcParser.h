#pragma once

#include <QString>
#include <QVector>
#include <QVariantMap>
#include <QVariantList>

struct LrcWord {
    QString word;
    double startTime = 0.0;
    double endTime = 0.0;

    QVariantMap toMap() const {
        QVariantMap m;
        m["word"] = word;
        m["startTime"] = startTime;
        m["endTime"] = endTime;
        return m;
    }
};

struct LrcLine {
    QString text;
    QString translation;
    double startTime = 0.0;
    double endTime = 0.0;
    QVector<LrcWord> words;

    QVariantMap toMap() const {
        QVariantMap m;
        m["text"] = text;
        m["translation"] = translation;
        m["startTime"] = startTime;
        m["endTime"] = endTime;
        QVariantList wl;
        for (const auto& w : words) wl.append(w.toMap());
        m["words"] = wl;
        return m;
    }
};

struct LrcData {
    QString title;
    QString artist;
    QString album;
    double offset = 0.0;
    QVector<LrcLine> lines;
};

class LrcParser {
public:
    static LrcData parse(const QString& lrcContent, const QString& translationContent = QString());
    static LrcLine* findCurrentLine(LrcData& data, double time);
    static int findCurrentWord(const LrcLine& line, double time);
    static double getWordProgress(const LrcWord& word, double time);
};
