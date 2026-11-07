// QR code reading for the contact scan page (see qrscanner.h).

#include "qrscanner.h"

#include <cstring>

#include "quirc/quirc.h"

QrScanner::QrScanner(QObject *parent)
    : QObject(parent)
{
}

QString QrScanner::decodeImage(const QImage &image) const
{
    return image.isNull() ? QString() : decode(image);
}

QString QrScanner::decode(const QImage &colour)
{
    const QImage image = colour.convertToFormat(QImage::Format_Grayscale8);
    struct quirc *decoder = quirc_new();
    if (!decoder || quirc_resize(decoder, image.width(), image.height()) < 0) {
        quirc_destroy(decoder);
        return QString();
    }
    int width = 0;
    int height = 0;
    uint8_t *buffer = quirc_begin(decoder, &width, &height);
    for (int y = 0; y < height; ++y)
        std::memcpy(buffer + y * width, image.constScanLine(y), size_t(width));
    quirc_end(decoder);

    QString text;
    for (int i = 0; i < quirc_count(decoder) && text.isEmpty(); ++i) {
        struct quirc_code code;
        struct quirc_data data;
        quirc_extract(decoder, i, &code);
        quirc_decode_error_t result = quirc_decode(&code, &data);
        // A mirrored image (front camera) fails the ECC check; flip and retry.
        if (result == QUIRC_ERROR_DATA_ECC) {
            quirc_flip(&code);
            result = quirc_decode(&code, &data);
        }
        if (result == QUIRC_SUCCESS)
            text = QString::fromUtf8(reinterpret_cast<const char *>(data.payload),
                                     data.payload_len);
    }
    quirc_destroy(decoder);
    return text;
}
