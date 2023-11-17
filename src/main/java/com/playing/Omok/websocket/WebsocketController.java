package com.playing.Omok.websocket;

import java.util.Base64;
import java.util.Base64.Decoder;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.stereotype.Service;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
//import com.vane.badwordfiltering.BadWordFiltering;

@Controller
@Service
public class WebsocketController {
	
	@Autowired
	private SimpMessagingTemplate simpMessagingTemplate;
	
	// 게임방 서버맵
	public static Map<String, Map<String, String>> serverMap = new HashMap<String, Map<String, String>>();
	// 게임방 비밀번호맵
	private static Map<String, String> pwdMap = new HashMap<String, String>();
	
	// 접속 중인 유저 정보
	public static Map<String, Map<String, String>> userMap = new HashMap<String, Map<String, String>>();
	
	// 게임방 입장시 웹소켓 세션 정보
	public static Map<String, String> sessionMap = new HashMap<String, String>();
	
	private static Map<String, String> roomData = new HashMap<String, String>();
	
	// 게임관련 MAP
	public static Map<String, String> rockChangeMap = new HashMap<String, String>();
	public static Map<String, Map<String, String>> gameStartMap = new HashMap<String, Map<String, String>>();
	
	private static Decoder decoder = Base64.getDecoder();
	
//	private BadWordFiltering badWordFiltering = new BadWordFiltering();
	
	@RequestMapping(value = {"/","/h"}, method = RequestMethod.GET)
	public String gameGet(HttpSession session, Model model) {
		String mid = (String)session.getAttribute("sMid") != null ? (String)session.getAttribute("sMid") : "";
		String random = UUID.randomUUID().toString().substring(0,3) + UUID.randomUUID().toString().substring(0,3);
		if(mid.equals("")) {
			mid = "Guest_"+random;
			session.setAttribute("sMid",mid);
		}
		return "content/lobby";
	}
	
	@RequestMapping(value = "/createRoom", method = RequestMethod.GET)
	public String createRoomGet(HttpSession session, Model model) {
		return "content/createRoom";
	}
	
	@ResponseBody
	@RequestMapping(value = "/createRoom", method = RequestMethod.POST)
	public Map<String, String> createRoomPost(HttpSession session, 
			@RequestParam("pwd") String pwd,
			@RequestParam("pwdSetting") String pwdSetting,
			@RequestParam("title") String title) {
		String roomId = UUID.randomUUID().toString().substring(0,4)+"-"+UUID.randomUUID().toString().substring(0,8);
		roomData = new HashMap<String, String>();
		while(true) {
			if(serverMap.get(roomId) != null) {
				roomId = UUID.randomUUID().toString().substring(0,4)+"-"+UUID.randomUUID().toString().substring(0,8);
				continue;
			}
			break;
		}
		Map<String, String> returnMap = new HashMap<String, String>();
		returnMap.put("result", "1");
		returnMap.put("id", roomId);
		
		// 비속어 필터링
		// https://github.com/VaneProject/bad-word-filtering
		// Java Runtime(클래스 파일 버전 55.0) 이슈[Java Runtime 52.0 까지만 인식]
//		if(badWordFiltering.check(title)) {
//			returnMap.put("result", "SlangTitle");
//			return returnMap;
//		}
		
		roomData.put("title", title);
		roomData.put("head", "0");
		roomData.put("User1", (String)session.getAttribute("sMid"));
		roomData.put("User2", "");
		roomData.put("pwdS", pwdSetting);
		if(pwdSetting.equals("on")) pwdMap.put(roomId, pwd);
		serverMap.put(roomId, roomData);
		;
		
		Map<String, String> gameMaps = new HashMap<String, String>();
		gameMaps.put("start", "0");
		gameStartMap.put(roomId,gameMaps);
		
		return returnMap;
	}
	
	@RequestMapping(value = "/game:{roomId}", method = RequestMethod.GET)
	public String entryRoom(@PathVariable String roomId, Model model, HttpSession session,
			@RequestParam(name = "p", defaultValue = "", required = false) String pwd) throws InterruptedException {
		Thread.sleep(500);
		
//		System.out.println("접속 메소드 : "+serverMap);
//		System.out.println("접속 메소드 : "+userMap);
//		System.out.println("접속 메소드 : "+sessionMap);
		
		if(serverMap.get(roomId) == null) return "redirect:/";
		String mid = (String)session.getAttribute("sMid");
		
		roomData = new HashMap<String, String>();
		roomData = serverMap.get(roomId);
		
		if(roomData.get("pwdS").equals("on")) {
			// java base64 : https://url.kr/oa82uw
			byte[] pwdByteData = decoder.decode(pwd);
			pwd = new String(pwdByteData);
			if(pwdMap.get(roomId) != null && !pwdMap.get(roomId).equals(pwd)) return "redirect:msg/pwdiswrong";
		}
		
		if(roomData.get("head").equals("2")) {
			if(!roomData.get("User1").equals(mid) && !roomData.get("User2").equals(mid)) return "redirect:/msg/fullRoom";
		}
		
		serverMap.put(roomId, roomData);
		model.addAllAttributes(roomData);
		model.addAllAttributes(WsCheckservice.gameDataMap.get(roomId));
		
		return "content/game";
	}
	
	
	@ResponseBody
	@RequestMapping(value = "/pwdCheck", method = RequestMethod.POST)
	public String pwdCheckPost(@RequestParam("pwd") String pwd,
			@RequestParam("roomId") String roomId, Model model) {
		int res = 0;
		if(pwd != null && pwdMap.get(roomId).equals(pwd)) res = 1;
		return res+"";
	}
	
	@RequestMapping(value = "/msg/{text}", method = RequestMethod.GET)
	public String msgController(@PathVariable String text, Model model, HttpServletRequest request) {
		String homeUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getLocalPort() + request.getContextPath();
		model.addAttribute("msg", text);
		model.addAttribute("url", homeUrl);
		return "content/msg";
	}
	
	@MessageMapping("/lobbyEnter")
	public @ResponseBody void lobbyMsg(@RequestBody Map<String, String> msg) {
		
//		System.out.println("1. "+serverMap);
//		System.out.println("2. "+userMap);
//		System.out.println("3. "+sessionMap);
		
		ObjectMapper mapper = new ObjectMapper();
		String payload = "";
		try {
			payload = mapper.writeValueAsString(serverMap);
		} catch (JsonProcessingException e) {
			e.printStackTrace();
		}
		simpMessagingTemplate.convertAndSend("/topic/lobby",payload);
	}
	
	@ResponseBody
	@RequestMapping(value = "/gameData:{roomId}", method = RequestMethod.POST)
	public void gameDataPost(@PathVariable String roomId ,@RequestBody Map<String, String> gameData) {
		Map<String, String> newGameData = WsCheckservice.gameDataMap.get(roomId);
		
		String mid = gameData.get("mid");
		String black = "";
		String white = "";
		
		if(newGameData == null) {
			newGameData = new HashMap<String, String>();
			newGameData.put("black", gameData.get("mid"));
			newGameData.put("white", "");
			newGameData.put("blackWin", "0");
			newGameData.put("whiteWin", "0");
			newGameData.put("rock", "");
		}
		else {
			black = newGameData.get("black");
			white = newGameData.get("white");
			if(!black.equals("") && !black.equals(mid)) white = mid;
			else black = mid;
			newGameData.put("black",black);
			newGameData.put("white",white);
		}
		
		WsCheckservice.gameDataMap.put(roomId, newGameData);
		ObjectMapper mapper = new ObjectMapper();
		String payload = "";
		try {
			payload = mapper.writeValueAsString(WsCheckservice.gameDataMap.get(roomId));
		} catch (JsonProcessingException e) {
			e.printStackTrace();
		}
		simpMessagingTemplate.convertAndSend("/topic/"+roomId+"game",payload);
	}
	
	@ResponseBody
	@RequestMapping(value = "/gameRockChange:{roomId}", method = RequestMethod.POST)
	public void gameRockChangePost(@PathVariable String roomId) {
		Map<String, String> newGameData = WsCheckservice.gameDataMap.get(roomId);
		
		String black = "";
		String blackWin = "";
		String white = "";
		String whiteWin = "";
		black = newGameData.get("black");
		blackWin = newGameData.get("blackWin");
		white = newGameData.get("white");
		whiteWin = newGameData.get("whiteWin");
		newGameData.put("black", white);
		newGameData.put("blackWin", whiteWin);
		newGameData.put("white", black);
		newGameData.put("whiteWin", blackWin);
		
		WsCheckservice.gameDataMap.put(roomId, newGameData);
		ObjectMapper mapper = new ObjectMapper();
		String payload = "";
		try {
			payload = mapper.writeValueAsString(WsCheckservice.gameDataMap.get(roomId));
		} catch (JsonProcessingException e) {
			e.printStackTrace();
		}
		simpMessagingTemplate.convertAndSend("/topic/"+roomId+"game",payload);
	}
	
	@ResponseBody
	@RequestMapping(value = "/getMyRoomData:{roomId}", method = RequestMethod.POST)
	public void getMyRoomDataPost(@PathVariable String roomId) {
		roomData = new HashMap<String, String>();
		roomData = serverMap.get(roomId);
		ObjectMapper mapper = new ObjectMapper();
		String payload = "";
		try {
			payload = mapper.writeValueAsString(roomData);
		} catch (JsonProcessingException e) {
			e.printStackTrace();
		}
		simpMessagingTemplate.convertAndSend("/topic/"+roomId,payload);
	}
	
	@ResponseBody
	@RequestMapping(value = "/getMyRoomGameData:{roomId}", method = RequestMethod.POST)
	public void getMyRoomGameDataPost(@PathVariable String roomId) {
		Map<String, String> newGameData = WsCheckservice.gameDataMap.get(roomId);
		ObjectMapper mapper = new ObjectMapper();
		String payload = "";
		try {
			payload = mapper.writeValueAsString(newGameData);
		} catch (JsonProcessingException e) {
			e.printStackTrace();
		}
		simpMessagingTemplate.convertAndSend("/topic/"+roomId+"game",payload);
	}
	
	@ResponseBody
	@RequestMapping(value = "/gameRockChangeQA:{roomId}", method = RequestMethod.POST)
	public void gameRockChangeQAPost(@PathVariable String roomId, HttpSession session) {
		Map<String, String> newGameData = WsCheckservice.gameDataMap.get(roomId);
		if(gameStartMap.get(roomId).get("start").equals("1")) return;
		if(newGameData.get("white").equals("") || newGameData.get("black").equals("")) {
			gameRockChangePost(roomId);
			return;
		}
		Map<String, String> answerMap = new HashMap<String, String>();
		answerMap.put("send", (String)session.getAttribute("sMid"));
		answerMap.put("what", "Q");
		answerMap.put("ans", "");
		rockChangeMap.put(roomId, "1");
		
		ObjectMapper mapper = new ObjectMapper();
		String payload = "";
		try {
			payload = mapper.writeValueAsString(answerMap);
		} catch (JsonProcessingException e) {
			e.printStackTrace();
		}
		simpMessagingTemplate.convertAndSend("/topic/"+roomId+"rock",payload);
	}
	
	@ResponseBody
	@RequestMapping(value = "/gameRockChangeOk:{roomId}", method = RequestMethod.POST)
	public void gameRockChangeOkPost(@PathVariable String roomId) {
		if(rockChangeMap.get(roomId).equals("0") || rockChangeMap.get(roomId) == null) return;
		else if(gameStartMap.get(roomId).get("start") == "1") return;
		else if(rockChangeMap.get(roomId).equals("1")) gameRockChangePost(roomId);
		else return;
	}
	
	@ResponseBody
	@RequestMapping(value = "/gameRockChangeReset:{roomId}", method = RequestMethod.POST)
	public void gameRockChangeCanclePost(@PathVariable String roomId, HttpSession session) {
		Map<String, String> answerMap = new HashMap<String, String>();
		answerMap.put("send", (String)session.getAttribute("sMid"));
		answerMap.put("what", "Reset");
		rockChangeMap.put(roomId, "0");
		
		ObjectMapper mapper = new ObjectMapper();
		String payload = "";
		try {
			payload = mapper.writeValueAsString(answerMap);
		} catch (JsonProcessingException e) {
			e.printStackTrace();
		}
		simpMessagingTemplate.convertAndSend("/topic/"+roomId+"rock",payload);
	}
	
	@ResponseBody
	@RequestMapping(value = "/gameChat:{roomId}", method = RequestMethod.POST)
	public void gameChatPost(@PathVariable String roomId, @RequestParam("mid") String mid, @RequestParam("msg") String msg) {
		Map<String, String> chatMap = new HashMap<String, String>();
		chatMap.put("mid", mid);
		chatMap.put("msg", msg);
		
		ObjectMapper mapper = new ObjectMapper();
		String payload = "";
		try {
			payload = mapper.writeValueAsString(chatMap);
		} catch (JsonProcessingException e) {
			e.printStackTrace();
		}
		simpMessagingTemplate.convertAndSend("/topic/"+roomId+"chat",payload);
	}
	
	@ResponseBody
	@RequestMapping(value = "/gameStart:{roomId}", method = RequestMethod.POST)
	public void gameStartPost(@PathVariable String roomId) throws JsonProcessingException {
		
		ObjectMapper mapper = new ObjectMapper();
		Map<String, String> gameMap = WsCheckservice.gameDataMap.get(roomId);
		Map<String, String> gameStartMaps = gameStartMap.get(roomId);
		
		if(gameStartMap.get(roomId).get("start").equals("1")) return;
		else if(gameMap.get("black").equals("") || gameMap.get("white").equals("")) return;
		rockChangeMap.put(roomId, "0");
		
		gameMap.put("sign", "start");
		gameMap.put("rockColor", "black");
		
		gameStartMaps.put("start", "1");
		gameStartMaps.put("turn", gameMap.get("black"));
		gameStartMaps.put("rockColor", "black");
		gameStartMaps.put("blackNick", gameMap.get("black"));
		gameStartMaps.put("whiteNick", gameMap.get("white"));
		String[][] coodMap = new String[19][19];
		for(int i=0; i<19; i++) {
			for(int j=0; j<19; j++) {
				coodMap[i][j] = "transparent";
			}
		}
		gameStartMaps.put("coodMap", mapper.writeValueAsString(coodMap));
		
		gameStartMap.put(roomId, gameStartMaps);
		
		String payload = "";
		try {
			payload = mapper.writeValueAsString(gameMap);
		} catch (JsonProcessingException e) {
			e.printStackTrace();
		}
		simpMessagingTemplate.convertAndSend("/topic/"+roomId+"branch",payload);
	}
	
	@ResponseBody
	@RequestMapping(value = "/branch:{roomId}", method = RequestMethod.POST)
	public boolean branchPost(@PathVariable String roomId, @RequestParam("cood") String cood, HttpSession session) {
		ObjectMapper mapper = new ObjectMapper();
		
		Map<String, String> gameMap = gameStartMap.get(roomId);
		if(gameMap == null || !gameMap.get("turn").equals((String)session.getAttribute("sMid"))) return false;
		
		gameMap.put("sign", "branch");
		String[][] coodMap = null;
		String nowTrun = gameMap.get("turn");
		String nowColor = gameMap.get("rockColor");
		try {
			coodMap = mapper.readValue(gameMap.get("coodMap"), String[][].class);
			int x = Integer.valueOf(cood.split("-")[0]);
			int y = Integer.valueOf(cood.split("-")[1]);
			if(!coodMap[x][y].equals("transparent")) {
				if((coodMap[x][y].equals("33X") || coodMap[x][y].equals("44X")) && nowColor.equals("white"));
				else return false;
			}
			coodMap[x][y] = nowColor;
//			
			
			int checkLX = 0;
			int checkLY = 0;
			int checkRX = 18;
			int checkRY = 18;
			
			String checkLine = "";
			int tempX1 = 0;
			int tempX2 = 0;
			int tempY1 = 0;
			int tempY2 = 0;
			
			int res = 0;
			for(int i=0; i<4; i++) {
				checkLine = "";
				int XYcnt = 0;
				tempX1 = x-5 < 0 ? 0 : x-5;
				tempX2 = x+5 > 18 ? 18 : x+5;
				tempY1 = y-5 < 0 ? 0 : y-5;
				tempY2 = y+5 > 18 ? 18 : y+5;
				int startX = 0; int startY = 0;
				if(i == 0) {
					if(tempX2 - tempX1 != tempY2 - tempY1) XYcnt = tempX2 - tempX1 < tempY2 - tempY1 ? tempX2 - tempX1 : tempY2 - tempY1;
					else XYcnt = tempX2 - tempX1;
					if(x == 0 || y == 0) {startX = x; startY = y;}
					else {
						startX = x-4; startY = y-4;
						if(startX<0 || startY<0) {
							int distance = startX < startY ? startX : startY;
							startX -= distance;
							startY -= distance;
						}
					}
					for(int p=0; p<=XYcnt; p++) {
						if(startX+p > 18 || startY+p > 18) continue;
						else checkLine += createLine(coodMap[startX+p][startY+p]);
					}
					res = check5(checkLine);
				}
				else if(i == 1) {
					if(tempX2 - tempX1 != tempY2 - tempY1) XYcnt = tempX2 - tempX1 < tempY2 - tempY1 ? tempX2 - tempX1 : tempY2 - tempY1;
					else XYcnt = tempX2 - tempX1;
					if(x == 0 || y == 18) {startX = x; startY = y;}
					else {
						startX = x-4; startY = y+4;
						if(startX<0 || startY>18) {
							int distance = startX < (startY-18)*(-1) ? startX : (startY-18)*(-1);
							startX -= distance;
							startY += distance;
						}
					}
					for(int p=0; p<=XYcnt; p++) {
						if(startX+p > 18 || startY-p < 0) continue;
						else checkLine += createLine(coodMap[startX+p][startY-p]);
					}
					res = check5(checkLine);
				}
				else if(i == 2) {
					startX = x;
					startY = 0;
					XYcnt = tempY2 - tempY1 < 0 ? 0 : tempY2 - tempY1;
					
					if(y == 0) startY = y;
					else {
						startY = y-4;
						if(startY<0) startY=0;
					}
					for(int p=0; p<=XYcnt; p++) {
						if(startY+p > 18) continue;
						else checkLine += createLine(coodMap[startX][startY+p]);
					}
					res = check5(checkLine);
				}
				else if(i == 3) {
					startX = 0;
					startY = y;
					XYcnt = tempX2 - tempX1 < 0 ? 0 : tempX2 - tempX1;
					
					if(x == 0) startX = x;
					else {
						startX = x-4;
						if(startX<0) startX=0;
					}
					for(int p=0; p<=XYcnt; p++) {
						if(startX+p > 18) continue;
						else checkLine += createLine(coodMap[startX+p][startY]);
					}
					res = check5(checkLine);
				}
				if(res == 1) {
					gameMap.put("sign", "end");
					gameMap.put("win", gameMap.get("blackNick"));
					gameMap.put("start", "0");
					
					int blackWin = Integer.valueOf(WsCheckservice.gameDataMap.get(roomId).get("blackWin"));
					blackWin++;
					Map<String, String> gameDataMap = WsCheckservice.gameDataMap.get(roomId);
					gameDataMap.put("blackWin", blackWin+"");
					WsCheckservice.gameDataMap.put(roomId, gameDataMap);
					
					break;
				}
				else if(res == 2) {
					gameMap.put("sign", "end");
					gameMap.put("win", gameMap.get("whiteNick"));
					gameMap.put("start", "0");
					
					int whiteWin = Integer.valueOf(WsCheckservice.gameDataMap.get(roomId).get("whiteWin"));
					whiteWin++;
					Map<String, String> gameDataMap = WsCheckservice.gameDataMap.get(roomId);
					gameDataMap.put("whiteWin", whiteWin+"");
					WsCheckservice.gameDataMap.put(roomId, gameDataMap);
					
					break;
				}
			}
			
			for(int i=checkLX; i<=checkRX; i++) {
				if(gameMap.get("sign").equals("end")) break;
				for(int j=checkLY; j<=checkRY; j++) {
					int threeCnt = 0;	// 2번 이상시 33 금수
					int fourCnt = 0;	// 2번 이상시 44 금수
					
					
					// 금수 검사 자리의 범위 지정
					tempX1 = i-4 < 0 ? 0 : i-4;
					tempX2 = i+4 > 18 ? 18 : i+4;
					tempY1 = j-4 < 0 ? 0 : j-4;
					tempY2 = j+4 > 18 ? 18 : j+4;
					
					for(int cnt=1; cnt<=4; cnt++) {
						// 좌상 -> 우하 검사
						if(cnt == 1) {
							checkLine = "";
							// 1줄 검사시 몇개의 돌을 검사
							int XYcnt = 0;
							int startX = 0;
							int startY = 0;
							if(tempX2 - tempX1 != tempY2 - tempY1) XYcnt = tempX2 - tempX1 < tempY2 - tempY1 ? tempX2 - tempX1 : tempY2 - tempY1;
							else XYcnt = tempX2 - tempX1;
							
							// 검사 시작 위치 설정
							if(i == 0 || j == 0) {
								startX = i; startY = j;
							}
							else {
								startX = i-4; startY = j-4;
								if(startX<0 || startY<0) {
									int distance = startX < startY ? startX : startY;
									startX -= distance;
									startY -= distance;
								}
							}
							for(int p=0; p<=XYcnt; p++) {
								if(startX+p > 18 || startY+p > 18) continue;
								if(startX+p <= 0 || startY+p <= 0) checkLine += "b";
								if(startX+p == i && startY+p == j) checkLine += "A";
								else checkLine += createLine(coodMap[startX+p][startY+p]);
							}
//							System.out.println("XY : "+XYcnt+"  X : "+startX+"  Y : "+startY+"  checkLine : "+checkLine);
							threeCnt += check33(checkLine);
							fourCnt += check44(checkLine);
						}
						// 좌하 -> 우상 검사
						else if (cnt == 2) {
							checkLine = "";
							// 1줄 검사시 몇개의 돌을 검사
							int XYcnt = 0;
							int startX = 0;
							int startY = 0;
							if(tempX2 - tempX1 != tempY2 - tempY1) XYcnt = tempX2 - tempX1 < tempY2 - tempY1 ? tempX2 - tempX1 : tempY2 - tempY1;
							else XYcnt = tempX2 - tempX1;
							
							// 검사 시작 위치 설정
							if(i == 0 || j == 18) {
								startX = i; startY = j;
							}
							else {
								startX = i-4; startY = j+4;
								int distance = 0;
								if(startX<0 || startY>18) {
									distance = startX < (startY-18)*(-1) ? startX : (startY-18)*(-1);
									startX -= distance;
									startY += distance;
								}
							}
							for(int p=0; p<=XYcnt; p++) {
								if(startX+p > 18 || startY-p < 0) continue;
								if(startX+p <= 0 || startY-p <= 0) checkLine += "b";
								if(startX+p == i && startY-p == j) checkLine += "A";
								else checkLine += createLine(coodMap[startX+p][startY-p]);
							}
							threeCnt += check33(checkLine);
							fourCnt += check44(checkLine);
						}
						// 상 -> 하 검사
						else if (cnt == 3) {
							checkLine = "";
							// 1줄 검사시 몇개의 돌을 검사
							int XYcnt = tempY2 - tempY1 < 0 ? 0 : tempY2 - tempY1;
							int startX = i;
							int startY = 0;
							
							// 검사 시작 위치 설정
							if(j == 0) startY = j;
							else {
								startY = j-4;
								if(startY<0) startY=0;
							}
							for(int p=0; p<=XYcnt; p++) {
								if(startY+p <= 0) checkLine += "b";
								if(startY+p == j) checkLine += "A";
								else checkLine += createLine(coodMap[startX][startY+p]);
							}
							threeCnt += check33(checkLine);
							fourCnt += check44(checkLine);
						}
						// 좌 -> 우 검사
						else if (cnt == 4) {
							checkLine = "";
							// 1줄 검사시 몇개의 돌을 검사
							int XYcnt = tempX2 - tempX1 < 0 ? 0 : tempX2 - tempX1;
							int startX = 0;
							int startY = j;
							
							// 검사 시작 위치 설정
							if(i == 0) startX = i;
							else {
								startX = i-4;
								if(startX<0) startX=0;
							}
							for(int p=0; p<=XYcnt; p++) {
								if(startX+p <= 0) checkLine += "b";
								if(startX+p == i) checkLine += "A";
								else checkLine += createLine(coodMap[startX+p][startY]);
							}
							threeCnt += check33(checkLine);
							fourCnt += check44(checkLine);
						}
					}
					if(threeCnt >= 2) {
						if(!coodMap[i][j].equals("black") && !coodMap[i][j].equals("white")) coodMap[i][j] = "33X";
					}
					else if(fourCnt>= 2) {
						if(!coodMap[i][j].equals("black") && !coodMap[i][j].equals("white")) coodMap[i][j] = "44X";
					}
					else if(coodMap[i][j].equals("33X") || coodMap[i][j].equals("44X")) {
						coodMap[i][j] = "transparent";
					}
				}
			}
			
			gameMap.put("coodMap", mapper.writeValueAsString(coodMap));
			if(gameMap.get("blackNick").equals(nowTrun)) {
				gameMap.put("turn", gameMap.get("whiteNick"));
				gameMap.put("rockColor", "white");
			}
			else if(gameMap.get("whiteNick").equals(nowTrun)) {
				gameMap.put("turn", gameMap.get("blackNick"));
				gameMap.put("rockColor", "black");
			}
			else return false;
		} catch (Exception e) {
			e.printStackTrace();
			return false;
		}
		gameStartMap.put(roomId, gameMap);
		String payload = "";
		try {
			payload = mapper.writeValueAsString(gameMap);
		} catch (JsonProcessingException e) {
			e.printStackTrace();
		}
		simpMessagingTemplate.convertAndSend("/topic/"+roomId+"branch",payload);
		return true;
	}
	
	private String createLine(String str) {
		String lineWord = "";
		if(str.equals("transparent") || str.equals("33X") || str.equals("44X")) lineWord = "x";
		else if(str.equals("black")) lineWord = "o";
		else if(str.equals("white")) lineWord = "w";
		return lineWord;
	}
	
	private int check33(String line) {
		int checking = 0;
		
//		System.out.println(line);
		
		if(line.contains("ooxA")) {
			line = line.replace("ooxA", "A");
			if(line.contains("bA") || line.contains("Ao") || line.contains("oA") || line.contains("Aw") ||
				 line.contains("wA") || line.contains("Ab")) checking = 0;
			else checking = 1;
		}
		else if(line.contains("oxoA")) {
			line = line.replace("oxoA", "A");
			if(line.contains("bA") || line.contains("Ao") || line.contains("oA") || line.contains("Aw") ||
				 line.contains("wA") || line.contains("Ab")) checking = 0;
			else checking = 1;
		}
		else if(line.contains("ooA")) {
			line = line.replace("ooA", "A");
			if(line.contains("bA") || line.contains("oA") || line.contains("Ao") || line.contains("wA") ||
				 line.contains("Aw") || line.contains("Ab") || line.contains("Axo")) checking = 0;
			else checking = 1;
		}
		else if(line.contains("oxAo")) {
			line = line.replace("oxAo", "A");
			if(line.contains("bA") || line.contains("oA") || line.contains("Ao") || line.contains("wA") ||
				 line.contains("Aw") || line.contains("Ab")) checking = 0;
			else checking = 1;
		}
		else if(line.contains("oAo")) {
			line = line.replace("oAo", "A");
			if(line.contains("bA") || line.contains("oA") || line.contains("Ao") || line.contains("wA") ||
					line.contains("Aw") || line.contains("Ab") || line.contains("Axo") || line.contains("oxA")) checking = 0;
			else checking = 1;
		}
		else if(line.contains("oAxo")) {
			line = line.replace("oAxo", "A");
			if(line.contains("bA") || line.contains("oA") || line.contains("Ao") || line.contains("wA") ||
				 line.contains("Aw") || line.contains("Ab")) checking = 0;
			else checking = 1;
		}
		else if(line.contains("Aoo")) {
			line = line.replace("Aoo", "A");
			if(line.contains("bA") || line.contains("oA") || line.contains("Ao") || line.contains("wA") ||
				 line.contains("Aw") || line.contains("Ab") || line.contains("oxA")) checking = 0;
			else checking = 1;
		}
		else if(line.contains("Aoxo")) {
			line = line.replace("Aoxo", "A");
			if(line.contains("bA") || line.contains("Ao") || line.contains("oA") || line.contains("Aw") ||
				 line.contains("wA") || line.contains("Ab")) checking = 0;
			else checking = 1;
		}
		else if(line.contains("Axoo")) {
			line = line.replace("Axoo", "A");
			if(line.contains("bA") || line.contains("Ao") || line.contains("oA") || line.contains("Aw") ||
				 line.contains("wA") || line.contains("Ab")) checking = 0;
			else checking = 1;
		}
		return checking;
	}
	
	private int check44(String line) {
		int checking = 0;
		int length = line.length();
		String checkLine = "";
		for(int i=length; i>=5; i--) {
			checkLine = line.substring(i-5,i);
			// 스트림이용 (문자열 문자수 구하기) x : 빈공간 , w : 백
			long xCnt = checkLine.chars().filter(c -> c == 'x').count();
			long wCnt = checkLine.chars().filter(c -> c == 'w').count();
			if(xCnt <= 1 && wCnt <= 1) {
				//w가 있을 경우 x는 0, 없을 경우 x가 1일때 허용
				if(((checkLine.indexOf("w") == 0 || checkLine.indexOf("w") == 4) && xCnt == 0) ||
						(checkLine.indexOf("w") == -1 && xCnt == 1)) {
					if(line.replace("A", "").contains("oooo")) checking = 0;
					else {
						checking = 1;
						break;
					}
				}
			}
		}
		return checking;
	}
	
	public int check5(String line) {
		int checking = 0;
		if(line.contains("ooooo")) {
			line = line.replace("ooooo", "A");
			if(line.contains("oA") || line.contains("Ao")) checking = 2;
			else checking = 1;
		}
		else if (line.contains("wwwww")) checking = 2;
		return checking;
	}
	
}
