import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firestore_providers.g.dart';

/// The Firestore instance every repository reads and writes (ADR 0009).
///
/// A provider rather than `FirebaseFirestore.instance` at each call site, so a test
/// overrides it with `FakeFirebaseFirestore` and never reaches a platform channel.
@Riverpod(keepAlive: true)
FirebaseFirestore firestore(FirestoreRef ref) => FirebaseFirestore.instance;

/// The signed-in Firebase user's uid, read at call time.
///
/// A function, not a value: the user signs in and out while the repositories live, and
/// a uid captured at construction would write one donor's profile into another's
/// document. The Security Rules would refuse that write — this makes it unaskable.
@Riverpod(keepAlive: true)
String? Function() currentUid(CurrentUidRef ref) =>
    () => FirebaseAuth.instance.currentUser?.uid;
