import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<XFile?> pickPhoto() async {
    return _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
  }

  Future<XFile?> pickFromGallery() async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
  }

  Future<String> uploadCompletionPhoto({
    required String completionId,
    required File file,
  }) async {
    final ref = _storage.ref('users/$_uid/completions/$completionId.jpg');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<String> uploadAvatar(File file) async {
    final ref = _storage.ref('users/$_uid/avatar.jpg');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<String> uploadVoiceNote({
    required String noteId,
    required File file,
  }) async {
    final ref = _storage.ref('users/$_uid/voiceNotes/$noteId.m4a');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'audio/mp4'),
    );
    return ref.getDownloadURL();
  }
}
