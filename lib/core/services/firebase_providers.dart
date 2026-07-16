import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dependency-injection roots. Everything downstream (repositories,
/// services) receives these via Riverpod, so tests can override them with
/// fakes (see /test).
final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);
final firebaseStorageProvider = Provider<FirebaseStorage>((_) => FirebaseStorage.instance);
final analyticsProvider = Provider<FirebaseAnalytics>((_) => FirebaseAnalytics.instance);
