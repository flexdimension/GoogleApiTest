// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import QtWebKit 1.0

Rectangle { id: main
    width: 800
    height: 600

    property string accessToken : ""

    onAccessTokenChanged: {
        console.log("man.accessToken:" + accessToken);
        if(accessToken != "") {
            taskCategoryModel.updateData();
            taskModel.updateData();
        }
    }

    Component.onCompleted: {
        getAccessToken();
    }

    function setRefreshToken(newToken) {
        var db = openDatabaseSync("FlexNote", "0.1", "TaskList", 1000000);

        db.transaction(
                    function(tx) {
                        tx.executeSql('CREATE TABLE IF NOT EXISTS Token(name TEXT, token TEXT)');
                        tx.executeSql('DELETE From Token WHERE name = "GoogleTask"');

                        tx.executeSql('INSERT INTO Token VALUES(?, ?)', ['GoogleTask', newToken]);
                        console.log('refresh token is stored in DB');
                    }
        );
        refreshToken = newToken;
    }

    function getAccessToken() {
        //getAccessTokenFromWeb();
        //return;
        var refreshedToken = getRefreshToken();
        if(refreshedToken == "")
            getAccessTokenFromWeb();
        else {
            getAccessTokenFromRefresh();
        }
    }

    function getAccessTokenFromRefresh() {
        var refreshToken = getRefreshToken();
        var http = new XMLHttpRequest();
        var url = "https://accounts.google.com/o/oauth2/token";
        var params = ("client_id=539155836145.apps.googleusercontent.com&" +
                "client_secret=ROxaig4lFam3q_IlTWK846ET&" +
                "refresh_token=" + refreshToken + "&" +
                "grant_type=refresh_token");
        http.open("POST", url, true);
        http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");

        http.onreadystatechange = function() {
            if (http.readyState == XMLHttpRequest.DONE) {
                console.log(http.responseText);
                eval("var rs = " + http.responseText);
                accessToken = rs["access_token"];
            }else{
                print("failed to connect");
            }
        }
        http.send(params);
    }

    function getRefreshToken() {
        var db = openDatabaseSync("FlexNote", "0.1", "TaskList", 1000000);

        var token = "";

        db.transaction(
                    function(tx) {
                        tx.executeSql('CREATE TABLE IF NOT EXISTS Token(name TEXT, token TEXT)');

                        var rs = tx.executeSql('SELECT * FROM Token');

                        if(rs.rows.length > 0) {
                            console.log("refreshed token:" + rs.rows.item(0).token);
                            token = rs.rows.item(0).token;
                        }
                        else {
                            console.log("no refreshed token");
                            //getAccessTokenFromWeb();
                        }
                    }
        );

        return token;
    }

    function getAccessTokenFromWeb() {
        web.createObject(main);
    }

    Rectangle { id:taskViewFrame
        x: parent.width / 2
        width: parent.width / 2
        height: parent.height
        color: "#BBBBBB"
        clip: true
        ListView {

            model: taskModel
            width: parent.width
            height: parent.height

            delegate:
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
                                parent.insertTask(model.index, {"title":"insertTest into head"});
                                //parent.updateTask(model.idx + 1, model.id, text);
                            }
                            else if(cursorPosition == text.length) {
                                parent.insertTask(model.index + 1, {"title":"insertTest into End"});
                                //parent.updateTask(model.idx, model.id, text);
                            }
                            else {
                                parent.updateTask(model.index, model.id, text);
                            }
                        }

                        function isUpdated() {
                            return originalText == text;
                        }
                    }

                    Rectangle {

                    }

                    function updateTask(idx, id, title) {

                        ListView.view.model.updateTask(idx, id, title);
                    }

                    function insertTask(idx, data) {
                        ListView.view.model.insert(idx, data);
                    }
                }

        }
    }
    ListModel { id: taskModel
        property string accessToken
        property string taskListId : "MDg4Mzg4MjQ5ODgzMTA1Nzg1MDE6Nzg1NDk2ODA1OjA"

        function updateData() {
            accessToken = main.accessToken;
            var http = new XMLHttpRequest();
            var baseUrl = "https://www.googleapis.com/tasks/v1";
            var params = "access_token=" + accessToken;
            var url = baseUrl + "/lists/" + taskListId + "/tasks" + "?" + params;
            console.log("url:" + url);
            http.open("GET", url, true);
            http.onreadystatechange = function() {
                if (http.readyState == XMLHttpRequest.DONE) {
                    var rs = http.responseText;
                    console.log("Tasks:" + rs);
                    var taskList = getTaskList(rs);
                    console.log(taskList[0]["title"]);

                    for(var i = 0; i < taskList.length; i++) {
                        var item = taskList[i];
                        append({    "title": item["title"],
                                    "id": item["id"],
                                    "updated":item["updated"],
                                    "notes":item["notes"],
                                    "needPush": false,
                                    "needPull": false,
                                    "parent" : item["parent"],
                                    "indent" : -1});
                    }

                    for(var i = 0; i < count; i++) {
                        if(get(i)["indent"] == -1)
                            setProperty(i, "indent", evalIndent(i));
                        console.log("indent:" + i + ":" + get(i)["indent"]);
                    }

                }else{
                    print("task failed to connect :" + http.readyState);
                }
            }
            http.send();
        }

        function getIdxFromId(curIdx, id) {
            for(var i = curIdx -1; i >= 0; i--) {
                var item = get(i);
                if(item["id"] == id) {
                    if(item["indent"] == -1)
                        setProperty(i, "indent", evalIndent(i));
                    return get(i)["indent"] + 1;
                }
            }
            return -1;
        }

        function evalIndent(idx) {
            var item = get(idx);

            if(item["parent"] == null)
                return 0;

            return getIdxFromId(idx, item["parent"]);
        }

        function getTaskList(text) {
            var iBegin = text.search("items") + 8;
            var headCut = text.substring(iBegin);
            var iEnd = headCut.search("]") + 1;
            var itemList = headCut.substring(0, iEnd);
            console.log(itemList);

            return eval(itemList);
        }

        function updateTask(idx, id, title) {
            console.log("update Item :" + title);
            accessToken = main.accessToken;
            var http = new XMLHttpRequest();
            var baseUrl = "https://www.googleapis.com/tasks/v1";
            var paramToken = "access_token=" + accessToken;
            var url = baseUrl + "/lists/" + taskListId + "/tasks/" + id + "?" + paramToken;
            console.log("url:" + url);
            http.open("PUT", url, true);
            http.setRequestHeader("Content-type", "application/json");
            http.onreadystatechange = function() {
                if (http.readyState == XMLHttpRequest.DONE) {
                    var rs = http.responseText;
                    console.log("Tasks:" + rs);
                    eval("var task = " + rs);
                    console.log(task["title"]);

                    setProperty(idx, "title", task["title"]);
                }else{
                    print("task failed to connect :" + http.readyState);
                }
            }


            var params = '{"id":' + '"' + id + '"' + ',"title":"' + title + '"}';

            console.log("update params: " + params);

            http.send(params);
        }
    }

    ListView {
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

        function updateData() {
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

    Component { id:web
        WebView { id:webView
            x: -parent.width
            y: -parent.height
            //anchors.centerIn: parent.center


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

            property string accessToken
            property string refreshToken

            state: "activated"

            onLoadFinished: {
                console.log("load finished");
                console.log("title:" + title);

                if(title.substring(0, 12) == "Success code") {
                    var code = title.split("=")[1];
                    codeToToken(code);
                }
            }



            onAccessTokenChanged: {
                main.accessToken = accessToken;
                console.log("web view visible is false");
                state = "hidden";
            }

            onRefreshTokenChanged: {
                main.setRefreshToken(refreshToken);
            }

            function codeToToken(code) {
                var http = new XMLHttpRequest();
                var url = "https://accounts.google.com/o/oauth2/token";
                var params = ("code=" + code + "&" +
                        "client_id=539155836145.apps.googleusercontent.com&" +
                        "client_secret=ROxaig4lFam3q_IlTWK846ET&" +
                        "redirect_uri=urn:ietf:wg:oauth:2.0:oob&" +
                        "grant_type=authorization_code");
                http.open("POST", url, true);
                http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");

                http.onreadystatechange = function() {
                    if (http.readyState == XMLHttpRequest.DONE) {
                        console.log(http.responseText);
                        eval("var rs = " + http.responseText);
                        accessToken = rs["access_token"];
                        refreshToken = rs["refresh_token"];
                    }else{
                        print("failed to connect");
                    }
                }
                http.send(params);
            }


            url: ("https://accounts.google.com/o/oauth2/auth?" +
                "scope=https://www.googleapis.com/auth/tasks+https://www.googleapis.com/auth/calendar&"+
                "redirect_uri=urn:ietf:wg:oauth:2.0:oob&" +
                "response_type=code&" +
                "client_id=539155836145.apps.googleusercontent.com")

            Component.onCompleted : {

            }
        }
    }

}
