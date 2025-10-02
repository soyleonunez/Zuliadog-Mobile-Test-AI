import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:zuliadog/mobile/core/mobile_theme.dart';
import 'package:zuliadog/mobile/widgets/animated_card.dart';
import 'package:zuliadog/mobile/services/mobile_data_service.dart';

class MobilePetDetailScreen extends StatefulWidget {
  final String petId;

  const MobilePetDetailScreen({super.key, required this.petId});

  @override
  State<MobilePetDetailScreen> createState() => _MobilePetDetailScreenState();
}

class _MobilePetDetailScreenState extends State<MobilePetDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _pet;
  List<Map<String, dynamic>> _medicalHistory = [];
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPetData();
  }

  Future<void> _loadPetData() async {
    setState(() => _isLoading = true);
    try {
      final pet = await MobileDataService.getPetById(widget.petId);
      final history = await MobileDataService.getMedicalHistoryByPet(widget.petId);
      final appointments = await MobileDataService.getAllAppointmentsByPet(widget.petId);

      setState(() {
        _pet = pet;
        _medicalHistory = history;
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pet data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MobileTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildPetHeader(),
                      _buildInfoCards(),
                      _buildTabBar(),
                    ],
                  ),
                ),
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMedicalHistoryTab(),
                      _buildAppointmentsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: MobileTheme.primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_pet?['photo_url'] != null)
              Image.network(
                _pet!['photo_url'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildGradientBackground(),
              )
            else
              _buildGradientBackground(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: MobileTheme.primaryGradient(),
      ),
      child: const Center(
        child: Icon(
          Iconsax.heart,
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPetHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            _pet?['name'] ?? '',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _pet?['breed'] ?? _pet?['species'] ?? '',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: MobileTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    final birthDate = _pet?['birth_date'] != null
        ? DateTime.parse(_pet!['birth_date'])
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoCard(
              icon: Iconsax.cake,
              label: 'Edad',
              value: birthDate != null ? _calculateAge(birthDate) : 'N/A',
              delay: 0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCard(
              icon: Iconsax.weight,
              label: 'Peso',
              value: _pet?['weight'] != null ? '${_pet!['weight']} kg' : 'N/A',
              delay: 100,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCard(
              icon: _pet?['gender'] == 'macho' ? Iconsax.man : Iconsax.woman,
              label: 'Género',
              value: _pet?['gender'] ?? 'N/A',
              delay: 200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required int delay,
  }) {
    return AnimatedCard(
      delay: delay,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: MobileTheme.primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MobileTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [MobileTheme.cardShadow()],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: MobileTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: MobileTheme.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Historial Médico'),
          Tab(text: 'Citas'),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryTab() {
    if (_medicalHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.note_1,
              size: 64,
              color: MobileTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay historial médico',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _medicalHistory.length,
      itemBuilder: (context, index) {
        final record = _medicalHistory[index];
        return _buildMedicalRecordCard(record, index * 100);
      },
    );
  }

  Widget _buildMedicalRecordCard(Map<String, dynamic> record, int delay) {
    final date = DateTime.parse(record['visit_date']);

    return AnimatedCard(
      delay: delay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MobileTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Iconsax.health,
                  color: MobileTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record['visit_type'] ?? 'Consulta',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            textTransform: TextTransform.capitalize,
                          ),
                    ),
                    Text(
                      DateFormat('d MMMM yyyy', 'es').format(date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (record['diagnosis'] != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Diagnóstico',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              record['diagnosis'],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (record['treatment'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Tratamiento',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              record['treatment'],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (record['veterinarian'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Iconsax.user,
                  size: 14,
                  color: MobileTheme.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  record['veterinarian'],
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.calendar_1,
              size: 64,
              color: MobileTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay citas registradas',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        return _buildAppointmentCard(appointment, index * 100);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, int delay) {
    final date = DateTime.parse(appointment['appointment_date']);
    final isPast = date.isBefore(DateTime.now());

    return AnimatedCard(
      delay: delay,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPast
                  ? MobileTheme.textTertiary.withOpacity(0.1)
                  : MobileTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('d', 'es').format(date),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: isPast
                            ? MobileTheme.textTertiary
                            : MobileTheme.successColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  DateFormat('MMM', 'es').format(date).toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isPast
                            ? MobileTheme.textTertiary
                            : MobileTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment['appointment_type'] ?? 'Consulta',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        textTransform: TextTransform.capitalize,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm', 'es').format(date),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (appointment['veterinarian'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    appointment['veterinarian'],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isPast
                  ? MobileTheme.textTertiary.withOpacity(0.1)
                  : MobileTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPast ? 'Completada' : 'Próxima',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isPast
                        ? MobileTheme.textTertiary
                        : MobileTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final years = now.year - birthDate.year;
    final months = now.month - birthDate.month;

    if (years > 0) {
      return '$years ${years == 1 ? 'año' : 'años'}';
    } else if (months > 0) {
      return '$months ${months == 1 ? 'mes' : 'meses'}';
    } else {
      return 'Recién nacido';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
