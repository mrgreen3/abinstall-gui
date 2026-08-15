import QtQuick
import QtQuick.Layouts
import "../"

RowLayout {
    spacing: 0

    Repeater {
        model: InstallController.stepCount

        delegate: RowLayout {
            required property int index
            spacing: 0

            Rectangle {
                id: dot
                readonly property int status: InstallController.stepStatus[index]
                width: 32
                height: 32
                radius: 16
                color: status === InstallController.statusSuccess ? "#4caf7d"
                       : status === InstallController.statusError ? "#e05c5c"
                       : status === InstallController.statusRunning ? "#7367e0"
                       : index === InstallController.currentStep ? "#414258" : "#2a2b3d"
                border.width: index === InstallController.currentStep ? 2 : 0
                border.color: "#a9b1d6"

                Text {
                    anchors.centerIn: parent
                    text: dot.status === InstallController.statusSuccess ? "✓"
                          : dot.status === InstallController.statusError ? "!"
                          : (index + 1).toString()
                    color: "#ffffff"
                    font.pixelSize: 14
                    font.bold: true
                }
            }

            Text {
                text: InstallController.stepLabels[index]
                color: index === InstallController.currentStep ? "#ffffff" : "#a9b1d6"
                font.pixelSize: 12
                leftPadding: 8
                rightPadding: 8
            }

            Rectangle {
                visible: index < InstallController.stepCount - 1
                Layout.fillWidth: true
                Layout.preferredWidth: 40
                height: 2
                color: "#414258"
            }
        }
    }
}
