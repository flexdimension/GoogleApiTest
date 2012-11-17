// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import QtWebKit 1.0

import "UI"

import "Google.js" as Google

Rectangle { id: main
    width: 800
    height: 600

    signal failedToRefresh

    property string accessToken : ""

    Component.onCompleted: {
        Google.getAccessToken();
    }

    onAccessTokenChanged: {
        console.log("man.accessToken:" + accessToken);
        if(accessToken != "") {
            //taskCategoryModel.pull();
            taskModel.pull();
            connectionState = "online"
        }
    }

    onFailedToRefresh: {
        connectionState = "offline";
    }

    property string connectionState : "unknown";


    Rectangle { id:taskViewFrame
        x: parent.width / 2
        width: parent.width / 2
        height: parent.height
        color: "#BBBBBB"
        clip: true

        Frame { id:topToolbar
            width: parent.width
            height: 50

        }

        ListView { id:taskView
            y:50
            height: parent.height - topToolbar.height - bottomToolbar.height

            model: taskModel
            width: parent.width

            clip: true
            focus: true

            delegate: TaskWidget {
            }

        }

        Frame {id: bottomToolbar
            y: topToolbar.height + taskView.height
            width: parent.width
            height: 50
            Button {
                height: 40
                anchors.centerIn : parent
                text: "New"

                onClicked: {
                    console.log("clicked");
                    taskModel.insertTask(0);
                }
            }
        }
    }

    TaskModel { id: taskModel

    }

    /*
    ListView { id: taskCategoryView
        model: taskCategoryModel
        width: parent.width / 2
        height: parent.height

        delegate:
            Rectangle {
                width: parent.width
                height: 40
                Text {
                    x: 10
                    y: 10
                    text: model.title
                }
            }

    }


    ListModel { id: taskCategoryModel

        property string accessToken

        property variant taskList

        function pull() {
            accessToken = main.accessToken;
            var http = new XMLHttpRequest();
            var baseUrl = "https://www.googleapis.com/tasks/v1";
            var params = "access_token=" + accessToken;
            var url = baseUrl + "/users/@me/lists" + "?" + params;
            console.log("url:" + url);
            http.open("GET", url, true);
            http.onreadystatechange = function() {
                if (http.readyState == XMLHttpRequest.DONE) {
                    var rs = http.responseText;
                    console.log("Json:" + rs);
                    var taskList = getTaskCategory(rs);
                    console.log(taskList[0]["title"]);

                    for(var i = 0; i < taskList.length; i++) {
                        var item = taskList[i];
                        append({"title": item["title"], "id": item["id"], "updated":item["updated"]});
                    }
                }else{
                    print("failed to connect :" + http.readyState);
                }
            }
            http.send();
        }

        function getTaskCategory(text) {
            var iBegin = text.search("items") + 8;
            var headCut = text.substring(iBegin);
            var iEnd = headCut.search("]") + 1;
            var itemList = headCut.substring(0, iEnd);
            console.log(itemList);

            return eval(itemList);

        }
    }
    */
    Component { id:web
        OAuthWebView { id:webView
            x: -parent.width
            y: -parent.height

            onAccessTokenChanged: {
                main.accessToken = accessToken;
                console.log("web view visible is false");
                state = "hidden";
            }

            onRefreshTokenChanged: {
                main.setRefreshToken(refreshToken);
            }

            state: "activated"

            states: [
                State{
                    name:"activated"
                    PropertyChanges {
                        target: webView
                        x: 0
                        y: 0
                        width: parent.width
                        height: parent.height
                    }
                },
                State{
                    name:"hidden"
                    PropertyChanges {
                        target: webView
                        x: -parent.width
                        y: -parent.height

                    }
                }
            ]

            transitions: [
                Transition {
                    NumberAnimation {
                        properties: "x, y, width, height"
                        easing.type: Easing.Linear
                        duration: 300
                    }
                }
            ]
        }
    }
}
