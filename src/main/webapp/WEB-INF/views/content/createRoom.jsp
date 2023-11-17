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
		#main {
			width: 380px;
			display: flex;
			flex-direction: column;
			margin: 0 auto;
			background-color: #ddd;
			border-radius: 10px;
			border: 4px solid #777;
			margin-top: 200px;
		}
		#header {
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
			padding: 5px;
			text-align: center;
		}
		#headerBtn {
			margin: auto auto;
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
		input[type=text]{
			width: 150px;
			height: 20px;
		}
		input[type=password]{
			width: 70px;
			height: 20px;
		}
		input[type=checkbox]{
			width: 20px;
			height: 20px;
		}
	</style>	
	<script>
		'use strict';
		
		$(function(){
			$("#pwdCheck").change(function() {
				if($("#pwdCheck").is(":checked")) document.getElementById("roomPwd").disabled = false;
				else {
					document.getElementById("roomPwd").disabled = true;
					$("#roomPwd").val("");
				}
			})
  	});
		
		function createRoom() {
			let roomPwd = $("#roomPwd").val();
			let pwdS = "off";
			let title = $("#title").val();
			if($("#pwdCheck").is(":checked") && $("#roomPwd").val() != "") pwdS = "on";
			if(title.trim() == "") title = "${sMid}님의 방"
			$.ajax({
				type : "post",
				url : "${ctp}/createRoom",
				data : {pwd : roomPwd, pwdSetting : pwdS, title : title},
				success : function(res) {
					if(res.result == "1") location.href="${ctp}/game:"+res.id+"?p="+btoa(unescape(encodeURIComponent(roomPwd)));
					else {
						if(res.result == "SlangTitle") alert("제목에 비속어가 포함되어 있습니다.");
					}
				},
				error : function() {
					alert("전송 오류");
				}
				
			});
			
		}
		
	</script>
</head>
<body style="background-color: #eee">
	<div id="main">
		<div id="header">
			<div id="headerUser" style="">게임방 생성</div>
			<div style="padding: 5px; margin-top: 10px; text-align: center; margin-bottom: 10px;">
				방 제목 : <input type="text" id="title" placeholder='"User"님의 방'/>
			</div>
			<div style="padding: 5px; margin-top: 10px; text-align: center; margin-bottom: 10px; display: flex; justify-content: center;">
				비밀번호 사용 : <input type="checkbox" id="pwdCheck" />
			</div>
			<div style="padding: 5px; margin-top: 10px; text-align: center; margin-bottom: 10px;">
				비밀번호 : <input type="password" id="roomPwd" disabled="disabled"/>
			</div>
			<div id="headerBtn">
				<!-- <div id="loginBtn" class="BtnC">로그인</div> -->
				<div id="createBtn" class="BtnC" onclick="createRoom()">생성</div>
			</div>
			
		</div>
	</div>
</body>
</html>