var Socket = "MozWebSocket" in window ? MozWebSocket : WebSocket;
var ws;

function reciveDataSpace(string) {
    var element = document.getElementById("reciveDataSpace");
    var p = document.createElement("li");
    //p.appendChild(document.createTextNode(string.replace(/\r?\n/g, "<br>")));
    p.innerHTML = string.replace(/\r?\n/g, "<br>");
    element.insertBefore(p, element.firstChild);
}

function sendMessage(){
    var sendMsg = document.getElementById("message");
    if(sendMsg.value == "") return;
    
    ws.send(sendMsg.value);
    sendMsg.value = "";

    sendMsg.focus();
}

function pressEnter(){
    if (event.keyCode == 13){
	if (event.shiftKey){
	    sendMessage();
	    return false;
	}
    }
}

function closeWebSocket(){
    ws.close();
}

function selectRadioRoom(){
    modifyRoomItemsStatus(this.value=="create")
}

function modifyRoomItemsStatus(isCreate){
    document.getElementById("newroom").disabled = !isCreate;
    document.getElementById("selectroom").disabled = isCreate;
}

function changeLoginStatus(b){
    // b==true  : login / b==false : logout

    //login item
    document.getElementById("newroom").disabled = b;
    document.getElementById("selectroom").disabled = b;
    var rdoroom = document.getElementsByName("room");
    for(var i=0; i<rdoroom.length; i++){
	rdoroom[i].disabled = b;
    }
    document.getElementById("roompwd").disabled = b;
    document.getElementById("roomlogin").disabled = b;

    document.getElementById("roomlogout").disabled = !b;

    //chat item
    document.getElementById("message").disabled = !b;
    document.getElementById("buttonSend").disabled = !b;
}

function init() {
    // event register
    document.getElementById("buttonSend").onclick = sendMessage;
    document.getElementById("message").onkeydown = pressEnter;
    document.getElementById("roomlogin").onclick = openWebSocket;
    document.getElementById("roomlogout").onclick = closeWebSocket;
    var rdoroom = document.getElementsByName("room")
    for(var i=0; i<rdoroom.length; i++){
	rdoroom[i].onclick = selectRadioRoom;
	if(rdoroom[i].value == "create"){
	    rdoroom[i].checked = "checked";
	}
    }

    changeLoginStatus(false);
    modifyRoomItemsStatus(true);
}

function openWebSocket() {
    // value get
    var login = document.getElementById("login").value;
    var userhash = document.getElementById("userhash").value;
    var username = document.getElementById("username").value;
    var rdoroom = document.getElementsByName("room");
    var isnewroom = false;
    for(var i=0; i<rdoroom.length; i++){
	if (rdoroom[i].checked){
	    isnewroom = (rdoroom[i].value == "create");
	}
    }
    var roomname = ""
    if (isnewroom){
	roomname = document.getElementById("newroom").value;
    } else {
	var tmpSel = document.getElementById("selectroom");
	roomname = tmpSel.options[tmpSel.selectedIndex].value;
    }
    var roompwd = document.getElementById("roompwd").value;

    // input check
    if (roomname == ""){
	errmsg = "";
	if(isnewroom) errmsg = "ルーム名を入力してください。";
	else errmsg = "ルームを選択してください。";
	document.getElementById("errmsg").textContent = errmsg;
	return;
    }
    document.getElementById("errmsg").textContent = "";

    // websocket initialize
    ws = new Socket("ws://localhost:23456/" +
		    "?login=" + login +
		    "&userhash=" + userhash +
		    "&username=" + username +
		    "&newroom=" + isnewroom +
		    "&roomname=" + roomname +
		    "&roompwd=" + roompwd
		   );
    ws.onmessage = function(evt) {
        reciveDataSpace(evt.data); 
    };
    ws.onclose = function() {
	reciveDataSpace("socket closed");
	changeLoginStatus(false);
	location.reload();
    };
    ws.onopen = function() {
        reciveDataSpace("connected...");
	changeLoginStatus(true);
    };
}

//loading function register
window.addEventListener("DOMContentLoaded", init, false);
window.addEventListener("beforeunload", closeWebSocket, false);
