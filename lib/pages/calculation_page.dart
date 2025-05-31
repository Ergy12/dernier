import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/variable.dart';
import '../models/formula.dart';
import '../services/storage_service.dart';
import '../services/calculation_service.dart';

class CalculationPage extends StatefulWidget {
  const CalculationPage({super.key});

  @override
  State<CalculationPage> createState() => _CalculationPageState();
}

class _CalculationPageState extends State<CalculationPage> with TickerProviderStateMixin {
  List<Variable> _variables = [];
  List<Formula> _formulas = [];
  Map<String, dynamic> _inputValues = {};
  Map<String, dynamic> _results = {};
  bool _isLoading = true;
  bool _isCalculating = false;
  
  late AnimationController _animationController;
  late AnimationController _resultAnimationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _resultAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _resultAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final variables = await StorageService.instance.getVariables();
    final formulas = await StorageService.instance.getFormulas();
    final savedValues = await StorageService.instance.getCalculationValues();
    
    setState(() {
      _variables = variables.where((v) => v.isDisplayed).toList();
      _formulas = formulas;
      _inputValues = savedValues;
      _isLoading = false;
    });
    
    // Initialiser les valeurs par défaut
    for (final variable in _variables) {
      if (!_inputValues.containsKey(variable.name) && variable.defaultValue != null) {
        _inputValues[variable.name] = variable.defaultValue;
      }
    }
    
    _animationController.forward();
    _calculateResults();
  }

  Future<void> _calculateResults() async {
    if (_formulas.isEmpty) return;

    setState(() {
      _isCalculating = true;
    });

    await Future.delayed(const Duration(milliseconds: 200)); // Animation

    try {
      final results = CalculationService.instance.calculateAllResults(
        _formulas,
        _inputValues,
      );
      
      setState(() {
        _results = results;
        _isCalculating = false;
      });
      
      _resultAnimationController.forward();
      
      // Sauvegarder les valeurs
      await StorageService.instance.saveCalculationValues(_inputValues);
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de calcul: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _exportToPdf() async {
    final settings = await StorageService.instance.getSettings();
    
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              pw.Header(
                level: 0,
                child: pw.Text(
                  settings['pdfTitle'] ?? 'Décompte Final Employé',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              pw.Text(
                'Date: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              
              pw.SizedBox(height: 30),
              
              // Entrées
              if (settings['showInputs'] == true) ...[
                pw.Text(
                  'VALEURS D\'ENTRÉE',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Variable',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Valeur',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ..._variables.map((variable) {
                      final value = _inputValues[variable.name];
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(variable.displayName),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              variable.getDisplayValue(value),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 30),
              ],
              
              // Résultats
              if (settings['showResults'] == true) ...[
                pw.Text(
                  'RÉSULTATS DE CALCUL',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Formule',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Résultat',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ..._formulas.map((formula) {
                      final result = _results[formula.name];
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(formula.name),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              result?.toString() ?? '0',
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
              
              // Formules
              if (settings['showFormulas'] == true) ...[
                pw.SizedBox(height: 30),
                pw.Text(
                  'FORMULES UTILISÉES',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ..._formulas.map((formula) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 10),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          formula.name,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          formula.getDisplayExpression(),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Calcul',
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
            onPressed: _results.isNotEmpty ? _exportToPdf : null,
            icon: Icon(
              Icons.picture_as_pdf_rounded,
              color: _results.isNotEmpty 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            tooltip: 'Exporter en PDF',
          ),
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
    if (_variables.isEmpty && _formulas.isEmpty) {
      return _buildEmptyState(theme);
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animationController,
          child: CustomScrollView(
            slivers: [
              // Section des entrées
              if (_variables.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildInputSection(theme),
                  ),
                ),
              ],
              
              // Section des résultats
              if (_formulas.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildResultsSection(theme),
                  ),
                ),
              ],
              
              // Espace en bas
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
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
                Icons.calculate_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune donnée à calculer',
              style: theme.textTheme.headlineSmall!.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez d\'abord vos variables et formules pour commencer les calculs',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.input_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Valeurs d\'entrée',
              style: theme.textTheme.titleLarge!.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        ..._variables.asMap().entries.map((entry) {
          final index = entry.key;
          final variable = entry.value;
          
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                index * 0.1,
                1.0,
                curve: Curves.easeOutBack,
              ),
            )),
            child: _buildInputField(variable, theme),
          );
        }),
      ],
    );
  }

  Widget _buildInputField(Variable variable, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            variable.displayName,
            style: theme.textTheme.titleMedium!.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (variable.description != null && variable.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              variable.description!,
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
          const SizedBox(height: 8),
          
          if (variable.type == VariableType.choice)
            _buildChoiceField(variable, theme)
          else if (variable.type == VariableType.boolean)
            _buildBooleanField(variable, theme)
          else
            _buildTextField(variable, theme),
        ],
      ),
    );
  }

  Widget _buildTextField(Variable variable, ThemeData theme) {
    return TextFormField(
      initialValue: _inputValues[variable.name]?.toString() ?? '',
      decoration: InputDecoration(
        hintText: variable.type == VariableType.number 
            ? 'Entrez un nombre'
            : 'Entrez du texte',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(
          variable.type == VariableType.number 
              ? Icons.numbers_rounded
              : Icons.text_fields_rounded,
          color: theme.colorScheme.primary,
        ),
      ),
      keyboardType: variable.type == VariableType.number 
          ? TextInputType.number
          : TextInputType.text,
      onChanged: (value) {
        setState(() {
          _inputValues[variable.name] = variable.parseValue(value);
        });
        _calculateResults();
      },
    );
  }

  Widget _buildChoiceField(Variable variable, ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _inputValues[variable.name]?.toString(),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(
          Icons.list_rounded,
          color: theme.colorScheme.primary,
        ),
      ),
      hint: const Text('Sélectionnez une option'),
      items: variable.choices.map((choice) {
        return DropdownMenuItem(
          value: choice,
          child: Text(choice),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _inputValues[variable.name] = value;
        });
        _calculateResults();
      },
    );
  }

  Widget _buildBooleanField(Variable variable, ThemeData theme) {
    final value = _inputValues[variable.name] as bool? ?? false;
    
    return SwitchListTile(
      title: Text(value ? 'Oui' : 'Non'),
      value: value,
      onChanged: (newValue) {
        setState(() {
          _inputValues[variable.name] = newValue;
        });
        _calculateResults();
      },
      contentPadding: EdgeInsets.zero,
      activeColor: theme.colorScheme.primary,
    );
  }

  Widget _buildResultsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(
          children: [
            Icon(
              Icons.analytics_rounded,
              color: theme.colorScheme.secondary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Résultats',
              style: theme.textTheme.titleLarge!.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isCalculating) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        
        if (_results.isEmpty && !_isCalculating)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.pending_actions_rounded,
                  size: 48,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'En attente de calcul',
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Remplissez les champs ci-dessus pour voir les résultats',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          )
        else
          AnimatedBuilder(
            animation: _resultAnimationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _resultAnimationController,
                child: Column(
                  children: _formulas.asMap().entries.map((entry) {
                    final index = entry.key;
                    final formula = entry.value;
                    final result = _results[formula.name];
                    
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _resultAnimationController,
                        curve: Interval(
                          index * 0.1,
                          1.0,
                          curve: Curves.easeOutBack,
                        ),
                      )),
                      child: _buildResultCard(formula, result, theme),
                    );
                  }).toList(),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildResultCard(Formula formula, dynamic result, ThemeData theme) {
    final isPositive = result is num && result > 0;
    final resultColor = isPositive 
        ? theme.colorScheme.secondary
        : theme.colorScheme.error;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: resultColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: resultColor.withOpacity(0.1),
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
                  color: resultColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  formula.type == FormulaType.normal
                      ? Icons.calculate_rounded
                      : Icons.alt_route_rounded,
                  color: resultColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  formula.name,
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result is num 
                      ? result.toStringAsFixed(2)
                      : result.toString(),
                  style: theme.textTheme.titleLarge!.copyWith(
                    color: resultColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          if (formula.description != null && formula.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              formula.description!,
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              formula.getDisplayExpression(),
              style: theme.textTheme.bodySmall!.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}