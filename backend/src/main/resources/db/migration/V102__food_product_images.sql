-- Real product photos for the 34 food-shop dishes seeded in V101 (shop id=3,
-- "Thiru food shop"). These were showing placeholder icons since V101 didn't
-- attach images. URLs are verified, appropriately-licensed (Wikimedia Commons,
-- public domain / CC-BY / CC-BY-SA) photos of the actual dish, hotlinked as
-- absolute https:// URLs — the app's image helper renders full URLs as-is.
-- Idempotent: only inserts if the master product doesn't already have an image.

INSERT INTO master_product_images (master_product_id, image_url, alt_text, is_primary, sort_order, created_by, created_at)
SELECT mp.id, v.image_url, v.alt_text, true, 1, 'system_seed', NOW()
FROM master_products mp
JOIN (VALUES
    ('FOOD-IDLI-001',       'https://upload.wikimedia.org/wikipedia/commons/7/75/Idli_%285194454248%29.jpg', 'Steamed white idli rice cakes'),
    ('FOOD-DOSA-002',       'https://upload.wikimedia.org/wikipedia/commons/d/d1/Dosa_Classic.jpg', 'Plain crispy dosa'),
    ('FOOD-MDOSA-003',      'https://upload.wikimedia.org/wikipedia/commons/4/43/Masala_dosa_01.jpg', 'Masala dosa with potato filling'),
    ('FOOD-PONGAL-004',     'https://upload.wikimedia.org/wikipedia/commons/2/21/Ven_pongal_with_sambar_and_chutney.jpg', 'Ven pongal with sambar and chutney'),
    ('FOOD-VADA-005',       'https://upload.wikimedia.org/wikipedia/commons/1/1b/Medu_Vada.JPG', 'Medu vada, fried lentil fritter'),
    ('FOOD-UTTAPAM-006',    'https://upload.wikimedia.org/wikipedia/commons/4/48/Uttapam.jpg', 'Uttapam, thick savory rice pancake'),
    ('FOOD-POORI-007',      'https://upload.wikimedia.org/wikipedia/commons/1/1e/Poori_with_Potato_Masala.JPG', 'Poori with potato masala'),
    ('FOOD-IDIYAPPAM-008',  'https://upload.wikimedia.org/wikipedia/commons/0/03/Idiyappam_and_curry_in_Green_leaf_plate.jpg', 'Idiyappam string hoppers with curry'),
    ('FOOD-PAROTTA-009',    'https://upload.wikimedia.org/wikipedia/commons/2/2a/Malabar_Porotta.jpg', 'Layered flaky parotta'),
    ('FOOD-CHAPATI-010',    'https://upload.wikimedia.org/wikipedia/commons/8/89/Chapati2.JPG', 'Soft whole wheat chapati'),

    ('FOOD-CBIRYANI-011',   'https://upload.wikimedia.org/wikipedia/commons/f/fe/Chicken_Biryani.jpg', 'Chicken biryani'),
    ('FOOD-MBIRYANI-012',   'https://upload.wikimedia.org/wikipedia/commons/6/68/Seeraga_Samba_Rice_Mutton_Biryani_01.JPG', 'Mutton biryani, seeraga samba rice'),
    ('FOOD-EBIRYANI-013',   'https://upload.wikimedia.org/wikipedia/commons/c/c8/Hyderabadi_egg_biryani.jpg', 'Egg biryani with boiled eggs'),
    ('FOOD-VBIRYANI-014',   'https://upload.wikimedia.org/wikipedia/commons/8/8f/Veg_Kaju_Biryani.jpg', 'Vegetable biryani with cashews'),
    ('FOOD-RICE-015',       'https://upload.wikimedia.org/wikipedia/commons/6/69/Bowl_of_white_rice_02.jpg', 'Bowl of plain steamed white rice'),
    ('FOOD-CURDRICE-016',   'https://upload.wikimedia.org/wikipedia/commons/4/43/Curd_Rice_ThayirSaadam.JPG', 'Curd rice (thayir saadam)'),
    ('FOOD-LEMONRICE-017',  'https://upload.wikimedia.org/wikipedia/commons/f/f0/Chitranna_%28Lemon_Rice%29_prepared_by_an_indian_woman.jpg', 'Lemon rice with peanuts and curry leaves'),

    ('FOOD-CCURRY-018',     'https://upload.wikimedia.org/wikipedia/commons/2/21/Chicken_curry.jpg', 'Chicken curry in spiced gravy'),
    ('FOOD-C65-019',        'https://upload.wikimedia.org/wikipedia/commons/5/5d/Chicken_65_%28Dish%29.jpg', 'Chicken 65, spicy fried chicken bites'),
    ('FOOD-CFRY-020',       'https://upload.wikimedia.org/wikipedia/commons/9/9b/Chicken_fry_spicy_Indian.jpg', 'Dry roasted spiced chicken fry'),
    ('FOOD-PEPCHICKEN-021', 'https://upload.wikimedia.org/wikipedia/commons/5/58/Spicy_Pepper_Chicken_Curry.jpg', 'Pepper chicken, dark semi-dry black pepper masala'),

    ('FOOD-MCURRY-022',     'https://upload.wikimedia.org/wikipedia/commons/d/d4/Mutton_Chettinad.jpg', 'Mutton Chettinad curry'),
    ('FOOD-MCHUKKA-023',    'https://upload.wikimedia.org/wikipedia/commons/6/63/Mutton_Chilli-Mangalore-Karnataka-DSC001.jpg', 'Dry roasted spiced mutton chukka'),
    ('FOOD-MFRY-024',       'https://upload.wikimedia.org/wikipedia/commons/7/75/Mutton_Fry.jpg', 'Mutton fry, dry-roasted spiced mutton'),

    ('FOOD-BCURRY-025',     'https://upload.wikimedia.org/wikipedia/commons/9/99/Beef_Masala_Curry.jpg', 'Beef curry in spiced gravy'),
    ('FOOD-BFRY-026',       'https://upload.wikimedia.org/wikipedia/commons/7/79/Beef_Fry.jpg', 'Dry roasted spiced beef fry'),
    ('FOOD-BULARTHI-027',   'https://upload.wikimedia.org/wikipedia/commons/0/08/Traditional_Beef_Ularthiyathu.JPG', 'Beef ularthiyathu with coconut'),

    ('FOOD-FISHFRY-028',    'https://upload.wikimedia.org/wikipedia/commons/f/f9/Fish_fry_%28in_Kerala_style%29.jpg', 'Kerala-style spiced fish fry'),
    ('FOOD-EGGCURRY-029',   'https://upload.wikimedia.org/wikipedia/commons/8/8b/Egg_Curry_2.jpg', 'Boiled egg in spiced curry gravy'),
    ('FOOD-OMELETTE-030',   'https://upload.wikimedia.org/wikipedia/commons/1/12/Masala_egg_omelette_%28cropped%29.jpeg', 'Indian-style spiced masala omelette'),
    ('FOOD-RASAM-031',      'https://upload.wikimedia.org/wikipedia/commons/f/fa/Rasam.JPG', 'Bowl of South Indian rasam'),
    ('FOOD-SAMBAR-032',     'https://upload.wikimedia.org/wikipedia/commons/1/15/Sambar.JPG', 'Bowl of South Indian sambar'),
    ('FOOD-CSOUP-033',      'https://upload.wikimedia.org/wikipedia/commons/1/19/Chicken_soup.jpg', 'Bowl of warm chicken soup'),
    ('FOOD-BUTTERMILK-034', 'https://upload.wikimedia.org/wikipedia/commons/8/8d/Mattha_2.jpg', 'Chilled spiced buttermilk (chaas)')
) AS v(sku, image_url, alt_text)
ON mp.sku = v.sku
WHERE NOT EXISTS (
    SELECT 1 FROM master_product_images mpi WHERE mpi.master_product_id = mp.id
);
