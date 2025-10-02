import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:zuliadog/mobile/core/mobile_theme.dart';
import 'package:zuliadog/mobile/widgets/animated_card.dart';
import 'package:zuliadog/mobile/widgets/shimmer_loading.dart';
import 'package:zuliadog/mobile/services/mobile_data_service.dart';

class MobileProfileScreen extends StatefulWidget {
  const MobileProfileScreen({super.key});

  @override
  State<MobileProfileScreen> createState() => _MobileProfileScreenState();
}

class _MobileProfileScreenState extends State<MobileProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _owner;
  List<Map<String, dynamic>> _contacts = [];
  final String _ownerId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final owner = await MobileDataService.getPetOwner(_ownerId);
      final contacts = await MobileDataService.getVeterinaryContacts();

      setState(() {
        _owner = owner;
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MobileTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildProfileInfo(),
                  const SizedBox(height: 28),
                  _buildVeterinaryContacts(),
                  const SizedBox(height: 28),
                  _buildSettingsOptions(),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: MobileTheme.backgroundColor,
      elevation: 0,
      title: const Text('Perfil'),
    );
  }

  Widget _buildProfileHeader() {
    if (_isLoading) {
      return Column(
        children: [
          ShimmerLoading(
            width: 100,
            height: 100,
            borderRadius: BorderRadius.circular(50),
          ),
          const SizedBox(height: 16),
          ShimmerLoading(
            width: 150,
            height: 24,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 8),
          ShimmerLoading(
            width: 200,
            height: 16,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      );
    }

    final avatarUrl = _owner?['avatar_url'];
    final fullName = _owner?['full_name'] ?? 'Usuario';
    final email = _owner?['email'] ?? '';

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [MobileTheme.elevatedShadow()],
          ),
          child: ClipOval(
            child: avatarUrl != null
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                  )
                : _buildDefaultAvatar(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          fullName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MobileTheme.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: MobileTheme.primaryGradient(),
      ),
      child: const Center(
        child: Icon(
          Iconsax.user,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    if (_isLoading) {
      return ShimmerLoading(
        width: double.infinity,
        height: 100,
        borderRadius: BorderRadius.circular(16),
      );
    }

    final phone = _owner?['phone'] ?? 'No registrado';

    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información personal',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Iconsax.call, 'Teléfono', phone),
          const Divider(height: 24),
          _buildInfoRow(Iconsax.sms, 'Email', _owner?['email'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: MobileTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: MobileTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVeterinaryContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Contactos veterinarios',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          Column(
            children: List.generate(
              2,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShimmerLoading(
                  width: double.infinity,
                  height: 90,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          )
        else if (_contacts.isEmpty)
          AnimatedCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No hay contactos disponibles',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          )
        else
          ..._contacts.asMap().entries.map((entry) {
            final index = entry.key;
            final contact = entry.value;
            return _buildContactCard(contact, index * 100);
          }),
      ],
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact, int delay) {
    return AnimatedCard(
      delay: delay,
      onTap: () {},
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: MobileTheme.primaryGradient(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.hospital,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact['veterinarian_name'],
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  contact['specialty'] ?? 'Veterinario',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (contact['phone'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Iconsax.call,
                        size: 14,
                        color: MobileTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        contact['phone'],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MobileTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Iconsax.call,
              color: MobileTheme.successColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        AnimatedCard(
          delay: 300,
          onTap: () {},
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MobileTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.notification,
                  color: MobileTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Notificaciones',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(
                Iconsax.arrow_right_3,
                color: MobileTheme.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
        AnimatedCard(
          delay: 400,
          onTap: () {},
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MobileTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.lock,
                  color: MobileTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Privacidad',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(
                Iconsax.arrow_right_3,
                color: MobileTheme.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
        AnimatedCard(
          delay: 500,
          onTap: () {},
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MobileTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.info_circle,
                  color: MobileTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Acerca de',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(
                Iconsax.arrow_right_3,
                color: MobileTheme.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: MobileTheme.errorColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: MobileTheme.errorColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
