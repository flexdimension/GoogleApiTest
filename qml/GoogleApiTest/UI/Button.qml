// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1


BasicWidget { id: widget
    width: 50
    height: 30
    radius: 5
    clip: true
    color: "darkgray"

    property alias text: textBox.text

    signal clicked

    state: "normal"

    states: [
        State {
            name: "normal"
            PropertyChanges {
                target: buttonBody; x: 0; y: 0
            }
      },
        State {
            name: "pressed"

            PropertyChanges {
                target: buttonBody; x: 2; y: 2
            }
        }
    ]

    Rectangle { id:buttonBody
        width: parent.width
        height: parent.height

        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#ffffff"
            }

            GradientStop {
                position: 0.140
                color: "#aaaaff"
            }

            GradientStop {
                position: 0.840
                color: "#bcc0f7"
            }

            GradientStop {
                position: 1
                color: "#484e6b"
            }
        }

        Text { id: textBox
            text: qsTr("Hello World")
            anchors.centerIn: parent
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            //Qt.quit();
            widget.clicked(mouse);
        }

        onPressed: {
            widget.state = "pressed";
        }

        onReleased: {
            widget.state = "normal";
        }
    }
}
