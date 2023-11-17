package com.playing.Omok.websocket;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.AbstractWebSocketMessageBrokerConfigurer;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;

@Configuration
@EnableWebSocketMessageBroker
public class SocketConfiguration extends AbstractWebSocketMessageBrokerConfigurer  {
	
	@Override
	public void configureMessageBroker(MessageBrokerRegistry config) {
		config.enableSimpleBroker("/topic","queue");
		config.setApplicationDestinationPrefixes("/app");
	}
	@Override
	public void registerStompEndpoints(StompEndpointRegistry stompEndpointRegistry) {
		stompEndpointRegistry.addEndpoint("/lobbyEnter");
		stompEndpointRegistry.addEndpoint("/lobbyEnter").withSockJS();
		stompEndpointRegistry.addEndpoint("/infor");
		stompEndpointRegistry.addEndpoint("/infor").withSockJS();
		stompEndpointRegistry.addEndpoint("/gameData");
		stompEndpointRegistry.addEndpoint("/gameData").withSockJS();
		stompEndpointRegistry.addEndpoint("/rock");
		stompEndpointRegistry.addEndpoint("/rock").withSockJS();
		stompEndpointRegistry.addEndpoint("/chat");
		stompEndpointRegistry.addEndpoint("/chat").withSockJS();
		stompEndpointRegistry.addEndpoint("/branch");
		stompEndpointRegistry.addEndpoint("/branch").withSockJS();
	}
	
	
}
