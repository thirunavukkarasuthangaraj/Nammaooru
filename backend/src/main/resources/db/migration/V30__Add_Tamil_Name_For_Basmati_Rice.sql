-- Add Tamil name for Basmati Rice product for testing
UPDATE master_products
SET name_tamil = 'பாஸ்மதி அரிசி'
WHERE name = 'Basmati Rice 1kg';

-- Add Tamil name for Test Product After Restart
UPDATE master_products
SET name_tamil = 'மறுதொடக்கத்திற்குப் பிறகு சோதனை தயாரிப்பு'
WHERE name = 'Test Product After Restart';

-- Add more common product Tamil names
UPDATE master_products SET name_tamil = 'கோதுமை மாவு' WHERE name LIKE '%Wheat Flour%';
UPDATE master_products SET name_tamil = 'சர்க்கரை' WHERE name LIKE '%Sugar%';
UPDATE master_products SET name_tamil = 'பரசிட்டமால்' WHERE name LIKE '%Paracetamol%';
UPDATE master_products SET name_tamil = 'இருமல் சிரப்' WHERE name LIKE '%Cough Syrup%';
UPDATE master_products SET name_tamil = 'தக்காளி' WHERE name LIKE '%Tomato%';
UPDATE master_products SET name_tamil = 'பாஸ்மதி அரிசி' WHERE name LIKE '%Basmati Rice%';
