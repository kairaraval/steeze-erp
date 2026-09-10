# Steeze OS — Client Order Portal
### Plan & Specification (for review)

**Prepared for:** Kaira, Sir Miko
**Status:** Draft for approval — no code written yet
**Date:** September 2026

---

## 1. Summary

We want our recurring clients — especially sports/jersey accounts that order and reorder all year — to log in and submit their own orders instead of us managing a Google Sheet with a new tab per reorder each month.

The plan is to add a **Client Order Portal** to Steeze OS. Clients get a simple login where they can submit orders and reorders, upload artwork, track status, and (later) see their invoices and balances. On our side, every submission lands in one place so Sales can review it and turn it into a normal order in the OS.

The single most important design rule: **clients live in the same system but on a completely separate, walled-off surface.** They can only ever see their own orders — never anything else in the ERP.

---

## 2. Goals & non-goals

**Goals**
- One place for clients to submit new orders and monthly reorders (replaces the Google Sheet).
- Easy reorders — duplicate a past order and adjust.
- Both sides see the same submitted orders and their status.
- Clients can attach artwork/design files with an order.
- Later: clients can view their own invoices, balances, and our payment channels.
- Our internal workflow (Lead → Estimate → Tech Pack → Approval → Print → Graphics → Production) stays exactly the same.

**Non-goals (for now)**
- Clients do **not** get access to the internal OS (financials, other clients, suppliers, payroll, employees).
- The portal does **not** process payments — it only *displays* balances and where to pay.
- Not replacing our internal order management — the portal is an **intake + visibility** layer that feeds the existing OS.

---

## 3. Guiding principle: hard isolation

Steeze OS is our ERP. It holds sensitive data — RFPs, vouchers, payroll, commissions, bank accounts, supplier costs and margins, employee 201 files, and every other client's orders.

Today the system is built for staff only: essentially any logged-in user is trusted to read most data. That trust model is fine for staff, but it means **we cannot simply add client logins to the same pool** — a client account could otherwise reach data it must never see.

So the rule for this build is:

> A client account can read and write **only its own orders and its own invoices**, and nothing else — enforced at the database level, not just hidden in the screens.

This isolation is the foundation of the whole project and the part that most deserves careful work and testing.

---

## 4. How it fits our current workflow

Our "new tab per reorder per month" maps cleanly onto the portal:

| Today (Google Sheet) | Portal |
|---|---|
| A tab per reorder | One **submission** per reorder |
| Client edits cells | Client fills a **structured form** |
| We watch the sheet | Submissions arrive in a **Client Orders inbox** in OS |
| We retype into OS | Sales **converts** a submission into a Lead (prefilled) |
| Client asks "what's the status?" | Client sees status live: Received → In production → Ready → Delivered |

Once a submission is converted to a Lead, the rest is unchanged: request the estimate from Ms. Rose, build the Tech Pack, get Sir Miko's approval, print, ticket to Graphics, produce.

---

## 5. Architecture overview

- **One database, two surfaces.** Clients and staff share the same Supabase database. A client login renders **only** the portal; the internal OS never loads for them.
- **Security is in the database.** Because a login token can call the data API directly, the protection can't be only in the UI. Row-level rules in the database guarantee a client can touch only its own rows.
- **Invite-only accounts.** Just like staff, client accounts are created by us (we send an invite) and each account is linked to exactly one client company.
- **No new servers.** This reuses our existing Supabase + hosting. The portal is a separate screen/route inside the same app, gated so only client accounts see it.

---

## 6. Security model (the critical part)

This is the heart of the build. Three pieces:

**a) Client identity**
- A table links each client login to the client company it belongs to.
- A database helper answers "which client is this user?" (or "this user is staff") for every request.

**b) Portal data is scoped per client**
- New client-order tables have a rule: *you may only see/edit rows where the client is you.*
- Staff can see and manage all of them (for the inbox and conversion).

**c) Internal data is closed to clients (prerequisite)**
- Before any client login exists, we audit and tighten the rules on internal tables so they require a **staff** account. Client accounts get nothing from these tables even if they try the API directly.
- Financial visibility for clients (Phase 3) is delivered through a **read-only, client-safe view** that returns only client-appropriate columns (invoice number, amount due, paid, balance, due date, status) — never costs, margins, commissions, or other clients.

**Testing gate:** before the pilot goes live, we verify with a real client test account that it can read *only* its own orders/invoices and is denied on every internal table — tested directly against the data API, not just the UI.

---

## 7. Data model (plain-language)

**Client submission (the "tab")**
- Which client, a title/label (e.g. "October Reorder — Batch 2"), status, date submitted, general notes.

**Order lines (inside a submission)**
- Structured fields matching how sports orders actually look: design/colorway, garment (jersey / short set / etc.), size breakdown, names, numbers, quantity, colors, print placements, delivery date, per-line notes.

**Attachments**
- Artwork, logos, or a reference file — stored privately and scoped to that client.

**Link to internal work**
- When Sales converts a submission, it's linked to the Lead it became, so status can flow back to the client automatically.

**Finance (Phase 3, read-only)**
- The client sees a filtered view of their own invoices/balances plus a static "payment channels" info block.

---

## 8. Client portal — what the client sees

Deliberately small and simple:

- **My Orders** — a list of their submissions (their "tabs"), newest first, each showing status.
- **+ New Order** — the structured form; attach files; submit.
- **Duplicate last order** — clone a previous submission, adjust sizes/quantities, submit. (The key feature for monthly reorders.)
- **Order status** — Received → In production → Ready → Delivered.
- **Invoices & Balance** (Phase 3) — their outstanding balance, per-invoice detail, and where/how to pay.
- Mobile-friendly, mirroring the columns they already use in their sheet so it feels familiar.

---

## 9. Staff side — what our team sees in OS

- **Client Orders inbox** — every new submission in one queue, with the client, date, and contents.
- **Review & convert** — open a submission, check it (our "confirm, don't assume" step), then **Convert to Lead** — prefilled from the client's form so no retyping.
- **Status control** — update status; the client sees it update.
- **Client account management** — invite a client, link them to their company, deactivate when needed.

---

## 10. Finance visibility (Phase 3)

- Clients see **only their own** invoices and balances, through a read-only, client-safe view (no internal cost/margin data ever leaves).
- "Payment channels" is displayed information only (e.g., bank details / GCash) — the portal does **not** take payments.
- Turned on **after** the pilot proves the isolation is solid.

---

## 11. Phased delivery plan

| Phase | What ships | Why this order |
|---|---|---|
| **0 — Foundation** *(required first)* | Client identity + lock down internal data so client accounts are provably isolated. | Safety-critical groundwork. Nothing client-facing goes live until this is done and tested. |
| **1 — MVP** | Client login, submit a structured order, upload artwork, see submissions & status. Staff inbox + convert-to-lead. | Delivers the core value and lets us pilot. |
| **2 — Reorders** | Duplicate-a-past-order; status timeline. | The biggest convenience for recurring monthly accounts. |
| **3 — Finance** | Clients see their own invoices, balances, payment channels (read-only). | Highest-sensitivity data — added only after isolation is proven. |

---

## 12. Pilot plan

1. Pick 1–2 cooperative recurring sports clients.
2. Ship Phase 0 + 1; create their accounts; onboard them with a short walkthrough.
3. Run both the portal and their Google Sheet in parallel for a few order cycles (safety net).
4. Confirm submissions convert cleanly to Leads and status is useful to the client.
5. Add Phase 2, then Phase 3.
6. Expand to more clients once it's proven.

---

## 13. Risks & mitigations

- **Data exposure (highest risk).** → Database-level isolation + a real client test account verified against the API before launch. Finance visibility deferred to Phase 3.
- **Client adoption.** Some clients love their sheet. → Keep the form dead-simple and mobile-first; run in parallel during the pilot; offer a Sheet-import fallback for holdouts if needed.
- **Messy/incomplete submissions.** → Sales always reviews and confirms before converting (our existing "don't assume" checkpoint); required fields on the form.
- **Scope creep.** → Ship phase by phase; finance and extras come only after the core works.

---

## 14. Out of scope (for this build)

- Online payment processing.
- Client access to any internal OS module.
- Automatic production scheduling from client submissions (Sales still reviews and converts).
- Public/self-serve signup (accounts stay invite-only).

---

## 15. Open decisions for review

1. **Confirm the pilot clients** (which 1–2 accounts).
2. **Structured-form fields** — confirm the exact fields per order line to match how sports orders really come in.
3. **Status labels** — the exact wording clients should see.
4. **Payment channels** — which details we want shown, and confirm the portal only *displays* them.
5. **Sheet fallback** — do we want the Google Sheet importer for holdout clients, or portal-only?
6. **Branding** — should the portal look like a Steeze-branded client site, or match the OS style?

---

## 16. Recommendation

Proceed in this order: **Phase 0 (foundation) → Phase 1 (MVP) → pilot with 1–2 clients → Phase 2 → Phase 3.** Do the isolation groundwork carefully and prove it with a small pilot before enabling invoice/balance visibility. This is a bigger, higher-sensitivity build than our recent features because it brings outside users into a financial ERP — which is exactly why the separate, locked-down surface and the phased rollout matter.

---

*Once this plan is approved (and the open decisions above are settled), the first concrete step is Phase 0: the client-identity model and the internal-data lockdown, tested with a client dummy account.*
