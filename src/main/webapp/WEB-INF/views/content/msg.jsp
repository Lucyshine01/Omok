<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<c:set var="ctp" value="${pageContext.request.contextPath}"/>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>오류</title>
  <!-- 순서 서버 언어 => 뷰 언어 -->
  <script>
  	'use strict'
  	 
  	let msg = "${msg}";
  	let url = "${url}";
  	
  	if(msg == "fullRoom") msg = "방의 정원이 가득찼습니다.";
  	else if(msg == "pwdiswrong") msg = "비밀번호가 틀립니다.";
  	
  	
  	if(msg != "") alert(msg);
		if(url != "") location.href = url;
  </script>
  <style></style>
</head>
<body>
</body>
</html>