// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import "Google.js" as Google

ListModel { id: taskModel
    property string taskListId : "MDg4Mzg4MjQ5ODgzMTA1Nzg1MDE6Nzg1NDk2ODA1OjA"
    //property string taskListId : "@default"
    property string createTable : 'CREATE TABLE IF NOT EXISTS ' +
                               'Tasks(title TEXT, id TEXT, updated TEXT,' +
                               ' notes TEXT, needPush BOOLEAN, needPull BOOLEAN,' +
                               ' parent TEXT, indent INTEGER, status TEXT, position INTEGER)'



    signal syncFailed

    Component.onCompleted:  {

        console.log("taskModel is initializing data");
        //clearDB();
        restoreFromDB();

    }

    function clearDB() {
        var db = openDatabaseSync("FlexNote", "0.1", "TaskList", 1000000);
        db.transaction(
                    function(tx) {
                        tx.executeSql('DROP TABLE Tasks');
                    }
        );
    }

    function modifyTaskToDB(task) {
        var db = openDatabaseSync("FlexNote", "0.1", "TaskList", 1000000);

        db.transaction(
                function(tx) {
                    console.log('UPDATE Tasks SET ' +
                                'title="' + task["title"] + '" ' +
                                'WHERE id="' + task["id"] + '"');
                    tx.executeSql('UPDATE Tasks SET ' +
                                  'title="' + task["title"] + '" ' +
                                  'WHERE id="' + task["id"] + '"');
                }
        );
    }

    function storeToDB() {
        var db = openDatabaseSync("FlexNote", "0.1", "TaskList", 1000000);

        db.transaction(
                function(tx) {
                    tx.executeSql(createTable);

                    tx.executeSql('DELETE FROM Tasks');

                    for(var i = 0; i < count; i++) {
                        var item = get(i);
                        tx.executeSql('INSERT INTO Tasks VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                                      [item["title"], item["id"], item["updated"],
                                      item["notes"], false, false,
                                       item["parent"], item["indent"], item["status"], parseInt(item["position"])]);
                    }
                }
        );

    }

    function restoreFromDB() {
        clear();

        var db = openDatabaseSync("FlexNote", "0.1", "TaskList", 1000000);

        db.transaction(
                function(tx) {
                    tx.executeSql(createTable);

                    var rs = tx.executeSql('SELECT * FROM Tasks');

                    if(rs.rows.length > 0) {
                        for(var i = 0; i < rs.rows.length; i++) {
                            var item = rs.rows.item(i);
                            append({   "title": item["title"],
                                       "id": item["id"],
                                       "updated":item["updated"],
                                       "notes":item["notes"],
                                       "needPush": false,
                                       "needPull": false,
                                       "parent": item["parent"],
                                       "indent": item["indent"],
                                       "status": item["status"],
                                       "position": item["position"]
                                    });
                        }

                    }
                    else {
                        console.log("no taskes in DB");
                        //getAccessTokenFromWeb();
                    }
                }
        );

    }

    function allTaskPulled(taskList) {
        if(taskList == null) {
            console.log("failed to sync Google Task");
            syncFailed();
            return;
        }

        clear();
        var db = openDatabaseSync("FlexNote", "0.1", "TaskList", 1000000);

        db.transaction(
                function(tx) {
                    tx.executeSql(createTable);

                    tx.executeSql('DELETE FROM Tasks');

                    for(var i = 0; i < taskList.length; i++) {
                        var item = taskList[i];
                        append({   "title": item["title"],
                                   "id": item["id"],
                                   "updated":item["updated"],
                                   "notes":item["notes"],
                                   "needPush": false,
                                   "needPull": false,
                                   "parent": item["parent"],
                                   "indent": -1,
                                   "status": item["status"],
                                   "position": item["position"]
                                });
                    }

                    for(var i = 0; i < count; i++) {
                        if(get(i)["indent"] == -1)
                            setProperty(i, "indent", evalIndent(i));
                        console.log("indent:" + i + ":" + get(i)["indent"]);
                    }

                    storeToDB();

                }
        );

        restoreFromDB();

    }

    function pull() {
        Google.pullTasks(taskListId, allTaskPulled);
    }

    function getIndentFromId(curIdx, id) {
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

    function getIndexFromId(id) {
        for(var i = 0; i < count; i++) {
            if(get(i)["id"] == id)
                break;
        }

        return i;
    }

    function evalIndent(idx) {
        var item = get(idx);

        console.log("parent:" + item["parent"]);
        if(item["parent"] == undefined)
            return 0;

        return getIndentFromId(idx, item["parent"]);
    }

    function modifyTask(idx, title) {
        setProperty(idx, "title", title);
        Google.modifyTask(taskListId, get(idx)["id"], title, taskModified);
    }

    function insertTask(idx) {
        var item = get(idx);
        var parent = item["parent"];

        var previous = "";
        if(idx > 0 && get(idx -1)["id"] != parent)
            previous = get(idx - 1)["id"];

        insert(idx,
               {   "title": "new Task",
                   "id": "",
                   "updated": "",
                   "notes":"",
                   "needPush": false,
                   "needPull": false,
                   "parent": item["parent"],
                   "indent": item["indent"],
                   "status": "",
                   "position": ""
                });

        Google.insertTask(taskListId, parent, previous, function(task) {taskInserted(task, idx)});

    }

    function taskInserted(task, idx) {
        setProperty(idx, "title", task["title"]);
        storeToDB();
    }

    function taskModified(task) {
        var idx = getIndexFromId(task["id"]);
        setProperty(idx, "title", task["title"]);
        modifyTaskToDB(task);
    }
}
