import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';

import '../images/tv_image_cache.dart';
import '../theme/tv_theme.dart';

/// Public creator image. Missing or failed images retain the same row geometry.
class CreatorAvatar extends StatelessWidget {
  const CreatorAvatar({
    required this.name,
    this.url,
    this.size = 22,
    super.key,
  });
  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: context.tvColors.accent.withValues(alpha: .13),
      child: Icon(
        CupertinoIcons.person_fill,
        size: size * .65,
        color: context.tvColors.muted,
      ),
    );
    return Semantics(
      label: '$name 的头像',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: url == null || url!.isEmpty
              ? fallback
              : CachedNetworkImage(
                  imageUrl: url!,
                  cacheManager: TvImageCache.manager,
                  memCacheWidth: 96,
                  memCacheHeight: 96,
                  maxWidthDiskCache: 96,
                  maxHeightDiskCache: 96,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => fallback,
                  errorWidget: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}
