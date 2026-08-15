import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../"
import "../components"

Item {
    id: root

    readonly property int step: InstallController.stepPartition
    readonly property int status: InstallController.stepStatus[step]
    property var devices: []

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        Text {
            text: "Select a disk to erase and partition"
            color: "#ffffff"
            font.pixelSize: 18
            font.bold: true
        }
        Text {
            text: "All data on the selected disk will be permanently deleted. An EFI/swap/root layout is created automatically, with swap sized from installed RAM."
            color: "#a9b1d6"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            visible: root.status === InstallController.statusIdle
            model: root.devices
            clip: true
            spacing: 6

            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: 48
                radius: 6
                color: InstallController.selectedDevice === modelData.path ? "#7367e0" : "#2a2b3d"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    Text { text: modelData.path; color: "#ffffff"; font.bold: true; Layout.preferredWidth: 140 }
                    Text { text: modelData.size; color: "#a9b1d6"; Layout.preferredWidth: 80 }
                    Text { text: modelData.model; color: "#a9b1d6"; Layout.fillWidth: true; elide: Text.ElideRight }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: InstallController.selectedDevice = modelData.path
                }
            }
        }

        ABButton {
            text: "Erase and Partition " + InstallController.selectedDevice
            primary: true
            visible: root.status === InstallController.statusIdle
            enabled: InstallController.selectedDevice.length > 0
            onClicked: confirmDialog.open = true
        }

        ABProgressView {
            Layout.fillWidth: true
            step: root.step
        }

        Item { Layout.fillHeight: true }
    }

    ABConfirmDialog {
        id: confirmDialog
        message: "This will PERMANENTLY ERASE all data on " + InstallController.selectedDevice + ". This cannot be undone. Continue?"
        confirmText: "Erase Disk"
        onAccepted: {
            open = false;
            InstallController.runStep(root.step);
        }
        onRejected: open = false
    }

    Process {
        command: ["lsblk", "-d", "-b", "-n", "-o", "PATH,SIZE,MODEL,TYPE"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                var list = [];
                var lines = text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.length === 0) continue;
                    var parts = line.split(/\s+/);
                    if (parts.length < 4) continue;
                    var path = parts[0], sizeBytes = parts[1], type = parts[parts.length - 1];
                    var model = parts.slice(2, parts.length - 1).join(" ");
                    if (type !== "disk") continue;
                    if (!/^\/dev\/(sd|hd|vd|nvme|mmcblk)/.test(path)) continue;
                    var gib = (parseInt(sizeBytes, 10) / (1024 * 1024 * 1024)).toFixed(1);
                    list.push({path: path, size: gib + " GiB", model: model || "Unknown"});
                }
                root.devices = list;
            }
        }
    }
}
