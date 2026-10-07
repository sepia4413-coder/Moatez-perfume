# متجر العطور — متجر عام + لوحة أدمن

هذا الإصدار يفصل الموقع إلى:
- `index.html`: الموقع الذي يراه الزبون. الزائر يستطيع مشاهدة العطور والبحث عنها وإرسال طلب.
- `admin.html`: لوحة خاصة بك لتسجيل الدخول وإضافة/تعديل/حذف العطور ومتابعة الطلبات.
- `config.js`: تضع فيه رابط Supabase وAnon Key.
- `supabase.sql`: تنشئ منه الجداول والصلاحيات والتخزين.
- `style.css`: التصميم.

## التشغيل على Supabase
1. أنشئ مشروع Supabase.
2. افتح SQL Editor والصق كامل محتوى `supabase.sql` ثم Run.
3. من Authentication > Users أنشئ حساب البريد وكلمة المرور الذي ستستخدمه كمدير.
4. انسخ UUID الخاص بهذا المستخدم.
5. في SQL Editor نفذ:
   `insert into public.admins (user_id) values ('UUID-هنا');`
6. من Supabase > Project Settings > API انسخ Project URL و Publishable/Anon key وضعهما في `config.js`.

## النشر على Vercel
ارفع الملفات الخمسة كما هي إلى GitHub ثم اربط المستودع بـ Vercel.

مهم: لا تضع Service Role Key داخل الموقع. الموقع يستخدم فقط Anon/Publishable key، والصلاحيات تحمي عمليات الإدارة عبر RLS.
