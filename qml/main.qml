import QtQuick
import QtQuick.Layouts
import Quickshell
import "components"
import "steps"

FloatingWindow {
    id: window
    title: "ArchBang Installer"
    color: "#1a1b26"
    implicitWidth: 900
    implicitHeight: 640
    minimumSize: Qt.size(760, 560)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        ABStepIndicator {
            Layout.fillWidth: true
        }

        StackLayout {
            id: stepStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: InstallController.currentStep

            Step01Partition {}
            Step02User {}
            Step03Copy {}
            Step04Bootloader {}
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ABButton {
                text: "Back"
                enabled: InstallController.canGoBack()
                onClicked: InstallController.goBack()
            }

            Item { Layout.fillWidth: true }

            Text {
                text: InstallController.stepMessage[InstallController.currentStep]
                color: "#a9b1d6"
                elide: Text.ElideRight
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
            }

            ABButton {
                text: InstallController.currentStep === InstallController.stepCount - 1
                      && InstallController.stepStatus[InstallController.currentStep] === InstallController.statusSuccess
                      ? "Finish" : "Next"
                primary: true
                enabled: InstallController.canGoNext()
                onClicked: {
                    if (InstallController.currentStep === InstallController.stepCount - 1) {
                        Qt.quit();
                    } else {
                        InstallController.goNext();
                    }
                }
            }
        }
    }
}
