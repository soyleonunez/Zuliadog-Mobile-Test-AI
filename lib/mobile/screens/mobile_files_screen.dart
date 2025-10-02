import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:zuliadog/mobile/core/mobile_theme.dart';
import 'package:zuliadog/mobile/widgets/animated_card.dart';
import 'package:zuliadog/mobile/widgets/shimmer_loading.dart';
import 'package:zuliadog/mobile/services/mobile_data_service.dart';

class MobileFilesScreen extends StatefulWidget {
  const MobileFilesScreen({super.key});

  @override
  State<MobileFilesScreen> createState() => _MobileFilesScreenState();
}

class _MobileFilesScreenState extends State<MobileFilesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _files = [];
  String _selectedFilter = 'todos';
  final String _ownerId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await MobileDataService.getAllMedicalFilesByOwner(_ownerId);
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading files: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredFiles {
    if (_selectedFilter == 'todos') return _files;
    return _files
        .where((file) => file['file_type'] == _selectedFilter)
        .toList();
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
                  _buildFilterChips(),
                  const SizedBox(height: 20),
                  _buildStats(),
                  const SizedBox(height: 24),
                  _buildFilesList(),
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
      title: const Text('Archivos'),
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
          'Documentos médicos',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Todos los archivos de tus mascotas',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'id': 'todos', 'label': 'Todos'},
      {'id': 'vacuna', 'label': 'Vacunas'},
      {'id': 'receta', 'label': 'Recetas'},
      {'id': 'análisis', 'label': 'Análisis'},
      {'id': 'certificado', 'label': 'Certificados'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label']!),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedFilter = filter['id']!);
              },
              backgroundColor: MobileTheme.surfaceColor,
              selectedColor: MobileTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : MobileTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? MobileTheme.primaryColor
                      : MobileTheme.dividerColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStats() {
    if (_isLoading) {
      return ShimmerLoading(
        width: double.infinity,
        height: 80,
        borderRadius: BorderRadius.circular(16),
      );
    }

    final filesByType = <String, int>{};
    for (var file in _files) {
      final type = file['file_type'] ?? 'otro';
      filesByType[type] = (filesByType[type] ?? 0) + 1;
    }

    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: MobileTheme.primaryGradient(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.folder_2,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_files.length} archivos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Total almacenado',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          if (filesByType.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filesByType.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MobileTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MobileTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    if (_isLoading) {
      return Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerLoading(
              width: double.infinity,
              height: 90,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    final filteredFiles = _filteredFiles;

    if (filteredFiles.isEmpty) {
      return AnimatedCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Iconsax.document,
                  size: 64,
                  color: MobileTheme.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay archivos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Los archivos aparecerán aquí',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedFilter == 'todos'
              ? 'Todos los archivos'
              : _selectedFilter.capitalize(),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ...filteredFiles.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;
          return _buildFileCard(file, index * 100);
        }),
      ],
    );
  }

  Widget _buildFileCard(Map<String, dynamic> file, int delay) {
    final uploadDate = DateTime.parse(file['upload_date']);
    final petData = file['pets'] as Map<String, dynamic>?;
    final petName = petData?['name'] ?? 'Mascota';
    final fileType = file['file_type'] ?? 'archivo';

    return AnimatedCard(
      delay: delay,
      onTap: () {},
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getFileTypeColor(fileType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getFileTypeIcon(fileType),
              color: _getFileTypeColor(fileType),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file['file_name'],
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                      DateFormat('d MMM yyyy', 'es').format(uploadDate),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 12),
                    if (file['file_size'] != null) ...[
                      Icon(
                        Iconsax.document,
                        size: 14,
                        color: MobileTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatFileSize(file['file_size']),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MobileTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Iconsax.arrow_down,
              color: MobileTheme.primaryColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'vacuna':
        return Iconsax.health;
      case 'receta':
        return Iconsax.note_1;
      case 'análisis':
        return Iconsax.document_text;
      case 'certificado':
        return Iconsax.award;
      default:
        return Iconsax.document;
    }
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'vacuna':
        return MobileTheme.successColor;
      case 'receta':
        return MobileTheme.primaryColor;
      case 'análisis':
        return MobileTheme.warningColor;
      case 'certificado':
        return MobileTheme.accentColor;
      default:
        return MobileTheme.textSecondary;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
