package com.playing.Omok.websocket;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

public class WsCheckservice extends TextWebSocketHandler {
	
	@Autowired
	private SimpMessagingTemplate simpMessagingTemplate;
	
	private List<WebSocketSession> sessionList = new ArrayList<WebSocketSession>();
	
	//roomId = MapData
	// white = ID , black = ID, whiteWin = winCount, blackWin = blackCount, rock = rockcoordinate
	public static Map<String, Map<String, String>> gameDataMap = new HashMap<String, Map<String,String>>();
	
	private static final Logger log = LoggerFactory.getLogger(WsCheckservice.class);
	
	private static ObjectMapper objectMapper = new ObjectMapper();
	
	@Override
	public void afterConnectionEstablished(WebSocketSession session) throws Exception {
//		log.info("접속 완료, afterConnectionEstablished");
//		log.info("접속 아이디 : " + session.getId());
		sessionList.add(session);
		//log.info(session.getPrincipal().getName() + "님이 입장하셨습니다.");
	}
	
	
	// a:get:game -> a:handleTextMessage -> a:afterConnectionClosed
	// 새로고침 a:get:game -> a:handleTextMessage -> b:get:game -> a:afterConnectionClosed -> b:handleTextMessage
	// 순서 꼬임 조심
	@Override
	protected void handleTextMessage(WebSocketSession session, TextMessage jsonMessage) throws Exception {
		// jsonson 매핑
		// https://jhyonhyon.tistory.com/11
		Map<String, String> mapMessage = objectMapper.readValue(jsonMessage.getPayload(), new TypeReference<Map<String, String>>(){});
		
		String mid = mapMessage.get("mid");
		String roomId = mapMessage.get("roomId");
		
//		log.info("웹소켓 생성중.. , handleMessage");
//		log.info("아이디 : " + mid + "(세션 ID : " + session.getId() + ")" + " 접속중인 방 : " + roomId);
		System.out.println(sessionList);
		
		if(WebsocketController.userMap.get(mid) != null) exitPlayer(WebsocketController.userMap.get(mid).get("sessionId"));
		
		
		Map<String, String> userData = new HashMap<String, String>();
		userData.put("sessionId", session.getId());
		userData.put("roomId", roomId);
		WebsocketController.userMap.put(mid, userData);
		WebsocketController.sessionMap.put(session.getId(), mid);
		
		Map<String, String> roomData = new HashMap<String, String>();
		roomData = WebsocketController.serverMap.get(roomId);
		int head = Integer.valueOf(roomData.get("head"));
		if(head <= 0) head = 1;
		else if(head == 1) {
			if(roomData.get("User1").equals(mid) || roomData.get("User2").equals(mid));
			else head = 2;
		}
		
		
		if(roomData.get("head").equals("1")) {
			if(roomData.get("User1").equals(mid) || roomData.get("User2").equals(mid));
			else if(roomData.get("User1") == null || roomData.get("User1").equals("")) roomData.put("User1", mid);
			else roomData.put("User2", mid);
//			websocketController.changeinfor(roomId, roomData);
//			System.out.println(roomData);
			changeinfor(roomId, roomData);
		}
		else roomData.put("User1", mid);
		
		roomData.put("head", head+"");
		
		WebsocketController.serverMap.put(roomId, roomData);
		
	}
	
	@Override
	public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
//		log.info("소켓 종료, afterConnectionClosed");
//		log.info("종료 아이디 : " + session.getId());
		sessionList.remove(session);
		
//		websocketController.exitPlayer(session.getId());
		exitPlayer(session.getId());
	}
	
	@MessageMapping("/infor")
	public void changeinfor(String roomId, Map<String, String> roomData) {
//		System.out.println("정보 보냄 : " +roomData);
//		System.out.println("roomId : " +roomId);
		ObjectMapper mapper = new ObjectMapper();
		String payload = "";
		try {
			payload = mapper.writeValueAsString(roomData);
		} 
		catch (JsonProcessingException e) {e.printStackTrace();}
//		System.out.println("changeinfor 후 방정보 : " + roomData);
		simpMessagingTemplate.convertAndSend("/topic/"+roomId,payload);
	}
	
	
	public void exitPlayer(String sessionId) {
		try {
//			System.out.println("exitPlayer 실행");
			
			String mid = WebsocketController.sessionMap.get(sessionId);
			if(WebsocketController.userMap.get(mid) == null) return;
			String roomId = WebsocketController.userMap.get(mid).get("roomId");
			WebsocketController.sessionMap.remove(sessionId);
			WebsocketController.userMap.remove(mid);
			
			
			Map<String, String> roomData = new HashMap<String, String>();
			Map<String, String> newGameData = new HashMap<String, String>();
			roomData = WebsocketController.serverMap.get(roomId);
			newGameData = gameDataMap.get(roomId);
			
			
			String user1 = roomData.get("User1");
			String user2 = roomData.get("User2");
			String black = newGameData.get("black");
			String white = newGameData.get("white");
			
			if(black.equals(mid)) newGameData.put("black", "");
			else if(white.equals(mid)) newGameData.put("white","");
			newGameData.put("blackWin", "0");
			newGameData.put("whiteWin", "0");
			newGameData.put("rock", "");
			gameDataMap.put(roomId, newGameData);
			
			
			Map<String, String> newGameStartMap = new HashMap<String, String>();
			newGameStartMap.put("start", "0");
			WebsocketController.gameStartMap.put(roomId,newGameStartMap);
			WebsocketController.rockChangeMap.put(roomId, "0");
			
			if(user1.equals(mid)) roomData.put("User1", "");
			else if(user2.equals(mid)) roomData.put("User2", "");
			else return;
			
			int head = Integer.valueOf(roomData.get("head"));
			roomData.put("head", (head-1)+"");
			
//			System.out.println("끊긴 아이디 : " + mid);
//			System.out.println("끊긴 후 방정보 : " + roomData);
			WebsocketController.serverMap.put(roomId, roomData);
			changeinfor(roomId, roomData);
		} catch (NullPointerException e) {
			e.printStackTrace();
			System.out.println("*********** NULLPOINTER EXCEPTION ************");
		}
		
	}
	
	
}
