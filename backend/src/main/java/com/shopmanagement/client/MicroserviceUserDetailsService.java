package com.shopmanagement.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

@Slf4j
@RequiredArgsConstructor
public class MicroserviceUserDetailsService implements UserDetailsService {

    private final UserServiceClient userServiceClient;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        log.info("Loading user '{}' from user-service microservice", username);

        UserBasicDTO dto = userServiceClient.getUserByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException(
                        "User not found in user-service: " + username));

        log.info("User '{}' loaded from user-service (role: {})", username, dto.getRole());
        return userServiceClient.toUserEntity(dto);
    }
}
