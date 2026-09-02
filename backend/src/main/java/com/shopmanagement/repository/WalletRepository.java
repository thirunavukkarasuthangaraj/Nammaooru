package com.shopmanagement.repository;

import com.shopmanagement.entity.Wallet;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface WalletRepository extends JpaRepository<Wallet, Long> {

    Optional<Wallet> findByOwnerTypeAndOwnerId(Wallet.WalletOwnerType ownerType, Long ownerId);

    Page<Wallet> findByOwnerTypeOrderByBalanceDesc(Wallet.WalletOwnerType ownerType, Pageable pageable);
}
