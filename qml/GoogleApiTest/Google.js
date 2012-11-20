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

function setRefreshToken(newToken) {
    var db = openDatabaseSync("FlexNote", "0.1", "TaskList", 1000000);

    db.transaction(
                function(tx) {
                    tx.executeSql('CREATE TABLE IF NOT EXISTS Token(name TEXT, token TEXT)');
                    tx.executeSql('DELETE From Token WHERE name = "GoogleTask"');

                    tx.executeSql('INSERT INTO Token VALUES(?, ?)', ['refreshToken', newToken]);
                    console.log('refresh token is stored in DB:' + newToken);
                }
    );
    main.refreshToken = newToken;
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
            console.log("Refreshed result:" + http.responseText);
            if(http.responseText == "") {
                console.log("failed to refresh");
                main.failedToRefresh();
                return;
            }
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

function pullTasks(taskListId, func) {
    var http = new XMLHttpRequest();
    var baseUrl = "https://www.googleapis.com/tasks/v1";
    var params = "access_token=" + main.accessToken;
    var url = baseUrl + "/lists/" + taskListId + "/tasks" + "?" + params;
    console.log("url:" + url);
    http.open("GET", url, true);
    http.onreadystatechange = function() {
        if (http.readyState == XMLHttpRequest.DONE) {
            var rs = http.responseText;
            console.log("Tasks:" + rs);
            var taskList = getTaskList(rs);

            func(taskList);
        }else{
            print("task failed to connect :" + http.readyState);
        }
    }

    http.send();
}

function insertTask(TaskListId, parentId, previousId, func) {
    console.log("insert Task");
    var http = new XMLHttpRequest();
    var baseUrl = "https://www.googleapis.com/tasks/v1";
    var paramToken = "access_token=" + main.accessToken;
    var paramOptions = "&parent=" + parentId + "&previous=" + previousId;
    var url = baseUrl + "/lists/" + taskListId + "/tasks" + "?" + paramToken + paramOptions;
    var params = '{"title":""}';
    console.log("url:" + url);
    http.open("POST", url, true);
    http.setRequestHeader("Content-type", "application/json");
    http.onreadystatechange = function() {
        if (http.readyState == XMLHttpRequest.DONE) {
            var rs = http.responseText;
            console.log("Tasks:" + rs);
            eval("var task = " + rs);
            console.log(task["title"]);

            func(task);

        }else{
            print("task failed to connect :" + http.readyState);
        }
    }
    console.log("insert params: " + params);

    http.send(params);
}

function modifyTask(taskListId, task, func) {
    var taskId = task["id"];

    console.log("modify Task :" + task["title"]);
    var http = new XMLHttpRequest();
    var baseUrl = "https://www.googleapis.com/tasks/v1";
    var paramToken = "access_token=" + main.accessToken;
    var url = baseUrl + "/lists/" + taskListId + "/tasks/" + taskId + "?" + paramToken;
    console.log("url:" + url);
    http.open("PUT", url, true);
    http.setRequestHeader("Content-type", "application/json");
    http.onreadystatechange = function() {
        if (http.readyState == XMLHttpRequest.DONE) {
            var rs = http.responseText;
            console.log("Tasks:" + rs);
            eval("var task = " + rs);
            console.log(task["title"]);

            func(task);

        }else{
            print("task failed to connect :" + http.readyState);
        }
    }

    var params = '{"id":' + '"' + taskId + '"' +
                    ',"title":"' + task["title"] + '"' +
                    ',"notes":"' + task["notes"] + '"' +
                    '}';

    console.log("update params: " + params);

    http.send(params);
}

function moveTask(taskListId, task, func) {
    var taskId = task["id"];
    var parentId = task["parent"];
    var previousId = task["previous"];

    console.log("move Task");
    var http = new XMLHttpRequest();
    var baseUrl = "https://www.googleapis.com/tasks/v1";
    var paramToken = "access_token=" + main.accessToken;
    var paramOptions = "&parent=" + parentId + "&previous=" + previousId;
    var url = baseUrl + "/lists/" + taskListId + "/tasks/" + taskId + "/move" + "?" + paramToken + paramOptions;
    console.log("url:" + url);
    http.open("POST", url, true);
    http.onreadystatechange = function() {
        if (http.readyState == XMLHttpRequest.DONE) {
            var rs = http.responseText;
            console.log("Tasks:" + rs);
            eval("var task = " + rs);
            console.log(task["title"]);

            func(task);

        }else{
            print("task failed to connect :" + http.readyState);
        }
    }

    http.send();
}

function removeTask(taskListId, taskId, func) {
    console.log("remove Task :" + taskId);
    var http = new XMLHttpRequest();
    var baseUrl = "https://www.googleapis.com/tasks/v1";
    var paramToken = "access_token=" + main.accessToken;
    var url = baseUrl + "/lists/" + taskListId + "/tasks/" + taskId + "?" + paramToken;
    console.log("url:" + url);
    http.open("DELETE", url, true);
    http.onreadystatechange = function() {
        if (http.readyState == XMLHttpRequest.DONE) {
            func();
        }
    }

    http.send();
}

function getTaskList(text) {
    var iBegin = text.search("items") + 8;
    var headCut = text.substring(iBegin);
    var iEnd = headCut.lastIndexOf("]") + 1;
    var itemList = headCut.substring(0, iEnd);
    console.log(itemList);

    return eval(itemList);
}
