package com.shopmanagement.service;

import org.springframework.stereotype.Service;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class TokenBlacklistService {
    
    // In production, use Redis or database instead of in-memory storage
    private final Set<String> blacklistedTokens = ConcurrentHashMap.newKeySet();
    
    public void blacklistToken(String token) {
        blacklistedTokens.add(token);
    }
    
    public boolean isTokenBlacklisted(String token) {
        return blacklistedTokens.contains(token);
    }
    
    public void removeExpiredTokens() {
        // This should be called periodically to clean up expired tokens
        // In production, Redis can handle TTL automatically
    }
    
    public int getBlacklistSize() {
        return blacklistedTokens.size();
    }
}