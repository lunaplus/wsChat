var Socket = "MozWebSocket" in window ? MozWebSocket : WebSocket;
var ws;

function reciveDataSpace(string) {
    var element = document.getElementById("reciveDataSpace");
    var p = document.createElement("p");
    p.appendChild(document.createTextNode(string));
    element.insertBefore(p, element.firstChild);
}

function sendMessage(){
    var sendMsg = document.getElementById("message");
    if(sendMsg.value == "") return;
    
    ws.send(sendMsg.value);
    sendMsg.value = "";
}

function init() {
    Socket = "MozWebSocket" in window ? MozWebSocket : WebSocket;

    login = document.getElementById("login").value;
    userhash = document.getElementById("userhash").value;
    username = document.getElementById("username").value;

    document.getElementById("buttonSend").disabled = true;

    ws = new Socket("ws://localhost:3000/?login=" + login + "&userhash=" + userhash + "&username=" + username);
    
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
window.addEventListener("beforeunload", function (){
    ws.close();
}, false);
