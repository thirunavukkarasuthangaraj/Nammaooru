package com.shopmanagement.event;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class LoginEventListener {

    @EventListener
    public void handleLoginEvent(LoginEvent event) {
        switch (event.getResult()) {
            case SUCCESS -> log.info("[AUDIT] Login SUCCESS | user={} | source={}",
                    event.getIdentifier(), event.getLoginSource());
            case FAILURE -> log.warn("[AUDIT] Login FAILURE | user={} | source={} | error={}",
                    event.getIdentifier(), event.getLoginSource(), event.getErrorMessage());
            case FALLBACK -> log.info("[AUDIT] Login FALLBACK | user={} | source={}",
                    event.getIdentifier(), event.getLoginSource());
        }
    }
}
