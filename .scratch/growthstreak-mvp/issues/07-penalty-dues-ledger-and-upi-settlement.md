# 07: Penalty Dues Ledger & Direct UPI Intent Settlement

**What to build:** The penalty dues ledger and peer-to-peer UPI payment settlement flow. When a verified task is marked `missed`, an owed penalty banner appears. Tapping "Pay Penalty" opens the native UPI intent (`upi://pay?pa=friend_vpa&am=10...`) in GPay, PhonePe, or Paytm. The student taps "Marked Paid", prompting the friend on their web review link: *"Did [Name] pay you ₹10 via UPI? [Yes] [No]"*. Friend confirmation settles the debt and unfreezes the student's daily streak.

**Blocked by:** 06: Missed-Day Excuse Flow & Morning Grace Auto-Finalize

**Status:** ready-for-agent

- [ ] Missed verified task generates a `penalties/{penaltyId}` document with status `owed` and amount ₹10.
- [ ] Student app displays an active penalty banner and locks daily streak progression until all penalties are resolved.
- [ ] "Pay Penalty" action opens the native Android UPI intent with prefilled friend VPA, recipient name, amount (₹10), and note.
- [ ] Student taps "Marked Paid" after completing payment; status transitions to `marked_paid`.
- [ ] Friend review web page displays a one-tap confirmation prompt: *"Did [Name] pay you ₹10 via UPI? [Yes] [No]"*.
- [ ] Friend tapping "Yes" updates penalty status to `confirmed` in Firestore and unfreezes the student's streak immediately.
- [ ] Penalties (Dues) screen lists full history of settled and pending penalties.
