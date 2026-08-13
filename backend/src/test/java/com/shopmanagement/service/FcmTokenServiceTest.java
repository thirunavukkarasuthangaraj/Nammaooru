package com.shopmanagement.service;

import com.shopmanagement.dto.fcm.FcmTokenRequest;
import com.shopmanagement.entity.UserFcmToken;
import com.shopmanagement.repository.UserFcmTokenRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class FcmTokenServiceTest {

    private static final String TOKEN = "fcm-token-abc";

    private UserFcmTokenRepository repository;
    private FcmTokenService service;

    @BeforeEach
    void setUp() {
        repository = mock(UserFcmTokenRepository.class);
        when(repository.save(any(UserFcmToken.class))).thenAnswer(inv -> inv.getArgument(0));
        service = new FcmTokenService(repository);
    }

    private UserFcmToken row(Long id, Long userId, boolean active) {
        UserFcmToken t = new UserFcmToken(userId, TOKEN, "android");
        t.setId(id);
        t.setIsActive(active);
        return t;
    }

    private FcmTokenRequest request() {
        return new FcmTokenRequest(TOKEN, "android", "device-1");
    }

    @Test
    void firstRegistrationCreatesActiveMapping() {
        when(repository.findAllByFcmToken(TOKEN)).thenReturn(List.of());
        when(repository.findByUserIdAndIsActiveTrue(101L)).thenReturn(List.of());

        UserFcmToken saved = service.registerToken(101L, request());

        assertEquals(101L, saved.getUserId());
        assertEquals(TOKEN, saved.getFcmToken());
        assertTrue(saved.getIsActive());
    }

    @Test
    void sameUserReloginReactivatesExistingRowWithoutDuplicate() {
        UserFcmToken existing = row(1L, 101L, false); // deactivated at logout
        when(repository.findAllByFcmToken(TOKEN)).thenReturn(List.of(existing));

        UserFcmToken saved = service.registerToken(101L, request());

        assertSame(existing, saved);
        assertTrue(saved.getIsActive());
        // No new row: only the existing row was saved
        verify(repository, times(1)).save(any(UserFcmToken.class));
    }

    @Test
    void otherUsersActiveMappingIsDeactivatedOnRegistration() {
        UserFcmToken previousUserRow = row(1L, 101L, true); // user A still active
        when(repository.findAllByFcmToken(TOKEN)).thenReturn(List.of(previousUserRow));
        when(repository.findByUserIdAndIsActiveTrue(205L)).thenReturn(List.of());

        UserFcmToken saved = service.registerToken(205L, request());

        assertFalse(previousUserRow.getIsActive());
        assertEquals(205L, saved.getUserId());
        assertTrue(saved.getIsActive());
    }

    @Test
    void duplicateRowsForSameUserAreCollapsedToOneActive() {
        UserFcmToken first = row(1L, 101L, true);
        UserFcmToken duplicate = row(2L, 101L, true);
        when(repository.findAllByFcmToken(TOKEN)).thenReturn(List.of(first, duplicate));

        UserFcmToken saved = service.registerToken(101L, request());

        assertSame(first, saved);
        assertTrue(first.getIsActive());
        assertFalse(duplicate.getIsActive());
    }

    @Test
    void registrationIsIdempotent() {
        UserFcmToken existing = row(1L, 101L, true);
        when(repository.findAllByFcmToken(TOKEN)).thenReturn(List.of(existing));

        service.registerToken(101L, request());
        service.registerToken(101L, request());

        assertTrue(existing.getIsActive());
        ArgumentCaptor<UserFcmToken> captor = ArgumentCaptor.forClass(UserFcmToken.class);
        verify(repository, times(2)).save(captor.capture());
        assertTrue(captor.getAllValues().stream().allMatch(t -> t == existing));
    }

    @Test
    void rotatedTokenDeactivatesOldTokenForSameDevice() {
        UserFcmToken oldDeviceToken = new UserFcmToken(101L, "old-token", "android");
        oldDeviceToken.setId(1L);
        oldDeviceToken.setDeviceId("device-1");
        oldDeviceToken.setIsActive(true);

        when(repository.findAllByFcmToken(TOKEN)).thenReturn(List.of());
        when(repository.findByUserIdAndIsActiveTrue(101L)).thenReturn(List.of(oldDeviceToken));

        UserFcmToken saved = service.registerToken(101L, request());

        assertFalse(oldDeviceToken.getIsActive());
        assertEquals(TOKEN, saved.getFcmToken());
        assertTrue(saved.getIsActive());
    }

    @Test
    void logoutDeactivatesOnlyThatUsersMapping() {
        UserFcmToken mine = row(1L, 101L, true);
        when(repository.findAllByUserIdAndFcmToken(101L, TOKEN)).thenReturn(List.of(mine));

        service.deactivateToken(101L, TOKEN);

        assertFalse(mine.getIsActive());
        verify(repository).save(mine);
    }

    @Test
    void logoutWithNoMappingIsANoOp() {
        when(repository.findAllByUserIdAndFcmToken(101L, TOKEN)).thenReturn(List.of());

        service.deactivateToken(101L, TOKEN);

        verify(repository, never()).save(any());
    }

    @Test
    void blankTokenIsRejected() {
        assertThrows(IllegalArgumentException.class,
                () -> service.registerToken(101L, new FcmTokenRequest("  ", "android", null)));
    }
}
