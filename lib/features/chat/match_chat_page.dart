import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/theme/app_theme.dart';

class MatchChatPage extends StatefulWidget {
  final String matchId;
  final String nomeCampo;

  const MatchChatPage({
    super.key,
    required this.matchId,
    required this.nomeCampo,
  });

  @override
  State<MatchChatPage> createState() => _MatchChatPageState();
}

class _MatchChatPageState extends State<MatchChatPage> {
  final _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;
  String? _cachedUserName;

  @override
  void initState() {
    super.initState();
    _caricaNomeUtente();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Recupera il nome reale dell'utente dalla tabella 'utenti'
  Future<void> _caricaNomeUtente() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final datiUtente = await _supabase
          .from('utenti')
          .select('nome, cognome')
          .eq('id', user.id)
          .maybeSingle();

      if (datiUtente != null) {
        final nome = (datiUtente['nome'] as String?)?.trim() ?? '';
        final cognome = (datiUtente['cognome'] as String?)?.trim() ?? '';
        final nomeCompleto = "$nome $cognome".trim();

        if (nomeCompleto.isNotEmpty && mounted) {
          setState(() {
            _cachedUserName = nomeCompleto;
          });
        }
      }
    } catch (_) {
      // Se fallisce, userà il fallback
    }
  }

  Future<void> _inviaMessaggio() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _messageController.clear();

    // Priorità: 1. Nome da tabella utenti, 2. userMetadata, 3. 'Giocatore'
    String userName = _cachedUserName ?? '';
    if (userName.isEmpty) {
      userName =
          user.userMetadata?['full_name'] ??
          user.userMetadata?['nome'] ??
          'Giocatore';
    }

    try {
      await _supabase.from('messaggi_partita').insert({
        'id_partita': widget.matchId,
        'id_utente': user.id,
        'nome_mittente': userName,
        'testo': text,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore invio messaggio: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser?.id;

    final chatStream = _supabase
        .from('messaggi_partita')
        .stream(primaryKey: ['id'])
        .eq('id_partita', widget.matchId)
        .order('created_at', ascending: true);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Chat Matchmaking",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.nomeCampo,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.testoSecondario,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: chatStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.neonCyan),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Errore caricamento: ${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      "Nessun messaggio. Scrivi per organizzare la partita!",
                      style: TextStyle(color: AppTheme.testoSecondario),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['id_utente'] == currentUserId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.neonCyan : AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  msg['nome_mittente'] ?? 'Giocatore',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.neonGreen,
                                  ),
                                ),
                              ),
                            Text(
                              msg['testo'] ?? '',
                              style: TextStyle(
                                color: isMe ? Colors.black : Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.cardBg,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Scrivi un messaggio...",
                        hintStyle: const TextStyle(
                          color: AppTheme.testoSecondario,
                        ),
                        filled: true,
                        fillColor: AppTheme.darkBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: AppTheme.neonCyan,
                    ),
                    onPressed: _inviaMessaggio,
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
