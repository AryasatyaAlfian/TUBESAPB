import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

/// A single chat bubble in the conversation.
class _ChatMessage {
  final String text;
  final bool fromUser;
  final bool isError;
  _ChatMessage(this.text, {this.fromUser = false, this.isError = false});
}

/// Floating AI assistant: a draggable bubble that expands into a chat panel.
///
/// Mount this once (e.g. in [HomePage]) on top of the page content via a
/// [Stack]. It is fully role-aware — the greeting and the quick-suggestion
/// chips adapt to whether the logged-in user is a `dosen` or `mahasiswa`,
/// while the actual answers come from the backend agent (`POST /chat`), which
/// resolves the role from the auth token. Any newly registered account gets a
/// working assistant automatically; nothing here is hard-coded per user.
class ChatAssistant extends StatefulWidget {
  final Map<String, dynamic> user;
  const ChatAssistant({super.key, required this.user});

  @override
  State<ChatAssistant> createState() => _ChatAssistantState();
}

class _ChatAssistantState extends State<ChatAssistant>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_ChatMessage> _messages = [];

  late final AnimationController _anim;
  bool _open = false;
  bool _sending = false;

  bool get _isMahasiswa => widget.user['role'] == 'mahasiswa';
  String get _displayName =>
      (widget.user['name'] ?? 'Pengguna').toString().split(' ').first;

  List<String> get _suggestions => _isMahasiswa
      ? const [
          'Berapa kali saya hadir?',
          'Apakah saya pernah alpa?',
          'Status izin saya',
        ]
      : const [
          'Rekap kehadiran kelas',
          'Siapa yang sering alpa?',
          'Kehadiran mata kuliah saya',
        ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _messages.add(
      _ChatMessage(
        'Halo $_displayName! 👋\nSaya asisten presensi Anda. '
        '${_isMahasiswa ? 'Tanyakan rekap kehadiran atau status izin Anda.' : 'Tanyakan rekap kehadiran kelas yang Anda ampu.'}',
      ),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _anim.forward() : _anim.reverse();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage(text, fromUser: true));
      _input.clear();
      _sending = true;
    });
    _scrollToBottom();

    final res = await _api.sendChatMessage(text);
    if (!mounted) return;

    setState(() {
      _sending = false;
      if (res['success'] == true) {
        _messages.add(_ChatMessage(res['reply'].toString()));
      } else {
        _messages.add(
          _ChatMessage(
            res['message']?.toString() ??
                'Maaf, terjadi gangguan. Coba lagi sebentar.',
            isError: true,
          ),
        );
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Expanded chat panel
        Positioned(
          right: 16,
          bottom: 16,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
            alignment: Alignment.bottomRight,
            child: FadeTransition(
              opacity: _anim,
              child: _open ? _buildPanel(context) : const SizedBox.shrink(),
            ),
          ),
        ),
        // Floating bubble (hidden while panel is open)
        if (!_open)
          Positioned(right: 16, bottom: 16, child: _buildBubble()),
      ],
    );
  }

  Widget _buildBubble() {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.smart_toy_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final panelBg = isDark ? AppColors.surfaceDark : Colors.white;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: size.width > 420 ? 380 : size.width - 32,
        height: size.height * 0.62,
        constraints: const BoxConstraints(maxHeight: 560),
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessageList(isDark)),
            if (_messages.length <= 1) _buildSuggestions(isDark),
            _buildComposer(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Asisten Presensi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isMahasiswa ? 'Mode Mahasiswa' : 'Mode Dosen',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Tutup',
            onPressed: _toggle,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(14),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (context, i) {
        if (_sending && i == _messages.length) {
          return _buildTyping(isDark);
        }
        return _buildBubbleMsg(_messages[i], isDark);
      },
    );
  }

  Widget _buildBubbleMsg(_ChatMessage m, bool isDark) {
    final userBg = AppColors.primary;
    final botBg = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
    final botText = isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight;

    return Align(
      alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.62,
        ),
        decoration: BoxDecoration(
          color: m.isError
              ? AppColors.errorLight
              : (m.fromUser ? userBg : botBg),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(m.fromUser ? 16 : 4),
            bottomRight: Radius.circular(m.fromUser ? 4 : 16),
          ),
        ),
        child: Text(
          m.text,
          style: TextStyle(
            color: m.isError
                ? AppColors.error
                : (m.fromUser ? Colors.white : botText),
            fontSize: 13.5,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildTyping(bool isDark) {
    final botBg = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: botBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: const _TypingDots(),
      ),
    );
  }

  Widget _buildSuggestions(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestions.map((s) {
          return ActionChip(
            label: Text(s, style: const TextStyle(fontSize: 12)),
            onPressed: _sending ? null : () => _send(s),
            backgroundColor: isDark
                ? AppColors.surfaceVariantDark
                : AppColors.infoLight,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
            labelStyle: TextStyle(
              color: isDark ? AppColors.onSurfaceDark : AppColors.primary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComposer(bool isDark) {
    final fieldBg = isDark ? AppColors.surfaceVariantDark : AppColors.backgroundLight;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Tulis pertanyaan...',
                isDense: true,
                filled: true,
                fillColor: fieldBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: _sending ? AppColors.neutral : AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _sending ? null : () => _send(),
              child: Padding(
                padding: const EdgeInsets.all(11),
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated "typing…" three-dot indicator.
class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_c.value - i * 0.2) % 1.0;
            final scale = 0.6 + 0.4 * (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.neutral.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
