import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/presentation/pages/login_utente.dart';
import 'package:app_campi/features/admin/presentation/pages/piani_abbonamento.dart';
import 'package:app_campi/core/theme/app_theme.dart';

const String googlePlayUrl =
    'https://play.google.com/store/apps/details?id=com.matchly.app';

const String appleAppStoreUrl =
    'https://apps.apple.com/app/matchinzona/id6822423689';

const Color _bg = Color(0xFF07100D);
const Color _card = Color(0xFF0D1712);
const Color _cardBorder = Color(0xFF233129);
const Color _green = Color(0xFF79FF61);
const Color _orange = AppTheme.neonOrange;
const Color _secondary = Color(0xFF9CABA3);

class LandingGestoreWebPage extends StatefulWidget {
  const LandingGestoreWebPage({super.key});

  @override
  State<LandingGestoreWebPage> createState() => _LandingGestoreWebPageState();
}

class _LandingGestoreWebPageState extends State<LandingGestoreWebPage> {
  final GlobalKey _giocatoriKey = GlobalKey();
  final GlobalKey _gestoriKey = GlobalKey();

  void _vaiAllaSezione(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeInOutCubic,
      alignment: 0.03,
    );
  }

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
            KeyedSubtree(
              key: _giocatoriKey,
              child: _clientAppSection(context, desktop),
            ),
            _downloadSection(),
            KeyedSubtree(
              key: _gestoriKey,
              child: _managerShowcase(context, desktop),
            ),
            _introSection(context),
            _featuresSection(context),
            _footer(),
          ],
        ),
      ),
    );
  }

  // ========================= NAVBAR =========================

  Widget _navbar(BuildContext context, bool desktop) {
    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () => _apriUrl(googlePlayUrl),
          icon: const Icon(Icons.shop_rounded, size: 18),
          label: const Text('GOOGLE PLAY'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: _bg,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        OutlinedButton.icon(
          // Sostituisci appleAppStoreUrl con il link reale per attivarlo.
          onPressed: appleAppStoreUrl.isEmpty
              ? null
              : () => _apriUrl(appleAppStoreUrl),
          icon: const Icon(Icons.apple_rounded, size: 18),
          label: const Text('APP STORE'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: _secondary,
            side: const BorderSide(color: _cardBorder),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
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
    return Image.asset(
      'assets/images/logo_matchinzona_largo.png',
      width: size == 23 ? 180 : 230,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Text(
          'MatchInZona',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        );
      },
    );
  }

  // ========================= HERO =========================

  Widget _hero(BuildContext context, bool desktop) {
    return Stack(
      children: [
        Positioned(left: -220, top: 40, child: _glow(_green, 400)),
        Positioned(right: -230, bottom: -70, child: _glow(_orange, 450)),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: desktop ? 72 : 24,
                vertical: desktop ? 105 : 65,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _green.withOpacity(0.25)),
                    ),
                    child: const Text(
                      'LA COMMUNITY DELLO SPORT, NELLA TUA ZONA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text.rich(
                    const TextSpan(
                      children: [
                        TextSpan(text: 'Il tuo sport.\n'),
                        TextSpan(
                          text: 'La tua zona.',
                          style: TextStyle(color: _green),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: desktop ? 76 : 45,
                      height: 1.02,
                      fontWeight: FontWeight.w900,
                      letterSpacing: desktop ? -3.8 : -2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 720),
                    child: Text(
                      'MatchInZona avvicina chi ama giocare e chi organizza lo sport. '
                      'Scopri persone, attività e opportunità sportive vicino a te, '
                      'oppure porta il tuo centro sportivo in una piattaforma pensata per crescere.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _secondary,
                        fontSize: 17,
                        height: 1.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 38),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _vaiAllaSezione(_giocatoriKey),
                        icon: const Icon(Icons.sports_soccer_rounded),
                        label: const Text('SONO UN GIOCATORE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: _bg,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _vaiAllaSezione(_gestoriKey),
                        icon: const Icon(Icons.business_rounded),
                        label: const Text('SONO UN GESTORE'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _orange,
                          side: const BorderSide(color: _orange, width: 1.5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 45),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 22,
                    runSpacing: 14,
                    children: const [
                      _HeroPill(
                        icon: Icons.people_alt_rounded,
                        text: 'Community di giocatori',
                        accent: _green,
                      ),
                      _HeroPill(
                        icon: Icons.place_rounded,
                        text: 'Sport vicino a te',
                        accent: _orange,
                      ),
                      _HeroPill(
                        icon: Icons.calendar_month_rounded,
                        text: 'Strumenti per i centri',
                        accent: _green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
            'UNO SPAZIO PER OGNI SPORT',
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
          'Gestisci campi, orari e prenotazioni in modo semplice e veloce, risparmiando tempo ogni giorno. Aumenta le opportunità di guadagno permettendo di creare partite aperte a cui i giocatori della zona possono unirsi. Riempi più facilmente i campi, riduci gli orari vuoti e fai crescere il tuo centro sportivo.',
      features: const [
        'Gestione di campi e sport',
        'Orari e disponibilità',
        'Prenotazioni organizzate',
        'Visibilità tra i giocatori della zona',
      ],
      orange: true,
      actions: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton(
            onPressed: () => _accedi(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: _bg,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            ),
            child: const Text(
              'ACCEDI AL GESTIONALE',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          OutlinedButton(
            onPressed: () => _apriPiani(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: _orange),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            ),
            child: const Text(
              'VEDI I PIANI',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
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
    Widget? actions,
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
        if (actions != null) ...[const SizedBox(height: 20), actions],
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
                      // Center impedisce a Expanded di dilatare la cornice.
                      child: Center(
                        child: _PhoneMockup(
                          imagePath: '/images/3.png',
                          showEntireImage: true,
                          width: 280,
                          height: 525,
                        ),
                      ),
                    ),
                    const SizedBox(width: 70),
                    Expanded(child: _clientAppText(context, true)),
                  ],
                )
              : Column(
                  children: [
                    Builder(
                      builder: (context) {
                        final phoneWidth =
                            (MediaQuery.sizeOf(context).width - 64)
                                .clamp(220.0, 280.0)
                                .toDouble();
                        // 3.png: 720x1432. 16px sono la cornice del mockup.
                        final phoneHeight = (phoneWidth - 16) * 1432 / 720;
                        return _PhoneMockup(
                          imagePath: '/images/3.png',
                          showEntireImage: true,
                          width: phoneWidth,
                          height: phoneHeight,
                        );
                      },
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
          'PER CHI AMA GIOCARE',
          style: TextStyle(
            color: _green,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 18),
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'Lo sport è più bello\n'),
              TextSpan(
                text: 'insieme.',
                style: TextStyle(color: _green),
              ),
            ],
          ),
          textAlign: desktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: desktop ? 45 : 35,
            fontWeight: FontWeight.w900,
            height: 1.09,
            letterSpacing: -1.8,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Che tu giochi spesso o voglia ricominciare, MatchInZona ti aiuta '
          'a entrare nel mondo sportivo della tua zona. Crea il tuo profilo, '
          'conosci altri giocatori e rimani in contatto con la community. Prenota un campo in pochi tap oppure unisciti alle partite organizzate da altri giocatori. Trova la tua prossima occasione per scendere in campo!',
          textAlign: desktop ? TextAlign.left : TextAlign.center,
          style: const TextStyle(color: _secondary, fontSize: 16, height: 1.8),
        ),
        const SizedBox(height: 26),
        const _BenefitRow(
          text:
              'Il tuo profilo sportivo, con livelli e informazioni per presentarti',
        ),
        const _BenefitRow(
          text: 'Chat e messaggi per restare in contatto con altri giocatori',
        ),
        const _BenefitRow(
          text: 'Scopri centri e opportunità sportive nella tua zona',
        ),
        const _BenefitRow(
          text: 'Una community costruita attorno alla voglia di giocare',
        ),
        const SizedBox(height: 24),
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
            'Entra in campo con MatchInZona.',
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
            'Scarica gratuitamente MatchInZona su Google Play e App Store. '
            'Trova giocatori, scopri campi sportivi e organizza le tue partite.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondary, fontSize: 15, height: 1.7),
          ),
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 14,
            children: [
              OutlinedButton.icon(
                onPressed: () => _apriUrl(googlePlayUrl),
                icon: const Icon(Icons.play_arrow_rounded, size: 26),
                label: const Text('SCARICA DA GOOGLE PLAY'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: _cardBorder),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 17,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _apriUrl(appleAppStoreUrl),
                icon: const Icon(Icons.apple_rounded, size: 26),
                label: const Text('SCARICA DA APP STORE'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: _cardBorder),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 17,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
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
            'Un posto per chi gioca. Un alleato per chi gestisce.',
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

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accent;
  const _HeroPill({
    required this.icon,
    required this.text,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _cardBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: accent, size: 20),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _BenefitRow extends StatelessWidget {
  final String text;
  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, color: _green, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

// ========================= CORNICE IMMAGINE =========================

class _PhoneMockup extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final bool orange;
  final bool showEntireImage;

  const _PhoneMockup({
    required this.imagePath,
    required this.width,
    required this.height,
    this.orange = false,
    this.showEntireImage = false,
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
            child: ColoredBox(
              color: _bg,
              child: Image.network(
                Uri.base.resolve(imagePath).toString(),
                fit: showEntireImage ? BoxFit.contain : BoxFit.cover,
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
