var Socket = "MozWebSocket" in window ? MozWebSocket : WebSocket;
var ws;

function reciveDataSpace(string) {
    var element = document.getElementById("reciveDataSpace");
    var p = document.createElement("p");
    p.appendChild(document.createTextNode(string));
    element.insertBefore(p, element.firstChild);
}

function loginState(string) {
    var element = document.getElementById("loginState");
    element.innerHTML = "<p>" + string + "</p>";
}

function init() {
    Socket = "MozWebSocket" in window ? MozWebSocket : WebSocket;
    ws = new Socket("ws://localhost:3000/");
    
    ws.onmessage = function(evt) {
        var splitData = evt.data.split(":");
        if("[CreateLoginUserCmd_OK]" == splitData[0]){
            splitData.shift();
            loginState("login : " + splitData.join(":"));
            changeloginState();
        }
        else if("[CreateLoginUserCmd_NG]" == evt.data){
            loginState("The login name is already used. ");
        }
        else{
            reciveDataSpace(evt.data); 
        }
    };
    
    ws.onclose = function() { reciveDataSpace("socket closed"); };
    
    ws.onopen = function() {
        reciveDataSpace("connected...");
    }
}

function sendMessage(){
    var sendMsg = document.getElementById("message");
    var name = document.getElementById("loginName");
    if(sendMsg.value == "") return;
    if(name.value == "") return;
    
    ws.send("[" + name.value + "]:" + sendMsg.value);
    sendMsg.value = "";
}

function sendLogin(){
    loginState("");
    var name = document.getElementById("loginName");
    var pass = document.getElementById("loginPass");
    if(name.value == "" || pass.value == "") {
        loginState("Name/Password is empty.");
        return;
    }
    // password hashing start -------------------------------------------
    var salt = "foobarfoobar";
    var sha = new jsSHA("SHA-512", "TEXT");
    sha.update(pass.value + salt);
    var shaDig = sha.getHash("HEX");

    ws.send("[CreateLoginUserCmd]:" + name.value + ":" + shaDig);
    // password hashing end   -------------------------------------------
    pass.value = "";
}

function changeloginState(){
    var name = document.getElementById("loginName");
    if(name.value == "") return;
    var login = document.getElementById("buttonLogin");
    login.disabled = true;
    var name = document.getElementById("loginName");
    name.disabled = true;
    var sendBtn = document.getElementById("buttonSend");
    sendBtn.disabled = false;
}

window.onload = init();
