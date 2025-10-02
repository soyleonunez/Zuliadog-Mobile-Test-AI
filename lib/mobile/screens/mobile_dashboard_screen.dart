import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:zuliadog/mobile/core/mobile_theme.dart';
import 'package:zuliadog/mobile/widgets/animated_card.dart';
import 'package:zuliadog/mobile/widgets/shimmer_loading.dart';
import 'package:zuliadog/mobile/services/mobile_data_service.dart';
import 'package:intl/intl.dart';

class MobileDashboardScreen extends StatefulWidget {
  const MobileDashboardScreen({super.key});

  @override
  State<MobileDashboardScreen> createState() => _MobileDashboardScreenState();
}

class _MobileDashboardScreenState extends State<MobileDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _upcomingAppointments = [];
  final String _ownerId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await MobileDataService.getDashboardStats(_ownerId);
      final appointments =
          await MobileDataService.getUpcomingAppointments(_ownerId);

      setState(() {
        _stats = stats;
        _upcomingAppointments = appointments.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MobileTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildGreeting(),
                    const SizedBox(height: 24),
                    _buildStatsCards(),
                    const SizedBox(height: 28),
                    _buildQuickActions(),
                    const SizedBox(height: 28),
                    _buildUpcomingAppointments(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: MobileTheme.backgroundColor,
      elevation: 0,
      title: Image.asset(
        'Assets/Images/logo.png',
        height: 32,
      ),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.notification, size: 24),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting = 'Buenos días';
    if (hour >= 12 && hour < 18) {
      greeting = 'Buenas tardes';
    } else if (hour >= 18) {
      greeting = 'Buenas noches';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: MobileTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'María González',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    if (_isLoading) {
      return Row(
        children: [
          Expanded(
            child: ShimmerLoading(
              width: double.infinity,
              height: 100,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ShimmerLoading(
              width: double.infinity,
              height: 100,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ShimmerLoading(
              width: double.infinity,
              height: 100,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Iconsax.heart,
            value: '${_stats['total_pets'] ?? 0}',
            label: 'Mascotas',
            gradient: MobileTheme.primaryGradient(),
            delay: 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Iconsax.calendar,
            value: '${_stats['upcoming_appointments'] ?? 0}',
            label: 'Citas',
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            delay: 100,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Iconsax.folder_2,
            value: '${_stats['total_files'] ?? 0}',
            label: 'Archivos',
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
            ),
            delay: 200,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Gradient gradient,
    required int delay,
  }) {
    return AnimatedCard(
      delay: delay,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos Rápidos',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Iconsax.add_circle,
                label: 'Nueva Cita',
                color: MobileTheme.primaryColor,
                onTap: () {},
                delay: 300,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Iconsax.call,
                label: 'Contactar',
                color: MobileTheme.successColor,
                onTap: () {},
                delay: 400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return AnimatedCard(
      onTap: onTap,
      delay: delay,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Icon(
            Iconsax.arrow_right_3,
            color: MobileTheme.textTertiary,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Próximas Citas',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          Column(
            children: [
              ShimmerLoading(
                width: double.infinity,
                height: 100,
                borderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(height: 12),
              ShimmerLoading(
                width: double.infinity,
                height: 100,
                borderRadius: BorderRadius.circular(16),
              ),
            ],
          )
        else if (_upcomingAppointments.isEmpty)
          AnimatedCard(
            delay: 500,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.calendar_1,
                      size: 48,
                      color: MobileTheme.textTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay citas programadas',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._upcomingAppointments.asMap().entries.map((entry) {
            final index = entry.key;
            final appointment = entry.value;
            return _buildAppointmentCard(appointment, 500 + (index * 100));
          }),
      ],
    );
  }

  Widget _buildAppointmentCard(
      Map<String, dynamic> appointment, int delay) {
    final date = DateTime.parse(appointment['appointment_date']);
    final petData = appointment['pets'] as Map<String, dynamic>?;
    final petName = petData?['name'] ?? 'Mascota';
    final petPhoto = petData?['photo_url'];

    return AnimatedCard(
      delay: delay,
      onTap: () {},
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: petPhoto != null
                ? Image.network(
                    petPhoto,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultPetAvatar(),
                  )
                : _buildDefaultPetAvatar(),
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
                  petName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Iconsax.calendar,
                      size: 14,
                      color: MobileTheme.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('d MMM, HH:mm', 'es').format(date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: MobileTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Programada',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: MobileTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPetAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: MobileTheme.primaryGradient(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Iconsax.heart,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
