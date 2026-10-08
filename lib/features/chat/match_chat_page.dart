import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/theme/app_theme.dart';

class MatchChatPage extends StatefulWidget {
  final String matchId;
  final String nomeSocieta;

  const MatchChatPage({
    super.key,
    required this.matchId,
    required this.nomeSocieta,
  });

  @override
  State<MatchChatPage> createState() => _MatchChatPageState();
}

class _MatchChatPageState extends State<MatchChatPage> {
  final _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;

  String? _cachedUserName;
  Set<String> _utentiBloccati = {};

  @override
  void initState() {
    super.initState();
    _caricaNomeUtente();
    _caricaUtentiBloccati();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _caricaNomeUtente() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final datiUtente = await _supabase
          .from('utenti')
          .select('nome, cognome')
          .eq('id', user.id)
          .maybeSingle();

      if (datiUtente == null) return;

      final nome = (datiUtente['nome'] as String?)?.trim() ?? '';

      final cognome = (datiUtente['cognome'] as String?)?.trim() ?? '';

      final nomeCompleto = "$nome $cognome".trim();

      if (nomeCompleto.isNotEmpty && mounted) {
        setState(() {
          _cachedUserName = nomeCompleto;
        });
      }
    } catch (_) {
      // fallback su metadata Supabase
    }
  }

  Future<void> _caricaUtentiBloccati() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final rows = await _supabase
          .from('utenti_bloccati')
          .select('id_bloccato')
          .eq('id_utente', user.id);

      if (!mounted) return;

      setState(() {
        _utentiBloccati = rows
            .map<String>((row) => row['id_bloccato'].toString())
            .toSet();
      });
    } catch (e) {
      debugPrint('Errore caricamento utenti bloccati: $e');
    }
  }

  Future<void> _inviaMessaggio() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    final user = _supabase.auth.currentUser;

    if (user == null) return;

    _messageController.clear();

    String userName = _cachedUserName ?? '';

    if (userName.isEmpty) {
      userName =
          user.userMetadata?['full_name']?.toString() ??
          user.userMetadata?['nome']?.toString() ??
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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile inviare il messaggio. Riprova tra poco.'),
          backgroundColor: AppTheme.statoErrore,
        ),
      );
    }
  }

  Future<void> _segnalaMessaggio({
    required Map<String, dynamic> messaggio,
    required String idSegnalato,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) return;

    final motivo = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: const Text(
            'Segnala messaggio',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                ),
                title: const Text(
                  'Offensivo o molesto',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context, 'Offensivo o molesto');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.block_rounded,
                  color: Colors.orangeAccent,
                ),
                title: const Text(
                  'Spam',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context, 'Spam');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.report_problem_outlined,
                  color: Colors.orangeAccent,
                ),
                title: const Text(
                  'Contenuto inappropriato',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context, 'Contenuto inappropriato');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.orangeAccent,
                ),
                title: const Text(
                  'Altro',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context, 'Altro');
                },
              ),
            ],
          ),
        );
      },
    );

    if (motivo == null) return;

    try {
      await _supabase.from('segnalazioni_chat').insert({
        'id_segnalante': user.id,
        'id_segnalato': idSegnalato,
        'id_messaggio': messaggio['id'],
        'id_partita': widget.matchId,
        'motivo': motivo,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Segnalazione inviata.'),
          backgroundColor: AppTheme.statoSuccesso,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Impossibile inviare la segnalazione. Riprova tra poco.',
          ),
          backgroundColor: AppTheme.statoErrore,
        ),
      );
    }
  }

  Future<void> _bloccaUtente({
    required String idBloccato,
    required String nomeUtente,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) return;

    if (idBloccato == user.id) return;

    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: const Text(
            'Blocca utente',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Non vedrai più i messaggi di $nomeUtente nelle chat MatchInZona.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('ANNULLA'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statoErrore,
                foregroundColor: Colors.white,
              ),
              child: const Text('BLOCCA'),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    try {
      await _supabase.from('utenti_bloccati').upsert({
        'id_utente': user.id,
        'id_bloccato': idBloccato,
      });

      await _caricaUtentiBloccati();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utente bloccato.'),
          backgroundColor: AppTheme.statoSuccesso,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Impossibile bloccare l’utente. Riprova tra poco.',
          ),
          backgroundColor: AppTheme.statoErrore,
        ),
      );
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
              widget.nomeSocieta,
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
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "Impossibile caricare la chat in questo momento.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.testoSecondario),
                      ),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                final messagesVisibili = messages.where((msg) {
                  final idMittente = msg['id_utente']?.toString();

                  if (idMittente == null) {
                    return true;
                  }

                  return !_utentiBloccati.contains(idMittente);
                }).toList();

                if (messagesVisibili.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        "Nessun messaggio. Scrivi per organizzare la partita!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.testoSecondario),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messagesVisibili.length,
                  itemBuilder: (context, index) {
                    final msg = messagesVisibili[index];

                    final idMittente = msg['id_utente']?.toString();

                    final isMe = idMittente == currentUserId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 300),
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      msg['nome_mittente']?.toString() ??
                                          'Giocatore',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.neonGreen,
                                      ),
                                    ),
                                  ),
                                  if (idMittente != null)
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_horiz,
                                        size: 18,
                                        color: Colors.white54,
                                      ),
                                      color: AppTheme.cardBg,
                                      onSelected: (value) {
                                        if (value == 'segnala') {
                                          _segnalaMessaggio(
                                            messaggio: msg,
                                            idSegnalato: idMittente,
                                          );
                                        }

                                        if (value == 'blocca') {
                                          _bloccaUtente(
                                            idBloccato: idMittente,
                                            nomeUtente:
                                                msg['nome_mittente']
                                                    ?.toString() ??
                                                'Utente',
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'segnala',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.flag_outlined,
                                                size: 18,
                                              ),
                                              SizedBox(width: 10),
                                              Text('Segnala messaggio'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'blocca',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.block_rounded,
                                                size: 18,
                                              ),
                                              SizedBox(width: 10),
                                              Text('Blocca utente'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),

                            if (!isMe) const SizedBox(height: 2),

                            Text(
                              msg['testo']?.toString() ?? '',
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
                      minLines: 1,
                      maxLines: 4,
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
