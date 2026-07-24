import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  static const _suggestions = [
    'List my current courses',
    'Find my weakest assessment',
    'Summarize my academic year',
    'Prepare an advisor brief',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestion]) async {
    final text = suggestion ?? _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await context.read<AdvisorRepository>().send(text);
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final advisor = context.watch<AdvisorRepository>();
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [LensColors.indigo, LensColors.violet],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic advisor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          _OnlineDot(),
                          SizedBox(width: 6),
                          Text(
                            'Portal-grounded guidance',
                            style: TextStyle(
                              color: LensColors.muted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Reset conversation',
                  onPressed: advisor.messages.isEmpty
                      ? null
                      : () => _confirmReset(context),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: LensColors.line),
          Expanded(
            child: advisor.messages.isEmpty
                ? _AdvisorWelcome(onPrompt: _send)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                    itemCount:
                        advisor.messages.length + (advisor.isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == advisor.messages.length) {
                        return const _ThinkingBubble();
                      }
                      return _MessageBubble(message: advisor.messages[index]);
                    },
                  ),
          ),
          if (advisor.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: LensColors.rose.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 18, color: LensColors.rose),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        advisor.error!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (advisor.messages.isNotEmpty)
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ActionChip(
                  onPressed: advisor.isSending
                      ? null
                      : () => _send(_suggestions[index]),
                  label: Text(
                    _suggestions[index],
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          _Composer(
            controller: _controller,
            isSending: advisor.isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a fresh conversation?'),
        content: const Text(
          'Your portal cache stays available, but the advisor will forget this chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (reset == true && context.mounted) {
      await context.read<AdvisorRepository>().reset();
    }
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: LensColors.aqua,
      ),
    );
  }
}

class _AdvisorWelcome extends StatelessWidget {
  final ValueChanged<String> onPrompt;

  const _AdvisorWelcome({required this.onPrompt});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 32, 22, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [LensColors.indigo, LensColors.violet],
              ),
              borderRadius: BorderRadius.circular(23),
              boxShadow: [
                BoxShadow(
                  color: LensColors.indigo.withValues(alpha: .25),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Ask with context.\nDecide with clarity.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'I can inspect portal grades and your transcript, explain patterns, and turn evidence into a practical next step.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: LensColors.muted,
              ),
        ),
        const SizedBox(height: 28),
        ..._AdvisorScreenState._suggestions.map(
          (suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LensCard(
              onTap: () => onPrompt(suggestion),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.north_east_rounded,
                      color: LensColors.indigo, size: 19),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 330),
          margin: const EdgeInsets.only(left: 44, bottom: 15),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [LensColors.indigo, LensColors.violet],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(21),
              topRight: Radius.circular(21),
              bottomLeft: Radius.circular(21),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Text(
            message.text,
            style: const TextStyle(color: Colors.white, height: 1.4),
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        margin: const EdgeInsets.only(right: 12, bottom: 18),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(23),
            bottomLeft: Radius.circular(23),
            bottomRight: Radius.circular(23),
          ),
          border: Border.all(color: LensColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: message.text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LensColors.ink,
                      fontSize: 14,
                    ),
                h2: Theme.of(context).textTheme.titleLarge,
                h3: Theme.of(context).textTheme.titleMedium,
                listBullet: const TextStyle(color: LensColors.indigo),
                tableBorder: TableBorder.all(color: LensColors.line),
                tableCellsPadding: const EdgeInsets.all(8),
              ),
            ),
            if (message.tools.any((tool) => tool.status == 'error')) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: message.tools
                    .where((tool) => tool.status == 'error')
                    .map(
                      (tool) => GradientPill(
                        label: _friendlyToolName(tool.name),
                        icon: tool.status == 'error'
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (message.sources.isNotEmpty) ...[
              const SizedBox(height: 13),
              Text(
                'Sources · ${message.sources.join(' · ')}',
                style: const TextStyle(
                  color: LensColors.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _friendlyToolName(String name) {
    return name
        .replaceAll('get_', '')
        .replaceAll('list_', '')
        .replaceAll('_', ' ');
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: LensColors.line),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              'Reading your academic picture…',
              style: TextStyle(fontSize: 12, color: LensColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.paddingOf(context).bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: LensColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ask about a course, grade, or plan…',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                suffixIcon: keyboardVisible
                    ? IconButton(
                        tooltip: 'Hide keyboard',
                        onPressed: () =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        icon: const Icon(Icons.keyboard_hide_rounded),
                      )
                    : null,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 9),
          IconButton.filled(
            onPressed: isSending ? null : onSend,
            style: IconButton.styleFrom(
              minimumSize: const Size(50, 50),
            ),
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }
}
