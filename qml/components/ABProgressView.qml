import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../"

// Progress bar + scrolling log for whichever step this is embedded in.
ColumnLayout {
    id: root
    property int step: 0

    readonly property int status: InstallController.stepStatus[step]
    readonly property int progress: InstallController.stepProgress[step]
    readonly property string message: InstallController.stepMessage[step]
    readonly property string log: InstallController.stepLog[step]

    spacing: 10
    visible: status !== InstallController.statusIdle

    Rectangle {
        Layout.fillWidth: true
        height: 8
        radius: 4
        color: "#2a2b3d"

        Rectangle {
            width: parent.width * (root.progress / 100)
            height: parent.height
            radius: 4
            color: root.status === InstallController.statusError ? "#e05c5c" : "#7367e0"
            Behavior on width { NumberAnimation { duration: 150 } }
        }
    }

    Text {
        text: root.message
        color: root.status === InstallController.statusError ? "#e05c5c" : "#a9b1d6"
        font.pixelSize: 13
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: 160
        visible: root.log.length > 0

        TextArea {
            readOnly: true
            text: root.log
            color: "#6b7089"
            font.family: "monospace"
            font.pixelSize: 11
            wrapMode: TextArea.Wrap
            background: Rectangle { color: "#131420"; radius: 4 }

            onTextChanged: cursorPosition = length
        }
    }

    ABButton {
        text: "Retry"
        visible: root.status === InstallController.statusError
        onClicked: InstallController.retryStep(root.step)
    }
}
