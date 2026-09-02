package com.shopmanagement.repository;

import com.shopmanagement.entity.WalletWithdrawal;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface WalletWithdrawalRepository extends JpaRepository<WalletWithdrawal, Long> {

    Page<WalletWithdrawal> findByWallet_IdOrderByRequestedAtDesc(Long walletId, Pageable pageable);

    Page<WalletWithdrawal> findByStatusOrderByRequestedAtAsc(WalletWithdrawal.WithdrawalStatus status, Pageable pageable);

    boolean existsByWallet_IdAndStatus(Long walletId, WalletWithdrawal.WithdrawalStatus status);
}
