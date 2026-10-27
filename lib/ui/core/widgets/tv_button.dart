import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tv_theme.dart';

typedef TvKeyHandler = KeyEventResult Function(KeyEvent event);

class TvButton extends StatefulWidget {
  const TvButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.focusNode,
    this.autofocus = false,
    this.selected = false,
    this.onKeyEvent,
    this.onFocusChange,
    this.compact = false,
    this.iconOnly = false,
    super.key,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool selected;
  final bool compact;
  final bool iconOnly;
  final TvKeyHandler? onKeyEvent;
  final ValueChanged<bool>? onFocusChange;
  @override
  State<TvButton> createState() => _TvButtonState();
}

class _TvButtonState extends State<TvButton> {
  bool focused = false;
  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.iconOnly ? widget.label : null,
    selected: widget.selected,
    button: true,
    child: Tooltip(
      message: widget.iconOnly ? widget.label : '',
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, event) =>
            widget.onKeyEvent?.call(event) ?? KeyEventResult.ignored,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: focused
                ? context.tvColors.focus
                : widget.selected
                ? context.tvColors.selected
                : context.tvColors.button,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: focused
                  ? context.tvColors.accent
                  : widget.selected
                  ? context.tvColors.accent.withValues(alpha: .4)
                  : context.tvColors.line,
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(10),
              onFocusChange: (value) {
                setState(() => focused = value);
                widget.onFocusChange?.call(value);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.iconOnly
                      ? 12
                      : widget.compact
                      ? 12
                      : 16,
                  vertical: TvSpacing.medium,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: widget.iconOnly
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: widget.iconOnly ? 24 : 20,
                        color: focused
                            ? context.tvColors.onFocus
                            : context.tvColors.accent,
                      ),
                      if (!widget.iconOnly) const SizedBox(width: 10),
                    ],
                    if (!widget.iconOnly)
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: focused
                                ? context.tvColors.onFocus
                                : context.tvColors.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

bool isDirectionEvent(KeyEvent event) =>
    event is KeyDownEvent || event is KeyRepeatEvent;
