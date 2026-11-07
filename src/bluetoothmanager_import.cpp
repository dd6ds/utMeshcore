// BluetoothManager, part 4: adding a contact from a contact link.
//
// The MeshCore apps share contacts as QR codes holding
//   meshcore://contact/add?name=<name>&public_key=<64 hex>&type=<1..4>
// (docs.meshcore.io/qr_codes). The link carries no route, so the contact is
// stored without one and the first message to it is flooded.

#include "bluetoothmanager.h"

#include <QDebug>
#include <QUrl>
#include <QUrlQuery>

namespace {

constexpr int kPublicKeyHexLength = 64;
constexpr int kTypeCompanion = 1;
constexpr int kTypeSensor = 4;

// Query value with '+' read as a space, as in the documented example link
// ("name=Example+Contact"); a literal '+' would be sent as %2B.
QString queryValue(const QUrlQuery &query, const QString &key)
{
    QString raw = query.queryItemValue(key, QUrl::FullyEncoded);
    raw.replace(QLatin1Char('+'), QLatin1Char(' '));
    return QUrl::fromPercentEncoding(raw.toUtf8());
}

} // namespace

QString BluetoothManager::addContactFromLink(const QString &link)
{
    if (!m_sessionReady)
        return tr("Connect to your node first");

    const QUrl url(link.trimmed());
    if (url.scheme() != QLatin1String("meshcore") || url.host() != QLatin1String("contact")
            || url.path() != QLatin1String("/add"))
        return tr("This is not a MeshCore contact code");

    const QUrlQuery query(url);
    const QString keyHex = queryValue(query, QStringLiteral("public_key")).toLower();
    const QByteArray key = QByteArray::fromHex(keyHex.toLatin1());
    const QString name = queryValue(query, QStringLiteral("name")).trimmed();
    bool typeOk = false;
    const int type = queryValue(query, QStringLiteral("type")).toInt(&typeOk);
    if (keyHex.size() != kPublicKeyHexLength || key.toHex() != keyHex.toLatin1()
            || name.isEmpty())
        return tr("The contact code is incomplete");

    if (key == m_nodePublicKey)
        return tr("This is your own node");

    const QString tableFull = tr("Your node's contact list is full");
    const MeshContact *known = m_contacts.findByKeyHex(keyHex);
    if (known && known->onNode)
        return tr("%1 is already in your contacts").arg(known->name);
    // Heard from an advert but not stored: keep its route and position.
    if (known)
        return storeContactOnNode(*known) ? QString() : tableFull;

    MeshContact contact;
    contact.publicKey = key;
    contact.type = quint8(typeOk && type >= kTypeCompanion && type <= kTypeSensor
                          ? type : kTypeCompanion);
    contact.name = name;
    contact.outPathLen = -1;             // no route yet: flood
    contact.onNode = false;              // storeContactOnNode() sets it
    m_contacts.upsert(contact);
    qDebug() << "BluetoothManager: adding contact from link:" << name;
    return storeContactOnNode(contact) ? QString() : tableFull;
}
