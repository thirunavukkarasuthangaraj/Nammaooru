package com.shopmanagement.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Works out the final, ordered image list for a post when an admin saves the edit dialog.
 *
 * The dialog sends `keepImageUrls` as the FINAL ORDER. An entry is either an image the post
 * already has, or the token {@code NEW:<i>} standing for {@code newImages[i]}. That is what lets
 * a freshly uploaded photo be placed first and become the post's cover image; previously new
 * uploads were always appended, so the cover could never be changed to a new photo.
 *
 * Any new file the client did not place explicitly is appended at the end, so an older client
 * that sends no tokens behaves exactly as before.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PostImageOrderService {

    private static final String NEW_TOKEN_PREFIX = "NEW:";

    private final FileUploadService fileUploadService;

    /**
     * @param currentCsv  the post's stored comma-separated image URLs, used to reject any kept
     *                    entry that the post does not actually own
     * @param keepImageUrls the ordered list from the client; may contain NEW:i tokens
     * @param newImages   the uploaded files, indexed by the tokens
     * @param folder      upload folder for this module
     */
    public List<String> resolveOrderedImages(String currentCsv,
                                             List<String> keepImageUrls,
                                             List<MultipartFile> newImages,
                                             String folder) throws IOException {

        Set<String> owned = new LinkedHashSet<>();
        if (currentCsv != null && !currentCsv.isBlank()) {
            Arrays.stream(currentCsv.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .forEach(owned::add);
        }

        List<String> kept = keepImageUrls != null ? keepImageUrls : List.of();
        List<MultipartFile> incoming = newImages != null ? newImages : List.of();

        String[] uploaded = new String[incoming.size()];
        boolean[] placed = new boolean[incoming.size()];
        List<String> finalUrls = new ArrayList<>();

        for (String rawEntry : kept) {
            if (rawEntry == null) continue;
            String entry = rawEntry.trim();
            if (entry.isEmpty()) continue;

            if (entry.startsWith(NEW_TOKEN_PREFIX)) {
                int idx;
                try {
                    idx = Integer.parseInt(entry.substring(NEW_TOKEN_PREFIX.length()).trim());
                } catch (NumberFormatException e) {
                    log.warn("Ignoring malformed image slot token: {}", entry);
                    continue;
                }
                if (idx < 0 || idx >= incoming.size()) {
                    log.warn("Ignoring image slot token out of range: {}", entry);
                    continue;
                }
                MultipartFile file = incoming.get(idx);
                if (file == null || file.isEmpty()) continue;
                if (uploaded[idx] == null) {
                    uploaded[idx] = fileUploadService.uploadFile(file, folder);
                }
                placed[idx] = true;
                finalUrls.add(uploaded[idx]);
                continue;
            }

            // Only keep paths the post already owns. Without this an admin-authenticated caller
            // could point a post's images at any arbitrary path or external URL they liked.
            if (owned.contains(entry)) {
                finalUrls.add(entry);
            } else {
                log.warn("Ignoring image url that does not belong to this post: {}", entry);
            }
        }

        for (int i = 0; i < incoming.size(); i++) {
            if (placed[i]) continue;
            MultipartFile file = incoming.get(i);
            if (file == null || file.isEmpty()) continue;
            if (uploaded[i] == null) {
                uploaded[i] = fileUploadService.uploadFile(file, folder);
            }
            finalUrls.add(uploaded[i]);
        }

        return finalUrls;
    }

    public String toCsv(List<String> urls) {
        return (urls == null || urls.isEmpty()) ? null : String.join(",", urls);
    }
}
