import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:zuliadog/mobile/core/mobile_theme.dart';
import 'package:zuliadog/mobile/widgets/animated_card.dart';
import 'package:zuliadog/mobile/widgets/shimmer_loading.dart';
import 'package:zuliadog/mobile/services/mobile_data_service.dart';
import 'package:zuliadog/mobile/screens/mobile_pet_detail_screen.dart';

class MobilePetsScreen extends StatefulWidget {
  const MobilePetsScreen({super.key});

  @override
  State<MobilePetsScreen> createState() => _MobilePetsScreenState();
}

class _MobilePetsScreenState extends State<MobilePetsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pets = [];
  final String _ownerId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);
    try {
      final pets = await MobileDataService.getPetsByOwner(_ownerId);
      setState(() {
        _pets = pets;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pets: $e');
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
                  _buildTitle(),
                  const SizedBox(height: 20),
                  _buildPetsCarousel(),
                  const SizedBox(height: 32),
                  _buildPetsList(),
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
      title: const Text('Mis Mascotas'),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.search_normal_1, size: 24),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tus compañeros',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gestiona toda la información de tus mascotas',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildPetsCarousel() {
    if (_isLoading) {
      return SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(right: index < 2 ? 16 : 0),
              child: ShimmerLoading(
                width: 160,
                height: 200,
                borderRadius: BorderRadius.circular(20),
              ),
            );
          },
        ),
      );
    }

    if (_pets.isEmpty) {
      return AnimatedCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Iconsax.pet,
                  size: 64,
                  color: MobileTheme.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No tienes mascotas registradas',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pets.length,
        itemBuilder: (context, index) {
          final pet = _pets[index];
          return Padding(
            padding: EdgeInsets.only(right: index < _pets.length - 1 ? 16 : 0),
            child: _buildPetCarouselCard(pet, index * 100),
          );
        },
      ),
    );
  }

  Widget _buildPetCarouselCard(Map<String, dynamic> pet, int delay) {
    final photoUrl = pet['photo_url'];
    final speciesIcon = _getSpeciesIcon(pet['species']);

    return AnimatedCard(
      delay: delay,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MobilePetDetailScreen(petId: pet['id']),
          ),
        );
      },
      padding: EdgeInsets.zero,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: MobileTheme.primaryGradient(),
        ),
        child: Stack(
          children: [
            if (photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  photoUrl,
                  width: 160,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildDefaultPetImage(speciesIcon),
                ),
              )
            else
              _buildDefaultPetImage(speciesIcon),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pet['breed'] ?? pet['species'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  speciesIcon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultPetImage(IconData icon) {
    return Container(
      width: 160,
      height: 220,
      decoration: BoxDecoration(
        gradient: MobileTheme.primaryGradient(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPetsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Todos',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          Column(
            children: List.generate(
              3,
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
        else
          ..._pets.asMap().entries.map((entry) {
            final index = entry.key;
            final pet = entry.value;
            return _buildPetListCard(pet, 300 + (index * 100));
          }),
      ],
    );
  }

  Widget _buildPetListCard(Map<String, dynamic> pet, int delay) {
    final photoUrl = pet['photo_url'];
    final speciesIcon = _getSpeciesIcon(pet['species']);
    final birthDate = pet['birth_date'] != null
        ? DateTime.parse(pet['birth_date'])
        : null;
    final age = birthDate != null
        ? _calculateAge(birthDate)
        : null;

    return AnimatedCard(
      delay: delay,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MobilePetDetailScreen(petId: pet['id']),
          ),
        );
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: photoUrl != null
                ? Image.network(
                    photoUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultAvatar(speciesIcon),
                  )
                : _buildDefaultAvatar(speciesIcon),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet['name'],
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  pet['breed'] ?? pet['species'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (age != null) ...[
                      Icon(
                        Iconsax.cake,
                        size: 14,
                        color: MobileTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        age,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (pet['weight'] != null) ...[
                      Icon(
                        Iconsax.weight,
                        size: 14,
                        color: MobileTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${pet['weight']} kg',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Iconsax.arrow_right_3,
            color: MobileTheme.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(IconData icon) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: MobileTheme.primaryGradient(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  IconData _getSpeciesIcon(String? species) {
    switch (species?.toLowerCase()) {
      case 'dog':
        return Iconsax.pet;
      case 'cat':
        return Iconsax.heart;
      default:
        return Iconsax.heart;
    }
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
}
