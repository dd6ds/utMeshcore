#ifndef QRCODEITEM_H
#define QRCODEITEM_H

#include <QQuickPaintedItem>
#include <QString>
#include <QVector>

/// QML element "QrCode": draws `text` as a QR code, scaled to the item.
///
/// Always black on white with a quiet zone, whatever the app theme: phone
/// cameras read inverted or low-contrast codes badly.
class QrCodeItem : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(QString text READ text WRITE setText NOTIFY textChanged)

public:
    explicit QrCodeItem(QQuickItem *parent = nullptr);

    QString text() const { return m_text; }
    void setText(const QString &text);

    void paint(QPainter *painter) override;

signals:
    void textChanged();

private:
    /// Light modules around the code that the QR standard asks for.
    static constexpr int kQuietZoneModules = 4;

    QString m_text;
    int m_size = 0;              // modules per side, 0 = nothing to draw
    QVector<bool> m_modules;     // row-major, true = dark
};

#endif // QRCODEITEM_H
