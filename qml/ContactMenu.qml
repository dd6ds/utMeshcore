import QtQuick 2.12
import QtQuick.Controls 2.12

// Long-press menu of a contact row, with every action for that contact.
Menu {
    id: menu
    property var list                // ContactList (open chat/admin, delete)

    property string keyHex: ""
    property string contactName: ""
    property string contactType: ""
    property bool favorite: false
    property bool onNode: true
    property int hops: -1

    // contact = the row's model data; x/y = press position inside item.
    function show(contact, item, x, y) {
        keyHex = contact.publicKey
        contactName = contact.name
        contactType = contact.type
        favorite = contact.isFavorite
        onNode = contact.onNode
        hops = contact.hops
        var p = item.mapToItem(list, x, y)
        popup(list, p.x, p.y)
    }

    MenuItem {
        text: qsTr("Send message")
        // Direct messages go to companions; repeaters take CLI commands.
        visible: menu.contactType === "chat"
        height: visible ? implicitHeight : 0
        onTriggered: menu.list.openChat(menu.keyHex, menu.contactName)
    }
    MenuItem {
        text: qsTr("Manage")
        visible: menu.contactType === "repeater" || menu.contactType === "room"
        height: visible ? implicitHeight : 0
        onTriggered: menu.list.openAdmin(menu.keyHex, menu.contactName, menu.contactType)
    }
    MenuItem {
        text: menu.favorite ? qsTr("Remove from favourites") : qsTr("Add to favourites")
        onTriggered: BluetoothManager.contactsModel.toggleFavorite(menu.keyHex)
    }
    // Forget the stored route (e.g. "direct" when it should go via a
    // repeater): the next message is flooded and the route is learned anew.
    MenuItem {
        text: qsTr("Reset path")
        visible: menu.onNode && menu.hops >= 0
        height: visible ? implicitHeight : 0
        onTriggered: BluetoothManager.resetContactPath(menu.keyHex)
    }
    // The node's contact table is limited (e.g. 350 entries); these
    // manage what is stored there.
    MenuItem {
        text: qsTr("Save to node")
        visible: !menu.onNode
        height: visible ? implicitHeight : 0
        onTriggered: BluetoothManager.saveContactToNode(menu.keyHex)
    }
    MenuItem {
        text: qsTr("Delete contact")
        onTriggered: menu.list.confirmDelete([menu.keyHex], menu.contactName)
    }
}
