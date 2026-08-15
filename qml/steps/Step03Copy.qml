import QtQuick
import QtQuick.Layouts
import "../"
import "../components"

ColumnLayout {
    id: root
    spacing: 16

    readonly property int step: InstallController.stepCopy
    readonly property int status: InstallController.stepStatus[step]

    Text {
        text: "Copy system files"
        color: "#ffffff"
        font.pixelSize: 18
        font.bold: true
    }
    Text {
        text: "Copies the live system to the target disk, writes fstab, rebuilds the initramfs, and creates the account you configured in the previous step."
        color: "#a9b1d6"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    ABButton {
        text: "Start Copy"
        primary: true
        visible: status === InstallController.statusIdle
        onClicked: InstallController.runStep(root.step)
    }

    ABProgressView {
        Layout.fillWidth: true
        step: root.step
    }

    Item { Layout.fillHeight: true }
}
