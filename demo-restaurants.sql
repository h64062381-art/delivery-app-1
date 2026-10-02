-- وصّلني V12 — مطاعم تجريبية للعرض فقط.
-- شغّل هذا الملف بعد schema.sql إذا تريد بيانات مطاعم حقيقية داخل Supabase.
insert into public.categories(name_ar,slug,sort_order) values
('برغر','burger',1),('دجاج','chicken',2),('بيتزا','pizza',3),('عراقي','iraqi',4),('مشويات','grills',5),('فطور','breakfast',6),('حلويات','desserts',7),('قهوة','coffee',8),('شاورما','shawarma',9),('بحري','seafood',10),('صحي','healthy',11),('مشروبات','drinks',12),('مناقيش','manakish',13)
on conflict(slug) do nothing;

-- أسماء تجريبية غير مرتبطة بمطاعم حقيقية. يمكنك استبدالها من لوحة الإدارة.
insert into public.restaurants(name,slug,description,delivery_fee,min_order,is_open,is_verified,commission_rate)
values
('شاورما الساحة','sahaat-shawarma','شاورما دجاج ولحم بصوصات خاصة',1000,5000,true,true,15),
('دجلة سي فود','dijla-seafood','أسماك ومأكولات بحرية طازجة',2000,10000,true,true,15),
('دار الدولمة','dar-dolma','دولمة وكبة وأكلات بيتية عراقية',1500,7000,true,true,15),
('فطورنا','futoorna','فطور عراقي وشرقي طوال اليوم',750,5000,true,true,15),
('بيت التكة','bait-al-tikka','تكة وكباب ودجاج على الفحم',1750,10000,true,true,15),
('حلويات دجلة','dijla-sweets','بقلاوة وكنافة وحلويات شرقية',1000,5000,true,true,15),
('كافيه النخيل','nakheel-cafe','قهوة مختصة وحلويات ومشروبات باردة',750,4000,true,true,15),
('مناقيش الشام','manakeesh-alsham','مناقيش جبن وزعتر ولحم بعجين',1000,5000,true,true,15),
('سلة الخير','sallat-alkhair','سلطات وبوكسات صحية يومية',1000,7000,true,true,15),
('تشكن هاوس','chicken-house','دجاج مقرمش ووجبات عائلية',1250,6000,true,true,15),
('مشروبك','mashroobak','عصائر وميلك شيك ومشروبات باردة',500,3000,true,true,15),
('بيت الكبة','bait-alkubba','كبة عراقية وحساء وأطباق شعبية',1250,6000,true,true,15),
('باستا كورنر','pasta-corner','باستا وصواني وأطباق غربية',1500,7000,true,true,15),
('وافل وورد','waffle-ward','وافل وكريب وبانكيك',750,4000,true,true,15)
on conflict(slug) do nothing;
