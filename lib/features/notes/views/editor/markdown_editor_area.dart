import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

enum MarkdownLayout { tabs, split }

class MarkdownEditorArea extends StatefulWidget {
  const MarkdownEditorArea({
    super.key,
    required this.controller,
    required this.layout,
  });

  final TextEditingController controller;
  final MarkdownLayout layout;

  @override
  State<MarkdownEditorArea> createState() => _MarkdownEditorAreaState();
}

class _MarkdownEditorAreaState extends State<MarkdownEditorArea> {
  final _markdownScrollController = ScrollController();
  final _previewScrollController = ScrollController();
  bool _markdownRenderErrorShown = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onMarkdownChanged);
    _markdownScrollController.addListener(_syncPreviewScroll);
  }

  @override
  void didUpdateWidget(covariant MarkdownEditorArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onMarkdownChanged);
      widget.controller.addListener(_onMarkdownChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onMarkdownChanged);
    _markdownScrollController
      ..removeListener(_syncPreviewScroll)
      ..dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = _looksArabic(widget.controller.text);
    final direction = isRtl ? TextDirection.rtl : TextDirection.ltr;

    if (widget.layout == MarkdownLayout.tabs) {
      return DefaultTabController(
        length: 2,
        child: Directionality(
          textDirection: direction,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    TabBar(
                      tabs: [
                        Tab(text: 'Edit'),
                        Tab(text: 'Preview'),
                      ],
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _buildMarkdownEditor(theme, null),
                _buildMarkdownPreview(theme, null),
              ],
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: direction,
      child: Row(
        children: [
          Expanded(
            child: _buildMarkdownEditor(
              theme,
              _markdownScrollController,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMarkdownPreview(
              theme,
              _previewScrollController,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownEditor(
    ThemeData theme,
    ScrollController? controller,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: widget.controller,
          scrollController: controller,
          maxLines: null,
          expands: true,
          keyboardType: TextInputType.multiline,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Write markdown here...',
            isCollapsed: true,
          ),
        ),
      ),
    );
  }

  Widget _buildMarkdownPreview(
    ThemeData theme,
    ScrollController? controller,
  ) {
    try {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        child: Markdown(
          data: widget.controller.text,
          controller: controller,
          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
            p: theme.textTheme.bodyMedium,
          ),
        ),
      );
    } catch (error, stack) {
      _showMarkdownErrorSnackBar(context, error);
      // Still log the full error for debugging.
      // ignore: avoid_print
      print('Markdown render error: $error\n$stack');
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        child: SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(12),
          child: Text(
            widget.controller.text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }
  }

  void _showMarkdownErrorSnackBar(BuildContext context, Object error) {
    if (_markdownRenderErrorShown || !mounted) return;
    _markdownRenderErrorShown = true;

    final message = error.toString().toLowerCase();
    String hint =
        'Try simplifying or removing the most recent markdown (especially complex tables, images, or links).';
    if (message.contains('image')) {
      hint = 'Check your image syntax and that image URLs/paths are valid.';
    } else if (message.contains('link') || message.contains('href')) {
      hint = 'Check that your link syntax is valid, e.g. [label](https://example.com).';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'There was a problem rendering the markdown preview.\nHint: $hint',
        ),
      ),
    );
  }

  void _syncPreviewScroll() {
    if (widget.layout != MarkdownLayout.split) return;
    if (!_markdownScrollController.hasClients ||
        !_previewScrollController.hasClients) {
      return;
    }
    try {
      final source = _markdownScrollController.position;
      final target = _previewScrollController.position;
      if (!source.hasContentDimensions || !target.hasContentDimensions) {
        return;
      }
      if (source.maxScrollExtent <= 0 || target.maxScrollExtent <= 0) {
        return;
      }
      final ratio = source.pixels / source.maxScrollExtent;
      final desired = ratio * target.maxScrollExtent;
      if ((target.pixels - desired).abs() > 1) {
        _previewScrollController.jumpTo(
          desired.clamp(0, target.maxScrollExtent),
        );
      }
    } catch (_) {
      // Ignore scroll sync errors.
    }
  }

  bool _looksArabic(String s) {
    for (final code in s.runes) {
      final isArabic =
          (code >= 0x0600 && code <= 0x06FF) ||
          (code >= 0x0750 && code <= 0x077F) ||
          (code >= 0x08A0 && code <= 0x08FF) ||
          (code >= 0xFB50 && code <= 0xFDFF) ||
          (code >= 0xFE70 && code <= 0xFEFF);
      if (isArabic) return true;
    }
    return false;
  }

  void _onMarkdownChanged() {
    if (!mounted) return;
    setState(() {});
  }
}

