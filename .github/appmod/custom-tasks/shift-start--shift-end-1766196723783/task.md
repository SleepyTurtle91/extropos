---
id: shift-start--shift-end-1766196723783
name: Shift Start/ Shift end
type: task
---

**Prompt:**

In a Malaysian retail or F&B context, separating **Shift End** from **Day Closing** is a smart way to maintain high accountability (checking individual cashiers) while keeping clean daily books for accounting.

Here is the implementation logic for that specific workflow.

---


# 1. The Logic: Shift vs. Day


Think of the **Shift** as the "Cashier's Responsibility" and the **Day** as the "Business's Responsibility."

| Feature | Shift End (Handover) | Day Closing (Final) |
| --- | --- | --- |

| **Trigger** | Staff change or break. | Doors lock; business ends. |

| **Primary Goal** | Reconcile the cash drawer (RM). | Consolidate all shifts + finalize tax (SST). |

| **Action** | Count float and handover to next staff. | Total up all e-wallets, cards, and cash. |

| **Output** | **X-Report** (Running total). | **Z-Report** (Resets the system). |

---


## 2. Implementation Steps



### Step 1: "Start Business" (The Morning Ritual)


When you "Start Business," the system initializes the date and the tax counters for the day.


* **Logic:** Check if the previous day was closed. If not, force a "Day Close" before allowing a new day to start.

* **RM Entry:** Enter the **Master Float** (e.g., RM300 in a mix of RM1, RM5, and RM10 notes).


### Step 2: Ending a Shift (The Handover)


This happens when Cashier A leaves and Cashier B takes over.

1. **Count Cash:** Cashier A counts the drawer. Let’s say the drawer has **RM850**.

2. **System Check:** The POS says there should be **RM852.50** (including rounding).

3. **Variance:** The system records a **-RM2.50** shortage against Cashier A.

4. **Transition:** The POS does **not** reset daily sales. It simply marks a "breakpoint." Cashier B logs in and continues.


### Step 3: Day Closing (The Night Ritual)


This is the final step before the manager goes home.

1. **Consolidate:** The POS pulls data from Shift 1, Shift 2, and Shift 3.

2. **Non-Cash Reconciliation:** Verify e-wallet totals (Touch 'n Go, GrabPay, DuitNow) against the terminal's settlement slips.

3. **SST Reporting:** The system generates the daily tax summary required for Malaysian accounting (LHDN compliance).

4. **Z-Report:** Once "Day Close" is clicked, all totals reset to zero for the next business day.

---


## 3. Visual Workflow of the Process


---


## 4. Pro-Tips for Malaysia (SST & Rounding)


* **The 5-Sen Rule:** Ensure your **Shift End** report accounts for the rounding adjustment. If the total was RM10.02 and the customer paid RM10.00, the shift report must show the rounded "Actual" collected.

* **E-wallet Settlement:** Most Malaysian e-wallets (like Grab or TnG) settle at midnight. Your **Day Closing** should ideally happen after you "Settle" your credit card and e-wallet terminals so you can attach the physical slips to your Z-Report.

* **Shift Overlap:** If your business stays open past midnight (e.g., a mamak stall or 24h cafe), your "Day Closing" logic should allow you to set a **"Business Date"** that is different from the "Calendar Date."

