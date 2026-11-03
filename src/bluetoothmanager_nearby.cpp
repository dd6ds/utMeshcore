// BluetoothManager, part 3: discovering repeaters in radio range.
//
// Works like "Discover nearby" in the Android/iOS MeshCore apps: the node
// sends a NODE_DISCOVER_REQ control packet zero-hop, and every repeater that
// hears it answers after a random delay with its public key and the SNR at
// which it heard us. Needs companion firmware v8 or newer; older firmware
// answers the command with an error, which the page shows.

#include "bluetoothmanager.h"

#include <QDebug>
#include <QRandomGenerator>

namespace {

constexpr quint8 kAdvTypeRepeater = 2;   // ADV_TYPE_REPEATER
// Repeaters answer after a random delay (their retransmit delay x4), so the
// window has to be generous.
constexpr int kAnswerWindowMs = 12000;

} // namespace

void BluetoothManager::setupNearbySearch()
{
    m_nearbyTimer.setSingleShot(true);
    m_nearbyTimer.setInterval(kAnswerWindowMs);
    connect(&m_nearbyTimer, &QTimer::timeout, this, [this]() {
        m_nearbySearching = false;
        qDebug() << "BluetoothManager: nearby search done," << m_nearbyRepeaters.size()
                 << "repeater(s)";
        emit nearbyChanged();
    });
}

bool BluetoothManager::discoverNearbyRepeaters()
{
    if (!checkSession())
        return false;
    // A fresh tag per search, so late answers to an earlier one are ignored.
    m_nearbyTag = QRandomGenerator::global()->generate() | 1u;
    m_nearbyRepeaters.clear();
    m_nearbySearching = true;
    m_nearbyTimer.start();
    emit nearbyChanged();
    m_companion.sendNodeDiscover(m_nearbyTag, quint8(1u << kAdvTypeRepeater));
    return true;
}

void BluetoothManager::onNodeDiscovered(quint32 tag, quint8 nodeType,
                                        const QByteArray &publicKey,
                                        double snrHere, double snrThere, int rssi)
{
    if (tag != m_nearbyTag || nodeType != kAdvTypeRepeater)
        return;
    const QString keyHex = QString::fromLatin1(publicKey.toHex());
    const MeshContact *c = m_contacts.findByKeyHex(keyHex);

    const QVariantMap entry{
        { QStringLiteral("keyHex"), keyHex },
        { QStringLiteral("keyPrefix"), keyHex.left(8) },
        { QStringLiteral("name"), c ? c->name : QString() },
        { QStringLiteral("known"), c != nullptr },
        { QStringLiteral("snrHere"), snrHere },
        { QStringLiteral("snrThere"), snrThere },
        { QStringLiteral("rssi"), rssi }
    };

    // One row per repeater (an answer can arrive twice), strongest first.
    for (int i = 0; i < m_nearbyRepeaters.size(); ++i) {
        if (m_nearbyRepeaters.at(i).toMap().value(QStringLiteral("keyHex")) == keyHex) {
            m_nearbyRepeaters.removeAt(i);
            break;
        }
    }
    int pos = 0;
    while (pos < m_nearbyRepeaters.size()
           && m_nearbyRepeaters.at(pos).toMap().value(QStringLiteral("snrHere")).toDouble()
                  >= snrHere)
        ++pos;
    m_nearbyRepeaters.insert(pos, entry);
    emit nearbyChanged();
}
