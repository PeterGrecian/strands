---
name: secrets-not-trash
description: Secrets/payment notes should be destroyed, not trashed; and never assume what an unlabelled file holds
metadata:
  type: feedback
---

When disposing of a **secret, credential, or payment instruction** (e.g. a
one-shot payee + reference note), a real delete/shred is the right action —
**not** `trash`. The house rule "never rm data, always trash" is about *data*;
these are one-shot sensitive instructions, and leaving them recoverable in
`~/.trash` for 14 days is a worse outcome than destroying them.

**Why:** Peter put a payment note in `~/z`; I assumed it was the Surbiton
tennis-club login I was waiting for, stored both lines in the secrets store
mislabelled, attempted a login with them, and trashed the file — all without
confirming what the file was. The £2.00 vs his stated £7.14 balance should have
tipped me off it wasn't his account. He corrected: "that was a request for me to
pay someone" and "I trashed it — that's a case where trash is not the right
action."

**How to apply:**
- Before reading/storing/deleting an **unlabelled or ambiguously-described
  file**, confirm what it is first. Don't fill the blank with what you expect.
- For secrets/payment data, destroy (shred/rm) rather than `trash`.
- A mismatch between observed state and stated expectation (wrong balance, wrong
  account) is a stop-and-check signal, not something to explain away.

Related: [[calendaralarm-surbiton]]
