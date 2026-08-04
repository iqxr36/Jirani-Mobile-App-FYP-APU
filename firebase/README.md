# Firebase Storage CORS

Apply the Firebase Storage CORS configuration for Flutter web image loads.

This requires the Google Cloud SDK (`gsutil`). Run from the project root:

```sh
gsutil cors set firebase/storage-cors.json gs://final-year-project-faisal.firebasestorage.app
```

Verify the deployed configuration:

```sh
gsutil cors get gs://final-year-project-faisal.firebasestorage.app
```

Add any custom hosting domain to `firebase/storage-cors.json` before deploying
when the web application is served from another origin.
