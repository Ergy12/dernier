import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/variable.dart';
import '../models/formula.dart';

class StorageService {
  static const String _variablesKey = 'variables';
  static const String _formulasKey = 'formulas';
  static const String _settingsKey = 'settings';
  static const String _calculationValuesKey = 'calculation_values';

  static StorageService? _instance;
  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }
  
  StorageService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Variables
  Future<List<Variable>> getVariables() async {
    await init();
    final String? variablesJson = _prefs!.getString(_variablesKey);
    if (variablesJson == null) return [];
    
    final List<dynamic> variablesList = json.decode(variablesJson);
    return variablesList.map((json) => Variable.fromJson(json)).toList();
  }

  Future<void> saveVariables(List<Variable> variables) async {
    await init();
    final String variablesJson = json.encode(variables.map((v) => v.toJson()).toList());
    await _prefs!.setString(_variablesKey, variablesJson);
  }

  Future<void> addVariable(Variable variable) async {
    final variables = await getVariables();
    variables.add(variable);
    await saveVariables(variables);
  }

  Future<void> updateVariable(Variable variable) async {
    final variables = await getVariables();
    final index = variables.indexWhere((v) => v.id == variable.id);
    if (index != -1) {
      variables[index] = variable;
      await saveVariables(variables);
    }
  }

  Future<void> deleteVariable(String variableId) async {
    final variables = await getVariables();
    variables.removeWhere((v) => v.id == variableId);
    await saveVariables(variables);
  }

  Future<Variable?> getVariable(String id) async {
    final variables = await getVariables();
    try {
      return variables.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  // Formulas
  Future<List<Formula>> getFormulas() async {
    await init();
    final String? formulasJson = _prefs!.getString(_formulasKey);
    if (formulasJson == null) return [];
    
    final List<dynamic> formulasList = json.decode(formulasJson);
    return formulasList.map((json) => Formula.fromJson(json)).toList();
  }

  Future<void> saveFormulas(List<Formula> formulas) async {
    await init();
    final String formulasJson = json.encode(formulas.map((f) => f.toJson()).toList());
    await _prefs!.setString(_formulasKey, formulasJson);
  }

  Future<void> addFormula(Formula formula) async {
    final formulas = await getFormulas();
    formulas.add(formula);
    await saveFormulas(formulas);
  }

  Future<void> updateFormula(Formula formula) async {
    final formulas = await getFormulas();
    final index = formulas.indexWhere((f) => f.id == formula.id);
    if (index != -1) {
      formulas[index] = formula;
      await saveFormulas(formulas);
    }
  }

  Future<void> deleteFormula(String formulaId) async {
    final formulas = await getFormulas();
    formulas.removeWhere((f) => f.id == formulaId);
    await saveFormulas(formulas);
  }

  Future<Formula?> getFormula(String id) async {
    final formulas = await getFormulas();
    try {
      return formulas.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  // Settings
  Future<Map<String, dynamic>> getSettings() async {
    await init();
    final String? settingsJson = _prefs!.getString(_settingsKey);
    if (settingsJson == null) {
      return {
        'showInputs': true,
        'showResults': true,
        'showFormulas': true,
        'showDescriptions': true,
        'pdfTitle': 'Décompte Final Employé',
      };
    }
    return json.decode(settingsJson);
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await init();
    final String settingsJson = json.encode(settings);
    await _prefs!.setString(_settingsKey, settingsJson);
  }

  // Calculation Values
  Future<Map<String, dynamic>> getCalculationValues() async {
    await init();
    final String? valuesJson = _prefs!.getString(_calculationValuesKey);
    if (valuesJson == null) return {};
    return json.decode(valuesJson);
  }

  Future<void> saveCalculationValues(Map<String, dynamic> values) async {
    await init();
    final String valuesJson = json.encode(values);
    await _prefs!.setString(_calculationValuesKey, valuesJson);
  }

  Future<void> clearCalculationValues() async {
    await init();
    await _prefs!.remove(_calculationValuesKey);
  }

  // Utility methods
  Future<void> clearAllData() async {
    await init();
    await _prefs!.clear();
  }

  Future<bool> hasData() async {
    final variables = await getVariables();
    final formulas = await getFormulas();
    return variables.isNotEmpty || formulas.isNotEmpty;
  }

  Future<Map<String, dynamic>> exportData() async {
    final variables = await getVariables();
    final formulas = await getFormulas();
    final settings = await getSettings();
    
    return {
      'variables': variables.map((v) => v.toJson()).toList(),
      'formulas': formulas.map((f) => f.toJson()).toList(),
      'settings': settings,
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    if (data['variables'] != null) {
      final variables = (data['variables'] as List)
          .map((json) => Variable.fromJson(json))
          .toList();
      await saveVariables(variables);
    }

    if (data['formulas'] != null) {
      final formulas = (data['formulas'] as List)
          .map((json) => Formula.fromJson(json))
          .toList();
      await saveFormulas(formulas);
    }

    if (data['settings'] != null) {
      await saveSettings(data['settings']);
    }
  }
}