# Restaurant App – Assessment & Integration Plan

**App path:** `/home/nelson/meza_restaurant-RESTAURANT-APP-FOR-MEZAHUB`  
**Backend:** MEZAHUB Flask API (same as customer app)

---

## 1. Current State Summary

### 1.1 Tech stack
- **Flutter** (Dart), **GoRouter**, **Provider**, **Hive** (local storage)
- **Firebase:** Auth, Database, Firestore, Messaging (auth is Firebase-only; no backend JWT yet)
- **Supabase/Postgrest** in `pubspec.yaml` but not used in code – safe to remove
- **http**, **dio** available for API calls (no central backend client yet)

### 1.2 Auth
- **Current:** Firebase Auth only. Login/register with email+password; user stored in Hive as `User` (id = Firebase UID, email, restaurantName, phoneNumber, role: `restaurant_owner`).
- **Gap:** Backend expects JWT with `role: "restaurant"` and a **User** in the DB. Restaurant app never talks to backend auth, so:
  - No JWT → no access to `/orders`, `/restaurants`, etc.
  - Backend has no “restaurant” user or linked **Restaurant** for this Firebase user.

### 1.3 Orders
- **Current:** 100% mock data.
  - **HomeScreen (Orders tab):** `_loadSampleOrders()` fills a local list; status updates and “Assign Delivery” only change in-memory state.
  - **Order History:** `_getFilteredOrders()` returns a hardcoded list; filters work on that list only.
- **Gap:** No API calls. Real orders (from customer app) live in the backend; restaurant app does not fetch or update them.

### 1.4 Order models (in-app)
- **Three different “Order” usages:**
  1. `lib/models/order.dart` – minimal (id, customerName, timeAgo, items, total).
  2. `lib/pages/order_history.dart` – full local model (id, timeAgo, status, location, itemCount, totalAmount, orderType, orderDate, items) + `OrderStatus` (all, pending, completed, canceled).
  3. `lib/pages/homescreen.dart` – another full model (id, customerName, tableNumber, orderType, status, items, totalAmount, orderTime, estimatedTime, assignedToDelivery, deliveryPerson) + `OrderStatus` (pending, accepted, preparing, ready, outForDelivery, completed) and `OrderType` (dineIn, takeaway, delivery).
- **Gap:** Need one canonical order model (or adapter) that maps from backend JSON (id, customer_id, restaurant_id, status, total_amount, delivery_address, contact_name, contact_phone, items[], etc.) and matches backend status values (e.g. pending, confirmed, preparing, ready, assigned, on_the_way, delivered, cancelled).

### 1.5 Upload dish (menu)
- **Current:** UI only (name, price, description, category, image picker). No persistence to backend.
- **Backend:** `GET /restaurants/<id>/menu` returns categories + items. There is **no** `POST` for menu categories or menu items in the current API.
- **Gap:** To support “upload dish” from the app, backend needs endpoints to create/update menu categories and menu items (for the authenticated restaurant).

### 1.6 Riders / assign delivery
- **Current:** HomeScreen “Assign Delivery” uses a hardcoded list of names; assignment only updates local state.
- **Backend:** `POST /orders/<order_id>/assign-rider` with `rider_id` exists and is allowed for `restaurant` role. **But** `GET /riders` is **admin-only**, so restaurant app cannot list riders to choose from.
- **Gap:** Either backend exposes a “list riders” (or “available riders”) for restaurant role, or we add a new endpoint (e.g. `GET /riders` for restaurant as well).

### 1.7 Other
- **DeliveryService:** Commented out; used to use Firestore. Can be replaced later by backend/real-time if needed.
- **Notification service:** Present; can stay for FCM; order updates can eventually come from backend (e.g. WebSocket or polling).
- **Profile/Settings:** Use Hive/Firebase only; profile should eventually sync with backend (name, phone, and link to backend User/Restaurant).

---

## 2. Backend Capabilities (Relevant to Restaurant)

| Area              | Endpoint / behavior | Notes |
|-------------------|---------------------|--------|
| Auth              | POST /auth/register, /auth/login | Returns JWT + user. Role `restaurant` supported. |
| Auth              | GET/PUT /auth/profile | JWT required. |
| Orders (list)     | GET /orders | JWT + role `restaurant` → returns orders for restaurants owned by user. |
| Order (one)       | GET /orders/<id> | Restaurant can read if order.restaurant_id in their restaurants. |
| Order status      | PATCH /orders/<id>/status | Body: `{ "status": "preparing" }` etc. Restaurant/admin. |
| Assign rider      | POST /orders/<id>/assign-rider | Body: `{ "rider_id": 1 }`. Restaurant/admin. |
| Riders list       | GET /riders | **Admin only** – restaurant cannot list riders today. |
| Restaurants       | POST /restaurants | Create restaurant (owner_id = current user). |
| Restaurants       | GET /restaurants | Public list (approved, is_open). No “my restaurants” yet. |
| Restaurant one    | GET/PUT/DELETE /restaurants/<id> | Get/update/delete; restaurant can only touch own. |
| Menu              | GET /restaurants/<id>/menu | Public; categories + items. No POST for menu. |

**Backend order status values** (to align app with): e.g. `pending`, `confirmed`, `preparing`, `ready`, `assigned`, `on_the_way`, `delivered`, `cancelled` (confirm exact set in `Order` model / API).

---

## 3. System Expectations (What “Solved” Looks Like)

1. **Restaurant auth**
   - Restaurant app uses **backend** for login/register (same as customer app pattern).
   - On success: store JWT + user in Hive (and optionally keep Firebase for FCM only).
   - User in DB has `role = "restaurant"` and is linked to one (or more) **Restaurant** via `Restaurant.owner_id`.

2. **Restaurant identity**
   - After login, app knows “my” restaurant(s). Either:
     - Backend: `GET /restaurants/mine` (or `?owner=me`) returning restaurants where `owner_id = current user`, or
     - App creates restaurant on first use via `POST /restaurants` if none exist.

3. **Orders**
   - **HomeScreen (Orders tab):** Load orders from `GET /orders` (backend returns only this restaurant’s orders). Show in tabs by status (Pending, Preparing, Ready, Delivery, Completed).
   - **Order History:** Same source (`GET /orders`) with filters (date, status, type) applied in app.
   - **Status updates:** “Accept”, “Start Preparing”, “Mark Ready”, etc. call `PATCH /orders/<id>/status` with the right status value.
   - **Assign rider:** Call `POST /orders/<id>/assign-rider` with selected `rider_id`. Requires backend to expose rider list to restaurant (see below).

4. **Riders**
   - Restaurant needs a way to list riders (e.g. `GET /riders` for role `restaurant`, or `GET /riders/available`). Backend change required.

5. **Menu / Upload dish**
   - Either:
     - Backend adds `POST /restaurants/<id>/menu/categories` and `POST /restaurants/<id>/menu/items` (and optionally PATCH/DELETE), and app “Upload dish” uses them, or
     - Menu is managed elsewhere (e.g. admin/seed) and app only uses `GET /restaurants/<id>/menu` for display.

6. **Profile**
   - Profile screen can show backend user (name, phone) and optionally “my restaurant” (name, address, etc.). Updates via `PUT /auth/profile` and `PUT /restaurants/<id>`.

7. **Dependencies**
   - Remove Supabase/Postgrest if unused. Keep Firebase if used for FCM. Add a single `BackendApi` (or `RestaurantBackendApi`) for HTTP + JWT.

---

## 4. Recommended Implementation Plan

### Phase 1 – Auth and config (foundation)
1. **Backend API client**
   - Add `lib/config/api_config.dart` (base URL, same idea as customer app).
   - Add `lib/services/backend_api.dart`: login, register, getProfile, updateProfile, getOrders, getOrder(id), updateOrderStatus(id, status), assignRider(id, riderId). Use `http` or `dio`; send `Authorization: Bearer <token>` from stored JWT.
2. **Token storage**
   - Store access (and optionally refresh) token in Hive (e.g. same `auth` box) and read it in the API client.
3. **Auth flow**
   - **Option A (recommended):** Switch to backend-only auth: register/login via backend, store JWT + user in Hive. Use backend user id and role; keep Firebase only for FCM if needed.
   - **Option B:** Keep Firebase Auth for sign-in, then call backend “link or create user” and get JWT (requires an extra backend endpoint). More work.
4. **User model**
   - Extend or replace current `User` so it can hold backend user id, email, name, phone, role, and (if needed) “my restaurant” id/name from backend.
5. **“My restaurant”**
   - Backend: add `GET /restaurants/mine` (or equivalent) returning list of restaurants where `owner_id = current_user_id`. On first login in app, if list is empty, call `POST /restaurants` to create one (using restaurant name from register/profile), then cache “my” restaurant id in app.

### Phase 2 – Orders (core value)
1. **Unify order model**
   - Single `Order` (and `OrderItem`) in `lib/models/order.dart` that matches backend (id, customer_id, restaurant_id, status, total_amount, delivery_address, contact_name, contact_phone, items[], etc.) with `fromJson`/toJson and status enum aligned to backend.
2. **Orders provider**
   - Add an `OrdersProvider` (or reuse one) that:
     - Fetches orders with `GET /orders` (with JWT).
     - Exposes lists by status for tabs (Pending, Preparing, Ready, Out for delivery, Completed).
     - Caches in memory/Hive for offline-ish UX if desired.
3. **HomeScreen**
   - Replace `_loadSampleOrders()` with provider load from backend. Replace local status updates with `PATCH /orders/<id>/status`. Map backend status to UI (e.g. pending → Pending, preparing → Preparing, ready → Ready, assigned/on_the_way → Out for delivery, delivered → Completed).
4. **Order History**
   - Use same provider/orders source; apply filters (date, status, type) in the app. Remove hardcoded list.
5. **Assign rider**
   - Backend: allow restaurant to list riders (e.g. `GET /riders` for role `restaurant`, or new endpoint). App: fetch riders, show picker, call `POST /orders/<id>/assign-rider` with chosen `rider_id`.

### Phase 3 – Menu (Upload dish)
1. **Backend**
   - Add endpoints for restaurant to create/update menu:
     - e.g. `POST /restaurants/<id>/menu/categories` (name, description, display_order),
     - `POST /restaurants/<id>/menu/items` (category_id, name, description, price, image_url, preparation_time, available),
     - and optionally PATCH/DELETE for categories and items (with ownership checks).
2. **Upload dish screen**
   - Load “my restaurant” id and categories from backend; on submit, call POST menu item (and category if needed). Upload image to storage (e.g. Firebase Storage or backend upload endpoint) and send resulting URL as `image_url`.

### Phase 4 – Profile and polish
1. **Profile**
   - Load user from backend profile; allow edit name/phone via `PUT /auth/profile`. Optionally show and edit restaurant details via `PUT /restaurants/<id>`.
2. **Logout**
   - Clear JWT and local user; redirect to sign-in/sign-up.
3. **Remove Supabase**
   - Remove `supabase_flutter` and `postgrest` from `pubspec.yaml` and any leftover imports.

---

## 5. Backend Changes to Add (Checklist)

- [ ] **GET /restaurants/mine** (or `GET /restaurants?owner=me`) – return restaurants where `owner_id = current user`. Required so app knows “my” restaurant(s).
- [ ] **GET /riders** for role `restaurant` – return same list as admin (or a subset like “available” riders) so restaurant can choose rider when assigning.
- [ ] **POST (and optionally PATCH/DELETE) menu categories and items** under `/restaurants/<id>/menu/...` so “Upload dish” can create categories and items. Include ownership check (only owner or admin).

---

## 6. Suggested Order of Work

1. **Backend:** Add `GET /restaurants/mine` and open `GET /riders` for restaurant role.
2. **Restaurant app:** API config + BackendApi (auth + orders + restaurants mine + riders).
3. **Restaurant app:** Auth service + User model to use backend JWT and user; token storage in Hive.
4. **Restaurant app:** Single Order model + OrdersProvider + wire HomeScreen and Order History to real data and status updates.
5. **Restaurant app:** Assign rider flow (list riders, call assign-rider).
6. **Backend:** Menu POST endpoints; then **Restaurant app:** Upload dish wired to backend.
7. **Restaurant app:** Profile and “my restaurant” from backend; remove Supabase.

This order gets “orders from customer app show in restaurant app and can be updated” working first, then menu and profile.

---

## 7. File-Level Hints (Restaurant App)

| Task              | Files to add/change |
|-------------------|----------------------|
| API config        | `lib/config/api_config.dart` (new) |
| Backend client    | `lib/services/backend_api.dart` (new) |
| Auth + JWT        | `lib/services/auth_service.dart`, `lib/providers/user_provider.dart`, `lib/models/user_model.dart` |
| Order model       | `lib/models/order.dart` (unify; align with backend) |
| Orders provider   | `lib/provider/orders_provider.dart` (new or refactor) |
| HomeScreen orders | `lib/pages/homescreen.dart` (replace mock data, use provider, call API for status) |
| Order History     | `lib/pages/order_history.dart` (use same provider, remove hardcoded list) |
| Riders list       | In BackendApi + UI in HomeScreen for “Assign rider” |
| Upload dish       | `lib/pages/upload_dish.dart` (call menu APIs when backend has them) |
| Profile           | `lib/pages/profile.dart` (load/update via backend profile + restaurants) |
| Splash / routing  | `lib/pages/splashscreen.dart` (ensure post-login has JWT and “my restaurant”) |
| Dependencies      | `pubspec.yaml` (remove supabase/postgrest if unused) |

---

You can start with **Phase 1 (auth + config)** and **Phase 2 (orders)** so that orders placed in the customer app appear in the restaurant app and can be updated (and optionally assigned to a rider) from the app. If you tell me your preferred starting point (e.g. “backend first” or “restaurant app auth first”), the next step can be a concrete patch list or code edits for that part.
