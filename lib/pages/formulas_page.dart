import 'package:flutter/material.dart';
import '../models/formula.dart';
import '../models/variable.dart';
import '../services/storage_service.dart';
import '../widgets/formula_builder.dart';

class FormulasPage extends StatefulWidget {
  const FormulasPage({super.key});

  @override
  State<FormulasPage> createState() => _FormulasPageState();
}

class _FormulasPageState extends State<FormulasPage> with TickerProviderStateMixin {
  List<Formula> _formulas = [];
  List<Variable> _variables = [];
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final formulas = await StorageService.instance.getFormulas();
    final variables = await StorageService.instance.getVariables();
    setState(() {
      _formulas = formulas;
      _variables = variables;
      _isLoading = false;
    });
    _animationController.forward();
  }

  Future<void> _deleteFormula(Formula formula) async {
    await StorageService.instance.deleteFormula(formula.id);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Formule "${formula.name}" supprimée'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Formules',
          style: theme.textTheme.titleLarge!.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: Icon(
              Icons.refresh_rounded,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: _isLoading 
          ? _buildLoadingState(theme)
          : _buildContent(theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormulaBuilder(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle Formule'),
      ),
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
    if (_formulas.isEmpty) {
      return _buildEmptyState(theme);
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animationController,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _formulas.length,
            itemBuilder: (context, index) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.1,
                    1.0,
                    curve: Curves.easeOutBack,
                  ),
                )),
                child: _buildFormulaCard(_formulas[index], theme),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.functions_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune formule définie',
              style: theme.textTheme.headlineSmall!.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre première formule pour automatiser vos calculs de décompte final',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            if (_variables.isEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.tertiary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: theme.colorScheme.tertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vous devez d\'abord créer des variables avant de pouvoir créer des formules.',
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _variables.isNotEmpty 
                  ? () => _showFormulaBuilder(context)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Créer une formule'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulaCard(Formula formula, ThemeData theme) {
    final typeColor = _getTypeColor(formula.type, theme);
    final typeIcon = _getTypeIcon(formula.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFormulaBuilder(context, formula: formula),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: typeColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: typeColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        typeIcon,
                        color: typeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formula.name,
                            style: theme.textTheme.titleMedium!.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getTypeDisplayName(formula.type),
                              style: theme.textTheme.labelSmall!.copyWith(
                                color: typeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showFormulaBuilder(context, formula: formula);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(formula);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, 
                                   color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              const Text('Modifier'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded, 
                                   color: theme.colorScheme.error, size: 20),
                              const SizedBox(width: 8),
                              const Text('Supprimer'),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                
                if (formula.description != null && formula.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    formula.description!,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
                
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    _getFormulaPreview(formula),
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      color: theme.colorScheme.secondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Variables utilisées: ',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _getUsedVariablesText(formula),
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                if (formula.type == FormulaType.conditional) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.rule_rounded,
                        color: theme.colorScheme.tertiary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${formula.conditions.length} condition${formula.conditions.length > 1 ? 's' : ''}',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(FormulaType type, ThemeData theme) {
    switch (type) {
      case FormulaType.normal:
        return theme.colorScheme.primary;
      case FormulaType.conditional:
        return theme.colorScheme.secondary;
    }
  }

  IconData _getTypeIcon(FormulaType type) {
    switch (type) {
      case FormulaType.normal:
        return Icons.calculate_rounded;
      case FormulaType.conditional:
        return Icons.alt_route_rounded;
    }
  }

  String _getTypeDisplayName(FormulaType type) {
    switch (type) {
      case FormulaType.normal:
        return 'Simple';
      case FormulaType.conditional:
        return 'Conditionnelle';
    }
  }

  String _getFormulaPreview(Formula formula) {
    switch (formula.type) {
      case FormulaType.normal:
        return formula.expression ?? '';
      case FormulaType.conditional:
        if (formula.conditions.isEmpty) return 'Aucune condition définie';
        final firstCondition = formula.conditions.first;
        return 'SI ${firstCondition.expression} ALORS ${firstCondition.resultExpression}';
    }
  }

  String _getUsedVariablesText(Formula formula) {
    final usedVariables = formula.getUsedVariables();
    if (usedVariables.isEmpty) return 'Aucune';
    if (usedVariables.length <= 3) {
      return usedVariables.join(', ');
    }
    return '${usedVariables.take(3).join(', ')} (+${usedVariables.length - 3})';
  }

  void _showDeleteConfirmation(Formula formula) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la formule'),
        content: Text('Êtes-vous sûr de vouloir supprimer la formule "${formula.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteFormula(formula);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showFormulaBuilder(BuildContext context, {Formula? formula}) {
    // Combine regular variables with variables derived from other formulas
    List<Variable> allAvailableVariables = List.from(_variables);

    for (final existingFormula in _formulas) {
      // Avoid adding the formula being edited as a variable to itself
      if (formula != null && existingFormula.id == formula.id) {
        continue;
      }
      allAvailableVariables.add(
        Variable(
          id: 'formula_${existingFormula.name}', // Ensure unique ID, prefix with 'formula_'
          name: existingFormula.name,
          type: VariableType.result,
          displayName: existingFormula.name,
          description: 'Résultat de la formule "${existingFormula.name}"',
          isDisplayed: true, // Should be displayed as a selectable chip
          // defaultValue and choices are not applicable for VariableType.result
        ),
      );
    }

    // Prevent opening builder if there are no input variables to build a formula
    // Formula results alone are not sufficient to build new formulas without other inputs.
    if (_variables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vous devez d\'abord créer des variables de type nombre, texte etc.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => FormulaBuilder(
        availableVariables: allAvailableVariables, // Pass the augmented list
        initialFormula: formula,
        onFormulaSaved: (savedFormula) async {
          if (formula == null) {
            await StorageService.instance.addFormula(savedFormula);
          } else {
            await StorageService.instance.updateFormula(savedFormula);
          }
          
          await _loadData();
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(formula == null 
                    ? 'Formule créée avec succès' 
                    : 'Formule modifiée avec succès'),
              ),
            );
          }
        },
      ),
    );
  }
}