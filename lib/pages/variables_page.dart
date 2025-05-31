import 'package:flutter/material.dart';
import '../models/variable.dart';
import '../services/storage_service.dart';

class VariablesPage extends StatefulWidget {
  const VariablesPage({super.key});

  @override
  State<VariablesPage> createState() => _VariablesPageState();
}

class _VariablesPageState extends State<VariablesPage> with TickerProviderStateMixin {
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
    _loadVariables();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadVariables() async {
    final variables = await StorageService.instance.getVariables();
    setState(() {
      _variables = variables;
      _isLoading = false;
    });
    _animationController.forward();
  }

  Future<void> _deleteVariable(Variable variable) async {
    await StorageService.instance.deleteVariable(variable.id);
    await _loadVariables();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Variable "${variable.name}" supprimée'),
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
          'Variables',
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
            onPressed: _loadVariables,
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
        onPressed: () => _showVariableDialog(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle Variable'),
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
    if (_variables.isEmpty) {
      return _buildEmptyState(theme);
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animationController,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _variables.length,
            itemBuilder: (context, index) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.1,
                    1.0,
                    curve: Curves.easeOutBack,
                  ),
                )),
                child: _buildVariableCard(_variables[index], theme),
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
                Icons.data_object_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune variable définie',
              style: theme.textTheme.headlineSmall!.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre première variable pour commencer à définir vos formules de calcul',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showVariableDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Créer une variable'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariableCard(Variable variable, ThemeData theme) {
    final typeColor = _getTypeColor(variable.type, theme);
    final typeIcon = _getTypeIcon(variable.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showVariableDialog(context, variable: variable),
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
                            variable.name,
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
                              _getTypeDisplayName(variable.type),
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
                          _showVariableDialog(context, variable: variable);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(variable);
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
                if (variable.description != null && variable.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    variable.description!,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      variable.isDisplayed 
                          ? Icons.visibility_rounded 
                          : Icons.visibility_off_rounded,
                      color: variable.isDisplayed 
                          ? theme.colorScheme.secondary 
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      variable.isDisplayed 
                          ? 'Affiché dans le calcul' 
                          : 'Masqué du calcul',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: variable.isDisplayed 
                            ? theme.colorScheme.secondary 
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (variable.type == VariableType.choice && variable.choices.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: variable.choices.take(3).map((choice) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          choice,
                          style: theme.textTheme.labelSmall!.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (variable.choices.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${variable.choices.length - 3} autres choix',
                        style: theme.textTheme.labelSmall!.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(VariableType type, ThemeData theme) {
    switch (type) {
      case VariableType.number:
        return theme.colorScheme.primary;
      case VariableType.string:
        return theme.colorScheme.secondary;
      case VariableType.boolean:
        return theme.colorScheme.tertiary;
      case VariableType.choice:
        return const Color(0xFF9C27B0);
    }
  }

  IconData _getTypeIcon(VariableType type) {
    switch (type) {
      case VariableType.number:
        return Icons.numbers_rounded;
      case VariableType.string:
        return Icons.text_fields_rounded;
      case VariableType.boolean:
        return Icons.toggle_on_rounded;
      case VariableType.choice:
        return Icons.list_rounded;
    }
  }

  String _getTypeDisplayName(VariableType type) {
    switch (type) {
      case VariableType.number:
        return 'Nombre';
      case VariableType.string:
        return 'Texte';
      case VariableType.boolean:
        return 'Booléen';
      case VariableType.choice:
        return 'Choix';
    }
  }

  void _showDeleteConfirmation(Variable variable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la variable'),
        content: Text('Êtes-vous sûr de vouloir supprimer la variable "${variable.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteVariable(variable);
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

  void _showVariableDialog(BuildContext context, {Variable? variable}) {
    showDialog(
      context: context,
      builder: (context) => VariableDialog(
        variable: variable,
        onSaved: () async {
          await _loadVariables();
        },
      ),
    );
  }
}

class VariableDialog extends StatefulWidget {
  final Variable? variable;
  final VoidCallback onSaved;

  const VariableDialog({
    super.key,
    this.variable,
    required this.onSaved,
  });

  @override
  State<VariableDialog> createState() => _VariableDialogState();
}

class _VariableDialogState extends State<VariableDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _defaultValueController = TextEditingController();
  final _choiceController = TextEditingController();
  
  VariableType _selectedType = VariableType.number;
  bool _isDisplayed = true;
  List<String> _choices = [];

  @override
  void initState() {
    super.initState();
    if (widget.variable != null) {
      _nameController.text = widget.variable!.name;
      _descriptionController.text = widget.variable!.description ?? '';
      _displayNameController.text = widget.variable!.displayName;
      _defaultValueController.text = widget.variable!.defaultValue?.toString() ?? '';
      _selectedType = widget.variable!.type;
      _isDisplayed = widget.variable!.isDisplayed;
      _choices = List.from(widget.variable!.choices);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _displayNameController.dispose();
    _defaultValueController.dispose();
    _choiceController.dispose();
    super.dispose();
  }

  Future<void> _saveVariable() async {
    if (!_formKey.currentState!.validate()) return;

    dynamic defaultValue;
    switch (_selectedType) {
      case VariableType.number:
        defaultValue = double.tryParse(_defaultValueController.text) ?? 0.0;
        break;
      case VariableType.boolean:
        defaultValue = _defaultValueController.text.toLowerCase() == 'true';
        break;
      case VariableType.choice:
        defaultValue = _choices.isNotEmpty ? _choices.first : '';
        break;
      case VariableType.string:
        defaultValue = _defaultValueController.text;
        break;
    }

    final variable = Variable(
      id: widget.variable?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      type: _selectedType,
      defaultValue: defaultValue,
      choices: _choices,
      isDisplayed: _isDisplayed,
      displayName: _displayNameController.text.trim().isEmpty 
          ? _nameController.text.trim()
          : _displayNameController.text.trim(),
    );

    if (widget.variable == null) {
      await StorageService.instance.addVariable(variable);
    } else {
      await StorageService.instance.updateVariable(variable);
    }

    widget.onSaved();
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.variable == null 
              ? 'Variable créée avec succès' 
              : 'Variable modifiée avec succès'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.variable == null ? 'Nouvelle Variable' : 'Modifier Variable',
                style: theme.textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom de la variable *',
                          hintText: 'Ex: salaire_base',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom est obligatoire';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom d\'affichage',
                          hintText: 'Ex: Salaire de base',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (optionnel)',
                          hintText: 'Description de la variable',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<VariableType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type de variable *',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                            _defaultValueController.clear();
                            _choices.clear();
                          });
                        },
                        items: VariableType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(_getTypeIcon(type), size: 20),
                                const SizedBox(width: 8),
                                Text(_getTypeDisplayName(type)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedType == VariableType.choice) ...[
                        _buildChoicesSection(theme),
                        const SizedBox(height: 16),
                      ] else ...[
                        TextFormField(
                          controller: _defaultValueController,
                          decoration: InputDecoration(
                            labelText: 'Valeur par défaut',
                            hintText: _getDefaultValueHint(_selectedType),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: _selectedType == VariableType.number 
                              ? TextInputType.number 
                              : TextInputType.text,
                        ),
                        const SizedBox(height: 16),
                      ],
                      SwitchListTile(
                        title: const Text('Afficher dans l\'interface de calcul'),
                        subtitle: const Text('La variable sera visible lors du calcul'),
                        value: _isDisplayed,
                        onChanged: (value) {
                          setState(() {
                            _isDisplayed = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
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
                    onPressed: _saveVariable,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: Text(widget.variable == null ? 'Créer' : 'Modifier'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoicesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _choiceController,
                decoration: const InputDecoration(
                  labelText: 'Ajouter un choix',
                  hintText: 'Ex: Célibataire',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (_) => _addChoice(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addChoice,
              icon: Icon(Icons.add_rounded, color: theme.colorScheme.primary),
            ),
          ],
        ),
        if (_choices.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _choices.map((choice) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                      child: Text(
                        choice,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      onPressed: () => _removeChoice(choice),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _addChoice() {
    final choice = _choiceController.text.trim();
    if (choice.isNotEmpty && !_choices.contains(choice)) {
      setState(() {
        _choices.add(choice);
        _choiceController.clear();
      });
    }
  }

  void _removeChoice(String choice) {
    setState(() {
      _choices.remove(choice);
    });
  }

  String _getDefaultValueHint(VariableType type) {
    switch (type) {
      case VariableType.number:
        return 'Ex: 1500.50';
      case VariableType.string:
        return 'Ex: Valeur par défaut';
      case VariableType.boolean:
        return 'true ou false';
      case VariableType.choice:
        return '';
    }
  }

  Color _getTypeColor(VariableType type, ThemeData theme) {
    switch (type) {
      case VariableType.number:
        return theme.colorScheme.primary;
      case VariableType.string:
        return theme.colorScheme.secondary;
      case VariableType.boolean:
        return theme.colorScheme.tertiary;
      case VariableType.choice:
        return const Color(0xFF9C27B0);
    }
  }

  IconData _getTypeIcon(VariableType type) {
    switch (type) {
      case VariableType.number:
        return Icons.numbers_rounded;
      case VariableType.string:
        return Icons.text_fields_rounded;
      case VariableType.boolean:
        return Icons.toggle_on_rounded;
      case VariableType.choice:
        return Icons.list_rounded;
    }
  }

  String _getTypeDisplayName(VariableType type) {
    switch (type) {
      case VariableType.number:
        return 'Nombre';
      case VariableType.string:
        return 'Texte';
      case VariableType.boolean:
        return 'Booléen';
      case VariableType.choice:
        return 'Choix';
    }
  }
}