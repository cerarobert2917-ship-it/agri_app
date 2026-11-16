import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../services/api_client.dart';
import 'customer_home.dart';

class _ChatMessage {
  final bool isUser;
  final String text;
  final List<Map<String, dynamic>> products;

  const _ChatMessage({
    required this.isUser,
    required this.text,
    this.products = const [],
  });
}

class ChatScreen extends StatefulWidget {
  /// Kapag may laman, may close (X) na button sa header (ginagamit sa lumulutang na AgriBot).
  final VoidCallback? onClose;
  const ChatScreen({super.key, this.onClose});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      isUser: false,
      text:
          'Hi! I am AgriBot. Ask me about prices, stock and stores in Mamburao.',
    ),
  ];

  bool _isSending = false;

  // Totoong lokasyon ng user (para sa "malapit na store"). Kung walang pahintulot, gagamitin ang gitna ng Mamburao.
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      _lat = pos.latitude;
      _lng = pos.longitude;
    } catch (_) {}
  }

  static const _suggestions = [
    'Where can I find fertilizer?',
    'Cheapest urea',
    'What rice seeds are available?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestedText]) async {
    final message = (suggestedText ?? _input.text).trim();
    if (message.isEmpty || _isSending) return;

    final history = _messages.skip(1).map((item) {
      return {
        'role': item.isUser ? 'user' : 'assistant',
        'content': item.text,
      };
    }).toList();

    _input.clear();
    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: message));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      // Keep the existing backend contract: POST /ai/chat.
      final response = await ApiClient.instance.post('/ai/chat', {
        'message': message,
        'history': history,
        'lat': _lat ?? AppConfig.defaultLat,
        'lng': _lng ?? AppConfig.defaultLng,
      });

      if (!mounted) return;

      if (response is! Map || response['reply'] == null) {
        throw ApiException(
          'The server returned an unexpected chatbot response. Please check the /ai/chat endpoint.',
        );
      }

      final rawProducts = response['products'];
      final products = rawProducts is List
          ? rawProducts
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _messages.add(
          _ChatMessage(
            isUser: false,
            text: response['reply'].toString(),
            products: products,
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            isUser: false,
            text: _friendlyError(error),
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.toLowerCase().contains('cannot reach the server')) {
      return 'I cannot connect to the AgriBot server right now. Please check that your backend is running and that the API URL is correct.';
    }
    return message;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 180,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const _TypingBubble();
                }

                final message = _messages[index];
                return _MessageBubble(message: message);
              },
            ),
          ),
          _buildSuggestions(),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
      ),
      child: Row(
        children: [
          // Parehong logo ng floating AgriBot (may manipis na puting outline para kita sa berde)
          Image.asset('assets/images/agribot_logo_outline.png',
              width: 36, height: 36),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AgriBot',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (widget.onClose != null)
            IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Close',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ActionChip(
            label: Text(suggestion),
            backgroundColor: AppColors.light,
            side: BorderSide.none,
            onPressed: _isSending ? null : () => _send(suggestion),
          );
        },
      ),
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              enabled: !_isSending,
              maxLength: 500,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: 'Ask a question...',
                counterText: '',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: SizedBox(
              width: 46,
              height: 46,
              child: IconButton.filled(
                tooltip: 'Send message',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.light,
                ),
                onPressed: _isSending ? null : () => _send(),
                icon: const Icon(Icons.send_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.84,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(19),
                  topRight: const Radius.circular(19),
                  bottomLeft: Radius.circular(isUser ? 19 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 19),
                ),
              ),
              child: SelectableText(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.text,
                  fontSize: 15.5,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: message.products
                    .take(3)
                    .map((product) => ProductTile(product))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 9),
            Text('AgriBot is typing...',
                style: TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
