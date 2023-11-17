<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ page session="false" %>
<c:set var="ctp" value="${pageContext.request.contextPath}" />
<html>
<head>
	<title>Home</title>
	<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.1/jquery.min.js"></script>
	<script src="https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js"></script>
	<script src="https://cdnjs.cloudflare.com/ajax/libs/stomp.js/2.3.3/stomp.min.js"></script>
	<style>
		#chBoardBack {
			width: 100%;
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
	</style>
	<script>
		'use strict';
		// 1 - black , 0 - white
		let rock = 0;
		let rockColor = "";
		if(rock != 0) rockColor = "black";
		else rockColor = "white";
		
		let turn = "";
		
		var sock = new SockJS('http://${pageContext.request.serverName}:${pageContext.request.serverPort}${pageContext.request.contextPath}/enterToRoom');
  	let stompClient = Stomp.over(sock);
  	stompClient.connect({}, function(frame) {
			console.log('Conneted : ' + frame);
			stompClient.subscribe(topic, function(res) {
				let msg = JSON.parse(res.body);
				alert(msg);
				
			});
  	});
		
		$(document).ready(function(){
			for(let i=1; i<=19; i++) {
				$("#rock").append("<div id='line"+i+"'></div>");
				$("#line"+i).addClass("lines");
				for(let j=1; j<=19; j++) {
					$("#line"+i).append("<div class='space'>"+
							"<img id='"+i+"-"+j+"' src='${ctp}/resources/transparent.png' class='rockDesign place'/>"+
							"</div>");
				}
			}
			$(".place").click(function() {
				if(turn == "my"){
				let cood = $(this).attr("id");
					$("#"+cood).attr("src","${ctp}/resources/"+rockColor+".png");
					$("#"+cood).css("cursor","auto");
				}
			});
			
			$(".place").mouseover(function() {
				if(turn == "my"){
				let cood = $(this).attr("id");
					if($("#"+cood).css("cursor") == "pointer") {
						$("#"+cood).attr("src","${ctp}/resources/mouseOver_"+rockColor+".png");
					}
				}
			});
			$(".place").mouseout(function() {
				if(turn == "my"){
				let cood = $(this).attr("id");
					if($("#"+cood).css("cursor") == "pointer") {
						$("#"+cood).attr("src","${ctp}/resources/transparent.png");
					}
				}
			});
			
		});
	</script>
</head>
<body>
<h1>
	Hello world!  
</h1>

<P>  The time on the server is ${serverTime}. </P>

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
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/black.png" style="position:absolute; width:38px; height:38px; transform: translate(-50%, -50%);"></div>
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/transparent.png" style="width:38px; height:38px; transform: translate(-50%, -50%);"></div>
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/black.png" style="width:38px; height:38px; transform: translate(-50%, -50%);"></div>
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/transparent.png" style="width:38px; height:38px; transform: translate(-50%, -50%);"></div>
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/black.png" style="width:38px; height:38px; transform: translate(-50%, -50%);"></div>
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/white.png" style="width:38px; height:38px; transform: translate(-50%, -50%);"></div>
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/black.png" style="width:38px; height:38px; transform: translate(-50%, -50%);"></div>
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/black.png" style="width:38px; height:38px; transform: translate(-50%, -50%);"></div>
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/black.png" style="width:38px; height:38px; transform: translate(-50%, -50%);"></div>
		</div>
		<div style="height: 37.5px; width: 100%; display: flex;">
			<img src="${ctp}/resources/transparent.png" style="width:38px; height:38px; transform: translate(0%, -50%);">
		</div>
		<div style="height: 37.5px; width: 100%; display: flex;">
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/black.png" style="position:absolute; width:38px; height:38px; transform: translate(-50%, -50%);"></div>
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/transparent.png" style="width:38px; height:38px; transform: translate(-50%, -50%);"></div>
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/black.png" style="width:38px; height:38px; transform: translate(-50%, -50%);"></div>
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/transparent.png" style="width:38px; height:38px; transform: translate(-50%, -50%);"></div>
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/black.png" style="width:38px; height:38px; transform: translate(-50%, -50%);"></div>
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/white.png" style="width:38px; height:38px; transform: translate(-50%, -50%);"></div>
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/black.png" style="width:38px; height:38px; transform: translate(-50%, -50%);"></div>
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/black.png" style="width:38px; height:38px; transform: translate(-50%, -50%);"></div>
			<div style="width: 37.5px; transform: translate(50%, 0%);"><img src="${ctp}/resources/black.png" style="width:38px; height:38px; transform: translate(-50%, -50%);"></div>
		</div> --%>
	</div>
</div>
<script>
	
</script>

</body>
</html>
