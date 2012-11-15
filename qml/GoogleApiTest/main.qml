// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import QtWebKit 1.0

Rectangle { id: main
    width: 800
    height: 600


    Rectangle {
        width: parent.width
        height: 60
        Text {
            text: code
        }
    }

    WebView {
        y: 60
        width: parent.width
        height: parent.height

        property string accessToken

        onLoadFinished: {
            console.log("load finished");
            console.log("title:" + title);

            if(title.substring(0, 12) == "Success code") {
                var code = title.split("=")[1];
                codeToToken(code);
            }
        }

        onAccessTokenChanged: {
            var http = new XMLHttpRequest();
            var baseUrl = "https://www.googleapis.com/tasks/v1";
            var params = "access_token=" + accessToken;
            var url = baseUrl + "/users/@me/lists" + "?" + params;

            http.open("GET", url, true);
            http.onreadystatechange = function() {
                if (http.readyState == XMLHttpRequest.DONE) {
                    var rs = http.responseText;
                    var items = getTaskList(rs);
                    console.log(items[0]["title"]);

                }else{
                    print("failed to connect :" + http.readyState);
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
    }


}
