import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_theme.dart';

class FinanceBotSheet extends ConsumerStatefulWidget {
  const FinanceBotSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FinanceBotSheet(),
    );
  }

  @override
  ConsumerState<FinanceBotSheet> createState() => _FinanceBotSheetState();
}

class _FinanceBotSheetState extends ConsumerState<FinanceBotSheet> {
  final _focusNode = FocusNode();
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      role: 'bot',
      text: '¡Hola! Soy FinanceBot 🤖. ¿Qué necesitas saber sobre las finanzas familiares hoy?',
    ),
  ];
  bool _isLoading = false;

  @override
  void dispose() {
    _focusNode.dispose();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: text));
      _isLoading = true;
    });
    _ctrl.clear();
    _scrollToBottom();

    final familiaId = ref.read(familiaIdProvider);
    if (familiaId == null) return;

    final reply = await ref.read(financeBotServiceProvider).sendMessage(
      pregunta: text,
      saldoTotal: ref.read(saldoTotalProvider(familiaId)),
      ingresosMes: ref.read(resumenMesProvider(familiaId)).ingresos,
      gastosMes: ref.read(resumenMesProvider(familiaId)).gastos,
      sueldoFamiliar: ref.read(sueldoMesActualProvider(familiaId)).value?.totalFamiliar ?? 0,
      movimientosMes: ref.read(resumenMesProvider(familiaId)).movimientos,
      metas: ref.read(metasStreamProvider(familiaId)).value ?? [],
      nombreFamilia: ref.read(familiaStreamProvider(familiaId)).value?.nombre ?? 'Familia',
    );

    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(role: 'bot', text: reply));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy, color: AppTheme.accent, size: 28),
                const SizedBox(width: 12),
                const Text('FinanceBot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, index) {
                final msg = _messages[index];
                final isBot = msg.role == 'bot';
                return Align(
                  alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: EdgeInsets.only(
                      bottom: 12,
                      left: isBot ? 0 : 32,
                      right: isBot ? 32 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isBot ? AppTheme.cardDark : AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomLeft: isBot ? Radius.zero : const Radius.circular(16),
                        bottomRight: !isBot ? Radius.zero : const Radius.circular(16),
                      ),
                    ),
                    child: Text(msg.text, style: const TextStyle(fontSize: 15)),
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),

          // Input
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Ej: ¿Llegamos al ahorro este mes?',
                        filled: true,
                        fillColor: AppTheme.cardDark,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.accent,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black87),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String text;
  const _ChatMessage({required this.role, required this.text});
}
