# Backend (agri_api) na kailangang baguhin

Wala sa zip ang PHP backend, kaya hindi ko nakita ang schema at router mo.
Ang mga pangalan ng table/column sa ibaba ay **assumption**: i-adjust sa totoong meron ka.

## 1. SQL (phpMyAdmin)

```sql
-- ang store ay ginagawa na ng admin, kaya puwedeng walang owner pa
ALTER TABLE stores MODIFY owner_id INT NULL;

CREATE TABLE store_claims (
  id INT AUTO_INCREMENT PRIMARY KEY,
  store_id INT NOT NULL,
  owner_id INT NOT NULL,
  permit_image VARCHAR(255) NOT NULL,
  storefront_image VARCHAR(255) NOT NULL,
  status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  rejection_reason VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at DATETIME NULL,
  reviewed_by INT NULL,
  FOREIGN KEY (store_id) REFERENCES stores(id),
  FOREIGN KEY (owner_id) REFERENCES users(id)
);
CREATE INDEX idx_claim_store_status ON store_claims (store_id, status);
```

Gumawa ng folder `agri_api/uploads/claims/` (writable).

## 2. Mga endpoint

### Owner
| Endpoint | Gawa |
|---|---|
| `GET /owner/stores/available` | Stores na `owner_id IS NULL` at walang `pending` claim. Ibalik: `id, name, address, barangay`. |
| `POST /owner/store/claim` | Body: `store_id, permit_image, storefront_image` (base64 JPEG). Dapat `store_owner` ang user. I-decode, i-save sa `uploads/claims/<random>.jpg` (i-check na image at < 3 MB). Tanggihan kung may owner na ang store, may pending claim na, o ang owner ay may pending/approved claim na. Insert sa `store_claims` na `status='pending'`. |
| `GET /owner/store` | Kunin ang **pinakabagong claim** ng owner. Wala -> `null`. Kung meron, ibalik ang store fields (`name, address, barangay, latitude, longitude, description, contact_number, opening_hours`) kasama ang `store_id`, `status` (galing sa claim) at `rejection_reason`. |
| `POST /owner/store` | **Tanggapin lang** `description, contact_number, opening_hours`, at sa approved store lang ng owner. Huwag i-update ang `name, address, barangay, latitude, longitude` kahit ipadala. |
| `/owner/products*` | Payagan lang kung may approved claim ang owner. |

### Admin (`role = 'admin'` lang)
| Endpoint | Gawa |
|---|---|
| `GET /admin/claims?status=pending` | Join `store_claims`, `stores`, `users`. Ibalik: `id, store_name, address, barangay, owner_name, owner_email, permit_url, storefront_url` (hal. `uploads/claims/xxx.jpg`). |
| `POST /admin/claims/review` | Body: `claim_id, action ('approve'/'reject'), reason`. **Approve:** sa isang transaction, `status='approved'`, `stores.owner_id = claim.owner_id`, at i-reject ang ibang pending claim sa store na iyon. **Reject:** `status='rejected'` at `rejection_reason` (required). Itakda ang `reviewed_at`, `reviewed_by`. |
| `GET /admin/stores` | Lahat ng store: `id, name, barangay, owner_name, status`. |
| `POST /admin/stores` | Body: `name, address, barangay, description, latitude, longitude`. Insert sa `stores` na `owner_id = NULL`. I-validate ang coordinates. |

### Pang-customer
Ipakita lang sa customers ang store na may owner (`owner_id IS NOT NULL`, approved claim).

### `/auth/me` at login
Ang `store_status` ay galing sa pinakabagong claim ng owner (`pending/approved/rejected`, o `null` kung wala).

## 3. Seguridad
- Huwag pagkatiwalaan ang `owner_id` mula sa client; laging gamitin ang user sa token.
- Naglalaman ng ID at permit ang `uploads/claims/`. Mas ligtas kung hindi public: `.htaccess` na `Require all denied` at i-serve lang sa admin sa pamamagitan ng PHP endpoint. Okay ang public habang nagde-develop, pero ayusin bago i-deploy.
- Lagyan ng rate limit ang `/owner/store/claim`.
