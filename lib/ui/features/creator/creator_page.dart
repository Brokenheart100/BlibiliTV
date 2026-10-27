import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/images/tv_image_cache.dart';

import '../../../domain/entities/app_models.dart';
import '../../core/widgets/tv_button.dart';
import '../../core/widgets/tv_grid.dart';
import '../catalog/views/catalog_page.dart';

class CreatorPage extends ConsumerStatefulWidget {
  const CreatorPage({required this.mid, this.name, this.avatar, super.key});
  final int mid;
  final String? name;
  final String? avatar;
  @override
  ConsumerState<CreatorPage> createState() => _CreatorPageState();
}

class _CreatorPageState extends ConsumerState<CreatorPage> {
  final back = FocusNode();
  final grid = TvGridController();
  var order = VideoOrder.newest;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                TvButton(
                  label: '返回',
                  key: const Key('creator-back'),
                  focusNode: back,
                  autofocus: true,
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 16),
                TvButton(
                  label: order == VideoOrder.newest
                      ? '最新投稿 · 切换排序'
                      : '最多播放 · 切换排序',
                  key: const Key('creator-sort'),
                  onPressed: () => setState(
                    () => order = order == VideoOrder.newest
                        ? VideoOrder.mostViewed
                        : VideoOrder.newest,
                  ),
                ),
              ],
            ),
          ),
          if (widget.avatar != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: widget.avatar!,
                  cacheManager: TvImageCache.manager,
                  width: 48,
                  height: 48,
                  memCacheWidth: 96,
                  memCacheHeight: 96,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const Icon(Icons.person, size: 48),
                ),
              ),
            ),
          Expanded(
            child: CatalogPage(
              section: 'creator',
              pageId: 'creator-${widget.mid}',
              branchIndex: 0,
              registerEntry: false,
              controller: grid,
              onTop: back.requestFocus,
              title: widget.name == null ? 'UP 主视频' : '${widget.name}的视频',
              subtitle: '公开投稿',
              options: CatalogOptions(creatorId: widget.mid, order: order),
            ),
          ),
        ],
      ),
    ),
  );
  @override
  void dispose() {
    back.dispose();
    super.dispose();
  }
}
