import 'package:flutter/material.dart';

import '../../../models/photo_entry.dart';
import '../../../widgets/photo_montage.dart';

class PhotoMontagePage extends StatelessWidget {
  final List<PhotoEntry> photos;
  final VoidCallback? onAnimationComplete;

  const PhotoMontagePage({
    super.key,
    required this.photos,
    this.onAnimationComplete,
  });

  @override
  Widget build(BuildContext context) {
    return PhotoMontage(
      photos: photos,
      onComplete: onAnimationComplete,
    );
  }
}
