import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/app_models.dart';
import '../theme/tv_theme.dart';
import '../images/tv_image_cache.dart';
import 'tv_button.dart';

class TvArtwork extends StatelessWidget {
  const TvArtwork({required this.video, super.key});
  final VideoSummary video;
  @override
  Widget build(BuildContext context) {
    const palettes = [
      Color(0xFF277F91),
      Color(0xFFAA754B),
      Color(0xFF536CA2),
      Color(0xFF4B8976),
      Color(0xFF77589F),
      Color(0xFF9C6675),
      Color(0xFF777254),
      Color(0xFF477A9B),
    ];
    const icons = [
      Icons.landscape_outlined,
      Icons.ramen_dining,
      Icons.apartment,
      Icons.code,
      Icons.nights_stay_outlined,
      Icons.camera_alt_outlined,
      Icons.menu_book,
      Icons.museum_outlined,
    ];
    final index = int.tryParse(video.id.split('-').last) ?? 0;
    final color = palettes[index % palettes.length];
    final artwork = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, const Color(0xFF101D2C), .72)!],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -25,
            top: -45,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -70,
            child: Container(
              width: 190,
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Colors.white.withValues(alpha: .06),
              ),
            ),
          ),
          Center(
            child: Icon(
              icons[index % icons.length],
              size: 58,
              color: Colors.white.withValues(alpha: .8),
            ),
          ),
        ],
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (video.coverUrl case final String url when url.isNotEmpty)
            CachedNetworkImage(
              imageUrl: url,
              cacheManager: TvImageCache.manager,
              memCacheWidth: 640,
              memCacheHeight: 360,
              maxWidthDiskCache: 640,
              maxHeightDiskCache: 360,
              fit: BoxFit.cover,
              placeholder: (_, _) => artwork,
              errorWidget: (_, _, _) => artwork,
            )
          else
            artwork,
          if (video.id.startsWith('demo-'))
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .24),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('演示', style: TextStyle(fontSize: 10)),
              ),
            ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${video.durationSeconds ~/ 60}:${(video.durationSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TvVideoCard extends StatefulWidget {
  const TvVideoCard({
    required this.video,
    required this.onPressed,
    required this.onFocus,
    required this.onKey,
    required this.onAttach,
    required this.onDetach,
    this.reducedMotion = false,
    super.key,
  });
  final VideoSummary video;
  final VoidCallback onPressed, onFocus;
  final TvKeyHandler onKey;
  final ValueChanged<FocusNode> onAttach, onDetach;
  final bool reducedMotion;
  @override
  State<TvVideoCard> createState() => _TvVideoCardState();
}

class _TvVideoCardState extends State<TvVideoCard> {
  late final node = FocusNode(debugLabel: 'video-${widget.video.id}');
  bool focused = false;
  @override
  void initState() {
    super.initState();
    widget.onAttach(node);
  }

  @override
  void dispose() {
    widget.onDetach(node);
    node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: (_, event) => widget.onKey(event),
    child: AnimatedScale(
      scale: focused && !widget.reducedMotion ? 1.015 : 1,
      duration: Duration(milliseconds: widget.reducedMotion ? 0 : 100),
      child: AnimatedContainer(
        duration: Duration(milliseconds: widget.reducedMotion ? 0 : 100),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: focused
              ? Colors.white.withValues(alpha: .12)
              : Colors.white.withValues(alpha: .035),
          border: Border.all(
            color: focused ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            focusNode: node,
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(10),
            onFocusChange: (value) {
              setState(() => focused = value);
              if (value) widget.onFocus();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: TvArtwork(video: widget.video)),
                const SizedBox(height: 9),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    widget.video.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: focused ? TvColors.accent : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    '${widget.video.creator}  ·  ${(widget.video.viewCount / 10000).toStringAsFixed(1)}万次观看',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: TvColors.muted),
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
