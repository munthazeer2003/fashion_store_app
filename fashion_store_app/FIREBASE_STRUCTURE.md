# Firebase Structure

## Firestore collections

### `users/{uid}`
```json
{
  "name": "Munthazeer",
  "email": "munthazeer@email.com",
  "phone": "+94 77 123 4567",
  "profileImageUrl": "https://...",
  "addresses": [
    {
      "title": "Home",
      "isDefault": true,
      "addressLine1": "123 Main Street",
      "addressLine2": "Colombo 03"
    }
  ],
  "updatedAt": "2026-05-19T00:00:00.000Z"
}
```

### `products/{productId}`
```json
{
  "name": "Men Shirt Classic",
  "price": 2500,
  "imageUrl": "https://firebasestorage.googleapis.com/...",
  "category": "Men",
  "description": "Comfort fit cotton shirt",
  "isPopular": true,
  "isNewArrival": true
}
```

### `categories/{categoryId}`
```json
{
  "name": "Men"
}
```

### `carts/{uid}/items/{productId}`
```json
{
  "name": "Men Shirt Classic",
  "imageUrl": "https://firebasestorage.googleapis.com/...",
  "price": 2500,
  "quantity": 2,
  "category": "Men",
  "updatedAt": "2026-05-19T00:00:00.000Z"
}
```

### `orders/{orderId}`
```json
{
  "userId": "firebase_uid",
  "items": [
    {
      "productId": "shirt_1",
      "name": "Men Shirt Classic",
      "imageUrl": "https://...",
      "price": 2500,
      "quantity": 2,
      "category": "Men"
    }
  ],
  "subtotal": 5000,
  "shipping": 10,
  "tax": 400,
  "total": 5410,
  "shippingTitle": "Home",
  "shippingSubtitle": "123 Main Street\\nColombo 03",
  "paymentTitle": "Visa ending in 4242",
  "paymentSubtitle": "Expires 12/24",
  "status": "active",
  "createdAt": "2026-05-19T00:00:00.000Z"
}
```

## Rules files
- Firestore rules: `firebase/firestore.rules`
- Storage rules: `firebase/storage.rules`
