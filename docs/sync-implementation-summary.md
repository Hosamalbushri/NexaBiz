# توثيق ما تم إنجازه في المزامنة (Experimental Sync)

> **الحالة:** تجريبي — ليس جاهزاً للإنتاج.  
> **التاريخ:** أغسطس 2026  
> **المراجع:** ADR-006 (الأساس)، ADR-010 (الخادم التجريبي)، هذا المستند (ملخص التنفيذ)

---

## 1. الهدف

ربط تطبيق Flutter الحالي (Offline-First) بخادم HTTP حقيقي وقاعدة PostgreSQL لاختبار:

- مزامنة جهازين على نفس الشركة
- رفع / سحب التغييرات
- التعارض حسب الإصدار (version)
- الاستيراد متعدد الأجهزة
- ترقيم فواتير آمن بدون دمج الفواتير

**ما لم يُغيَّر عن قصد:**

- `SyncManager`
- `SyncQueue`
- `SyncEntityHandler` (العقد نفسه)
- مستودعات الوحدات كمحرك مزامنة منفصل

تم استبدال طبقة الـ remote فقط:  
`InMemoryRemoteSyncApi` → `HttpRemoteSyncApi` → FastAPI → PostgreSQL

---

## 2. البنية العامة

```text
إجراء المستخدم
  → قاعدة محلية (Drift / Hive) + واجهة فورية
  → SyncQueue (عمليات pending)
  → SyncManager
      → رفع: SyncEntityHandler.upload → RemoteSyncApi.push
      → سحب: SyncEntityHandler.pull → applyRemoteChange
  → HttpRemoteSyncApi (عند التفعيل)
  → FastAPI /api/v1/sync/*
  → PostgreSQL
```

### الكيانات المدعومة في المزامنة التجريبية

| entity_type | الوحدة |
|---|---|
| `product` | المخزون |
| `inventory_item` | جرد المخزون |
| `customer` | العملاء |
| `account` | الدليل المحاسبي (إنشاء/تعديل/حذف + بذر النظامي بـ UUID ثابت) |
| `sale` | المبيعات |

غير مشمولة حالياً: قيود اليومية، أسعار العملات، دفاتر القسائم كمزامنة، الموردون، المشتريات، المصروفات.

---

## 3. الخادم التجريبي (`backend/`)

### التقنيات

- Python + FastAPI + Pydantic
- PostgreSQL + SQLAlchemy + Alembic
- Docker Compose

### التشغيل

```bash
cd backend
cp .env.example .env
docker compose up --build
```

| الخدمة | العنوان |
|---|---|
| API | http://localhost:8000 أو http://192.168.8.110:8000 |
| التوثيق | http://localhost:8000/docs |
| الصحة | http://localhost:8000/health |

### نقاط النهاية

| الطريقة | المسار | الوظيفة |
|---|---|---|
| `GET` | `/health` | فحص API + قاعدة البيانات |
| `POST` | `/api/v1/sync/push` | رفع عملية مزامنة واحدة (عقد Flutter) |
| `POST` | `/api/v1/sync/push/batch` | رفع دفعة مع نتيجة لكل عملية |
| `GET` | `/api/v1/sync/pull` | سحب تزايدي (`cursor` أو `since`) |
| `GET` | `/api/v1/sync/meta/{entity_type}/{entity_id}` | فحص الإصدار قبل الرفع |

### المصادقة (تجريبية بسيطة)

```http
Authorization: Bearer dev-sync-token-change-me
X-Company-Id: <tenant>
X-User-Id: <user>
X-Device-Id: <device>
```

عزل البيانات حسب `company_id`. كل جهاز يستخدم `X-Device-Id` مختلفاً.

### جداول قاعدة البيانات

| الجدول | الغرض |
|---|---|
| `companies` | المستأجر (tenant) |
| `sync_entities` | السجل الحالي (JSONB payload + version + soft delete) |
| `sync_changes` | سجل تغييرات متسلسل (cursor) لأجهزة متعددة |
| `sync_operations` | إdempotency حسب `operation_id` |
| `sync_sequences` | عداد التسلسل لكل شركة |

### قواعد الرفع

- **CREATE:** إنشاء أو إرجاع نفس النتيجة إذا تكررت العملية (idempotent)
- **UPDATE:** ينجح فقط إذا `base_version` متوافق مع إصدار الخادم؛ وإلا `409 conflict`
- **DELETE:** حذف ناعم (`deleted_at`) مع زيادة الإصدار
- الخادم هو المرجع لإصدارات `version`

### الاستجابة عند التعارض

```json
{
  "error": {
    "code": "conflict",
    "message": "...",
    "details": {
      "status": "conflict",
      "entity_type": "customer",
      "entity_id": "...",
      "server_version": 5,
      "client_base_version": 3,
      "server_record": { }
    }
  }
}
```

Flutter يحوّلها إلى `SyncConflictFailure` ويعلّم السجل المحلي `conflict`.

---

## 4. تكامل Flutter

### ملفات جديدة / معدّلة (المزامنة)

| الملف | الدور |
|---|---|
| `lib/core/network/http_remote_sync_api.dart` | تنفيذ HTTP لـ `RemoteSyncApi` |
| `lib/core/network/sync_api_config.dart` | عنوان الخادم / التوكن / الشركة / الجهاز |
| `lib/core/sync/sync_providers.dart` | تبديل InMemory ↔ HTTP |
| `lib/app/bootstrap/app_bootstrap.dart` | إنشاء `sync_device_id` ثابت لكل تثبيت |
| `android/.../debug/AndroidManifest.xml` | السماح بـ HTTP cleartext للتطوير |
| `android/.../main/AndroidManifest.xml` | صلاحية `INTERNET` |

### التفعيل للجهاز الحقيقي

الافتراضي **مغلق** (fail-closed):

- `SYNC_API_ENABLED=false` ما لم تُمرَّر dart-defines صراحة
- لا يوجد URL أو token افتراضي مشترك في البناء
- HTTP غير المشفّر يتطلب `--dart-define=SYNC_API_ALLOW_INSECURE_HTTP=true`

مثال جهاز حقيقي على LAN:

```bash
flutter run \
  --dart-define=SYNC_API_ENABLED=true \
  --dart-define=SYNC_API_BASE_URL=http://192.168.8.110:8000 \
  --dart-define=SYNC_API_TOKEN=your-local-dev-token \
  --dart-define=SYNC_API_ALLOW_INSECURE_HTTP=true
```

في إعدادات المزامنة يظهر سطر مثل `HTTP http://…` عند التهيئة الصحيحة، وإلا `Local only`.

إن ظهر `Local only` / In-memory فالجهاز لا يتصل بالخادم.

### Cursor السحب

- الخادم يدعم `cursor` متزايد.
- `HttpRemoteSyncApi` يخزّن cursor مرحلياً ويُثبّته فقط بعد نجاح تطبيق كل التغييرات محلياً (`confirmPull` / `abandonPull`).
- عند فشل تطبيق صف واحد لا يُفقد باقي التغييرات بصمت عبر تقدم cursor خاطئ.

---

## 5. إصلاح استيراد العملاء على جهازين

### المشكلة

كل جهاز يستورد نفس أكواد العملاء (`12210002`…) لكن يولّد **UUID مختلفاً**.  
عند السحب: محاولة إدراج العميل البعيد تفشل بسبب قيد التفرد على `customerCode` محلياً → فشل المزامنة واختفاء البيانات.

### الحل (بدون اعتبار الكود = نفس الكيان المحاسبي دائماً، بل حل تعارض هوية المزامنة)

عند `applyRemotePayload` للعملاء:

1. إن وُجد نفس `customerCode` محلياً وUUID مختلف → **اعتماد UUID الخادم** وتحديث الصف المحلي.
2. حذف عمليات الطابور المرتبطة بالـ UUID المحلي القديم.
3. نفس المنطق لحسابات الدليل حسب `accountCode`، مع إعادة ربط `customers.accountId` عند تغيّر UUID الحساب.

### ملفات مرتبطة

- `customer_repository_impl.dart` → دمج حسب الكود
- `account_repository_impl.dart` → دمج حسب كود الحساب + `onUuidRemapped`
- `module_bootstrap.dart` → ربط إعادة تعيين `accountId` عبر App
- `sync_queue.dart` → `removeForEntity`
- `test/customer_sync_merge_test.dart`

---

## 6. ترقيم الفواتير متعدد الأجهزة (بدون دمج)

### القرار

لا ندمج الفواتير حسب رقم الفاتورة — قد تكون لعميلين مختلفين.

### الحل

1. أرقام الفواتير تبقى **أرقاماً عادية فقط** (مثل `161000041`) — **بدون** إظهار رمز/اسم الجهاز بجانب الرقم.
2. لكل جهاز «مسار رقمي» صامت (`deviceSaleNumberBase`) يمنع التصادم بين الجهازين دون دمج الفواتير.
3. **كتل أرقام (Number blocks)** من دفتر القسائم: الجهاز يحجز دفعة ويستهلكها offline.

### ملفات مرتبطة

- `device_sale_number.dart`
- `sale_number_block_store.dart`
- `AccountingSaleVoucherBookAdapter`
- `VoucherBookRepository.reserveNumberBlock`
- `LocalSaleNumberAllocator` مع مسار رقمي صامت (بدون بادئة ظاهرة)
- `test/device_sale_number_test.dart`

### هوية المزامنة للفواتير

| الحقل | الدور |
|---|---|
| `uuid` | هوية المزامنة والتعارض |
| `saleNumber` | رقم عرض محاسبي فريد عالمياً عبر البادئة |

التعارض الحقيقي فقط عند تعديل **نفس UUID** بإصدار قديم على جهازين.

---

## 7. سيناريوهات القبول

### أ) عميل بين جهازين

1. الجهاز A ينشئ/يستورد عميلاً ويتزامن → يصل للخادم.
2. الجهاز B يتزامن → يستلم العميل ويظهر في القائمة.
3. B يعدّل offline ثم يتزامن → A يسحب التحديث.

### ب) تعارض إصدار

A و B يعدّلان نفس السجل بنفس `base_version` → واحد ينجح والآخر يحصل على `conflict`.

### ج) استيراد نفس الأكواد على جهازين

بعد الإصلاح: السحب يدمج حسب الكود إلى UUID الخادم ولا يفشل بسبب Unique constraint.

### د) فواتير على جهازين

كل جهاز يحصل على أرقام صحيحة مختلفة (مسار رقمي صامت) بدون إظهار رمز الجهاز وبدون دمج.

---

## 8. كيفية التشغيل والاختبار

### الخادم

```bash
cd backend && docker compose up --build
curl http://192.168.8.110:8000/health
```

### التطبيق (جهاز حقيقي)

```bash
flutter run
```

تأكد من ظهور `HTTP http://192.168.8.110:8000` في إعدادات المزامنة، ثم **مزامنة الآن** على الجهازين.

### اختبارات آلية مهمة

```bash
cd backend && pytest -q
flutter test test/http_remote_sync_api_test.dart
flutter test test/customer_sync_merge_test.dart
flutter test test/device_sale_number_test.dart
flutter test test/offline_sync_test.dart
```

---

## 9. ما لم يُنجز بعد (حدود التجربة)

- ليس نظام هوية إنتاج (OAuth / JWT كامل)
- دفاتر القسائم غير مُزامَنة ككيان sync بعد
- لا WebSockets / Redis / microservices
- Cursor السحب على العميل ما زال في الذاكرة (يُعاد عند إعادة التشغيل مع `since` / سحب كامل عند الحاجة)
- لا يُعتبر هذا النظام System of Record إنتاجياً

---

## 10. خريطة المستندات ذات الصلة

| المستند | المحتوى |
|---|---|
| `docs/adr/ADR-006-offline-first-sync.md` | قرار البنية Offline-first |
| `docs/adr/ADR-010-experimental-sync-backend.md` | قرار الخادم التجريبي |
| `docs/experimental-sync-backend.md` | مخططات Mermaid للمسارات |
| `backend/README.md` | تشغيل الخادم وربط Flutter |
| **هذا الملف** | ملخص تنفيذي لكل ما نُفّذ في المزامنة |

---

## 11. ملخص سريع

| الموضوع | النتيجة |
|---|---|
| خادم تجريبي حقيقي | FastAPI + PostgreSQL + Docker |
| عقد Flutter | محفوظ عبر `RemoteSyncApi` / `HttpRemoteSyncApi` |
| جهازان | نفس `company_id` + `device_id` مختلف |
| تعارض الإصدار | 409 → `SyncConflictFailure` |
| استيراد عملاء مكرر الأكواد | دمج حسب الكود إلى UUID الخادم |
| أرقام الفواتير | أرقام عادية + مسار رقمي صامت لكل جهاز + كتل — بدون دمج وبدون إظهار الجهاز |
| الحالة | **تجريبي** |
