import QtQuick 2.12
import QtQuick.Controls 2.12
import utMeshcore 1.0

// A contact as a QR code in the MeshCore app's format, so another phone can
// add it by scanning instead of typing the 64-character key. Used for the own
// node ("My contact code") and from a contact's long-press menu.
Dialog {
    id: dialog
    property var app                 // main.qml root (sizes)

    property string contactName: ""
    property string keyHex: ""
    property int nodeType: typeCompanion

    // Contact types of the meshcore://contact/add link.
    readonly property int typeCompanion: 1
    readonly property int typeRepeater: 2
    readonly property int typeRoom: 3
    readonly property int typeSensor: 4

    // type: the contact model's type string ("chat", "repeater", ...).
    function showFor(name, key, type) {
        contactName = name
        keyHex = key
        nodeType = type === "repeater" ? typeRepeater
                 : type === "room" ? typeRoom
                 : type === "sensor" ? typeSensor : typeCompanion
        open()
    }

    readonly property string contactLink:
        "meshcore://contact/add?name=" + encodeURIComponent(contactName)
        + "&public_key=" + keyHex + "&type=" + nodeType

    parent: Overlay.overlay
    modal: true
    width: Math.min(parent.width - 2 * app.spacingUnit, Math.round(app.gu * 40))
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    title: contactName
    standardButtons: Dialog.Close

    contentItem: Column {
        spacing: app.spacingUnit

        QrCode {
            text: dialog.contactLink
            width: parent.width
            height: width
        }

        AppLabel {
            width: parent.width
            text: qsTr("Scan with the MeshCore app to add this contact.")
            font.pixelSize: app.fontSecondary
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }

        AppLabel {
            width: parent.width
            text: dialog.keyHex
            color: app.colorSecondaryText
            font.pixelSize: app.fontSecondary
            font.family: "monospace"
            wrapMode: Text.WrapAnywhere
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
