import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app.dart';
import '../../constants/app_colors.dart';
import '../../constants/routes.dart';
import '../health/pet_health.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    return Scaffold(
        backgroundColor: thmode.darkMode ? AppColors.darkBG : Colors.white,
        appBar: AppBar(
          backgroundColor: thmode.darkMode ? AppColors.darkBG : Colors.white,
          elevation: 0,
          title: const Text(
            'Patas Essencial',
            style: TextStyle(
              fontFamily: 'Fredoka',
              color: AppColors.patasColor,
              fontSize: 30,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 200),
          children: [
            AspectRatio(
              aspectRatio: 2 / 1.2,
              child: _FeatureCard(
                title: 'Patas Saúde',
                description:
                    'A saúde do seu pet está aqui, agende consultas, acompanhe exames laboratoriais e muito mais!',
                asset: 'assets/patas_essencial/patas_saude.gif',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PetHealthPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 2 / 1.2,
              child: _FeatureCard(
                title: 'Patas História',
                description:
                    'Veja e edite a história completa dos seus animais de estimação!',
                asset: 'assets/patas_essencial/patas_historia.gif',
                showSoonBadge: true,
                onTap: () {},
              ),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 2 / 1.2,
              child: _FeatureCard(
                title: 'Patas Friendly',
                description:
                    'Encontre no mapa locais próximos que aceitam animais e saiba onde você e seu pet são bem-vindos.',
                asset: 'assets/patas_essencial/patas_friendly.png',
                showSoonBadge: false,
                onTap: () {
                  Navigator.pushNamed(context, NamedRoute.friendlyDashboard);
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: Row(
                children: [
                  Expanded(
                    child: _FeatureCard(
                      title: 'Patas Shop',
                      description: 'Produtos e serviços da sua região.',
                      asset: 'assets/patas_essencial/patas_shop.gif',
                      isSmall: true,
                      showSoonBadge: true,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _FeatureCard(
                      title: 'Patas Encontra',
                      description: 'Ajuda a encontrar seu animal perdido.',
                      asset: 'assets/patas_essencial/patas_encontra.gif',
                      isSmall: true,
                      showSoonBadge: true,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ));
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final String asset;
  final VoidCallback onTap;
  final bool isSmall;
  final bool showSoonBadge;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.asset,
    required this.onTap,
    this.isSmall = false,
    this.showSoonBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);

    return Container(
      decoration: BoxDecoration(
        color: thmode.darkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Area (Top)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                color: thmode.darkMode
                    ? Colors.black.withValues(alpha: 0.2)
                    : AppColors.bodyLight.withValues(alpha: 0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: isSmall ? 15 : 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.patasColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: isSmall ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isSmall ? 9 : 11,
                        color: thmode.darkMode
                            ? Colors.white60
                            : AppColors.darkBG.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Image Area (Bottom - filling remaining space)
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: thmode.darkMode ? Colors.black26 : Colors.white,
                      ),
                      child: Image.asset(
                        asset,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (showSoonBadge)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.patasColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Em breve',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Fredoka',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
