import QtQuick

Rectangle {
    id: root
    property alias text: label.text
    property bool primary: false
    signal clicked()

    implicitWidth: Math.max(96, label.implicitWidth + 32)
    implicitHeight: 40
    radius: 6
    color: !enabled ? "#2a2b3d"
           : primary ? (mouse.pressed ? "#6d5edb" : mouse.containsMouse ? "#7f70f0" : "#7367e0")
           : (mouse.pressed ? "#33344a" : mouse.containsMouse ? "#3a3b54" : "#2f3042")
    border.color: primary ? "#7367e0" : "#414258"
    border.width: 1
    opacity: enabled ? 1.0 : 0.5

    Text {
        id: label
        anchors.centerIn: parent
        color: "#ffffff"
        font.pixelSize: 14
        font.bold: root.primary
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.enabled) root.clicked()
    }
}
