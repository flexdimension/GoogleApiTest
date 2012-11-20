// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import "Google.js" as Google

ListModel { id: taskModel
    property string taskListId : "MDg4Mzg4MjQ5ODgzMTA1Nzg1MDE6Nzg1NDk2ODA1OjA"
    //property string taskListId : "@default"
    property string createTable : 'CREATE TABLE IF NOT EXISTS ' +
                               'Tasks(title TEXT, id TEXT, updated TEXT,' +
                               ' notes TEXT, needPush BOOLEAN, needPull BOOLEAN,' +
                               ' parent TEXT, previous TEXT, indent INTEGER, status TEXT, position INTEGER)'



    signal syncFailed

    Component.onCompleted:  {

        console.log("taskModel is initializing data");
        clearDB();
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

    function removeTaskToDB(task) {
        var db = openDatabaseSync("FlexNote", "0.1", "TaskList", 1000000);

        db.transaction(
                function(tx) {
                    var removeState = 'Delete Tasks WHERE id="' + task["id"] + '"';
                    tx.executeSql(removeState);
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
                        tx.executeSql('INSERT INTO Tasks VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                                      [item["title"], item["id"], item["updated"],
                                      item["notes"], false, false,
                                      item["parent"], item["previous"], item["indent"],
                                      item["status"], parseInt(item["position"])]);
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
                                       "previous": item["previous"],
                                       "indent": parseInt(item["indent"]),
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
                                   "previous": item["previous"],
                                   "indent": -1,
                                   "status": item["status"],
                                   "position": item["position"]
                                });
                    }

                    calcIndents();
                    storeToDB();

                }
        );

        restoreFromDB();

    }

    function clearIndents() {
        for(var i = 0; i < count; i++) {
            get(i)["indent"] = -1;
        }
    }

    function calcIndents() {
        for(var i = 0; i < count; i++) {
            if(get(i)["indent"] == -1)
                setProperty(i, "indent", evalIndent(i));
            console.log("indent:" + i + ":" + get(i)["indent"]);
        }
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
        if(item["parent"] == undefined || item["parent"] == "")
            return 0;

        return getIndentFromId(idx, item["parent"]);
    }

    function modifyTitle(idx, title) {
        setProperty(idx, "title", title);
        Google.modifyTask(taskListId, get(idx), taskModified);
    }

    function modifyTask(task) {
        var idx = getIndexFromId(task["id"]);
        setProperty(idx, "title", task["title"]);
        setProperty(idx, "parent", task["parent"]);
        setProperty(idx, "previous", task["previous"]);
        Google.modifyTask(taskListId, task, taskModified);
    }

    function insertTask(idx) {
        var parent = "";
        var previous = "";
        var indent = 0;

        if(idx > 0) {
            parent = get(idx - 1)["parent"];
            indent = get(idx -1)["indent"];
        }

        if(idx > 0 && get(idx -1)["id"] != parent)
            previous = get(idx - 1)["id"];

        insert(idx,
               {   "title": "",
                   "id": "",
                   "updated": "",
                   "notes":"",
                   "needPush": false,
                   "needPull": false,
                   "parent": parent,
                   "previous": previous,
                   "indent": indent,
                   "status": "",
                   "position": ""
                });

        Google.insertTask(taskListId, parent, previous, function(task) {taskInserted(task, idx)});
    }

    function removeTask(idx) {
        var id = get(idx)["id"];
        console.log("id" + idx );
        remove(idx);
        Google.removeTask(taskListId, id, taskRemoved);
    }

    function taskRemoved(task) {
        storeToDB();
    }

    function taskInserted(task, idx) {
        setProperty(idx, "id", task["id"]);
        setProperty(idx, "title", task["title"]);
        setProperty(idx, "parent", task["parent"]);
        setProperty(idx, "previous", task["previous"]);

        storeToDB();
    }

    function taskModified(task) {
        var idx = getIndexFromId(task["id"]);
        setProperty(idx, "title", task["title"]);
        modifyTaskToDB(task);
    }

    function increaseIndent(idx) {
        console.log("increase indent");
        var indent = get(idx).indent;
        console.log("indent :" + (indent));

        var parent = "";
        var previous = "";

        //find a item has same indent
        for(var i = idx -1; i >= 0; i--) {
            if(get(i).indent == indent) {
                parent = get(i).id;
                break;
            }
        }
        for(var i = idx -1; i >= 0; i--) {
            var item = get(i);
            //console.log("get(i).indent:" + (get(i).indent));
            //console.log("get(i).indent == indent + 1:", get(i).indent == indent + 1);
            if(get(i).indent == indent + 1) {
                //setProperty(idx, "indent", indent + 1);
                previous = get(i).id;
                break;
            }
        }

        setProperty(idx, "parent", parent);
        setProperty(idx, "previous", previous);

        clearIndents();
        calcIndents();
        //should be asserted

        var task = get(idx);
        //Google.moveTask(taskListId, task, taskModified);
    }

    function decreaseIndent(idx) {
        var indent = get(idx).indent;

        var parent = "";
        var previous = "";

        if(indent <= 1)
            parent = "";
        else {
            parent = get(getIndexFromId(get(idx).parent)).parent;
        }

        for(var i = idx -1; i >= 0; i--) {
            if(get(i).indent == indent - 1) {
                //setProperty(idx, "indent", indent + 1);
                previous = get(i).id;
                break;
            }
        }

        setProperty(idx, "parent", parent);
        setProperty(idx, "previous", previous);

        clearIndents();
        calcIndents();
        //should be asserted

        var task = get(idx);
        //Google.moveTask(taskListId, task, taskModified);
    }
}
