package com.shopmanagement.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.Map;

@Data
@Component
@ConfigurationProperties(prefix = "email")
public class EmailProperties {
    
    private String from;
    private String fromName;
    private Map<String, String> templates;
    private Map<String, String> subject;
    
}