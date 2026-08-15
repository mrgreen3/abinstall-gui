import QtQuick
import QtQuick.Layouts
import "../"
import "../components"

ColumnLayout {
    id: root
    spacing: 16

    readonly property int step: InstallController.stepBootloader
    readonly property int status: InstallController.stepStatus[step]

    Text {
        text: "Install bootloader"
        color: "#ffffff"
        font.pixelSize: 18
        font.bold: true
    }
    Text {
        text: "Installs and configures GRUB for the mode detected on this machine (UEFI or BIOS)."
        color: "#a9b1d6"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    ABButton {
        text: "Install Bootloader"
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
