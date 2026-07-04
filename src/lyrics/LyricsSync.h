#pragma once

#include <QObject>
#include <QVariantMap>
#include "LrcParser.h"

class LyricsSync : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap syncState READ syncState NOTIFY syncStateChanged)
    Q_PROPERTY(bool hasLyrics READ hasLyrics NOTIFY hasLyricsChanged)

public:
    explicit LyricsSync(QObject* parent = nullptr);

    QVariantMap syncState() const { return m_state; }
    bool hasLyrics() const;

    void load(const QString& lrcContent, const QString& translationContent = QString());
    void update(double timeSeconds);
    void clear();

signals:
    void syncStateChanged();
    void hasLyricsChanged();

private:
    void resetState();
    void rebuildLineCache();

    LrcData m_data;
    QVariantMap m_state;
    QVariantList m_lineCache;
};
