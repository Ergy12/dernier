import 'package:flutter/material.dart';
import '../models/variable.dart';
import '../models/formula.dart';

class FormulaBuilder extends StatefulWidget {
  final List<Variable> availableVariables;
  final Formula? initialFormula;
  final Function(Formula) onFormulaSaved;

  const FormulaBuilder({
    super.key,
    required this.availableVariables,
    this.initialFormula,
    required this.onFormulaSaved,
  });

  @override
  State<FormulaBuilder> createState() => _FormulaBuilderState();
}

class _FormulaBuilderState extends State<FormulaBuilder> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _expressionController = TextEditingController();
  final _defaultExpressionController = TextEditingController();
  
  FormulaType _formulaType = FormulaType.normal;
  List<FormulaCondition> _conditions = [];
  
  late TabController _tabController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    if (widget.initialFormula != null) {
      _loadFormula(widget.initialFormula!);
    }
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _expressionController.dispose();
    _defaultExpressionController.dispose();
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadFormula(Formula formula) {
    _nameController.text = formula.name;
    _descriptionController.text = formula.description ?? '';
    _formulaType = formula.type;
    
    if (formula.type == FormulaType.normal) {
      _expressionController.text = formula.expression ?? '';
      _tabController.index = 0;
    } else {
      _conditions = List.from(formula.conditions);
      _defaultExpressionController.text = formula.defaultExpression ?? '';
      _tabController.index = 1;
    }
  }

  void _saveFormula() {
    if (!_formKey.currentState!.validate()) return;

    final formula = Formula(
      id: widget.initialFormula?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      type: _formulaType,
      expression: _formulaType == FormulaType.normal ? _expressionController.text.trim() : null,
      conditions: _formulaType == FormulaType.conditional ? _conditions : [],
      defaultExpression: _formulaType == FormulaType.conditional && _defaultExpressionController.text.trim().isNotEmpty
          ? _defaultExpressionController.text.trim()
          : null,
    );

    widget.onFormulaSaved(formula);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.initialFormula == null ? 'Nouvelle Formule' : 'Modifier Formule',
            style: theme.textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: _saveFormula,
              style: TextButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Enregistrer'),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _animationController,
              child: _buildContent(theme),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // En-tête avec informations de base
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la formule *',
                    hintText: 'Ex: indemnite_conges',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnel)',
                    hintText: 'Description de la formule',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          
          // Tabs pour type de formule
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                setState(() {
                  _formulaType = index == 0 ? FormulaType.normal : FormulaType.conditional;
                });
              },
              tabs: const [
                Tab(
                  icon: Icon(Icons.calculate_rounded),
                  text: 'Formule Simple',
                ),
                Tab(
                  icon: Icon(Icons.alt_route_rounded),
                  text: 'Formule Conditionnelle',
                ),
              ],
            ),
          ),
          
          // Contenu des tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNormalFormulaTab(theme),
                _buildConditionalFormulaTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalFormulaTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expression mathématique',
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre formule en cliquant sur les variables et opérateurs',
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          
          // Zone d\'expression
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: TextFormField(
              controller: _expressionController,
              decoration: InputDecoration(
                hintText: 'Ex: {salaire_base} * {taux_indemnite} / 100',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                border: InputBorder.none,
              ),
              maxLines: null,
              style: theme.textTheme.bodyLarge!.copyWith(
                fontFamily: 'monospace',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'L\'expression est obligatoire';
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Variables disponibles
          _buildVariableButtons(theme),
          
          const SizedBox(height: 16),
          
          // Opérateurs
          _buildOperatorButtons(theme),
        ],
      ),
    );
  }

  Widget _buildConditionalFormulaTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Conditions',
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addCondition,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Liste des conditions
          Expanded(
            child: Column(
              children: [
                if (_conditions.isEmpty)
                  _buildEmptyConditionsState(theme)
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _conditions.length,
                      itemBuilder: (context, index) {
                        return _buildConditionCard(_conditions[index], index, theme);
                      },
                    ),
                  ),
                
                // Expression par défaut
                const SizedBox(height: 16),
                Text(
                  'Expression par défaut (optionnel)',
                  style: theme.textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: TextFormField(
                    controller: _defaultExpressionController,
                    decoration: InputDecoration(
                      hintText: 'Ex: 0',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                    ),
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyConditionsState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.alt_route_rounded,
            size: 48,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune condition définie',
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des conditions SI/ALORS pour créer une formule dynamique',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionCard(FormulaCondition condition, int index, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.rule_rounded,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'SI',
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    condition.expression,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => _editCondition(index),
                  icon: Icon(
                    Icons.edit_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  onPressed: () => _removeCondition(index),
                  icon: Icon(
                    Icons.delete_rounded,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_forward_rounded,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'ALORS',
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    condition.resultExpression,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariableButtons(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Variables disponibles',
          style: theme.textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.availableVariables.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Aucune variable disponible. Créez d\'abord vos variables.',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.availableVariables.map((variable) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _insertVariable(variable.name),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      variable.name,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildOperatorButtons(ThemeData theme) {
    final arithmeticOps = ['+', '-', '*', '/', '%', '(', ')'];
    final comparisonOps = ['=', '!=', '<', '>', '<=', '>='];
    final logicalOps = ['ET', 'OU'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opérateurs',
          style: theme.textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // Opérateurs arithmétiques
        _buildOperatorSection('Arithmétiques', arithmeticOps, theme.colorScheme.onSurface, theme),
        const SizedBox(height: 8),
        
        // Opérateurs de comparaison
        _buildOperatorSection('Comparaison', comparisonOps, theme.colorScheme.tertiary, theme),
        const SizedBox(height: 8),
        
        // Opérateurs logiques
        _buildOperatorSection('Logiques', logicalOps, theme.colorScheme.secondary, theme),
      ],
    );
  }

  Widget _buildOperatorSection(String title, List<String> operators, Color color, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium!.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: operators.map((op) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _insertOperator(op),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    op,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _insertVariable(String variableName) {
    final controller = _formulaType == FormulaType.normal 
        ? _expressionController 
        : _defaultExpressionController;
    
    final text = controller.text;
    final selection = controller.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '{$variableName}',
    );
    
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + variableName.length + 2,
      ),
    );
  }

  void _insertOperator(String operator) {
    final controller = _formulaType == FormulaType.normal 
        ? _expressionController 
        : _defaultExpressionController;
    
    final text = controller.text;
    final selection = controller.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      ' $operator ',
    );
    
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + operator.length + 2,
      ),
    );
  }

  void _addCondition() {
    showDialog(
      context: context,
      builder: (context) => ConditionDialog(
        availableVariables: widget.availableVariables,
        onConditionCreated: (condition) {
          setState(() {
            _conditions.add(condition);
          });
        },
      ),
    );
  }

  void _editCondition(int index) {
    showDialog(
      context: context,
      builder: (context) => ConditionDialog(
        availableVariables: widget.availableVariables,
        initialCondition: _conditions[index],
        onConditionCreated: (condition) {
          setState(() {
            _conditions[index] = condition;
          });
        },
      ),
    );
  }

  void _removeCondition(int index) {
    setState(() {
      _conditions.removeAt(index);
    });
  }
}

class ConditionDialog extends StatefulWidget {
  final List<Variable> availableVariables;
  final FormulaCondition? initialCondition;
  final Function(FormulaCondition) onConditionCreated;

  const ConditionDialog({
    super.key,
    required this.availableVariables,
    this.initialCondition,
    required this.onConditionCreated,
  });

  @override
  State<ConditionDialog> createState() => _ConditionDialogState();
}

class _ConditionDialogState extends State<ConditionDialog> {
  final _conditionController = TextEditingController();
  final _resultController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCondition != null) {
      _conditionController.text = widget.initialCondition!.expression;
      _resultController.text = widget.initialCondition!.resultExpression;
    }
  }

  @override
  void dispose() {
    _conditionController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Condition SI/ALORS',
              style: theme.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Condition
            Text(
              'SI (condition)',
              style: theme.textTheme.titleMedium!.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: TextFormField(
                controller: _conditionController,
                decoration: InputDecoration(
                  hintText: 'Ex: {anciennete} > 5',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                ),
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Résultat
            Text(
              'ALORS (résultat)',
              style: theme.textTheme.titleMedium!.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.3),
                ),
              ),
              child: TextFormField(
                controller: _resultController,
                decoration: InputDecoration(
                  hintText: 'Ex: {salaire_base} * 1.2',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                ),
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_conditionController.text.trim().isNotEmpty &&
                        _resultController.text.trim().isNotEmpty) {
                      final condition = FormulaCondition(
                        expression: _conditionController.text.trim(),
                        resultExpression: _resultController.text.trim(),
                      );
                      widget.onConditionCreated(condition);
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('Ajouter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}