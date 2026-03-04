package com.shopmanagement.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "microservice.user-service.enabled", havingValue = "true")
public class MicroserviceUserDetailsService implements UserDetailsService {

    private final UserServiceClient userServiceClient;

    @Override
    @Cacheable(value = "microservice-users", key = "#username")
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        log.info("Loading user '{}' from user-service microservice (not cached)", username);

        UserBasicDTO dto = userServiceClient.getUserByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException(
                        "User not found in user-service: " + username));

        log.info("User '{}' loaded from user-service (role: {})", username, dto.getRole());
        return userServiceClient.toUserEntity(dto);
    }
}
