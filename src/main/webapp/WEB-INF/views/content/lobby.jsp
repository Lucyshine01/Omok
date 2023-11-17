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
	<script src="https://kit.fontawesome.com/368f95b037.js" crossorigin="anonymous"></script>
	<style>
		#main {
			width: 600px;
			display: flex;
			flex-direction: column;
			margin: 0 auto;
			background-color: #ddd;
			border-radius: 10px;
			border: 4px solid #777;
		}
		#header {
			height: 80px;
			background-color: #ffffff;
			border-radius: 10px;
			margin: 25px;
			border: 2px solid #777;
			padding: 8px;
			display: flex;
			flex-direction: column;
		}
		#headerUser {
			font-size: 18px;
			font-weight: bold;
		}
		#headerBtn {
			margin-left: auto;
			width: 160px;
			height: 100%;
			display: flex;
		}
		.BtnC {
			width: 60px;
			height: 40px;
			border-radius: 5px;
			border: 2px solid #999;
			margin: auto auto;
			display: flex;
			align-items : center;
			justify-content : center;
			font-size: 13px;
		}
		.BtnC:hover {
			background-color: #bbb;
			cursor: pointer;
		}
		#content {
			min-height: 700px;
			background-color: #ffffff;
			border-radius: 10px;
			margin: 25px;
			margin-top: 0px;
			border: 2px solid #777;
			padding: 8px;
			display: flex;
			flex-direction: column;
		}
		#content_title {
			display: flex;
			height: 50px;
		}
		.content_title_Attach {
			display: flex;
			flex-direction: column;
			justify-content : center;
			text-align: center;
			border-bottom: 1px solid #555;
		}
		.content_title_Attach > input[type=button] {width: 50%; height: 80%; margin: auto auto;}
		.content_title_Attach > input[type=button]:hover {cursor: pointer;}
		#content_subject {
			display: flex;
			flex-direction: column;
		}
		.content_subject_detail {
			display: flex;
			border-bottom: 1px solid #555;
			height: 50px;
		}
		.content_subject_detail:hover {
			background-color: #ddd;
		}
		.content_subject_detail_1 {
			width: 50%;
			display: flex;
			flex-direction: column;
			justify-content : center;
			text-align: center;
		}
		.content_subject_detail_2 {
			width: 25%;
			display: flex;
			flex-direction: column;
			justify-content : center;
			text-align: center;
		}
		.content_subject_detail_3 {
			width: 25%;
			display: flex;
			flex-direction: column;
			justify-content : center;
			text-align: center;
		}
		.content_subject_detail_3 > input[type=button] {height: 100%;}
		.content_subject_detail_3 > input[type=button]:hover {cursor: pointer;}
	</style>	
	<script>
		'use strict';
		
		let mid = '${sMid}';
		let topic = '/topic/lobby';
		let query = {};
		let map = {};
		
		var sock = new SockJS('http://${pageContext.request.serverName}:${pageContext.request.serverPort}${pageContext.request.contextPath}/lobbyEnter');
		let stompClient = Stomp.over(sock);
		// stompClient.debug = null -> stompjs 콘솔 메세지 숨기기
		// https://stackoverflow.com/questions/25683022/how-to-disable-debug-messages-on-sockjs-stomp
		 stompClient.debug = null
		stompClient.connect({}, function(frame) {
			console.log('Conneted : ' + frame);
			stompClient.subscribe(topic, function(res) {
				let msg = JSON.parse(res.body);
				map = msg;
				$("#content_subject").text("");
				for(let i in map) {
				/* 	
				<div class="content_subject_detail">
					<div class="content_subject_detail_1">대충 제목</div>
					<div class="content_subject_detail_2">1/2</div>
					<div class="content_subject_detail_3"><input type="button" value="입장하기" /></div>
				</div>
				 */
				 	if(map[i].head == 0) continue;
				 	let userName = map[i].User1;
				 	if(userName == "" || userName == null) userName = map[i].User2;
				 	let html = "<div class='content_subject_detail'>" + 
				 						 "<div class='content_subject_detail_1'><div>"+map[i].title;
				 	if(map[i].pwdS == "on") html += " <i class='fa-solid fa-lock'></i>"
				 			html +="</div></div>" + 
				 						 "<div class='content_subject_detail_2'>"+map[i].head+"/2</div>" +
				 						 "<div class='content_subject_detail_3'><input type='button' value='입장하기' onclick='enterRoom(\""+i+"\")' /></div>" +
				 						 "</div>";
				 
				 	$("#content_subject").append(html);
				}
			});
		});
		
		function send() {
			if($("#testinput").val() != "") {
				query = {
						data : $("#testinput").val(),
				}
			}
			let jsonMsg = JSON.stringify(query);
			stompClient.send("/app/lobbyEnter", {}, jsonMsg);
		}
		setTimeout(() => {send()}, 200);
		
		
		function enterRoom(roomId) {
			let inputPwd = "";
			let pwdRes = "";
			if(map[roomId].pwdS == "on") {
				inputPwd = prompt("비밀번호를 입력하세요.");
				if(inputPwd == null) return;
				
				$.ajax({
					type : "post",
					url : "${ctp}/pwdCheck",
					data : {pwd : inputPwd, roomId : roomId},
					async: false,	// ajax 동기식
					success : function(res) {
						pwdRes = res;
						if(res == "0") alert("비밀번호가 틀립니다.");
					},
					error : function() {
						alert("전송 오류");
					}
				});
				
			}
			
			if(pwdRes == "0") return;
			else if(map[roomId].head == "2") {
				alert("방의 정원이 가득찼습니다.");
				return;
			}
			// JS base64 : https://url.kr/9mlnuj
			// https://jamssoft.tistory.com/274
			else if(map[roomId].pwdS == "on") location.href="${ctp}/game:"+roomId+"?p="+btoa(unescape(encodeURIComponent(inputPwd)));
			else location.href="${ctp}/game:"+roomId
		}
		
		$(function(){
			$("#loginBtn").click(function() {
				alert("회원 서비스는 준비중입니다.");
			})
  	});
		
	</script>
</head>
<body style="background-color: #eee">
	<div id="main">
		<div id="header">
			<div id="headerUser">유저 : ${sMid}</div>
			<div id="headerBtn">
				<div id="loginBtn" class="BtnC">로그인</div>
				<div id="createBtn" class="BtnC" onclick="location.href='${ctp}/createRoom'">방만들기</div>
			</div>
		</div>
		<div id="content">
			<div id="content_title">
				<div style="width: 50%;" class="content_title_Attach">제목</div>
				<div style="width: 25%;" class="content_title_Attach">입장수</div>
				<div style="width: 25%;" class="content_title_Attach"><input type="button" value="↻" onclick="send();"/></div>
			</div>
			<div id="content_subject">
				<!-- <div class="content_subject_detail">
					<div class="content_subject_detail_1">대충 제목</div>
					<div class="content_subject_detail_2">1/2</div>
					<div class="content_subject_detail_3"><input type="button" value="입장하기" /></div>
				</div>
				<div class="content_subject_detail">
					<div class="content_subject_detail_1">대충 제목</div>
					<div class="content_subject_detail_2">1/2</div>
					<div class="content_subject_detail_3"><input type="button" value="입장하기" /></div>
				</div>
				<div class="content_subject_detail">
					<div class="content_subject_detail_1">대충 제목</div>
					<div class="content_subject_detail_2">1/2</div>
					<div class="content_subject_detail_3"><input type="button" value="입장하기" /></div>
				</div> -->
			</div>
		</div>
	</div>
</body>
</html>