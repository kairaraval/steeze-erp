# Steeze OS — Purchasing & Inventory Playbook

**For:** the Purchasing & Inventory role (onboarding guide + daily process)
**Owner:** Kaira / Sir Miko
**Last updated:** September 2026

---

## 1. What this role is really responsible for

Two things, and they are equally important:

1. **Buying what production needs, on time and at the right cost** (Purchase Requests → Purchase Orders → Receiving).
2. **Keeping the inventory count TRUE** — so that when anyone in the company looks at Steeze OS, the on-hand number matches what is physically in the stockroom.

If the count is wrong, everything downstream breaks: production gets surprised by stock-outs, costing is off, and money is wasted re-buying things we already had. So the golden rule of this role is:

> **Every physical movement of stock is recorded in Steeze OS on the same day it happens. Nothing moves in or out of the stockroom without a matching entry.**

---

## 2. How inventory works now (important — read this once)

Steeze OS keeps **one source of truth** for stock: the **stock ledger** (every stock-in and stock-out). The on-hand number you see on each item is calculated automatically by the system from that ledger. The database keeps them locked together — you can no longer have an on-hand number that disagrees with its history.

**What this means for you:**

- You **never type an on-hand quantity directly to "correct" it.** If a count is wrong, you fix it by posting a movement (a stock-in, a stock-out, or a cycle-count adjustment). The system then recalculates on-hand.
- Every stock-in and stock-out is permanent and auditable. If you make a mistake, you **reverse** it (which posts a correcting entry) — you don't delete it.
- When you add a brand-new item with a starting quantity, that starting quantity is recorded as an "opening balance" automatically.

This is the backbone that makes the count trustworthy. Respect it and the numbers stay clean.

---

## 3. The daily routine (your three lists)

Start every day by working these three lists to zero. This is the whole job, boiled down.

### List 1 — "What's low?" (prevent stock-outs)
- Go to **Inventory** and check items **at or below their reorder point**.
- For anything low that production will need, **raise a Purchase Request (PR)**.
- *(Reorder points are what make this list work. See §7 — setting them up is the single highest-value setup task.)*

### List 2 — "What have I ordered that hasn't arrived?" (chase & receive)
- Go to **Purchase Orders** and look at **open / partial** POs.
- Chase suppliers on anything overdue.
- The moment goods arrive, **Receive** them against the PO (see §5). Do not let received goods sit unreceived in the system.

### List 3 — "What's waiting on me?" (keep things moving)
- Go to **Request for Purchasing** / PRs and clear anything **submitted** and waiting: approve, convert to a PO, or fulfil from stock.
- Nothing should sit in "submitted" for more than a day or two without action.

---

## 4. Purchase Request → Purchase Order flow

1. **PR is created** (by you or by another department) listing what's needed, ideally linked to the lead/job it's for.
2. **Check stock first.** If we already have the item, use **Fulfil from stock** — this issues it from inventory instead of buying more. (This is a money-saver; always check before buying.)
3. **Approve** the PR.
4. **Convert to a PO** — pick the supplier, confirm quantities, prices, payment terms.
5. Send the PO to the supplier.
6. When goods arrive → **Receive** (next section).

**Confirm, don't assume.** Before converting, sanity-check quantities and prices against the request and the pricelist. A wrong PO is expensive to unwind.

---

## 5. Receiving (the step that keeps inventory current)

**Receive goods the same day they physically arrive.** This is the #1 discipline of the role.

1. Open the PO in **Purchase Orders**.
2. Click **Receive**.
3. Enter the quantity **actually received** for each line (not what was ordered — what actually showed up). Partial deliveries are fine; enter what came in and the PO stays "partial" until the rest arrives.
4. Save. The system posts a stock-in for each line and inventory goes up automatically.

**Why it matters:** if you skip this, the goods are physically in the stockroom but the system thinks we never got them — so on-hand is understated, and someone will re-order or panic-buy something we already have. An unreceived PO is invisible stock.

---

## 6. Issuing stock (stock-out) & other movements

- **Issuing materials to a production job:** use **Stock Out**. Pick the job, enter the materials and quantities. This records the consumption and lowers on-hand.
  - **Do not** mark a job's materials "complete" without recording the stock-out, unless materials genuinely came from outside the system. Skipping the stock-out makes inventory look higher than it really is.
- **Manual stock-out:** for samples, wastage, or anything issued outside a job — use the manual stock-out and write a clear reason.
- **Returns to stock:** if production returns unused material, record a **stock-in (return)** so it goes back on hand.
- **Cutting / converting** (e.g. fabric rolls → blocks): use **Convert** — it stocks out the source and stocks in the product in one step, keeping both counts right.
- **Made a mistake?** Use **Reverse** on the movement. It posts a correcting counter-entry and fixes on-hand. Never try to fix it by editing a number.

---

## 7. Setup that makes the system work FOR you

These are one-time (or occasional) setup tasks. They are what turn inventory from a chore into an early-warning system.

### a) Reorder points (highest priority)
Set a **reorder point** on every item production regularly uses — the level at which we should buy more. Once set, the "What's low?" list fills itself and stock-outs become preventable instead of surprises. *(Right now almost no items have one set — this is the biggest quick win.)*

### b) Preferred supplier per item
Link each item to the supplier we usually buy it from, so raising a PO/PO is fast and consistent.

### c) Locations / bins
Give each item a **location** (shelf/bin). This makes physical counting and finding stock far faster. *(Right now most items have no location — worth filling in as you handle each item.)*

---

## 8. Weekly cycle counts (how the count stays honest)

Don't wait for one giant year-end count. Count a **small rotating slice every week**:

1. Pick a group (e.g. one shelf, one category, or the 20 highest-value / fastest-moving items).
2. Physically count them.
3. Compare to what Steeze OS shows.
4. For any difference, post a **cycle-count adjustment** (a stock-in or stock-out for the gap) with the reason "cycle count." The system corrects on-hand.
5. Note *why* it differed if you can (miscount, unrecorded issue, breakage) — patterns tell you where the process is leaking.

Over a month or two you'll have counted everything important, and the count stays trustworthy year-round.

---

## 9. The golden rules (put this on the wall)

1. **Every stock move is recorded the same day.** In or out, no exceptions.
2. **Receive the day goods arrive.** Unreceived stock is invisible stock.
3. **Never type an on-hand number to "fix" it.** Post a movement or a cycle-count adjustment; let the system recalculate.
4. **Check stock before buying.** Fulfil from stock beats a new PO.
5. **Mistakes get reversed, not deleted.** The history stays clean and auditable.
6. **Confirm, don't assume,** before converting a PR to a PO.

---

## 10. What "good" looks like (KPIs to watch)

- **Open POs older than 2 weeks:** should be near zero (chase or receive them).
- **Items below reorder with no PR raised:** should be zero.
- **Cycle-count accuracy:** the % of counted items that matched the system — aim to push this up over time.
- **Stock-outs that surprised production:** should trend to zero once reorder points are in place.

---

## 11. Handover notes (current state, Sept 2026)

Things the new person should tackle early, because they're the current gaps:

- **Reorder points are essentially not set** across the catalogue. Setting them (§7a), starting with the most-used materials, is the highest-impact thing you can do.
- **Item locations are mostly blank** (§7c). Fill them in as you touch items.
- **There was a receiving backlog** — a handful of POs left open for weeks. Clear old open POs and keep List 2 at zero going forward.
- **The on-hand counts were reconciled to the ledger in Sept 2026,** so today's numbers are a clean baseline. Keep them clean by following the golden rules — start the weekly cycle counts to prove and maintain accuracy.

---

*This playbook is the process. The system now enforces the hardest part (the count can't silently drift). The rest is discipline: record everything, receive on time, and count a little every week.*
