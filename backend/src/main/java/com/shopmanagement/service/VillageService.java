package com.shopmanagement.service;

import com.shopmanagement.entity.Village;
import com.shopmanagement.repository.VillageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class VillageService {

    private final VillageRepository villageRepository;

    public List<Village> getActiveVillages() {
        return villageRepository.findByIsActiveTrueOrderByDisplayOrderAscNameAsc();
    }

    public List<Village> getAllVillages() {
        return villageRepository.findAllByOrderByDisplayOrderAscNameAsc();
    }

    @Transactional
    public Village create(Village village) {
        return villageRepository.save(village);
    }

    @Transactional
    public Village update(Long id, Village updated) {
        Village existing = villageRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Village not found: " + id));
        existing.setName(updated.getName());
        existing.setNameTamil(updated.getNameTamil());
        existing.setDistrict(updated.getDistrict());
        existing.setPanchayatName(updated.getPanchayatName());
        existing.setPanchayatUrl(updated.getPanchayatUrl());
        existing.setDescription(updated.getDescription());
        existing.setIsActive(updated.getIsActive());
        existing.setDisplayOrder(updated.getDisplayOrder());
        return villageRepository.save(existing);
    }

    @Transactional
    public void delete(Long id) {
        villageRepository.deleteById(id);
    }

    @Transactional
    public Village toggleActive(Long id) {
        Village village = villageRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Village not found: " + id));
        village.setIsActive(!village.getIsActive());
        return villageRepository.save(village);
    }
}
