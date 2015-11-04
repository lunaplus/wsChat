function onchangeRdo(){
    var roomrdos = document.getElementsByName("room");
    for(var i=0; i<roomrdos.length; i++){
	if(roomrdos[i].checked){
	    changeAvailItems(roomrdos[i].value == "update");
	    break;
	}
    }
    document.getElementById("chkdellog").checked = false;
}

function onchangeRoomsel(){
    var roomsel = document.getElementById("selectroom");
    document.getElementById("rname").value =
	roomsel[roomsel.selectedIndex].text;
    document.getElementById("chkdellog").checked = false;
}

function onchangeChkbox(){
    var isupd = false;
    var roomrdos = document.getElementsByName("room");
    for(var i=0; i<roomrdos.length; i++){
	if(roomrdos[i].checked){
	    isupd = (roomrdos[i].value == "update");
	    break;
	}
    }
    changeChkbox(isupd);
}

function changeChkbox(isupd){
    var chkrname = document.getElementById("chkrname");
    var chkrown = document.getElementById("chkrown");
    var chknewpwd = document.getElementById("chknewpwd");

    // room name
    document.getElementById("rname").disabled =
	!(chkrname.checked && isupd);
    // room owner
    document.getElementById("selectowner").disabled =
	!(chkrown.checked && isupd);
    // new room password
    document.getElementById("newpwd").disabled =
	!(chknewpwd.checked && isupd);
    document.getElementById("cfnewpwd").disabled =
	!(chknewpwd.checked && isupd);
}

function changeAvailItems(isupd){
    var chkrname = document.getElementById("chkrname");
    var chkrown = document.getElementById("chkrown");
    var chknewpwd = document.getElementById("chknewpwd");

    chkrname.disabled = !isupd;
    chkrown.disabled = !isupd;
    chknewpwd.disabled = !isupd;
    changeChkbox(isupd);

    document.getElementById("chkdellog").disabled = isupd;
}

function checkSubmit(){
    var roomrdos = document.getElementsByName("room")
    var selval = ""
    for(var i=0; i<roomrdos.length; i++){
	if(roomrdos[i].checked){
	    selval = roomrdos[i].value;
	    break;
	}
    }
    var roomsel = document.getElementById("selectroom");
    var rselname = roomsel[roomsel.selectedIndex].text;
    var ownsel = document.getElementById("selectowner");
    var ownname = ownsel[ownsel.selectedIndex].value;

    var curpwd = document.getElementById("curpwd").value;
    var newpwd = document.getElementById("newpwd").value;
    var cfnewpwd = document.getElementById("cfnewpwd").value;

    var ischkrname = document.getElementById("chkrname").checked;
    var ischkrown = document.getElementById("chkrown").checked;
    var ischknewpwd = document.getElementById("chknewpwd").checked;

    var errarr = [];

    //if(curpwd == "") //パスワードチェック
    //    errarr.push('現在のパスワードを入力してください。\n');

    if(selval == "update"){ //更新時入力チェック
	if(! (ischkrname || ischkrown || ischknewpwd)) //no change
	    errarr.push('いずれかのアイテムを変更してください。\n');
	if(ischkrname){ // room name
	    var nameequ = (rselname == document.getElementById("rname").value);
	    if(nameequ)
		errarr.push('新しいルーム名を入力してください。\n');
	}
	if(ischkrown){ // room owner
	    var ownerequ = (ownname == document.getElementById("uid").value);
	    if(ownerequ)
		errarr.push('新しいルーム所有者を選択してください。\n');
	}
	if(ischknewpwd){ // new password
	    //if(newpwd == "")
		//errarr.push('新パスワードを入力してください。\n');
	    if(newpwd != cfnewpwd)
		errarr.push('新パスワードが一致しません。\n');
	    if((curpwd != "") && (newpwd == curpwd))
		errarr.push('新パスワードが現在のパスワードと同じです。\n');
	}
    }
    else{ //削除時入力チェック
	var strmsg = '本当に削除してよろしいですか？';
	if(document.getElementById("chkdellog").checked)
	    strmsg = 'ルームとログを削除します。' + strmsg;
	else strmsg = 'ルームを削除します。' + strmsg;
	if(!confirm(strmsg)){
	    errarr.push('チャットログ削除要否を確認してください。\n');
	}
    }

    var retval = false;
    if (errarr.length > 0) alert(errarr);
    else retval = true;

    return retval;
}

function init(){
    roomrdos = document.getElementsByName("room")
    for(var i=0; i<roomrdos.length; i++){
	roomrdos[i].onchange = onchangeRdo;
	if(roomrdos[i].value == "update") roomrdos[i].checked = true;
    }
    document.getElementById("selectroom").onchange = onchangeRoomsel;
    document.getElementById("submitroom").onclick = checkSubmit;

    document.getElementById("chkrname").onchange = onchangeChkbox;
    document.getElementById("chkrown").onchange = onchangeChkbox;
    document.getElementById("chknewpwd").onchange = onchangeChkbox;

    onchangeRdo();
    onchangeRoomsel();
}

//loading function register
window.addEventListener("DOMContentLoaded", init, false);
