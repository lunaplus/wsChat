var Socket = "MozWebSocket" in window ? MozWebSocket : WebSocket;
var ws;

function reciveDataSpace(string) {
    var element = document.getElementById("reciveDataSpace");
    var p = document.createElement("li");
    p.appendChild(document.createTextNode(string));
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
	sendMessage();
    }
}

function closeWebSocket(){
    ws.close();
}

function selectRadioRoom(){
    if(this.value == "create"){
	document.getElementById("newroom").disabled = false;
	document.getElementById("selectroom").disabled = true;
    }
    else{
	document.getElementById("newroom").disabled = true;
	document.getElementById("selectroom").disabled = false;
    }
}

function init() {
    document.getElementById("buttonSend").onclick = sendMessage;
    document.getElementById("message").onkeydown = pressEnter;
    var rdoroom = document.getElementsByName("room")
    for(var i=0; i<rdoroom.length; i++){
	rdoroom[i].onclick = selectRadioRoom;
    }

    login = document.getElementById("login").value;
    userhash = document.getElementById("userhash").value;
    username = document.getElementById("username").value;

    document.getElementById("buttonSend").disabled = true;
    openWebSocket();
}

function openWebSocket() {
    ws = new Socket("ws://localhost:23456/?login=" + login + "&userhash=" + userhash + "&username=" + username);
    
    ws.onmessage = function(evt) {
        reciveDataSpace(evt.data); 
    };
    
    ws.onclose = function() {
	reciveDataSpace("socket closed");
	document.getElementById("buttonSend").disabled = true;
    };
    
    ws.onopen = function() {
        reciveDataSpace("connected...");
	document.getElementById("buttonSend").disabled = false;
    };
}

//window.onload = init();
window.addEventListener("DOMContentLoaded", init, false);
window.addEventListener("beforeunload", closeWebSocket, false);
