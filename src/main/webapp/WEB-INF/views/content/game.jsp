<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<c:set var="ctp" value="${pageContext.request.contextPath}"/>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>Playing Omok</title>
	<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.1/jquery.min.js"></script>
	<script src="https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js"></script>
	<script src="https://cdnjs.cloudflare.com/ajax/libs/stomp.js/2.3.3/stomp.min.js"></script>
	<style>
		div{ -webkit-touch-callout: none;
     user-select: none;
     -moz-user-select: none;
     -ms-user-select: none;
     -webkit-user-select: none;
		}
		#chBoardBack {
			width: 724px;
			display: flex;
			justify-content: center;
			align-items: center;
		}
		#rock {
			margin: 0 auto;
			position: absolute;
			transform: translate(0%, 50%);
		}
		.lines{
			height: 37.5px;
			width: 100%;
			display: flex;
			flex-direction: row;
		}
		.space {
			width: 37.5px;
			transform: translate(50%, 0%);
		}
		.rockDesign{
			width:38px;
			height:38px;
			transform: translate(-50%, -50%);
		}
		.place{
			cursor: pointer;
		}
		.noneDrag {-webkit-user-drag: none;}
		
		#UI {
			margin-left: 5px;
			padding: 5px;
			width: 280px;
			/* background-color: #555; */
			display: flex;
			flex-direction: column;
			background-color: #eee;
			border-radius: 5px;
			border: 3px solid #999
		}
		#UI div {
			margin: auto 0;
		}
		#UI > #UserName {
			margin: 2px;
			height: 90px;
			display: flex;
			flex-direction: column;
		}
		#UI > #UserName > div {
			margin: 2px;
			height: 50%;
			display: flex;
			flex-direction: row;
			text-align: center;
			border-radius: 2px;
			border: 1px solid #999;
		}
		#UI > #UserName > div > .UserNames {width: 55%;}
		#UI > #selectRock {
			display: flex;
			flex-direction: row;
		}
		#UI > #selectRock > .rocks{
			width: 50%;
			height: 80px;
			margin: 2px;
			margin-top: 8px;
		}
		#UI > #selectRock > .rocks > .rockImg{
			display: flex;
			justify-content: center;
		}
		#UI > #selectRock > .rocks > .rockSelectName{
			margin-top: 5px;
			display: flex;
			justify-content: center;
/* 			font-size: 0.9em; */
		}
		#UI > .UIBtn > input[type=button]{
			margin: 2px;
			width: 99%;
			height: 40px;
			font-size: 1.2em;
		}
		#UI > #rockBtn{display: flex;}
		#UI #gameStartBtn {color: red;}
		#UI > #chat {
			width: 98%;
			height: 380px;
			background-color: #fff;
			margin: 2px;
			margin-bottom: 22px;
			border: 1px solid #555;
			border-radius: 2px;
			display: flex;
			flex-direction: column;
		}
		#UI > #chat > #chatWindow {
			height: 91%;
			display: flex;
			flex-direction: column-reverse;
			overflow-y: scroll;
			font-size: 0.9em;
		}
		#UI > #chat > #chatWindow::-webkit-scrollbar {
  		width: 11px;
	    height: 20%;
		}
		#UI > #chat > #chatWindow::-webkit-scrollbar-track {
	    background: rgba(0,0,0,0);  /*스크롤바 뒷 배경 색상*/
		}
  	#UI > #chat > #chatWindow::-webkit-scrollbar-thumb {
	    background: rgba(40,40,40,0.5); /* 스크롤바의 색상 */
	    background-clip: padding-box;
	    border: 2px solid transparent;
	    border-radius: 10px;
	    /* border-radius: 10px; */
		}
		#UI > #chat > #chatWindow > div {
			margin: 0px;
			margin-left: 3px; 
			margin-bottom: 3px;
		}
		#UI > #chat > #chatBtn {
			height: 9%;
			display: flex;
			flex-direction: row;
		}
		#UI > #chat > #chatBtn > input[type="text"] {
			width: 80%;
			margin: 1px;
		}
		#UI > #chat > #chatBtn > input[type="button"] {
			width: 20%;
			margin: 1px;
		}
	</style>
	<script>
		'use strict';
		let rockColor = "";
		let sw = 0;
		
		let roomData = {
				mid : '${sMid}',
				roomId : '${roomId}',
				head : '${head}',
				User1 : '${User1}',
				User2 : '${User2}',
				pwdS : '${pwdS}',
				black : '${black}',
				wihte : '${white}',
				whiteWin : '${whiteWin}',
				blackWin : '${blackWin}',
				rock : '${rock}'
		}
		let turn = "";
		
		const realSock = new SockJS('http://${pageContext.request.serverName}:${pageContext.request.serverPort}${pageContext.request.contextPath}/realtime');
  	realSock.onopen = function() {
			console.log("Connecting...");
			let query = {
					mid : "${sMid}",
					roomId : "${roomId}"
			}
			let jsonMsg = JSON.stringify(query);
			realSock.send(jsonMsg);
		}
		realSock.onmessage = function(msg) {
		}
		realSock.onclose = function() {
			console.log("Disconnect...");
		}
		
  	var sock = new SockJS('http://${pageContext.request.serverName}:${pageContext.request.serverPort}${pageContext.request.contextPath}/gameData');
  	let gameStomp = Stomp.over(sock);
  	//gameStomp.debug = null
  	gameStomp.connect({}, function(frame) {
  		console.log('Conneted : ' + frame);
  		gameStomp.subscribe('/topic/'+'${roomId}'+'game', function(res) {
  			let data = JSON.parse(res.body);
  			roomData.black = data.black;
  			roomData.white = data.white;
  			roomData.whiteWin = data.whiteWin;
  			roomData.blackWin = data.blackWin;
  			roomData.rock = data.rock;
  			rockSetting();
			});
  	});
  	
  	sock = new SockJS('http://${pageContext.request.serverName}:${pageContext.request.serverPort}${pageContext.request.contextPath}/infor');
  	let inforClient= Stomp.over(sock);
  	//inforClient.debug = null
  	inforClient.connect({}, function(frame) {
  		console.log('Conneted : ' + frame);
  		sendGameData();
  		inforClient.subscribe('/topic/'+'${roomId}', function(res) {
				console.log("infor : "+res.body);
				let msg = JSON.parse(res.body);
				roomData.head = msg.head;
				roomData.User1 = msg.User1;
				roomData.User2 = msg.User2;
				roomData.pwdS = msg.pwdS;
				if(roomData.User1 != "${sMid}" && roomData.User2 != "${sMid}") {
					alert("퇴장되었습니다.");
					location.href="${ctp}/"
				}
				if(roomData.User1 != "" && roomData.User2 != "") sw = 1;
				if(roomData.User1 == "" || roomData.User2 == "") {
					// 상대방 퇴장시 선택돌 초기화
					$.ajax({
						type : "post",
						url : "${ctp}/getMyRoomGameData:${roomId}"
					});
					if(roomData.User1 == "" || roomData.User2 == "") {
						if(sw == 0) sw = 1;
						else {
							turn = "";
							rockColor = "";
							let today = new Date();
			  			let time = today.getHours()+":";
			  			if((today.getMinutes()+"").length == 1) time += "0"
							time += today.getMinutes();
			  			let html = '<div>['+time+'] <font color="#f33">상대방이 게임을 종료했습니다.</font>';
							$("#chatWindow").prepend(html);
							$("#rock").html("");
							$("#rockBtn input[type=button]").attr("disabled",false);
						}
					}
				}
				setting();
			});
  	});
  	
  	sock = new SockJS('http://${pageContext.request.serverName}:${pageContext.request.serverPort}${pageContext.request.contextPath}/rock');
  	let rockDataClient= Stomp.over(sock);
  	//rockDataClient.debug = null
  	rockDataClient.connect({}, function(frame) {
  		getRoomData();
  		console.log('Conneted : ' + frame);
  		rockDataClient.subscribe('/topic/'+'${roomId}'+'rock', function(res) {
				let msg = JSON.parse(res.body);
				if(msg.send=="${sMid}" && msg.what == "Q") 
					$("#rockBtn").html('<input type="button" onclick="changeCancle()" value="취소"/>');
				else if(msg.send != "${sMid}" && msg.what == "Q") 
					$("#rockBtn").html('<input type="button" onclick="changeBtnOk()" value="수락"/><input type="button" onclick="changeBtnNo()" value="거절"/>');
				else if(msg.what == "Reset")
					$("#rockBtn").html('<input type="button" onclick="rockChangeQA()" value="돌 바꾸기"/>');
			});
  	});
  	
  	sock = new SockJS('http://${pageContext.request.serverName}:${pageContext.request.serverPort}${pageContext.request.contextPath}/chat');
  	let chatClient= Stomp.over(sock);
  	//chatClient.debug = null
  	chatClient.connect({}, function(frame) {
  		console.log('Conneted : ' + frame);
  		chatClient.subscribe('/topic/'+'${roomId}'+'chat', function(res) {
				let msg = JSON.parse(res.body);
  			
  			let today = new Date();
  			let time = today.getHours()+":";
  			if((today.getMinutes()+"").length == 1) time += "0"
  					time += today.getMinutes();
  			let html = ''; 
  					html += '<div>['+time+'] <font color="#f33">'+msg.mid+'</font> : ';
  					html += msg.msg+'</div>';
  			
				$("#chatWindow").prepend(html);
			});
  	});
  	
  	sock = new SockJS('http://${pageContext.request.serverName}:${pageContext.request.serverPort}${pageContext.request.contextPath}/branch');
  	let branchClient= Stomp.over(sock);
  	//branchClient.debug = null
  	branchClient.connect({}, function(frame) {
  		console.log('Conneted : ' + frame);
  		branchClient.subscribe('/topic/'+'${roomId}'+'branch', function(res) {
  			let msg = JSON.parse(res.body);
  			if(msg.sign == 'start'){
  				roomData.black = msg.black;
	  			roomData.white = msg.white;
	  			roomData.whiteWin = msg.whiteWin;
	  			roomData.blackWin = msg.blackWin;
	  			roomData.rock = msg.rock;
	  			rockColor = msg.rockColor;
	  			rockSetting();
	  			$("#gameStartBtn").attr("disabled",true);
	  			$("#rockBtn input[type='button']").attr("disabled",true);
	  			if(roomData.black == roomData.mid) turn = "my";
	  			else turn = "opp";
	  			$("#rock").html('<div style="height: 23px; width: 38px"></div>');
	  			for(let i=0; i<=18; i++) {
						$("#rock").append("<div id='line"+i+"'></div>");
						$("#line"+i).addClass("lines");
						for(let j=0; j<=18; j++) {
							$("#line"+i).append("<div class='space'>"+
									"<img id='"+j+"-"+i+"' src='${ctp}/resources/transparent.png' class='rockDesign place' style='-webkit-user-drag: none;'/>"+
									"</div>");
							$("#"+j+"-"+i).addClass("noneDrag");
						}
					}
  			}
  			else if(msg.sign == 'branch') {
  				let turnName = msg.turn;
  				if(turnName == "${sMid}") turn = "my";
  				else turn = "opp";
  				rockColor = msg.rockColor;
  				let coodMap = JSON.parse(msg.coodMap);
  				
  				$("#rock").html('<div style="height: 23px; width: 38px"></div>');
	  			for(let i=0; i<=18; i++) {
						$("#rock").append("<div id='line"+i+"'></div>");
						$("#line"+i).addClass("lines");
						for(let j=0; j<=18; j++) {
							if((coodMap[j][i] == "33X" || coodMap[j][i] == "44X") && msg.whiteNick == "${sMid}") {
								$("#line"+i).append("<div class='space'>"+
										"<img id='"+j+"-"+i+"' src='${ctp}/resources/transparent.png' class='rockDesign place' style='-webkit-user-drag: none;'/>"+
										"</div>");
							}
							else {
								$("#line"+i).append("<div class='space'>"+
									"<img id='"+j+"-"+i+"' src='${ctp}/resources/"+coodMap[j][i]+".png' class='rockDesign place' style='-webkit-user-drag: none;'/>"+
									"</div>");
							}
							if(coodMap[j][i] != "transparent") $("#"+j+"-"+i).css("cursor","auto");
							if((coodMap[j][i] == "33X" || coodMap[j][i] == "44X") && msg.whiteNick == "${sMid}") $("#"+j+"-"+i).css("cursor","pointer");
							$("#"+j+"-"+i).addClass("noneDrag");
						}
					}
  			}
  			else if (msg.sign == 'end') {
  				let coodMap = JSON.parse(msg.coodMap);
  				$("#rock").html('<div style="height: 23px; width: 38px"></div>');
  				for(let i=0; i<=18; i++) {
						$("#rock").append("<div id='line"+i+"'></div>");
						$("#line"+i).addClass("lines");
						for(let j=0; j<=18; j++) {
							if((coodMap[j][i] == "33X" || coodMap[j][i] == "44X")) {
								$("#line"+i).append("<div class='space'>"+
										"<img id='"+j+"-"+i+"' src='${ctp}/resources/transparent.png' class='rockDesign place' style='-webkit-user-drag: none;'/>"+
										"</div>");
							}
							else {
								$("#line"+i).append("<div class='space'>"+
									"<img id='"+j+"-"+i+"' src='${ctp}/resources/"+coodMap[j][i]+".png' class='rockDesign place' style='-webkit-user-drag: none;'/>"+
									"</div>");
							}
							if(coodMap[j][i] != "transparent") $("#"+j+"-"+i).css("cursor","auto");
							if((coodMap[j][i] == "33X" || coodMap[j][i] == "44X") && msg.whiteNick == "${sMid}") $("#"+j+"-"+i).css("cursor","pointer");
							$("#"+j+"-"+i).addClass("noneDrag");
						}
					}
  				
  				let html = ''; 
					html += '<div><font color="#f33">'+msg.win+'</font>님이 승리하였습니다.</div>';
					$("#chatWindow").prepend(html);
					// 3초 딜레이
					setTimeout(()=> {
						$("#rock").html("");
						$.ajax({
							type : "post",
							url : "${ctp}/getMyRoomGameData:${roomId}"
						});
						setting();
						$("#rockBtn input[type='button']").attr("disabled",false);
					},3000);
  			}
  			
			});
  	});
  	
  	window.onload = function() {setTimeout(()=> {setting();},1000);}
  	
  	function sendGameData() {
			let jsonMsg = JSON.stringify(roomData);
			$.ajax({
				type : "post",
				url : "${ctp}/gameData:${roomId}",
				contentType: 'application/json; charset=utf-8',
				data : jsonMsg,
				//async: false	// ajax 동기식
			});
		}
  	
  	function getRoomData() {
  		$.ajax({
				type : "post",
				url : "${ctp}/getMyRoomData:${roomId}"
			});
		}
  	
  	function setting() {
  		$("#User1Name").text(roomData.User1);
			$("#User2Name").text(roomData.User2);
			
			if(roomData.User1 != "" && roomData.User2 != "") {
				$("#gameStartBtn").attr("disabled",false);
			}
			else $("#gameStartBtn").attr("disabled",true);
		}
  	
  	function rockSetting() {
  		$("#blackRock").html(roomData.black + "<br/>" + roomData.blackWin + "승");
			$("#whiteRock").html(roomData.white + "<br/>" + roomData.whiteWin + "승");
		}
  	
  	
  	function rockChangeQA() {
  		$.ajax({
				type : "post",
				url : "${ctp}/gameRockChangeQA:${roomId}"
			});
  		if(roomData.white != '' && roomData.black != '') sendChat("<font color='blue'>[바둑알 교환 신청]</font>");
		}
  	function changeBtnOk() {
			$.ajax({
				type : "post",
				url : "${ctp}/gameRockChangeOk:${roomId}"
			});
			rockChangeReset();
			sendChat("<font color='green'>[수락]</font>");
		}
  	
  	function rockChangeReset() {
  		$.ajax({
				type : "post",
				url : "${ctp}/gameRockChangeReset:${roomId}"
			});
		}
  	function changeCancle() {
  		rockChangeReset();
			sendChat("<font color='blue'>[교환 신청 취소]</font>");
		}
  	function changeBtnNo() {
  		rockChangeReset();
			sendChat("<font color='red'>[거절]</font>");
		}
  	
  	function sendChat(msg) {
  		if(msg.trim() == "") return;
  		$.ajax({
				type : "post",
				url : "${ctp}/gameChat:${roomId}",
				data : {mid:"${sMid}",msg:msg}
			});
  		$("#chatText").val("");
		}
  	
  	function exit() {
			let ans = confirm("게임에서 나가시겠습니까?");
  		if(ans)	location.href='${ctp}/';
		}
		$(document).ready(function(){
			$("#chatBtn input[type='button']").click(function() {
				let msg = $("#chatText").val();
				sendChat(msg);
			});
			
			$("#chatText").on('keydown', function(e){
				if(e.keyCode == 13) {
					sendChat($("#chatText").val());
				}
			});
			
			$(document).on("click", "#gameStartBtn", function() {
				$.ajax({
					type : "post",
					url : "${ctp}/gameStart:${roomId}"
				});
			});
			
			$(document).on("click", ".place", function() {
				if(turn == "my"){
					let cood = $(this).attr("id");
						$.ajax({
							type : "post",
							url : "${ctp}/branch:${roomId}",
							data : {cood:cood},
							success: function(res) {if(!res) return;}
						});
						/* $("#"+cood).attr("src","${ctp}/resources/"+rockColor+".png");
						$("#"+cood).css("cursor","auto");
						$("#"+cood).addClass("noneDrag"); */
					}
			});
			$(document).on("mouseover", ".place", function() {
				if(turn == "my"){
					let cood = $(this).attr("id");
					if($("#"+cood).css("cursor") == "pointer") {
						$("#"+cood).attr("src","${ctp}/resources/mouseOver_"+rockColor+".png");
						$("#"+cood).addClass("noneDrag");
					}
				}
			});
			$(document).on("mouseout", ".place", function() {
				if(turn == "my"){
				let cood = $(this).attr("id");
					if($("#"+cood).css("cursor") == "pointer") {
						$("#"+cood).attr("src","${ctp}/resources/transparent.png");
						$("#"+cood).addClass("noneDrag");
					}
				}
			});
		});
	</script>
</head>
<body style="-webkit-user-drag: none; background-color: #ddd;">
<div style="width: 100%; margin-top: 100px;">
	<div style="display: flex; margin: 0 auto; justify-content: center;">
		<div>
			<div id="chBoardBack">
				<div>
					<!-- 바둑판 -->
					<div style="margin: 0 auto;"> 
						<img src="${ctp}/resources/checkerboard.png" style="position: absolute; transform: translate(-50%, 0%);">
					</div>
				</div>
				<div id="rock">
					<div style="height: 23px; width: 38px"></div> <!-- 상단 여백 -->
					<%-- <div style="height: 37.5px; width: 100%; display: flex;">
						<img src="${ctp}/resources/transparent.png" style="width:38px; height:38px; transform: translate(0%, -50%);">
					</div> --%>
				</div>
			</div>
		</div>
		<div id="UI">
			<div id="UserName">
				<div>
					<div style="width: 40%;">Player 1 : </div>
					<div id="User1Name" class="UserNames"></div>
				</div>
				<div>
					<div style="width: 40%;">Player 2 : </div>
					<div id="User2Name" class="UserNames"></div>
				</div>
			</div>
			<div id="selectRock">
				<div class="rocks">
					<div class="rockImg">
						<img src="${ctp}/resources/black.png" style="width:30px; height: 30px;">
					</div>
					<div id="blackRock" class="rockSelectName" style="text-align: center;"></div>
				</div>
				<div class="rocks">
					<div class="rockImg">
						<img src="${ctp}/resources/white.png" style="width:30px; height: 30px;">
					</div>
					<div id="whiteRock" class="rockSelectName" style="text-align: center;"></div>
				</div>
			</div>
			<div id="rockBtn" class="UIBtn"><input type="button" onclick="rockChangeQA()" value="돌 바꾸기"/></div>
			<div class="UIBtn"><input type="button" id="gameStartBtn" value="게임시작"/></div>
			<div id="chat">
				<div id="chatWindow">
					<div>
						현재 적용되고 있는 룰은 렌주룰입니다. <a href="https://namu.wiki/w/%EC%98%A4%EB%AA%A9/%EB%A3%B0%EC%9D%98%20%EC%A2%85%EB%A5%98#s-2.4" target="_blank" >[설명]</a><br/>
					</div>
				</div>
				<div id="chatBtn">
					<input type="text" id="chatText" placeholder="채팅입력" />
					<input type="button" value="입력" />
				</div>
			</div>
			<div id="exitBtn" class="UIBtn"><input type="button" value="나가기" onclick="exit()"/></div>
		</div>
	</div>
	<script>
	</script>
</div>
</body>
</html>