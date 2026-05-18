import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/photo_entry.dart';

/// A full-screen, fast-cut photo montage that plays through photos with
/// dramatic TikTok/Reels-style transitions: slide+fade+scale in, Ken Burns
/// hold, quick fade out, and a camera-flash between cuts.
class PhotoMontage extends StatefulWidget {
  final List<PhotoEntry> photos;
  final VoidCallback? onComplete;

  const PhotoMontage({
    super.key,
    required this.photos,
    this.onComplete,
  });

  @override
  State<PhotoMontage> createState() => _PhotoMontageState();
}

class _PhotoMontageState extends State<PhotoMontage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _random = Random();
  bool _imagesReady = false;

  // Pre-computed random slide direction per photo (0=left,1=right,2=top,3=bottom).
  late final List<int> _slideDirections;

  static const _photoDurationMs = 800;

  @override
  void initState() {
    super.initState();

    _slideDirections = List.generate(
      widget.photos.length,
      (_) => _random.nextInt(4),
    );

    final totalMs = widget.photos.length * _photoDurationMs;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _preloadImages();
  }

  Future<void> _preloadImages() async {
    // Resolve all image providers so first frames are cached.
    final futures = <Future>[];
    for (final photo in widget.photos) {
      final file = File(photo.localPath);
      if (file.existsSync()) {
        futures.add(
          precacheImage(FileImage(file), context),
        );
      } else if (photo.remotePath != null) {
        futures.add(
          precacheImage(
            CachedNetworkImageProvider(photo.remotePath!),
            context,
          ),
        );
      }
    }
    await Future.wait(futures);
    if (!mounted) return;
    setState(() => _imagesReady = true);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────

  Offset _slideOffset(int direction, double amount) {
    switch (direction) {
      case 0:
        return Offset(-amount, 0);
      case 1:
        return Offset(amount, 0);
      case 2:
        return Offset(0, -amount);
      case 3:
        return Offset(0, amount);
      default:
        return Offset(-amount, 0);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  // ── build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_imagesReady) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white24),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final totalPhotos = widget.photos.length;
        final progress = _controller.value * totalPhotos; // 0..totalPhotos
        final index = progress.floor().clamp(0, totalPhotos - 1);
        final local = progress - index; // 0..1 within current photo

        final photo = widget.photos[index];
        final dir = _slideDirections[index];

        // ── phase boundaries (normalised 0-1 within 800ms) ──
        const enterEnd = 0.25; // 200/800
        const holdEnd = 0.75; // 600/800
        // exit: 0.75 -> 1.0

        // ── photo opacity ──
        double photoOpacity;
        if (local < enterEnd) {
          photoOpacity = (local / enterEnd).clamp(0.0, 1.0);
        } else if (local < holdEnd) {
          photoOpacity = 1.0;
        } else {
          photoOpacity = (1.0 - (local - holdEnd) / (1.0 - holdEnd))
              .clamp(0.0, 1.0);
        }

        // ── photo scale ──
        double photoScale;
        if (local < enterEnd) {
          // 1.1 -> 1.0
          photoScale = 1.1 - 0.1 * (local / enterEnd);
        } else if (local < holdEnd) {
          // Ken Burns: 1.0 -> 1.03
          final holdT = (local - enterEnd) / (holdEnd - enterEnd);
          photoScale = 1.0 + 0.03 * holdT;
        } else {
          photoScale = 1.03;
        }

        // ── photo translate ──
        Offset photoOffset;
        if (local < enterEnd) {
          final t = local / enterEnd;
          final slide = _slideOffset(dir, 0.05);
          photoOffset = Offset(
            slide.dx * (1.0 - t),
            slide.dy * (1.0 - t),
          );
        } else if (local < holdEnd) {
          // subtle drift during hold
          final holdT = (local - enterEnd) / (holdEnd - enterEnd);
          photoOffset = Offset(0.005 * holdT, 0.005 * holdT);
        } else {
          photoOffset = const Offset(0.005, 0.005);
        }

        // ── info pill (appears 100ms after enter = local 0.125) ──
        const pillAppear = 0.125; // 100/800
        const pillFadeDur = 0.125;
        double pillOpacity;
        double pillSlide;
        if (local < pillAppear) {
          pillOpacity = 0;
          pillSlide = 8;
        } else if (local < pillAppear + pillFadeDur) {
          final t = (local - pillAppear) / pillFadeDur;
          pillOpacity = t.clamp(0.0, 1.0);
          pillSlide = 8 * (1.0 - t);
        } else if (local < holdEnd) {
          pillOpacity = 1;
          pillSlide = 0;
        } else {
          pillOpacity = photoOpacity;
          pillSlide = 0;
        }

        // ── flash overlay (150ms centred on cut point) ──
        // Flash peaks at local ≈ 0 (start of each photo = cut point).
        // 150ms = 0.1875 of 800ms. We use half-window = 0.09375.
        const flashHalf = 0.09375;
        double flashOpacity = 0;
        if (local < flashHalf) {
          // fade out from 0.08
          flashOpacity = 0.08 * (1.0 - local / flashHalf);
        }
        // also handle the tail end of the previous photo's flash:
        if (local > 1.0 - flashHalf) {
          flashOpacity =
              0.08 * ((local - (1.0 - flashHalf)) / flashHalf);
        }

        // ── image provider ──
        final file = File(photo.localPath);
        final imageWidget = file.existsSync()
            ? Image.file(
                file,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            : (photo.remotePath != null
                ? CachedNetworkImage(
                    imageUrl: photo.remotePath!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : const SizedBox.shrink());

        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── photo layer ──
              Opacity(
                opacity: photoOpacity,
                child: Transform(
                  alignment: Alignment.center,
                  // ignore: deprecated_member_use
                  transform: Matrix4.identity()
                    ..translate(
                      photoOffset.dx *
                          MediaQuery.of(context).size.width,
                      photoOffset.dy *
                          MediaQuery.of(context).size.height,
                    )
                    // ignore: deprecated_member_use
                    ..scale(photoScale),
                  child: imageWidget,
                ),
              ),

              // ── vignette ──
              IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        Colors.transparent,
                        Color(0x99000000), // black 60%
                      ],
                      stops: [0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // ── flash ──
              if (flashOpacity > 0)
                IgnorePointer(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: flashOpacity),
                  ),
                ),

              // ── info pill ──
              Positioned(
                bottom: 48 + MediaQuery.of(context).padding.bottom,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: pillOpacity.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, pillSlide),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${photo.habitName}  ·  ${_formatDate(photo.date)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
