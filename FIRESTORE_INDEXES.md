# Firestore Composite Indexes

Certain queries in R.E.M. filter documents by `userId` and order them by `timestamp`. Firestore requires a composite index for these patterns.

## Example Queries

Sleep logs and dreams are retrieved using code similar to:

```dart
FirebaseFirestore.instance
  .collection('sleep_logs')
  .where('userId', isEqualTo: uid)
  .orderBy('timestamp', descending: true);
```

A matching query exists for the `dreams` collection. Without an index, Firestore will prompt you to create one.

## Creating Indexes

You can create the indexes through the Firebase console under **Firestore Database > Indexes > Composite** or via the `gcloud` CLI.

### Sample `firestore.indexes.json`

```json
{
  "indexes": [
    {
      "collectionGroup": "sleep_logs",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId",    "order": "ASCENDING"},
        {"fieldPath": "timestamp", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "dreams",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId",    "order": "ASCENDING"},
        {"fieldPath": "timestamp", "order": "DESCENDING"}
      ]
    }
  ],
  "fieldOverrides": []
}
```

Deploy with:

```bash
# Example for sleep_logs
 gcloud firestore indexes composite create \ 
   --collection-group="sleep_logs" \ 
   --query-scope=COLLECTION \ 
   --field-config field-path=userId,order=ASCENDING \ 
   --field-config field-path=timestamp,order=DESCENDING
```

Repeat for the `dreams` collection (change `collection-group`). Alternatively, add the JSON above to a `firestore.indexes.json` file and run `gcloud firestore indexes composite create` for each entry or deploy using `firebase deploy`.

For charts that stream data chronologically, an ascending index is also required:

```json
{
  "collectionGroup": "sleep_logs",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "userId",    "order": "ASCENDING"},
    {"fieldPath": "timestamp", "order": "ASCENDING"}
  ]
}
```

Create a similar ascending index for the `dreams` collection if you ever query it in that order.
