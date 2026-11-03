import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

/**
 * Repeaters in direct radio range of the connected node, like "Discover
 * nearby" in the Android/iOS MeshCore apps. The node sends a discover
 * request zero-hop; each repeater that hears it answers with the signal
 * strength in both directions. Tapping a known repeater opens its admin page.
 */
Item {
    id: nearby

    property var app                 // main.qml root (colours)
    property var list                // ContactList (opens the admin page)

    signal backRequested()

    readonly property real gu: gridUnitPx > 0 ? gridUnitPx : 10
    readonly property int fontBody: Math.round(gu * 1.6)
    readonly property int fontSecondary: Math.round(gu * 1.3)
    readonly property int spacingUnit: Math.round(gu * 1.0)

    property string errorText: ""
    property bool searchedOnce: false

    function search() {
        errorText = ""
        if (BluetoothManager.discoverNearbyRepeaters())
            searchedOnce = true
    }

    function snrText(snr) {
        return (snr > 0 ? "+" : "") + snr.toFixed(1) + " dB"
    }

    Component.onCompleted: search()

    Connections {
        target: BluetoothManager
        // e.g. firmware older than v8, which does not know the request.
        onSendFailed: if (BluetoothManager.nearbySearching) nearby.errorText = reason
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: nearby.spacingUnit

        RowLayout {
            Layout.fillWidth: true
            spacing: nearby.spacingUnit
            Button {
                text: qsTr("‹ Contacts")
                onClicked: nearby.backRequested()
            }
            AppLabel {
                Layout.fillWidth: true
                text: qsTr("Nearby repeaters")
                font.bold: true
                font.pixelSize: nearby.fontBody
                elide: Text.ElideRight
            }
            Button {
                text: qsTr("Search")
                enabled: BluetoothManager.sessionReady && !BluetoothManager.nearbySearching
                onClicked: nearby.search()
            }
        }

        AppLabel {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font.pixelSize: nearby.fontSecondary
            color: nearby.errorText.length ? app.colorError : app.colorSecondaryText
            text: nearby.errorText.length ? nearby.errorText
                  : !BluetoothManager.sessionReady ? qsTr("Connect to your node first")
                  : BluetoothManager.nearbySearching
                    ? qsTr("Searching... repeaters answer within a few seconds")
                    : nearby.searchedOnce
                      ? qsTr("%1 repeater(s) in direct range").arg(BluetoothManager.nearbyRepeaters.length)
                      : ""
        }

        ListView {
            id: resultList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Math.round(nearby.gu * 0.6)
            model: BluetoothManager.nearbyRepeaters

            AppLabel {
                anchors.centerIn: parent
                width: parent.width * 0.85
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                visible: resultList.count === 0 && nearby.searchedOnce
                         && !BluetoothManager.nearbySearching && nearby.errorText.length === 0
                text: qsTr("No repeater answered. Only repeaters your node can hear directly "
                           + "(without hops) show up here.")
                color: app.colorSecondaryText
                font.pixelSize: nearby.fontSecondary
            }

            delegate: Rectangle {
                width: ListView.view.width
                height: Math.round(nearby.gu * 7.5)
                radius: Math.round(nearby.gu * 0.5)
                color: tap.pressed && modelData.known ? app.colorSurfacePressed : app.colorSurface
                border.color: "#d32f2f"      // repeater colour, as in the contact list
                border.width: 2

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Math.round(nearby.gu * 0.8)
                    spacing: 0
                    AppLabel {
                        Layout.fillWidth: true
                        text: modelData.known ? modelData.name
                                              : qsTr("Unknown repeater (%1)").arg(modelData.keyPrefix)
                        font.bold: true
                        font.pixelSize: nearby.fontBody
                        elide: Text.ElideRight
                    }
                    AppLabel {
                        Layout.fillWidth: true
                        // ↓ how our node hears it, ↑ how it hears our node.
                        text: qsTr("↓ SNR %1 · RSSI %2 dBm  ·  ↑ SNR %3")
                              .arg(nearby.snrText(modelData.snrHere)).arg(modelData.rssi)
                              .arg(nearby.snrText(modelData.snrThere))
                              + (modelData.known ? "" : "  ·  " + qsTr("not in contacts yet"))
                        color: modelData.known ? app.colorSecondaryText : app.colorWarning
                        font.pixelSize: nearby.fontSecondary
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: tap
                    anchors.fill: parent
                    enabled: modelData.known
                    onClicked: nearby.list.openAdmin(modelData.keyHex, modelData.name, "repeater")
                }
            }
        }
    }
}
