import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../core/widgets/tv_button.dart';
import '../view_models/library_view_model.dart';

class PersonalActionsDialog extends ConsumerWidget {
  const PersonalActionsDialog({
    required this.videoId,
    required this.ownerKey,
    super.key,
  });
  final String videoId, ownerKey;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    if (session?.isAuthenticated != true || session?.ownerKey != ownerKey) {
      return AlertDialog(
        title: const Text('账号状态已变化'),
        content: const Text('请关闭弹层后重新打开。'),
        actions: [
          TvButton(
            label: '返回',
            autofocus: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    }
    final provider = personalActionsViewModelProvider(
      videoId: videoId,
      ownerKey: ownerKey,
    );
    final value = ref.watch(provider);
    return AlertDialog(
      title: const Text('收藏与稍后再看'),
      content: SizedBox(
        width: 540,
        height: (MediaQuery.sizeOf(context).height - 200).clamp(120, 350),
        child: value.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('账号列表暂不可用，请稍后重试'),
              TvButton(
                label: '重试',
                autofocus: true,
                onPressed: () => ref.invalidate(provider),
              ),
            ],
          ),
          data: (state) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      state.message!,
                      key: const Key('personal-message'),
                    ),
                  ),
                TvButton(
                  key: const Key('personal-later'),
                  autofocus: true,
                  label: state.busy
                      ? '正在确认…'
                      : state.membership!.watchLater
                      ? '移出稍后再看'
                      : '加入稍后再看',
                  onPressed: () {
                    if (!state.busy && !state.pending) {
                      unawaited(
                        ref
                            .read(provider.notifier)
                            .change(desired: !state.membership!.watchLater),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (state.membership!.folders.isEmpty)
                  const Text('还没有收藏夹，请先在 B 站创建收藏夹'),
                for (final folder in state.membership!.folders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Builder(
                      builder: (folderContext) => TvButton(
                        key: ValueKey('personal-folder-${folder.id}'),
                        label: '${folder.selected ? '✓ ' : ''}${folder.title}',
                        onFocusChange: (focused) {
                          if (focused) {
                            unawaited(
                              Scrollable.ensureVisible(
                                folderContext,
                                alignment: .5,
                              ),
                            );
                          }
                        },
                        onPressed: () {
                          if (!state.busy && !state.pending) {
                            unawaited(
                              ref
                                  .read(provider.notifier)
                                  .change(
                                    folderId: folder.id,
                                    desired: !folder.selected,
                                  ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                TvButton(
                  key: const Key('personal-recheck'),
                  label: state.pending ? '仅检查上次结果' : '刷新状态',
                  onPressed: () {
                    if (!state.busy) {
                      unawaited(ref.read(provider.notifier).recheck());
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [TvButton(label: '返回', onPressed: () => Navigator.pop(context))],
    );
  }
}
