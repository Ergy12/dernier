import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/storage_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await StorageService.instance.getSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
    _animationController.forward();
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    setState(() {
      _settings[key] = value;
    });
    await StorageService.instance.saveSettings(_settings);
  }

  Future<void> _exportData() async {
    try {
      final data = await StorageService.instance.exportData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      // Pour la démo, on affiche juste un message
      // Dans une vraie app, vous utiliseriez file_picker pour sauvegarder
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export réussi'),
            content: const Text('Les données ont été exportées avec succès.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import de données'),
          content: const Text('Cette fonctionnalité sera disponible dans une prochaine version.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer toutes les données'),
        content: const Text(
          'Cette action supprimera définitivement toutes vos variables, formules et paramètres. Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.instance.clearAllData();
      await _loadSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes les données ont été effacées.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: theme.textTheme.titleLarge!.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
          ? _buildLoadingState(theme)
          : _buildContent(theme),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: CircularProgressIndicator(
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animationController,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                'Export PDF',
                Icons.picture_as_pdf_rounded,
                theme.colorScheme.primary,
                [
                  _buildTextFieldSetting(
                    'Titre du document',
                    'pdfTitle',
                    'Décompte Final Employé',
                    Icons.title_rounded,
                    theme,
                  ),
                  _buildSwitchSetting(
                    'Afficher les entrées',
                    'showInputs',
                    'Inclure les valeurs saisies dans le PDF',
                    Icons.input_rounded,
                    theme,
                  ),
                  _buildSwitchSetting(
                    'Afficher les résultats',
                    'showResults',
                    'Inclure les résultats de calcul dans le PDF',
                    Icons.analytics_rounded,
                    theme,
                  ),
                  _buildSwitchSetting(
                    'Afficher les formules',
                    'showFormulas',
                    'Inclure les formules utilisées dans le PDF',
                    Icons.functions_rounded,
                    theme,
                  ),
                  _buildSwitchSetting(
                    'Afficher les descriptions',
                    'showDescriptions',
                    'Inclure les descriptions des variables et formules',
                    Icons.description_rounded,
                    theme,
                  ),
                ],
                theme,
              ),
              
              const SizedBox(height: 24),
              
              _buildSection(
                'Sauvegarde & Restauration',
                Icons.backup_rounded,
                theme.colorScheme.secondary,
                [
                  _buildActionTile(
                    'Exporter les données',
                    'Sauvegarder vos variables et formules',
                    Icons.download_rounded,
                    theme.colorScheme.secondary,
                    _exportData,
                    theme,
                  ),
                  _buildActionTile(
                    'Importer les données',
                    'Restaurer à partir d\'un fichier de sauvegarde',
                    Icons.upload_rounded,
                    theme.colorScheme.secondary,
                    _importData,
                    theme,
                  ),
                ],
                theme,
              ),
              
              const SizedBox(height: 24),
              
              _buildSection(
                'Données',
                Icons.storage_rounded,
                theme.colorScheme.tertiary,
                [
                  _buildActionTile(
                    'Effacer toutes les données',
                    'Supprimer définitivement toutes les variables et formules',
                    Icons.delete_forever_rounded,
                    theme.colorScheme.error,
                    _clearAllData,
                    theme,
                  ),
                ],
                theme,
              ),
              
              const SizedBox(height: 24),
              
              _buildSection(
                'À propos',
                Icons.info_outline_rounded,
                theme.colorScheme.outline,
                [
                  _buildInfoTile(
                    'Version',
                    '1.0.0',
                    Icons.tag_rounded,
                    theme,
                  ),
                  _buildInfoTile(
                    'Développé avec',
                    'Flutter & Dart',
                    Icons.flutter_dash_rounded,
                    theme,
                  ),
                ],
                theme,
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.titleLarge!.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              
              return Container(
                decoration: BoxDecoration(
                  border: index < children.length - 1
                      ? Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                          ),
                        )
                      : null,
                ),
                child: child,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String key,
    String subtitle,
    IconData icon,
    ThemeData theme,
  ) {
    final value = _settings[key] as bool? ?? true;
    
    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall!.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: (newValue) => _updateSetting(key, newValue),
        activeColor: theme.colorScheme.primary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildTextFieldSetting(
    String title,
    String key,
    String defaultValue,
    IconData icon,
    ThemeData theme,
  ) {
    final controller = TextEditingController(
      text: _settings[key]?.toString() ?? defaultValue,
    );
    
    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          onChanged: (value) => _updateSetting(key, value),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall!.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: color,
        size: 16,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildInfoTile(
    String title,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.outline,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Text(
        value,
        style: theme.textTheme.bodyMedium!.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}