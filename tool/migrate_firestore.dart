import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'package:nexus/firebase_setup/firebase_options.dart';

/// One-off script to migrate Firestore data from the **old** Firebase project
/// (the one currently configured in [DefaultFirebaseOptions]) to the **new**
/// Firebase project corresponding to `android/app/new-google-services.json`.
///
/// Run with:
///   flutter run -t tool/migrate_firestore.dart
///
/// IMPORTANT:
/// - Make sure `android/app/google-services.json` still points at the OLD
///   project when you run this, so the old options work.
/// - After migration succeeds and you’ve verified data in the new project,
///   you can swap in the new `google-services.json` for the app itself.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  stdout.writeln('Initializing Firebase apps for migration...');

  // Initialize the DEFAULT app for the OLD project using your existing
  // firebase_options.dart configuration. Some desktop plugins expect a
  // default app to exist, even when you also use named apps.
  final defaultOldApp = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // NEW project: options derived from android/app/new-google-services.json
  // {
  //   "project_info": {
  //     "project_number": "252181378489",
  //     "project_id": "nexus-73",
  //     "storage_bucket": "nexus-73.firebasestorage.app"
  //   },
  //   "client": [
  //     {
  //       "client_info": {
  //         "mobilesdk_app_id": "1:252181378489:android:9788f1de126744f5d17268",
  //         "android_client_info": {
  //           "package_name": "com.life.nexus"
  //         }
  //       },
  //       "api_key": [
  //         { "current_key": "AIzaSyAoqaEsyQdFGNDZ-qwwLLcED537RKrWzS4" }
  //       ]
  //     }
  //   ]
  // }
  const newOptions = FirebaseOptions(
    apiKey: 'AIzaSyAoqaEsyQdFGNDZ-qwwLLcED537RKrWzS4',
    appId: '1:252181378489:android:9788f1de126744f5d17268',
    messagingSenderId: '252181378489',
    projectId: 'nexus-73',
    storageBucket: 'nexus-73.firebasestorage.app',
  );

  final newApp = await Firebase.initializeApp(name: 'new', options: newOptions);

  // Use the default app for old DB; desktop Firestore expects a default app.
  final oldDb = FirebaseFirestore.instanceFor(app: defaultOldApp);
  final newDb = FirebaseFirestore.instanceFor(app: newApp);

  // List of collections to migrate. Adjust as needed.
  const collectionsToMigrate = <String>[
    'tasks',
    'notes',
    'reminders',
    'habits',
    'categories',
  ];

  stdout.writeln('Starting Firestore migration...');

  for (final collection in collectionsToMigrate) {
    await _migrateCollection(collection, oldDb, newDb);
  }

  stdout.writeln('Migration complete.');
  // Exit the Flutter process once done.
  exit(0);
}

Future<void> _migrateCollection(
  String collectionPath,
  FirebaseFirestore oldDb,
  FirebaseFirestore newDb,
) async {
  stdout.writeln('Migrating collection: $collectionPath');

  final oldCollection = oldDb.collection(collectionPath);
  final newCollection = newDb.collection(collectionPath);

  final snapshot = await oldCollection.get();
  if (snapshot.docs.isEmpty) {
    stdout.writeln('  No documents found, skipping.');
    return;
  }

  stdout.writeln('  Found ${snapshot.docs.length} documents.');

  // Firestore limits batch size to 500 writes.
  const maxBatchSize = 450;
  var batch = newDb.batch();
  var writesInBatch = 0;
  var migrated = 0;

  Future<void> commitBatchIfNeeded({bool force = false}) async {
    if (writesInBatch == 0) return;
    if (!force && writesInBatch < maxBatchSize) return;
    await batch.commit();
    migrated += writesInBatch;
    stdout.writeln('  Committed batch, total migrated so far: $migrated');
    batch = newDb.batch();
    writesInBatch = 0;
  }

  for (final doc in snapshot.docs) {
    final targetRef = newCollection.doc(doc.id);
    batch.set(targetRef, doc.data());
    writesInBatch++;
    if (writesInBatch >= maxBatchSize) {
      await commitBatchIfNeeded(force: true);
    }
  }

  await commitBatchIfNeeded(force: true);

  stdout.writeln(
    '  Finished collection $collectionPath. Total migrated: $migrated documents.',
  );
}
