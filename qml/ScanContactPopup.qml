import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtMultimedia 5.12

// Full-screen scanner for MeshCore contact codes (see ContactQrDialog.qml):
// the viewfinder is read twice a second until a frame holds a contact link,
// which is then stored on the node. A link sent as text can be pasted instead.
Popup {
    id: scan
    property var app                 // main.qml root (sizes, colours)

    readonly property int scanIntervalMs: 500
    readonly property int closeDelayMs: 1200
    property string statusText: ""
    property string lastCode: ""     // handled once, not on every still

    parent: Overlay.overlay
    x: 0
    y: 0
    width: parent.width
    height: parent.height
    modal: true
    padding: app.spacingUnit
    background: Rectangle { color: app.colorBackground }

    onOpened: {
        statusText = qsTr("Hold a MeshCore contact code still in front of the camera.")
        lastCode = ""
        linkField.text = ""
    }

    function addFromLink(link) {
        var error = BluetoothManager.addContactFromLink(link)
        if (error.length) {
            statusText = error
            return
        }
        statusText = qsTr("Contact added.")
        closeTimer.start()
    }

    Timer {
        id: closeTimer
        interval: scan.closeDelayMs
        onTriggered: scan.close()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: app.spacingUnit

        AppLabel {
            text: qsTr("Scan contact")
            font.bold: true
            font.pixelSize: app.fontTitle
        }

        // Created only while the scanner is open, so the camera is released
        // as soon as it closes.
        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: scan.opened
            sourceComponent: cameraView
        }

        AppLabel {
            text: scan.statusText
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: app.spacingUnit
            AppField {
                id: linkField
                Layout.fillWidth: true
                placeholderText: qsTr("or paste a meshcore:// link")
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
            }
            Button {
                text: qsTr("Add")
                enabled: linkField.text.trim().length > 0
                onClicked: scan.addFromLink(linkField.text)
            }
        }

        Button {
            text: qsTr("Close")
            Layout.alignment: Qt.AlignHCenter
            onClicked: scan.close()
        }
    }

    function handleFrame(image) {
        var code = QrScanner.decodeImage(image)
        if (code.length && code !== lastCode) {
            lastCode = code
            addFromLink(code)
        }
    }

    Component {
        id: cameraView
        Item {
            Camera {
                id: camera
                captureMode: Camera.CaptureViewfinder
                // Macro: a code is held close to the phone. Continuous and
                // auto focus did not get it sharp on a Poco X3 Pro.
                focus.focusMode: Camera.FocusMacro
                onError: scan.statusText = errorString
            }
            VideoOutput {
                id: viewfinder
                anchors.fill: parent
                source: camera
                autoOrientation: true
                fillMode: VideoOutput.PreserveAspectCrop
            }
            Timer {
                interval: scan.scanIntervalMs
                repeat: true
                running: camera.cameraStatus === Camera.ActiveStatus && !closeTimer.running
                onTriggered: viewfinder.grabToImage(function(result) {
                    scan.handleFrame(result.image)
                })
            }
        }
    }
}
