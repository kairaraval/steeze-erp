# Steeze OS — Invoicing Design Plan

_Status: proposal for review. No code or database changes have been made yet._

## 1. Goal & scope

Add invoicing to Steeze OS as an **internal billing document / Statement of Account (SOA)**, generated from a Sales Order by the Accounting team.

- The OS invoice is for **billing the client and tracking what's owed** — it shows the order, what's already been paid (e.g. the 50% downpayment), and the balance due.
- The **official BIR Sales Invoice continues to be issued from QuickBooks.** We keep the existing `qb_invoice_number` / `qb_invoice_url` fields on the Sales Order so the OS billing doc and the official QB invoice stay linked.
- Access is restricted to **admin + accounting**, enforced in the UI and again by row-level security (same model as Estimates).

> **Compliance note:** In the Philippines the official Sales Invoice is BIR-regulated (controlled number series, no gaps, often via accredited software). This plan deliberately keeps the OS invoice as an internal/SOA document so we don't create a compliance gap. Confirm the final wording of the printed document with your accountant.

## 2. Where it lives — the document chain

```
Estimate (EST)  →  Sales Order (SO)  →  Invoice (INV)  →  Payments
  (from lead)       (at Closed Won)      (from the SO)     (recorded against SO/INV)
                                         + Delivery Receipt
```

- **Generate Invoice button on the Sales Order** (admin + accounting only), pre-filled from the SO — same pattern as the Estimate button on the lead.
- A dedicated **Invoices list / report view** under Finance (mirrors the Estimates list): search, filter by status, totals, AR outstanding, click-through to open / edit / reprint.

## 3. Why generate from the SO

The Sales Order is already the single source of truth and needs no re-entry:

- It holds `items`, `subtotal`, `discount`, `vat_amount`, `total`, `payment_terms`.
- It already tracks money received: `amount_paid` and `balance_due`, plus the `sales_order_payments` table.
- `sales_order_payments` **already has an `invoice_id` column** (currently unused) — the schema was clearly designed with invoices in mind, so payments can attach to a specific invoice.

## 4. Data model

### New table: `invoices`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `number` | text unique | `INV-YYYY-MM-NNN` (matches EST/SO scheme) |
| `sales_order_id` | uuid → sales_orders | source SO |
| `lead_id` | uuid → leads | carried for reference |
| `client_id` / `client_name` | uuid / text | snapshot |
| `invoice_type` | text | `full` \| `downpayment` \| `balance` |
| `items` | jsonb | snapshot of SO lines at generation |
| `subtotal` / `discount` / `vat_amount` / `total` | numeric | the **whole order** totals |
| `amount_due` | numeric | what **this invoice** bills (see §5) |
| `dp_percent` | numeric | optional, e.g. 50 for a 50% DP invoice |
| `payments_received` | numeric | snapshot of payments already received on the SO at issue |
| `balance_due` | numeric | order total − payments received |
| `status` | text | `draft` \| `issued` \| `partially_paid` \| `paid` \| `cancelled` |
| `issue_date` | date | |
| `due_date` | date | derived from payment terms |
| `payment_terms` | text | same `PAYMENT_TERMS_OPTIONS` list |
| `notes` | text | |
| `qb_invoice_number` / `qb_invoice_url` | text | link to the official QuickBooks invoice |
| `prepared_by` | uuid → profiles | |
| `created_at` / `updated_at` | timestamptz | trigger-maintained |

### Reuse, don't duplicate

- Payments stay in **`sales_order_payments`**; we just populate the existing **`invoice_id`** when a payment is applied to a specific invoice.
- The SO keeps its `amount_paid` / `balance_due` rollups. The invoice reads from these rather than maintaining its own parallel payment ledger.

### Security (RLS)

- Enable RLS; `select` / `insert` / `update` / `delete` limited to `is_admin() OR is_accounting()` — identical to the `estimates` table. Add an `updated_at` trigger.

## 5. Invoice types & the downpayment

Every invoice prints the same money block, driven by the SO's payments:

```
Order total .................. ₱100,000
Less: payments received .....  −₱50,000   (e.g. 50% DP already paid)
------------------------------------------
Balance due ................   ₱50,000
```

The three types differ in **what amount is being billed now**:

- **Full** — bills the entire order. `amount_due = total`. Still shows any DP already received and the remaining balance.
- **Downpayment** — bills the DP only (e.g. 50%). `amount_due = total × dp_percent`. Used to request the DP before production.
- **Balance** — bills the remainder after the DP. `amount_due = total − payments_received`.

`payments_received` is pulled from `sales_order_payments` for the SO, so the figure is always accurate to what's actually been collected.

## 6. Screens

1. **Generate Invoice (button on the Sales Order)** → opens an Invoice modal pre-filled from the SO: type selector (Full / DP / Balance), editable lines/notes/due date, live money block, Save draft / Mark issued / Preview & Print.
2. **Printable invoice** — Steeze letterhead (reusing `DocPrintHeader` + the portal/`po-page` print path we just fixed for estimates), Bill-To, line items, the money block above, payment terms, and standard footer. Marked "Billing Statement / SOA" per the compliance decision.
3. **Invoices list view (Finance)** — tiles (total billed, outstanding AR, paid, overdue), search + status/type filters, table with click-through, expired/overdue flags.

## 7. Status lifecycle

`draft → issued → partially_paid → paid` (plus `cancelled`).
Status can be derived from payments: when `payments_received ≥ total` → `paid`; `> 0 and < total` → `partially_paid`. Overdue = `issued`/`partially_paid` past `due_date`.

## 8. Integration with what exists

- **Customer Ledger / AR aging** can read invoices for a truer AR picture (currently driven off SO balances).
- **Payment Calendar / Finance Home** can surface overdue invoices.
- **QuickBooks** stays the official record via the `qb_invoice_*` link fields.

## 9. Build checklist (when approved)

1. `invoices` table + `is_accounting()`-based RLS + `updated_at` trigger (Supabase migration).
2. `InvoiceModal` (generate-from-SO, edit, type logic, money block).
3. Printable invoice on letterhead (portal + `po-page`, as fixed for estimates).
4. "Generate Invoice" button on the Sales Order (admin + accounting).
5. `InvoicesListView` + Finance nav entry + route + data load.
6. Wire `sales_order_payments.invoice_id` when payments are applied.
7. Verify (schema test + JSX checks), commit, push.

## 10. Open questions for you

- Should marking an invoice **issued** auto-set the SO status or notify anyone?
- Do you want the printed document titled **"Billing Statement"**, **"Statement of Account"**, or **"Invoice"**?
- Should the Invoices list feed the existing **Customer Ledger / AR aging**, or stay standalone for now?
