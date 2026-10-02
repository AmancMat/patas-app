import 'package:flutter/material.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';

class ClinicSearchPage extends StatefulWidget {
  const ClinicSearchPage({super.key});

  @override
  State<ClinicSearchPage> createState() => _ClinicSearchPageState();
}

class _ClinicSearchPageState extends State<ClinicSearchPage> {
  bool _isMapView = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);

    return Scaffold(
      backgroundColor: thmode.darkMode ? AppColors.darkBG : Colors.white,
      appBar: PatasEssencialAppBar(
        title: 'Encontrar Profissional',
        subtitle: 'Clínicas e veterinários',
        leadingIcon: const Icon(
          Icons.local_hospital_rounded,
          color: AppColors.patasColor,
          size: 22,
        ),
        showBackButton: true,
        actions: [
          IconButton(
            tooltip: _isMapView ? 'Ver lista' : 'Ver mapa',
            icon: Icon(
              _isMapView ? Icons.list_rounded : Icons.map_outlined,
              color: AppColors.patasColor,
            ),
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.feedMaxWidth),
          child: Column(
            children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                  color: thmode.darkMode ? Colors.white : AppColors.darkBG),
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou especialidade...',
                hintStyle: TextStyle(
                    color: thmode.darkMode ? Colors.grey : Colors.black45),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.patasColor),
                filled: true,
                fillColor: thmode.darkMode
                    ? const Color(0xFF1E1E1E)
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          _buildCategories(),
          Expanded(
            child: _isMapView ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildCategories() {
    final categories = [
      'Clínicas',
      'Veterinários',
      'Especialistas',
      '24 Horas'
    ];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(categories[index]),
              labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
              backgroundColor: index == 0 ? AppColors.patasColor : Colors.grey,
              onPressed: () {},
            ),
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Mockup
      itemBuilder: (context, index) {
        return _ClinicResultCard(index: index);
      },
    );
  }

  Widget _buildMapView() {
    final thmode = Provider.of<DarkMode>(context, listen: false);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: thmode.darkMode ? const Color(0xFF1E1E1E) : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 50, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Mapa de Clínicas Próximas',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
              child: Text(
                'Nesta tela o tutor verá os profissionais marcados no mapa de acordo com sua localização.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.patasColor),
              child: const Text('HABILITAR LOCALIZAÇÃO',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClinicResultCard extends StatelessWidget {
  final int index;
  const _ClinicResultCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final names = [
      'Clínica Veterinária Patas',
      'Hospital Animal Amigo',
      'Dr. Ricardo Oliveira',
      'Centro Vet 24h',
      'Clínica Gatos & Cia'
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: thmode.darkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.patasColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.location_city, color: AppColors.patasColor),
        ),
        title: Text(
          names[index % names.length],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: thmode.darkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Avenida das Américas, 1234',
              style: TextStyle(
                fontSize: 12,
                color: thmode.darkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '4.8 (120 avaliações)',
                  style: TextStyle(
                    fontSize: 11,
                    color: thmode.darkMode ? Colors.white60 : Colors.black45,
                  ),
                ),
                const Spacer(),
                Text(
                  index % 2 == 0 ? 'ABERTO' : 'FECHADO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: index % 2 == 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          final clinicName = names[index % names.length];
          final clinicId =
              '00000000-0000-0000-0000-00000000000$index'; // Mock UUID

          Navigator.pop(context, {
            'id': clinicId,
            'name': clinicName,
          });
        },
      ),
    );
  }
}
