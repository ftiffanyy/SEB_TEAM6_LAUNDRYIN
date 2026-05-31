# Custom Signup Flow with Phone Number Matching

This document describes the custom sign-up flow that avoids Firebase Auth email login and merges previous guest orders by phone number.

## Flutter MVVM Implementation

### Service Layer
- `FirestoreService` performs raw Firestore data access.
- `AuthService` contains authentication business rules:
  - register user using `username`, `password`, and `phone`
  - find existing guest users by phone
  - upgrade a guest user into a registered user when the phone matches
  - merge duplicate guest orders into the new user account

### ViewModel Layer
- `SignupViewModel` validates fields and calls `AuthService.registerCustomer`.
- `LoginViewModel` uses `AuthService.login` for username/password validation.

### View Layer
- `SignupPage` contains a `Form` with fields for name, username, password, phone, and optional address.
- `LoginPage` now links to `SignupPage`.

## Backend API Example

This pseudocode example shows a secure backend approach for custom signup and order merging.

```js
const express = require('express');
const bcrypt = require('bcrypt');
const { Firestore } = require('@google-cloud/firestore');

const firestore = new Firestore();
const app = express();
app.use(express.json());

app.post('/auth/signup', async (req, res) => {
  const { name, username, password, phone } = req.body;
  if (!name || !username || !password || !phone) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const normalizedPhone = phone.replace(/[^0-9]/g, '');
  const usersRef = firestore.collection('users');

  const existingUsername = await usersRef.where('username', '==', username).get();
  if (!existingUsername.empty) {
    return res.status(409).json({ error: 'Username already exists' });
  }

  const existingRegisteredPhone = await usersRef
    .where('phone', '==', normalizedPhone)
    .where('username', '!=', null)
    .get();

  if (!existingRegisteredPhone.empty) {
    return res.status(409).json({ error: 'Phone number already registered' });
  }

  const guestUsersSnapshot = await usersRef.where('phone', '==', normalizedPhone).get();
  const guestUsers = guestUsersSnapshot.docs
    .map(doc => ({ id: doc.id, ...doc.data() }))
    .filter(user => !user.username);

  const passwordHash = await bcrypt.hash(password, 12);
  let userId;

  if (guestUsers.length === 0) {
    userId = await getNextUserId();
    await usersRef.doc(`user_${userId}`).set({
      user_id: userId,
      name,
      username,
      password: passwordHash,
      phone: normalizedPhone,
      role: 'Customer',
    });
  } else {
    const primaryGuest = guestUsers[0];
    userId = primaryGuest.user_id;

    await usersRef.doc(primaryGuest.id).update({
      name,
      username,
      password: passwordHash,
      role: 'Customer',
    });

    const duplicateIds = guestUsers.slice(1).map(user => user.user_id);
    if (duplicateIds.length) {
      const ordersRef = firestore.collection('laundry_orders');
      const ordersSnapshot = await ordersRef.where('user_id', 'in', duplicateIds).get();
      const batch = firestore.batch();
      ordersSnapshot.docs.forEach(doc => {
        batch.update(doc.ref, { user_id: userId });
      });
      await batch.commit();
    }
  }

  return res.status(201).json({ user_id: userId });
});

app.listen(3000);
```

## Edge Cases and Security Notes

- Duplicate phone numbers are rejected when a registered account already exists.
- Guest accounts without a username/password are upgraded rather than duplicated.
- Passwords should be hashed with `bcrypt` or a strong KDF on the backend rather than stored in plaintext.
- In the Flutter app, the password is hashed before writing to Firestore as an additional mitigation layer.
- For real production security, move authentication to a backend service and never expose Firestore permissions directly to the client.
