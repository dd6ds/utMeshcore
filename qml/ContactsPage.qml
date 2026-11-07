import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

// Fifth page: the node's contacts (see ContactList.qml).
Page {
    id: page
    property var app                 // main.qml root (message model + DM helpers)

    title: qsTr("Contacts")

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: app.spacingUnit
        spacing: app.spacingUnit

        ContactList {
            Layout.fillWidth: true
            Layout.fillHeight: true
            app: page.app
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: app.spacingUnit
            Button {
                text: qsTr("Back")
                Layout.preferredHeight: Math.round(app.gu * 5)
                onClicked: app.showPage(app.pageConnection)
            }
            Button {
                text: qsTr("Scan contact")
                enabled: BluetoothManager.sessionReady
                Layout.preferredHeight: Math.round(app.gu * 5)
                onClicked: scanPopup.open()
            }
        }
    }

    ScanContactPopup {
        id: scanPopup
        app: page.app
    }
}
