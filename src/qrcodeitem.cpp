// QR code element for QML; the encoding itself is the qrcodegen library.

#include "qrcodeitem.h"

#include <QDebug>
#include <QPainter>
#include <QtGlobal>

#include "qrcodegen/qrcodegen.hpp"

QrCodeItem::QrCodeItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setAntialiasing(false);      // module edges must stay sharp
}

void QrCodeItem::setText(const QString &text)
{
    if (text == m_text)
        return;
    m_text = text;
    m_size = 0;
    m_modules.clear();

    if (!text.isEmpty()) {
        try {
            // Medium error correction, like the MeshCore app's own codes.
            const qrcodegen::QrCode qr = qrcodegen::QrCode::encodeText(
                        text.toUtf8().constData(), qrcodegen::QrCode::Ecc::MEDIUM);
            m_size = qr.getSize();
            m_modules.resize(m_size * m_size);
            for (int y = 0; y < m_size; ++y) {
                for (int x = 0; x < m_size; ++x)
                    m_modules[y * m_size + x] = qr.getModule(x, y);
            }
        } catch (const qrcodegen::data_too_long &) {
            qWarning() << "QrCodeItem: text too long for a QR code";
            m_size = 0;
        }
    }
    emit textChanged();
    update();
}

void QrCodeItem::paint(QPainter *painter)
{
    painter->fillRect(boundingRect(), Qt::white);
    if (m_size == 0)
        return;

    // Whole pixels per module, centred, so every module has the same size.
    const int total = m_size + 2 * kQuietZoneModules;
    const int module = qMax(1, int(qMin(width(), height())) / total);
    const int side = module * m_size;
    const int left = (int(width()) - side) / 2;
    const int top = (int(height()) - side) / 2;

    for (int y = 0; y < m_size; ++y) {
        for (int x = 0; x < m_size; ++x) {
            if (m_modules.at(y * m_size + x))
                painter->fillRect(left + x * module, top + y * module, module, module,
                                  Qt::black);
        }
    }
}
