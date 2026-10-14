import 'package:flutter/material.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:app_campi/features/admin/presentation/pages/piani_abbonamento.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            children: [
              //GIOCATORE
              _buildRoleSlide(
                context,
                title: "SEI UN GIOCATORE?",
                description:
                    "Trova match in zona, prenota campi in un tap e gioca quando vuoi.",
                buttonText: "ESPLORA L'ARENA",
                color: AppTheme.accent,
                imagePath: 'assets/images/giocatore.png',
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
              ),

              //GESTORE
              _buildRoleSlide(
                context,
                title: "SEI IL GESTORE DI UNA STRUTTURA?",
                description:
                    "Digitalizza il tuo impianto, ricevi prenotazioni h24 e aumenta gli incassi.",
                buttonText: "DIVENTA PARTNER",
                color: AppTheme.accent,
                imagePath: 'assets/images/proprietario.png',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PianiAbbonamentoScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: 2,
                effect: const ExpandingDotsEffect(
                  activeDotColor: AppTheme.accent,
                  dotColor: Colors.white24,
                  dotHeight: 8,
                  dotWidth: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSlide(
    BuildContext context, {
    required String title,
    required String description,
    required String buttonText,
    required Color color,
    required String imagePath,
    required VoidCallback onPressed,
    Widget? secondaryAction,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Container(color: AppTheme.darkBg),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.darkBg.withValues(alpha: 0.3),
                AppTheme.darkBg.withValues(alpha: 0.8),
                AppTheme.darkBg,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: AppTheme.darkBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              ?secondaryAction,

              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }
}
