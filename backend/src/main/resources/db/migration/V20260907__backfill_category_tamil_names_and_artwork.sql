-- Give the live grocery catalogue bilingual names and shared default artwork.
-- A shop owner's uploaded image remains authoritative; only missing/legacy emoji
-- icon values are replaced by the classpath artwork shipped with the backend.
WITH category_defaults(name, name_tamil, artwork_url) AS (
    VALUES
        ('Atta',                  'கோதுமை மாவு',                         '/category-artwork/grocery-staples.jpg'),
        ('BABY CARE',             'குழந்தை பராமரிப்பு',                  '/category-artwork/personal-care.jpg'),
        ('Bath & Hygiene',        'குளியல் மற்றும் சுகாதாரம்',            '/category-artwork/personal-care.jpg'),
        ('Beverages',             'பானங்கள்',                            '/category-artwork/beverages.jpg'),
        ('BISCUITS',              'பிஸ்கட்கள்',                           '/category-artwork/snacks.jpg'),
        ('Breakfast',             'காலை உணவு',                           '/category-artwork/snacks.jpg'),
        ('Chocolates',            'சாக்லேட்கள்',                          '/category-artwork/snacks.jpg'),
        ('Cleaners',              'சுத்தம் செய்யும் பொருட்கள்',            '/category-artwork/household-cleaning.jpg'),
        ('Dairy',                 'பால் பொருட்கள்',                       '/category-artwork/dairy.jpg'),
        ('Dal(பருப்பு)',          'பருப்பு வகைகள்',                       '/category-artwork/grocery-staples.jpg'),
        ('Detergent',             'சலவைத் தூள்',                          '/category-artwork/household-cleaning.jpg'),
        ('Dishwash',              'பாத்திரம் கழுவும் பொருட்கள்',           '/category-artwork/household-cleaning.jpg'),
        ('DRY FRUITS',            'உலர் பழங்கள் மற்றும் கொட்டைகள்',        '/category-artwork/dry-fruits.jpg'),
        ('Electronics',           'மின்னணு சாதனங்கள்',                    '/category-artwork/electronics.jpg'),
        ('Face Wash',             'முகக் கழுவி',                          '/category-artwork/personal-care.jpg'),
        ('Hair-Care',             'முடி பராமரிப்பு',                      '/category-artwork/personal-care.jpg'),
        ('Health Food Drinks',    'ஆரோக்கிய பானங்கள்',                    '/category-artwork/beverages.jpg'),
        ('Home Decor',            'வீட்டு அலங்காரம்',                     '/category-artwork/pooja-home.jpg'),
        ('Household',             'வீட்டு உபயோகப் பொருட்கள்',             '/category-artwork/household-cleaning.jpg'),
        ('ICE CREAM',             'ஐஸ்கிரீம்',                            '/category-artwork/dairy.jpg'),
        ('Maligai',               'மளிகைப் பொருட்கள்',                    '/category-artwork/grocery-staples.jpg'),
        ('Masala',                'மசாலா வகைகள்',                         '/category-artwork/grocery-staples.jpg'),
        ('MEDICINAL',             'மருந்து மற்றும் முதலுதவிப் பொருட்கள்',   '/category-artwork/medicinal.jpg'),
        ('Oil',                   'சமையல் எண்ணெய்',                       '/category-artwork/grocery-staples.jpg'),
        ('Oral-Care',             'வாய் பராமரிப்பு',                      '/category-artwork/personal-care.jpg'),
        ('PERSONAL CARE',         'தனிப்பட்ட பராமரிப்பு',                  '/category-artwork/personal-care.jpg'),
        ('Pickle',                'ஊறுகாய்',                              '/category-artwork/snacks.jpg'),
        ('PLASTICS',              'பிளாஸ்டிக் பொருட்கள்',                  '/category-artwork/household-cleaning.jpg'),
        ('Pooja',                 'பூஜைப் பொருட்கள்',                     '/category-artwork/pooja-home.jpg'),
        ('Rava & Semiya',         'ரவை மற்றும் சேமியா',                   '/category-artwork/grocery-staples.jpg'),
        ('Rice & Millet',         'அரிசி மற்றும் சிறுதானியங்கள்',          '/category-artwork/grocery-staples.jpg'),
        ('SEA FOOD',              'கடல் உணவுகள்',                         '/category-artwork/seafood.jpg'),
        ('Skin-Care',             'சரும பராமரிப்பு',                      '/category-artwork/personal-care.jpg'),
        ('Snacks & Packed Food',  'தின்பண்டங்கள் மற்றும் பொதி உணவுகள்',     '/category-artwork/snacks.jpg'),
        ('STATIONERY',            'எழுதுபொருட்கள்',                       '/category-artwork/stationery.jpg'),
        ('VEGETABLES',            'காய்கறிகள்',                           '/category-artwork/fresh-vegetables.jpg')
)
UPDATE product_categories AS category
SET name_tamil = CASE
        WHEN category.name_tamil IS NULL
          OR btrim(category.name_tamil) = ''
          OR lower(btrim(category.name_tamil)) = lower(btrim(category.name))
        THEN defaults.name_tamil
        ELSE category.name_tamil
    END,
    icon_url = CASE
        WHEN category.icon_url IS NULL
          OR btrim(category.icon_url) = ''
          OR (category.icon_url NOT LIKE '/%' AND category.icon_url NOT ILIKE 'http%')
        THEN defaults.artwork_url
        ELSE category.icon_url
    END,
    updated_at = CURRENT_TIMESTAMP
FROM category_defaults AS defaults
WHERE lower(btrim(category.name)) = lower(btrim(defaults.name));
