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
                        console.log('access token is stored in DB');
                    }
        );
        refreshToken = newToken;
    }

    function getAccessToken() {
        //accessToken = getAccessTokenFromWeb();
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

    ListView {
        model: taskModel
        x: parent.width / 2
        width: parent.width / 2
        height: parent.height

        delegate:
            Rectangle {
                width: parent.width
                height: 40
                border.color: "black"
                TextInput {
                    x: 10
                    y: 10
                    text: model.title + ":" + model.notes
                }
            }

    }

    ListModel { id: taskModel
        property string accessToken
        function updateData() {
            accessToken = main.accessToken;
            var http = new XMLHttpRequest();
            var baseUrl = "https://www.googleapis.com/tasks/v1";
            var params = "access_token=" + accessToken;
            var url = baseUrl + "/lists/" + "MDg4Mzg4MjQ5ODgzMTA1Nzg1MDE6Nzg1NDk2ODA1OjA" + "/tasks" + "?" + params;
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
                        append({"title": item["title"], "id": item["id"], "updated":item["updated"], "notes":item["notes"], "needPush": false});
                    }

                }else{
                    print("task failed to connect :" + http.readyState);
                }
            }
            http.send();
        }
        function getTaskList(text) {
            var iBegin = text.search("items") + 8;
            var headCut = text.substring(iBegin);
            var iEnd = headCut.search("]") + 1;
            var itemList = headCut.substring(0, iEnd);
            console.log(itemList);

            return eval(itemList);

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
        WebView {
            y: 60
            width: parent.width
            height: parent.height

            property string accessToken
            property string refreshToken

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
                visible = false;
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
