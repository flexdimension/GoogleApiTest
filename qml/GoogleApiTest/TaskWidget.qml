// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1

Rectangle {
    x: model.indent * 20
    width: parent.width - x
    height: 40
    border.color: "black"
    color: textTitle.isUpdated() ? "#FFFFDD" : "#FFDDAA"
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

        onTextChanged:
            console.log("text changed:" + text);

        Keys.onReturnPressed: {
            console.log("enter pressed");
            if(cursorPosition == 0) {
                parent.insertTask(model.index);
                //parent.updateTask(model.idx + 1, model.id, text);
            }
            else if(cursorPosition == text.length) {
                parent.insertTask(model.index + 1);
                //parent.updateTask(model.idx, model.id, text);
                parent.activateNext();
            }
            else {
                parent.modifyTask();
            }
        }

        onFocusChanged: {
            console.log("focused:" + model.index);
            parent.onActivated(focus);

        }

        function isUpdated() {
            return originalText == text;
        }
    }

    Rectangle {

    }

    function onActivated(focus) {
        if(focus == true) {
            ListView.view.currentIndex = model.index;
        }else {
            if(!textTitle.isUpdated())
                modifyTask();
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

    function activateNext() {

        console.log("current : " +  ListView.view.currentIndex);
        ListView.view.currentIndex = model.index + 1;
        ListView.view.currentItem.activateHead();
        console.log("current : " +  ListView.view.currentIndex);

    }
}
