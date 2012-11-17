// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1

Rectangle {
    width: 100
    height: 62
    gradient: Gradient {
        GradientStop {
            position: 0
            color: "#ffffff"
        }

        GradientStop {
            position: 0.040
            color: "#b2bcc2"
        }

        GradientStop {
            position: 0.950
            color: "#626c73"
        }

        GradientStop {
            position: 1
            color: "#1b262b"
        }
    }


}
