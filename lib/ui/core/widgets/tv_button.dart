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
    super.key,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool selected;
  final bool compact;
  final TvKeyHandler? onKeyEvent;
  final ValueChanged<bool>? onFocusChange;
  @override
  State<TvButton> createState() => _TvButtonState();
}

class _TvButtonState extends State<TvButton> {
  bool focused = false;
  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: (_, event) =>
        widget.onKeyEvent?.call(event) ?? KeyEventResult.ignored,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: focused
            ? Colors.white
            : widget.selected
            ? const Color(0xFF38445F)
            : const Color(0x16FFFFFF),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: focused
              ? Colors.white
              : widget.selected
              ? TvColors.accent.withValues(alpha: .4)
              : TvColors.line,
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
              horizontal: widget.compact ? 12 : 16,
              vertical: TvSpacing.medium,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 20,
                    color: focused ? TvColors.background : TvColors.accent,
                  ),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: focused ? TvColors.background : Colors.white,
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
  );
}

bool isDirectionEvent(KeyEvent event) =>
    event is KeyDownEvent || event is KeyRepeatEvent;
