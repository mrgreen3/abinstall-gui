import QtQuick
import QtQuick.Layouts

// Lightweight modal confirmation overlay. Intended for destructive actions
// (erasing a disk) — parent is responsible for anchoring this fill-parent
// and toggling `open`.
Rectangle {
    id: root
    property string message: ""
    property string confirmText: "Confirm"
    property bool open: false
    signal accepted()
    signal rejected()

    anchors.fill: parent
    visible: open
    color: "#000000cc"
    z: 100

    MouseArea {
        anchors.fill: parent
        onClicked: root.rejected()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 420
        implicitHeight: content.implicitHeight + 40
        radius: 10
        color: "#1f2033"
        border.color: "#e05c5c"
        border.width: 1

        MouseArea { anchors.fill: parent } // swallow clicks so the overlay doesn't dismiss

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            Text {
                text: root.message
                color: "#ffffff"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                font.pixelSize: 14
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item { Layout.fillWidth: true }

                ABButton {
                    text: "Cancel"
                    onClicked: root.rejected()
                }
                ABButton {
                    text: root.confirmText
                    primary: true
                    onClicked: root.accepted()
                }
            }
        }
    }
}
