# میراث ملک — Expo / React Native / TypeScript

نسخه کراس‌پلتفرم دستیار هوشمند ثبت فایل ملک برای Android، iOS و Web.

## امکانات
- صفحه اصلی با «شروع تماس با مشتری»
- پخش شش پرسش فارسی با expo-speech
- ضبط مکالمه با expo-av
- فرم بازبینی و ویرایش اطلاعات
- ذخیره محلی دائمی با AsyncStorage و Zustand
- ذخیره ابری اختیاری با Supabase
- نمایش فایل‌ها و JSON
- خروجی Web استاتیک

## نصب
```bash
npm install
```

برای Supabase فایل `.env.example` را به `.env` تبدیل کرده و مقادیر پروژه را وارد کنید.

## اجرا
```bash
npx expo start
npx expo start --web
```

## Web
```bash
npx expo export --platform web
```
خروجی در `dist/` ایجاد می‌شود.

## Android / APK
```bash
npx expo prebuild --platform android
npx expo run:android --variant release
```
یا پس از prebuild:
```bash
cd android
./gradlew assembleRelease
```
APK در `android/app/build/outputs/apk/release/` قرار می‌گیرد.

## iOS / Xcode
روی macOS:
```bash
npx expo prebuild --platform ios
npx expo run:ios --configuration Release
```
سپس فایل `ios/*.xcworkspace` را در Xcode باز کنید و برای IPA از Product → Archive استفاده کنید. برای IPA واقعی روی دستگاه، تنظیمات Signing و تیم Apple در Xcode لازم است.

## Supabase
فایل `supabase.sql` را در SQL Editor پروژه Supabase اجرا کنید. کلیدهای Supabase را داخل اپ یا GitHub commit نکنید.

## نکته Speech-to-Text
`expo-speech` متن را به صدا تبدیل می‌کند و Speech-to-Text نیست. این نسخه صدا را ضبط می‌کند و فرم نهایی امکان ورود/اصلاح متن پاسخ را دارد. برای تبدیل خودکار صدای مشتری به متن باید یک سرویس STT سمت سرور متصل شود.

## GitHub Actions
فایل `.github/workflows/mirath-melk.yml` برای ساخت Web و APK و آماده‌سازی پروژه iOS در GitHub Actions قرار داده شده است. خروجی‌ها به‌صورت Artifact در صفحه اجرای Workflow قابل دریافت هستند.