import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/presentation/pages/login_utente.dart';
import 'package:app_campi/features/admin/presentation/pages/piani_abbonamento.dart';

const String googlePlayUrl =
    'https://play.google.com/store/apps/details?id=com.matchly.app';

const Color _bg = Color(0xFF07100D);
const Color _card = Color(0xFF0D1712);
const Color _cardBorder = Color(0xFF233129);
const Color _green = Color(0xFF79FF61);
const Color _orange = Color(0xFFFF9D3C);
const Color _secondary = Color(0xFF9CABA3);

class LandingGestoreWebPage extends StatelessWidget {
  const LandingGestoreWebPage({super.key});

  Future<void> _apriUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _apriPiani(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PianiAbbonamentoScreen()),
    );
  }

  void _accedi(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginUtente()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 900;

    return Scaffold(
      backgroundColor: _bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _navbar(context, desktop),
            _hero(context, desktop),
            _sportSection(),
            _introSection(context),
            _managerShowcase(context, desktop),
            _featuresSection(context),
            _clientAppSection(context, desktop),
            _downloadSection(),
            _footer(),
          ],
        ),
      ),
    );
  }

  // ========================= NAVBAR =========================

  Widget _navbar(BuildContext context, bool desktop) {
    final actions = Wrap(
      spacing: desktop ? 18 : 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          onPressed: () => _apriPiani(context),
          child: const Text(
            'Piani Partner',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => _accedi(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: _bg,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'ACCEDI',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: desktop ? 64 : 22,
        vertical: 20,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1C2821))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: desktop
              ? Row(children: [_brand(), const Spacer(), actions])
              : Column(
                  children: [
                    Row(children: [Flexible(child: _brand())]),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _brand({double size = 27}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/icon/logo_app.png',
            width: 42,
            height: 42,
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(width: 12),

        Flexible(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                color: Colors.white,
              ),
              children: const [
                TextSpan(text: 'Match'),
                TextSpan(
                  text: 'In',
                  style: TextStyle(color: _orange),
                ),
                TextSpan(
                  text: 'Zona',
                  style: TextStyle(color: _green),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========================= HERO =========================

  Widget _hero(BuildContext context, bool desktop) {
    return Stack(
      children: [
        Positioned(left: -220, top: 60, child: _glow(_green, 400)),
        Positioned(right: -240, bottom: -60, child: _glow(_orange, 450)),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: desktop ? 80 : 24,
                vertical: desktop ? 95 : 60,
              ),
              child: desktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 11, child: _heroText(context, true)),
                        const SizedBox(width: 40),
                        Expanded(
                          flex: 9,
                          child: Center(
                            child: _PhoneMockup(
                              imagePath: '/images/8.jpg',
                              width: 310,
                              height: 470,
                              orange: true,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _heroText(context, false),
                        const SizedBox(height: 55),
                        _PhoneMockup(
                          imagePath: '/images/8.jpg',
                          width: (MediaQuery.sizeOf(context).width - 64)
                              .clamp(240.0, 310.0)
                              .toDouble(),
                          height: 440,
                          orange: true,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroText(BuildContext context, bool desktop) {
    return Column(
      crossAxisAlignment: desktop
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _orange.withOpacity(0.10),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _orange.withOpacity(0.28)),
          ),
          child: const Text(
            'PORTALE CIRCOLI & CENTRI SPORTIVI',
            style: TextStyle(
              color: _orange,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text.rich(
          TextSpan(
            children: const [
              TextSpan(text: 'Gestisci.\n'),
              TextSpan(text: 'Organizza.\n'),
              TextSpan(
                text: 'Riempi ogni campo.',
                style: TextStyle(
                  color: _green,
                  shadows: [Shadow(color: Color(0x3379FF61), blurRadius: 30)],
                ),
              ),
            ],
          ),
          textAlign: desktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: desktop ? 66 : 43,
            height: 0.99,
            fontWeight: FontWeight.w900,
            letterSpacing: desktop ? -3.5 : -2,
          ),
        ),
        const SizedBox(height: 26),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 590),
          child: Text(
            'Gestisci campi, orari e prenotazioni da un’unica piattaforma. '
            'Fai conoscere il tuo centro sportivo ai giocatori della tua zona.',
            textAlign: desktop ? TextAlign.left : TextAlign.center,
            style: const TextStyle(
              color: _secondary,
              fontSize: 17,
              height: 1.8,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: desktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _apriPiani(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: _bg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 23,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'SCOPRI I PIANI PARTNER',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () => _accedi(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: _cardBorder),
                padding: const EdgeInsets.symmetric(
                  horizontal: 23,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'ACCEDI AL GESTIONALE',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _glow(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.045),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 110,
              spreadRadius: 45,
            ),
          ],
        ),
      ),
    );
  }

  // ========================= SPORT =========================

  Widget _sportSection() {
    const sports = [
      ('⚽', 'Calcio'),
      ('🎾', 'Padel'),
      ('🎾', 'Tennis'),
      ('🏀', 'Basket'),
      ('🏐', 'Pallavolo'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 75),
      child: Column(
        children: [
          const Text(
            'UN UNICO GESTIONALE, PIÙ SPORT',
            style: TextStyle(
              color: _green,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: sports.map((sport) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _cardBorder),
                ),
                child: Text(
                  '${sport.$1}  ${sport.$2}',
                  style: const TextStyle(
                    color: Color(0xFFE9EFEA),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ========================= PRESENTAZIONE =========================

  Widget _introSection(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = (width - 64).clamp(250.0, 360.0).toDouble();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: width >= 900 ? 80 : 24,
        vertical: 90,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IL TUO CENTRO, SENZA COMPLICAZIONI',
                style: TextStyle(
                  color: _orange,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'Più controllo per te.\n'),
                    TextSpan(
                      text: 'Più semplicità per tutti.',
                      style: TextStyle(color: _green),
                    ),
                  ],
                ),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width >= 900 ? 58 : 39,
                  fontWeight: FontWeight.w900,
                  height: 1.04,
                  letterSpacing: -2.5,
                ),
              ),
              const SizedBox(height: 22),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 720),
                child: Text(
                  'Dimentica calendari disordinati e informazioni sparse. '
                  'Organizza il lavoro quotidiano e tieni sotto controllo '
                  'campi, disponibilità e prenotazioni.',
                  style: TextStyle(
                    color: _secondary,
                    fontSize: 17,
                    height: 1.8,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  _StepCard(
                    width: cardWidth,
                    number: '01',
                    title: 'Configura',
                    description:
                        'Imposta i tuoi campi, gli sport e le tariffe.',
                  ),
                  _StepCard(
                    width: cardWidth,
                    number: '02',
                    title: 'Organizza',
                    description:
                        'Gestisci gli orari e consulta le disponibilità.',
                  ),
                  _StepCard(
                    width: cardWidth,
                    number: '03',
                    title: 'Fatti trovare',
                    description:
                        'Dai ai giocatori un modo semplice per scoprire il tuo centro.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================= VETRINA GESTORE =========================

  Widget _managerShowcase(BuildContext context, bool desktop) {
    final width = MediaQuery.sizeOf(context).width;

    final image = Center(
      child: _PhoneMockup(
        imagePath: '/images/8.jpg',
        width: (width - 64).clamp(240.0, 330.0).toDouble(),
        height: 480,
        orange: true,
      ),
    );

    final content = _showcaseText(
      label: 'PER I CENTRI SPORTIVI',
      title: 'Il tuo centro.\n',
      highlightedTitle: 'Sempre sotto controllo.',
      description:
          'Un’esperienza pensata per aiutarti a organizzare le attività '
          'del centro e rendere più semplice il lavoro di ogni giorno.',
      features: const [
        'Gestione di campi e sport',
        'Orari e disponibilità',
        'Prenotazioni organizzate',
        'Visibilità tra i giocatori della zona',
      ],
      orange: true,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: desktop ? 80 : 24,
        vertical: 80,
      ),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.8, 0),
          radius: 1.1,
          colors: [_orange.withOpacity(0.055), _bg],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: desktop
              ? Row(
                  children: [
                    Expanded(child: image),
                    const SizedBox(width: 70),
                    Expanded(child: content),
                  ],
                )
              : Column(children: [image, const SizedBox(height: 50), content]),
        ),
      ),
    );
  }

  Widget _showcaseText({
    required String label,
    required String title,
    required String highlightedTitle,
    required String description,
    required List<String> features,
    bool orange = false,
  }) {
    final accent = orange ? _orange : _green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 18),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: title),
              TextSpan(
                text: highlightedTitle,
                style: TextStyle(color: accent),
              ),
            ],
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            height: 1.08,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          description,
          style: const TextStyle(color: _secondary, fontSize: 16, height: 1.8),
        ),
        const SizedBox(height: 28),
        ...features.map(
          (feature) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 11),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.045),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: accent.withOpacity(0.14)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: accent, size: 19),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========================= VANTAGGI =========================

  Widget _featuresSection(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = (width - 64).clamp(250.0, 350.0).toDouble();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: width >= 900 ? 60 : 24,
        vertical: 90,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text(
                'TUTTO QUELLO CHE TI SERVE',
                style: TextStyle(
                  color: _green,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Meno gestione manuale.\nPiù tempo per il tuo centro.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width >= 900 ? 44 : 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 42),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _FeatureCard(
                    width: cardWidth,
                    icon: Icons.sports_tennis_rounded,
                    title: 'Campi e sport',
                    description:
                        'Organizza le strutture e configura i servizi del tuo centro.',
                  ),
                  _FeatureCard(
                    width: cardWidth,
                    icon: Icons.calendar_month_rounded,
                    title: 'Orari e disponibilità',
                    description:
                        'Consulta gli orari e tieni organizzati gli slot dei tuoi campi.',
                  ),
                  _FeatureCard(
                    width: cardWidth,
                    icon: Icons.trending_up_rounded,
                    title: 'Più visibilità',
                    description:
                        'Aiuta i giocatori della zona a scoprire il tuo centro sportivo.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================= APP PER I CLIENTI =========================

  Widget _clientAppSection(BuildContext context, bool desktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: desktop ? 80 : 24,
        vertical: 80,
      ),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.8, 0),
          radius: 1.2,
          colors: [_green.withOpacity(0.055), _bg],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: desktop
              ? Row(
                  children: [
                    Expanded(
                      child: _PhoneMockup(
                        imagePath: '/images/3.png',
                        width: 280,
                        height: 440,
                      ),
                    ),
                    const SizedBox(width: 70),
                    Expanded(child: _clientAppText(context, true)),
                  ],
                )
              : Column(
                  children: [
                    _PhoneMockup(
                      imagePath: '/images/3.png',
                      width: (MediaQuery.sizeOf(context).width - 64)
                          .clamp(240.0, 300.0)
                          .toDouble(),
                      height: 430,
                    ),
                    const SizedBox(height: 42),
                    _clientAppText(context, false),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _clientAppText(BuildContext context, bool desktop) {
    return Column(
      crossAxisAlignment: desktop
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        const Text(
          'ANCHE I TUOI CLIENTI SONO PARTE DELLA PIATTAFORMA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _green,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'I giocatori ti cercano.\n'),
              TextSpan(
                text: 'Tu sei più facile da trovare.',
                style: TextStyle(color: _green),
              ),
            ],
          ),
          textAlign: desktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: desktop ? 43 : 34,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -1.8,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Con MatchInZona i giocatori possono scoprire le opportunità '
          'sportive nella propria zona. Il tuo centro entra in contatto '
          'con una community che vuole giocare.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _secondary, fontSize: 16, height: 1.8),
        ),
      ],
    );
  }

  // ========================= DOWNLOAD =========================

  Widget _downloadSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 65),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _green.withOpacity(0.16)),
      ),
      child: Column(
        children: [
          const Text(
            'MATCHINZONA PER I GIOCATORI',
            style: TextStyle(
              color: _green,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Il tuo centro, anche sul loro smartphone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'L’app per i giocatori è disponibile su Android. '
            'Presto anche su iPhone.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondary, fontSize: 15, height: 1.7),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => _apriUrl(googlePlayUrl),
            icon: const Icon(Icons.play_arrow_rounded, size: 26),
            label: const Text('SCARICA DA GOOGLE PLAY'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: _cardBorder),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================= FOOTER =========================

  Widget _footer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 45),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1C2821))),
      ),
      child: Column(
        children: [
          _brand(size: 23),
          const SizedBox(height: 12),
          const Text(
            'Gestisci il tuo centro. Riempi ogni campo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondary, fontSize: 13),
          ),
          const SizedBox(height: 22),
          const Text(
            '© 2026 MatchInZona. Tutti i diritti riservati.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF5F6E66), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ========================= CORNICE IMMAGINE =========================

class _PhoneMockup extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final bool orange;

  const _PhoneMockup({
    required this.imagePath,
    required this.width,
    required this.height,
    this.orange = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = orange ? _orange : _green;

    return Transform.rotate(
      angle: orange ? -0.035 : 0.035,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF020604),
          borderRadius: BorderRadius.circular(38),
          border: Border.all(color: accent.withOpacity(0.22)),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.09),
              blurRadius: 55,
              spreadRadius: 3,
              offset: const Offset(0, 25),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: Image.network(
              Uri.base.resolve(imagePath).toString(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: _card,
                  padding: const EdgeInsets.all(20),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        color: _secondary,
                        size: 38,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Immagine non trovata.\nControlla il percorso del file.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _secondary, height: 1.5),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ========================= CARD VANTAGGI =========================

class _FeatureCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _orange.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _orange, size: 26),
          ),
          const SizedBox(height: 23),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            description,
            style: const TextStyle(
              color: _secondary,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ========================= CARD PASSAGGI =========================

class _StepCard extends StatelessWidget {
  final double width;
  final String number;
  final String title;
  final String description;

  const _StepCard({
    required this.width,
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 205),
      padding: const EdgeInsets.all(27),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: _green,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(color: _secondary, height: 1.6),
          ),
        ],
      ),
    );
  }
}
