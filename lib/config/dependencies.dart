import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';
import '../ui/auth/view_models/session_view_model.dart';

/// Everything the app reads from `context`, above `MaterialApp` so pushed
/// routes see it too. Tests pass fakes for [auth] and [db].
List<SingleChildWidget> providers(FirebaseAuth auth, FirebaseFirestore db) => [
  Provider(create: (_) => AuthRepository(auth)),
  Provider(create: (_) => UserRepository(db)),
  ChangeNotifierProvider(
    create: (context) => SessionViewModel(
      context.read<AuthRepository>(),
      context.read<UserRepository>(),
    ),
  ),
];
