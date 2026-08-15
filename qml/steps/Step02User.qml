import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../"
import "../components"

ColumnLayout {
    id: root
    spacing: 16

    readonly property int step: InstallController.stepUser
    readonly property int status: InstallController.stepStatus[step]
    property string password2: ""

    readonly property bool usernameValid: /^[a-z_][a-z0-9_-]*$/.test(InstallController.username)
    readonly property bool passwordsMatch: InstallController.password.length > 0 && InstallController.password === password2

    Text {
        text: "Create your user account"
        color: "#ffffff"
        font.pixelSize: 18
        font.bold: true
    }
    Text {
        text: "This account is created on the target system with sudo (wheel) access."
        color: "#a9b1d6"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    ColumnLayout {
        visible: status === InstallController.statusIdle
        spacing: 10
        Layout.fillWidth: true

        Text { text: "Username"; color: "#a9b1d6"; font.pixelSize: 12 }
        TextField {
            Layout.fillWidth: true
            text: InstallController.username
            placeholderText: "e.g. kev"
            onTextChanged: InstallController.username = text
        }
        Text {
            text: "Lowercase letters, digits, - or _. Cannot start with a digit."
            color: root.usernameValid || InstallController.username.length === 0 ? "#6b7089" : "#e05c5c"
            font.pixelSize: 11
        }

        Text { text: "Password"; color: "#a9b1d6"; font.pixelSize: 12 }
        TextField {
            Layout.fillWidth: true
            echoMode: TextInput.Password
            text: InstallController.password
            onTextChanged: InstallController.password = text
        }

        Text { text: "Confirm password"; color: "#a9b1d6"; font.pixelSize: 12 }
        TextField {
            Layout.fillWidth: true
            echoMode: TextInput.Password
            text: root.password2
            onTextChanged: root.password2 = text
        }
        Text {
            text: "Passwords do not match"
            color: "#e05c5c"
            font.pixelSize: 11
            visible: root.password2.length > 0 && !root.passwordsMatch
        }
    }

    ABButton {
        text: "Create User"
        primary: true
        visible: status === InstallController.statusIdle
        enabled: root.usernameValid && root.passwordsMatch
        onClicked: InstallController.runStep(root.step)
    }

    ABProgressView {
        Layout.fillWidth: true
        step: root.step
    }

    Item { Layout.fillHeight: true }
}
