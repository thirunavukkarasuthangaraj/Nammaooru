package com.shopmanagement.event;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;

@Getter
public class LoginEvent extends ApplicationEvent {

    public enum Result {
        SUCCESS, FAILURE, FALLBACK
    }

    private final String identifier;
    private final Result result;
    private final String loginSource;
    private final String errorMessage;

    public LoginEvent(Object eventSource, String identifier, Result result, String loginSource, String errorMessage) {
        super(eventSource);
        this.identifier = identifier;
        this.result = result;
        this.loginSource = loginSource;
        this.errorMessage = errorMessage;
    }
}
