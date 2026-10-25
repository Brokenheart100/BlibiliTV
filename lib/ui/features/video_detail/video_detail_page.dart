import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../domain/entities/app_models.dart';
import '../../../core/result.dart';
import '../../core/images/tv_image_cache.dart';
import '../../core/theme/tv_theme.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/tv_button.dart';
import '../../core/widgets/tv_state_panel.dart';
import '../../core/widgets/tv_video_card.dart';
import 'view_models/video_detail_view_model.dart';
import '../library/views/personal_actions_dialog.dart';

class VideoDetailPage extends ConsumerStatefulWidget {
  const VideoDetailPage({required this.id, required this.pageId, super.key});
  final String id, pageId;
  @override
  ConsumerState<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends ConsumerState<VideoDetailPage> {
  final back = FocusNode(debugLabel: 'detail-back');
  final play = FocusNode(debugLabel: 'detail-play');
  final personal = FocusNode(debugLabel: 'detail-personal');
  final descriptionFocus = FocusNode(debugLabel: 'detail-description');
  final relatedRetry = FocusNode(debugLabel: 'related-retry');
  final partsScroll = ScrollController();
  final relatedScroll = ScrollController();
  final partNodes = <String, FocusNode>{};
  final relatedNodes = <String, FocusNode>{};
  List<VideoPart> parts = [];
  List<VideoSummary> related = [];
  bool focusedOnce = false, expanded = false;
  String get owner => ref.read(sessionProvider).value?.ownerKey ?? 'guest';
  VideoDetailViewModelProvider get provider => videoDetailViewModelProvider(
    id: widget.id,
    pageId: widget.pageId,
    ownerKey: owner,
  );
  @override
  void dispose() {
    back.dispose();
    play.dispose();
    personal.dispose();
    descriptionFocus.dispose();
    relatedRetry.dispose();
    partsScroll.dispose();
    relatedScroll.dispose();
    for (final node in partNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _showNode(FocusNode node) {
    if (node.context != null) {
      node.requestFocus();
      unawaited(Scrollable.ensureVisible(node.context!, alignment: .45));
    }
  }

  Future<void> _play(String partId, {FocusNode? returnFocus}) async {
    final scoped = provider;
    await context.push<void>('/player/${widget.id}?part=$partId');
    if (!mounted) return;
    ref.invalidate(scoped);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showNode(returnFocus ?? play);
    });
  }

  Future<void> _focusPart(int index) async {
    if (parts.isEmpty) return;
    final safe = index.clamp(0, parts.length - 1);
    if (partsScroll.hasClients) {
      partsScroll.jumpTo(
        (safe * 232.0).clamp(0, partsScroll.position.maxScrollExtent),
      );
    }
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) {
      final node = partNodes[parts[safe].id];
      if (node != null) _showNode(node);
    }
  }

  Future<void> _focusRelated(int index) async {
    if (related.isEmpty) {
      _showNode(relatedRetry.context != null ? relatedRetry : play);
      return;
    }
    final safe = index.clamp(0, related.length - 1);
    if (relatedScroll.hasClients) {
      relatedScroll.jumpTo(
        (safe * 258.0).clamp(0, relatedScroll.position.maxScrollExtent),
      );
    }
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) {
      final node = relatedNodes[related[safe].id];
      if (node != null) _showNode(node);
    }
  }

  KeyEventResult _partKey(int index, KeyEvent event) {
    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        unawaited(_focusPart(index + 1));
      case LogicalKeyboardKey.arrowLeft:
        if (index == 0) {
          _showNode(play);
        } else {
          unawaited(_focusPart(index - 1));
        }
      case LogicalKeyboardKey.arrowUp:
        _showNode(play);
      case LogicalKeyboardKey.arrowDown:
        unawaited(_focusRelated(0));
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _personal() async {
    final previous = FocusManager.instance.primaryFocus;
    if (ref.read(sessionProvider).value?.isAuthenticated != true) {
      await context.push<void>('/login?returnTo=%2Fvideo%2F${widget.id}');
      if (mounted) personal.requestFocus();
      return;
    }
    await showDialog<void>(
      context: context,
      requestFocus: true,
      traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
      builder: (_) =>
          PersonalActionsDialog(videoId: widget.id, ownerKey: owner),
    );
    if (mounted && previous?.context != null) previous!.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionProvider.select((s) => s.value?.scopeKey));
    final detailProvider = provider;
    final result = ref.watch(detailProvider);
    ref.listen(detailProvider, (_, next) {
      if (!focusedOnce && next.hasValue) {
        focusedOnce = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showNode(play);
        });
      }
    });
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TvButton(
                    key: const Key('detail-back'),
                    label: '返回',
                    focusNode: back,
                    autofocus: true,
                    icon: CupertinoIcons.chevron_left,
                    onPressed: _back,
                    onKeyEvent: (e) {
                      if (isDirectionEvent(e) &&
                          e.logicalKey == LogicalKeyboardKey.arrowDown &&
                          result.hasValue) {
                        _showNode(play);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                  ),
                  const Spacer(),
                  Text(
                    widget.id.startsWith('demo-') ? '演示内容' : 'BILIBILI · 视频详情',
                    style: const TextStyle(color: TvColors.muted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: result.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => TvStatePanel(
                    title: '内容暂不可用',
                    message: error is AppFailure
                        ? error.message
                        : '可以重新加载，或返回继续浏览。',
                    actionLabel: '重试',
                    onAction: () => ref.invalidate(detailProvider),
                  ),
                  data: (state) {
                    final detail = state.detail;
                    parts = detail.parts;
                    final resume = state.resume;
                    final selected = resume == null
                        ? 0
                        : parts.indexWhere((p) => p.id == resume.partId);
                    final minutes = resume == null
                        ? ''
                        : '${resume.position.inMinutes}:${(resume.position.inSeconds % 60).toString().padLeft(2, '0')}';
                    final playLabel = resume == null
                        ? '立即播放'
                        : '继续播放 · P${selected + 1} $minutes';
                    final description = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.video.title,
                          key: const Key('detail-title'),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ClipOval(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: detail.creatorAvatarUrl == null
                                    ? const Icon(
                                        CupertinoIcons.person_crop_circle,
                                        color: TvColors.accent,
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: detail.creatorAvatarUrl!,
                                        cacheManager: TvImageCache.manager,
                                        memCacheWidth: 96,
                                        memCacheHeight: 96,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, _, _) => const Icon(
                                          CupertinoIcons.person_crop_circle,
                                          color: TvColors.accent,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'UP · ${detail.video.creator}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: TvColors.accent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${detail.video.viewCount} 次观看 · ${parts.length} 个分集',
                          style: const TextStyle(
                            fontSize: 11,
                            color: TvColors.muted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            TvButton(
                              key: const Key('detail-play'),
                              label: playLabel,
                              focusNode: play,
                              icon: CupertinoIcons.play_fill,
                              onPressed: () => unawaited(
                                _play(resume?.partId ?? parts.first.id),
                              ),
                              onFocusChange: (focus) {
                                if (focus && play.context != null) {
                                  unawaited(
                                    Scrollable.ensureVisible(
                                      play.context!,
                                      alignment: .4,
                                    ),
                                  );
                                }
                              },
                              onKeyEvent: (e) {
                                if (!isDirectionEvent(e)) {
                                  return KeyEventResult.ignored;
                                }
                                if (e.logicalKey ==
                                    LogicalKeyboardKey.arrowDown) {
                                  unawaited(
                                    _focusPart(
                                      selected.clamp(0, parts.length - 1),
                                    ),
                                  );
                                } else if (e.logicalKey ==
                                        LogicalKeyboardKey.arrowUp ||
                                    e.logicalKey ==
                                        LogicalKeyboardKey.arrowLeft) {
                                  _showNode(back);
                                } else if (e.logicalKey ==
                                    LogicalKeyboardKey.arrowRight) {
                                  _showNode(personal);
                                } else {
                                  return KeyEventResult.ignored;
                                }
                                return KeyEventResult.handled;
                              },
                            ),
                            TvButton(
                              key: const Key('detail-personal'),
                              label: '收藏与稍后再看',
                              compact: true,
                              focusNode: personal,
                              onPressed: () => unawaited(_personal()),
                              onKeyEvent: (e) {
                                if (!isDirectionEvent(e)) {
                                  return KeyEventResult.ignored;
                                }
                                if (e.logicalKey ==
                                    LogicalKeyboardKey.arrowDown) {
                                  if (descriptionFocus.context != null) {
                                    _showNode(descriptionFocus);
                                  } else {
                                    unawaited(_focusPart(0));
                                  }
                                  return KeyEventResult.handled;
                                }
                                if (e.logicalKey ==
                                    LogicalKeyboardKey.arrowLeft) {
                                  _showNode(play);
                                  return KeyEventResult.handled;
                                }
                                return KeyEventResult.ignored;
                              },
                            ),
                          ],
                        ),
                        if (state.notice != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              state.notice!,
                              style: const TextStyle(
                                color: TvColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    );
                    return SingleChildScrollView(
                      key: const Key('detail-scroll'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final artwork = AspectRatio(
                                aspectRatio: 16 / 9,
                                child: TvArtwork(video: detail.video),
                              );
                              if (constraints.maxWidth < 700) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(width: 300, child: artwork),
                                    const SizedBox(height: 18),
                                    description,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 5, child: artwork),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 6, child: description),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          GlassPanel(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detail.description.isEmpty
                                      ? 'UP 主还没有填写简介'
                                      : detail.description,
                                  maxLines: expanded ? null : 3,
                                  overflow: expanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.6,
                                    color: TvColors.muted,
                                  ),
                                ),
                                if (detail.description.length > 100)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: TvButton(
                                      key: const Key(
                                        'detail-description-toggle',
                                      ),
                                      label: expanded ? '收起简介' : '展开简介',
                                      focusNode: descriptionFocus,
                                      onFocusChange: (focus) {
                                        if (focus) _showNode(descriptionFocus);
                                      },
                                      onKeyEvent: (e) {
                                        if (!isDirectionEvent(e)) {
                                          return KeyEventResult.ignored;
                                        }
                                        if (e.logicalKey ==
                                            LogicalKeyboardKey.arrowDown) {
                                          unawaited(_focusPart(0));
                                          return KeyEventResult.handled;
                                        }
                                        if (e.logicalKey ==
                                            LogicalKeyboardKey.arrowUp) {
                                          _showNode(personal);
                                          return KeyEventResult.handled;
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      compact: true,
                                      onPressed: () =>
                                          setState(() => expanded = !expanded),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '选集 · ${parts.length}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 72,
                            child: ListView.separated(
                              controller: partsScroll,
                              scrollDirection: Axis.horizontal,
                              itemCount: parts.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, index) {
                                final part = parts[index];
                                final node = partNodes.putIfAbsent(
                                  part.id,
                                  () => FocusNode(
                                    debugLabel: 'detail-part-${part.id}',
                                  ),
                                );
                                return SizedBox(
                                  width: 220,
                                  child: TvButton(
                                    key: ValueKey('detail-part-${part.id}'),
                                    focusNode: node,
                                    selected: resume?.partId == part.id,
                                    label: 'P${index + 1} · ${part.title}',
                                    onKeyEvent: (e) => _partKey(index, e),
                                    onPressed: () => unawaited(
                                      _play(part.id, returnFocus: node),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '接着发现',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          _relatedSection(),
                          const SizedBox(height: 18),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _relatedSection() {
    final relatedProvider = relatedVideosProvider(
      id: widget.id,
      pageId: widget.pageId,
      ownerKey: owner,
    );
    return Consumer(
      builder: (context, ref, _) => ref
          .watch(relatedProvider)
          .when(
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => Row(
              children: [
                const Expanded(
                  child: Text(
                    '相关视频暂不可用，仍可播放当前视频',
                    style: TextStyle(color: TvColors.muted),
                  ),
                ),
                TvButton(
                  key: const Key('related-retry'),
                  focusNode: relatedRetry,
                  onKeyEvent: (e) {
                    if (isDirectionEvent(e) &&
                        e.logicalKey == LogicalKeyboardKey.arrowUp) {
                      unawaited(_focusPart(0));
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  label: '重试',
                  compact: true,
                  onPressed: () => ref.invalidate(relatedProvider),
                ),
              ],
            ),
            data: (items) {
              related = items;
              if (items.isEmpty) {
                return const Text(
                  '暂时没有相关视频',
                  style: TextStyle(color: TvColors.muted),
                );
              }
              return SizedBox(
                height: 218,
                child: ListView.separated(
                  controller: relatedScroll,
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    final video = items[index];
                    return SizedBox(
                      width: 246,
                      child: TvVideoCard(
                        key: ValueKey('related-${video.id}'),
                        video: video,
                        reducedMotion: false,
                        onAttach: (node) => relatedNodes[video.id] = node,
                        onDetach: (node) {
                          if (relatedNodes[video.id] == node) {
                            relatedNodes.remove(video.id);
                          }
                        },
                        onFocus: () {
                          final node = relatedNodes[video.id];
                          if (node?.context != null) {
                            unawaited(
                              Scrollable.ensureVisible(
                                node!.context!,
                                alignment: .5,
                              ),
                            );
                          }
                        },
                        onKey: (e) {
                          if (!isDirectionEvent(e)) {
                            return KeyEventResult.ignored;
                          }
                          if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
                            unawaited(_focusRelated(index + 1));
                          } else if (e.logicalKey ==
                              LogicalKeyboardKey.arrowLeft) {
                            if (index == 0) {
                              unawaited(_focusPart(0));
                            } else {
                              unawaited(_focusRelated(index - 1));
                            }
                          } else if (e.logicalKey ==
                              LogicalKeyboardKey.arrowUp) {
                            unawaited(_focusPart(0));
                          } else {
                            return KeyEventResult.ignored;
                          }
                          return KeyEventResult.handled;
                        },
                        onPressed: () => unawaited(() async {
                          await context.push<void>('/video/${video.id}');
                          if (mounted) await _focusRelated(index);
                        }()),
                      ),
                    );
                  },
                ),
              );
            },
          ),
    );
  }
}
