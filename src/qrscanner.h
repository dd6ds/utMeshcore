#ifndef QRSCANNER_H
#define QRSCANNER_H

#include <QImage>
#include <QObject>
#include <QString>

/// Reads QR codes from camera viewfinder frames, exposed to QML as "QrScanner".
///
/// The scan page grabs the viewfinder now and then and hands the frame here.
/// Frames rather than photos: taking a photo plays the camera click sound on
/// Ubuntu Touch every time. The decoding is the quirc library.
class QrScanner : public QObject
{
    Q_OBJECT

public:
    explicit QrScanner(QObject *parent = nullptr);

    /// Text of the first QR code in a viewfinder frame, or "".
    Q_INVOKABLE QString decodeImage(const QImage &image) const;

private:
    /// Text of the first QR code quirc finds in the image, or "".
    static QString decode(const QImage &colour);
};

#endif // QRSCANNER_H
