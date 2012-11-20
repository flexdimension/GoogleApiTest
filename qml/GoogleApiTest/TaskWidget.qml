// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1

Rectangle { id: taskWidget
    width: parent.width
    height: 40
    color: "transparent"

    state: "initial"


    ListView.onRemove: SequentialAnimation {
        PropertyAction { target: taskWidget; property: "ListView.delayRemove"; value: true }
        NumberAnimation { target: taskWidget; property: "height"; to: 0; duration: 250; easing.type: Easing.InOutQuad }
        PropertyAction { target: taskWidget; property: "ListView.delayRemove"; value: false }
    }


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
        },
        State{
            name: "removing"
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
            text: model.index == -1 ? "" : model.index
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
                color: "#CCCCAA"
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

            Keys.onPressed: {
                console.log("Key pressed :" + event.key);
                if(event.key == Qt.Key_Backspace && text.length == 0 && model.index != 0) {
                    taskWidget.removeTask();
                }
                else if(event.key == Qt.Key_Tab) {
                    console.log("Tab pressed");
                    taskWidget.increaseIndent();
                }
                else if(event.key == Qt.Key_Backtab) {
                    console.log("^Tab pressed");
                    taskWidget.decreaseIndent();
                }
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
                    taskWidget.modifyTitle();
                }
            }

            onFocusChanged: {
                console.log("focused:" + model.index + "-" + focus);
                taskWidget.onActivated(focus);
                if(focus == false) {
                    if(originalText != text) {
                        taskWidget.modifyTitle();
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
        }
    }

    function setCursorToHead() {
        textTitle.focus = true;
        textTitle.cursorPosition = 0;
    }

    function setCursorToTail() {
        textTitle.focus = true;
        textTitle.cursorPosition = textTitle.text.length;
    }

    function modifyTitle() {
        console.log("TaskWidget.modifyTask : " + model.index);
        if(model.index == -1)
            return;
        ListView.view.model.modifyTitle(model.index, textTitle.text);
    }

    function insertTask(idx) {
        ListView.view.model.insertTask(idx)
    }

    function removeTask() {
        state = "removing";
        var idx = model.index;
        ListView.view.model.removeTask(model.index);
        taskWidget.activatePrevious(idx);
    }

    function activateNext() {
        console.log("current : " +  ListView.view.currentIndex);
        ListView.view.currentIndex = model.index + 1;
        ListView.view.currentItem.setCursorToHead();
        console.log("current : " +  ListView.view.currentIndex);
    }

    function activatePrevious(idx) {
        console.log("current : " +  idx);
        ListView.view.currentIndex = idx - 1;
        console.log("current : " +  idx);
        ListView.view.currentItem.setCursorToTail();
    }

    function pop(delay) {
        state = "poping";
    }

    function increaseIndent() {
        if(model.index != 0 && ListView.view.model.get(model.index -1).indent + 1 != model.indent) {
            ListView.view.model.increaseIndent(model.index);
        }
    }

    function decreaseIndent() {
        if(model.index != 0 && model.indent >= 1) {
            console.log("decrease indent");
            ListView.view.model.decreaseIndent(model.index);
        }
    }
}
