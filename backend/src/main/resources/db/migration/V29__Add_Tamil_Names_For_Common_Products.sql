-- Add Tamil names for common grocery products
-- This script updates existing products with their Tamil translations

-- Rice varieties
UPDATE master_products SET name_tamil = 'அரிசி' WHERE name ILIKE '%rice%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'பாஸ்மதி அரிசி' WHERE name ILIKE '%basmati%rice%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'சோனா மசூரி அரிசி' WHERE name ILIKE '%sona%masoori%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'இட்லி அரிசி' WHERE name ILIKE '%idli%rice%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'பொன்னி அரிசி' WHERE name ILIKE '%ponni%rice%' AND name_tamil IS NULL;

-- Sugar and sweeteners
UPDATE master_products SET name_tamil = 'சர்க்கரை' WHERE name ILIKE '%sugar%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'வெல்லம்' WHERE name ILIKE '%jaggery%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'கருப்பட்டி' WHERE name ILIKE '%palm%jaggery%' AND name_tamil IS NULL;

-- Milk and dairy
UPDATE master_products SET name_tamil = 'பால்' WHERE name ILIKE '%milk%' AND name NOT ILIKE '%coconut%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'தேங்காய் பால்' WHERE name ILIKE '%coconut%milk%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'தயிர்' WHERE name ILIKE '%curd%' OR name ILIKE '%yogurt%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'நெய்' WHERE name ILIKE '%ghee%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'வெண்ணெய்' WHERE name ILIKE '%butter%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'பாலாடைக்கட்டி' WHERE name ILIKE '%cheese%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'பன்னீர்' WHERE name ILIKE '%paneer%' AND name_tamil IS NULL;

-- Tea and coffee
UPDATE master_products SET name_tamil = 'தேநீர்' WHERE name ILIKE '%tea%' AND name NOT ILIKE '%green%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'பச்சை தேநீர்' WHERE name ILIKE '%green%tea%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'காபி' WHERE name ILIKE '%coffee%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'காபி பொடி' WHERE name ILIKE '%coffee%powder%' AND name_tamil IS NULL;

-- Oils
UPDATE master_products SET name_tamil = 'எண்ணெய்' WHERE name ILIKE '%oil%' AND name NOT ILIKE '%coconut%' AND name NOT ILIKE '%groundnut%' AND name NOT ILIKE '%sunflower%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'தேங்காய் எண்ணெய்' WHERE name ILIKE '%coconut%oil%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'கடலை எண்ணெய்' WHERE name ILIKE '%groundnut%oil%' OR name ILIKE '%peanut%oil%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'சூரியகாந்தி எண்ணெய்' WHERE name ILIKE '%sunflower%oil%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'நல்லெண்ணெய்' WHERE name ILIKE '%sesame%oil%' OR name ILIKE '%gingelly%oil%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'கடுகு எண்ணெய்' WHERE name ILIKE '%mustard%oil%' AND name_tamil IS NULL;

-- Flours and grains
UPDATE master_products SET name_tamil = 'கோதுமை மாவு' WHERE name ILIKE '%wheat%flour%' OR name ILIKE '%atta%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'மைதா மாவு' WHERE name ILIKE '%maida%' OR name ILIKE '%all%purpose%flour%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'கடலை மாவு' WHERE name ILIKE '%besan%' OR name ILIKE '%gram%flour%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'அரிசி மாவு' WHERE name ILIKE '%rice%flour%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'ரவை' WHERE name ILIKE '%rava%' OR name ILIKE '%semolina%' AND name_tamil IS NULL;

-- Pulses and dals
UPDATE master_products SET name_tamil = 'பருப்பு' WHERE name ILIKE '%dal%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'துவரம் பருப்பு' WHERE name ILIKE '%toor%dal%' OR name ILIKE '%arhar%dal%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'கடலை பருப்பு' WHERE name ILIKE '%chana%dal%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'பாசிப்பருப்பு' WHERE name ILIKE '%moong%dal%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'உளுந்து' WHERE name ILIKE '%urad%dal%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'மசூர் பருப்பு' WHERE name ILIKE '%masoor%dal%' AND name_tamil IS NULL;

-- Spices
UPDATE master_products SET name_tamil = 'உப்பு' WHERE name ILIKE '%salt%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'மிளகு' WHERE name ILIKE '%pepper%' AND name NOT ILIKE '%chilli%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'மிளகாய்' WHERE name ILIKE '%chilli%' OR name ILIKE '%red%chilli%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'மஞ்சள்' WHERE name ILIKE '%turmeric%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'சீரகம்' WHERE name ILIKE '%cumin%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'கொத்தமல்லி' WHERE name ILIKE '%coriander%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'கறிவேப்பிலை' WHERE name ILIKE '%curry%leaves%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'கடுகு' WHERE name ILIKE '%mustard%seeds%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'சோம்பு' WHERE name ILIKE '%fennel%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'ஏலக்காய்' WHERE name ILIKE '%cardamom%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'கிராம்பு' WHERE name ILIKE '%cloves%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'பட்டை' WHERE name ILIKE '%cinnamon%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'வெந்தயம்' WHERE name ILIKE '%fenugreek%' AND name_tamil IS NULL;

-- Vegetables
UPDATE master_products SET name_tamil = 'உருளைக்கிழங்கு' WHERE name ILIKE '%potato%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'வெங்காயம்' WHERE name ILIKE '%onion%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'தக்காளி' WHERE name ILIKE '%tomato%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'பச்சை மிளகாய்' WHERE name ILIKE '%green%chilli%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'கேரட்' WHERE name ILIKE '%carrot%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'முட்டைகோஸ்' WHERE name ILIKE '%cabbage%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'காலிஃப்ளவர்' WHERE name ILIKE '%cauliflower%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'பீன்ஸ்' WHERE name ILIKE '%beans%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'வெண்டைக்காய்' WHERE name ILIKE '%okra%' OR name ILIKE '%ladyfinger%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'கத்தரிக்காய்' WHERE name ILIKE '%brinjal%' OR name ILIKE '%eggplant%' AND name_tamil IS NULL;

-- Fruits
UPDATE master_products SET name_tamil = 'வாழைப்பழம்' WHERE name ILIKE '%banana%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'ஆப்பிள்' WHERE name ILIKE '%apple%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'மாம்பழம்' WHERE name ILIKE '%mango%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'ஆரஞ்சு' WHERE name ILIKE '%orange%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'திராட்சை' WHERE name ILIKE '%grapes%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'தர்பூசணி' WHERE name ILIKE '%watermelon%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'பப்பாளி' WHERE name ILIKE '%papaya%' AND name_tamil IS NULL;

-- Snacks and packaged foods
UPDATE master_products SET name_tamil = 'பிஸ்கட்' WHERE name ILIKE '%biscuit%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'நமகீன்' WHERE name ILIKE '%namkeen%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'சிப்ஸ்' WHERE name ILIKE '%chips%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'நூடுல்ஸ்' WHERE name ILIKE '%noodles%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'மாகரோனி' WHERE name ILIKE '%macaroni%' OR name ILIKE '%pasta%' AND name_tamil IS NULL;

-- Beverages
UPDATE master_products SET name_tamil = 'குளிர்பானம்' WHERE name ILIKE '%cold%drink%' OR name ILIKE '%soft%drink%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'ஜூஸ்' WHERE name ILIKE '%juice%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'தண்ணீர்' WHERE name ILIKE '%water%' AND name_tamil IS NULL;

-- Personal care
UPDATE master_products SET name_tamil = 'சோப்பு' WHERE name ILIKE '%soap%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'ஷாம்பு' WHERE name ILIKE '%shampoo%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'பல் துலக்கும் பொடி' WHERE name ILIKE '%toothpaste%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'பல் துலக்கும் தூரிகை' WHERE name ILIKE '%toothbrush%' AND name_tamil IS NULL;

-- Cleaning products
UPDATE master_products SET name_tamil = 'சோப்பு பவுடர்' WHERE name ILIKE '%detergent%' OR name ILIKE '%washing%powder%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'பாத்திரம் கழுவும் திரவம்' WHERE name ILIKE '%dishwash%' AND name_tamil IS NULL;

-- Eggs and meat (if applicable)
UPDATE master_products SET name_tamil = 'முட்டை' WHERE name ILIKE '%egg%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'கோழி' WHERE name ILIKE '%chicken%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'மீன்' WHERE name ILIKE '%fish%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'இறால்' WHERE name ILIKE '%prawn%' OR name ILIKE '%shrimp%' AND name_tamil IS NULL;

-- Bread and bakery
UPDATE master_products SET name_tamil = 'பிரெட்' WHERE name ILIKE '%bread%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'ரொட்டி' WHERE name ILIKE '%roti%' OR name ILIKE '%chapati%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'கேக்' WHERE name ILIKE '%cake%' AND name_tamil IS NULL;

-- Dry fruits and nuts
UPDATE master_products SET name_tamil = 'முந்திரி' WHERE name ILIKE '%cashew%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'பாதாம்' WHERE name ILIKE '%almond%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'திராட்சை' WHERE name ILIKE '%raisin%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'வேர்க்கடலை' WHERE name ILIKE '%peanut%' OR name ILIKE '%groundnut%' AND name NOT ILIKE '%oil%' AND name_tamil IS NULL;

-- Condiments
UPDATE master_products SET name_tamil = 'கெட்ச்அப்' WHERE name ILIKE '%ketchup%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'சாஸ்' WHERE name ILIKE '%sauce%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'ஊறுகாய்' WHERE name ILIKE '%pickle%' AND name_tamil IS NULL;
UPDATE master_products SET name_tamil = 'சட்னி' WHERE name ILIKE '%chutney%' AND name_tamil IS NULL;

-- Count updated records
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO updated_count FROM master_products WHERE name_tamil IS NOT NULL;
    RAISE NOTICE 'Total products with Tamil names: %', updated_count;
END $$;
