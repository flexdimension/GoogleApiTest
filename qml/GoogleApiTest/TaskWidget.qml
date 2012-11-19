// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1

Rectangle { id: taskWidget
    width: parent.width
    height: 40
    color: "transparent"

    state: "initial"

    onStateChanged: {
        console.log("taskWidget state:" + state);
    }

    Component.onCompleted: {
        state = "normal";
    }

    states: [
        State{
            name: "poping"
        },
        State{
            name: "normal"
        },
        State{
            name: "initial"
        }

    ]

    transitions: [
        Transition{
            from: "normal"
            to: "poping"
            SequentialAnimation {
                NumberAnimation{ target: contentBox; property: "y"; to: -20; duration: 100}
                NumberAnimation{ target: contentBox; property: "y"; to: 0;  duration: 100}
                PropertyAction{ target: taskWidget; property: "state"; value: "normal"}
            }
        }

    ]

    Rectangle { id: contentBox
        x: model.indent * 20
        width: parent.width - x
        height: 40
        border.color: "black"
        color: !textTitle.isModifying() ? "#FFFFDD" : "#FFDDAA"
        radius: 4

        Text {
            x: 10
            y: 10
            width: 20
            height: parent.height - 20
            text: model.index
        }

        TextInput { id: textTitle
            x: 40
            y: 10
            width: parent.width - 40
            height: parent.height - 20
            text: model.title
            property string originalText: model.title

            Text { id: noTitle
                text: "No Title"
                color: "gray"
                visible: textTitle.text == ""

                Rectangle {
                    anchors.fill: parent
                    color: "darkgray"
                    opacity: 0.5
                    visible: textTitle.focus ? true : false
                }
            }

            onTextChanged:
                console.log("text changed:" + text);

            onOriginalTextChanged: {
                console.log("original text changed");
                pop();
            }

            Keys.onReturnPressed: {
                console.log("enter pressed");
                if(cursorPosition == 0) {
                    taskWidget.insertTask(model.index);
                    //parent.updateTask(model.idx + 1, model.id, text);
                }
                else if(cursorPosition == text.length) {
                    taskWidget.insertTask(model.index + 1);
                    //parent.updateTask(model.idx, model.id, text);
                    taskWidget.activateNext();
                }
                else {
                    taskWidget.modifyTask();
                }
            }

            onFocusChanged: {
                console.log("focused:" + model.index + "-" + focus);
                taskWidget.onActivated(focus);
                if(focus == false) {
                    if(originalText != text) {
                        taskWidget.modifyTask();
                    }
                }

            }

            function isModifying() {
                return originalText != text;
            }
        }

        Rectangle {

        }
    }
    function onActivated(focus) {
        if(focus == true) {
            ListView.view.currentIndex = model.index;
            textTitle.focus = true;
            pop();
        }
    }

    function activateHead() {
        textTitle.focus = true;
        textTitle.cursorPosition = 0;
    }

    function modifyTask() {
        ListView.view.model.modifyTask(model.index, textTitle.text);
    }

    function insertTask(idx) {
        ListView.view.model.insertTask(idx)
    }

    function removeTask() {
        ListView.view.model.removeTask(model.index);
    }

    function activateNext() {

        console.log("current : " +  ListView.view.currentIndex);
        ListView.view.currentIndex = model.index + 1;
        ListView.view.currentItem.activateHead();
        console.log("current : " +  ListView.view.currentIndex);

    }

    function pop(delay) {
        state = "poping";
    }
}
