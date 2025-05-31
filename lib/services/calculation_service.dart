import 'dart:math' as math;
import '../models/variable.dart';
import '../models/formula.dart';

class CalculationService {
  static CalculationService? _instance;
  static CalculationService get instance {
    _instance ??= CalculationService._();
    return _instance!;
  }
  
  CalculationService._();

  /// Évalue une expression mathématique avec des variables
  double evaluateExpression(String expression, Map<String, dynamic> variables) {
    try {
      // Remplacer les variables par leurs valeurs
      String processedExpression = _replaceVariables(expression, variables);
      
      // Évaluer l\'expression mathématique
      return _evaluateMathExpression(processedExpression);
    } catch (e) {
      print('Erreur lors de l\'évaluation de l\'expression: $expression - $e');
      return 0.0;
    }
  }

  /// Évalue une formule (normale ou conditionnelle)
  dynamic evaluateFormula(Formula formula, Map<String, dynamic> variables) {
    try {
      switch (formula.type) {
        case FormulaType.normal:
          if (formula.expression == null) return 0.0;
          return evaluateExpression(formula.expression!, variables);
          
        case FormulaType.conditional:
          // Évaluer les conditions dans l\'ordre
          for (final condition in formula.conditions) {
            if (_evaluateCondition(condition.expression, variables)) {
              return evaluateExpression(condition.resultExpression, variables);
            }
            
            // Vérifier les conditions imbriquées
            for (final nested in condition.nestedConditions) {
              if (_evaluateCondition(nested.expression, variables)) {
                return evaluateExpression(nested.resultExpression, variables);
              }
            }
          }
          
          // Si aucune condition n\'est satisfaite, utiliser l\'expression par défaut
          if (formula.defaultExpression != null) {
            return evaluateExpression(formula.defaultExpression!, variables);
          }
          
          return 0.0;
      }
    } catch (e) {
      print('Erreur lors de l\'évaluation de la formule ${formula.name}: $e');
      return 0.0;
    }
  }

  /// Évalue une condition logique
  bool _evaluateCondition(String condition, Map<String, dynamic> variables) {
    try {
      String processedCondition = _replaceVariables(condition, variables);
      return _evaluateLogicalExpression(processedCondition);
    } catch (e) {
      print('Erreur lors de l\'évaluation de la condition: $condition - $e');
      return false;
    }
  }

  /// Remplace les variables dans une expression par leurs valeurs
  String _replaceVariables(String expression, Map<String, dynamic> variables) {
    String result = expression;
    
    // Pattern pour identifier les variables: {nom_variable}
    final RegExp variablePattern = RegExp(r'\{(\w+)\}');
    final matches = variablePattern.allMatches(expression);
    
    for (final match in matches) {
      final variableName = match.group(1)!;
      final value = variables[variableName];
      
      if (value != null) {
        String stringValue;
        if (value is bool) {
          stringValue = value ? '1' : '0';
        } else if (value is String) {
          // Pour les chaînes, on les met entre guillemets
          stringValue = '"$value"';
        } else {
          stringValue = value.toString();
        }
        result = result.replaceAll('{$variableName}', stringValue);
      } else {
        // Variable non trouvée, remplacer par 0
        result = result.replaceAll('{$variableName}', '0');
      }
    }
    
    return result;
  }

  /// Évalue une expression mathématique simple
  double _evaluateMathExpression(String expression) {
    // Nettoyer l\'expression
    expression = expression.replaceAll(' ', '');
    
    if (expression.isEmpty) return 0.0;
    
    // Gestion des opérateurs de base
    return _parseAddSubtract(expression);
  }

  double _parseAddSubtract(String expression) {
    List<String> tokens = _tokenize(expression, ['+', '-']);
    if (tokens.length == 1) return _parseMultiplyDivide(tokens[0]);
    
    double result = _parseMultiplyDivide(tokens[0]);
    for (int i = 1; i < tokens.length; i += 2) {
      String operator = tokens[i];
      double operand = _parseMultiplyDivide(tokens[i + 1]);
      
      if (operator == '+') {
        result += operand;
      } else if (operator == '-') {
        result -= operand;
      }
    }
    return result;
  }

  double _parseMultiplyDivide(String expression) {
    List<String> tokens = _tokenize(expression, ['*', '/', '%']);
    if (tokens.length == 1) return _parsePower(tokens[0]);
    
    double result = _parsePower(tokens[0]);
    for (int i = 1; i < tokens.length; i += 2) {
      String operator = tokens[i];
      double operand = _parsePower(tokens[i + 1]);
      
      if (operator == '*') {
        result *= operand;
      } else if (operator == '/') {
        if (operand != 0) {
          result /= operand;
        } else {
          throw Exception('Division par zéro');
        }
      } else if (operator == '%') {
        result = result % operand;
      }
    }
    return result;
  }

  double _parsePower(String expression) {
    if (expression.contains('^')) {
      List<String> parts = expression.split('^');
      double base = _parseParentheses(parts[0]);
      double exponent = _parseParentheses(parts[1]);
      return math.pow(base, exponent).toDouble();
    }
    return _parseParentheses(expression);
  }

  double _parseParentheses(String expression) {
    expression = expression.trim();
    
    if (expression.startsWith('(') && expression.endsWith(')')) {
      return _evaluateMathExpression(expression.substring(1, expression.length - 1));
    }
    
    // Essayer de parser comme nombre
    double? number = double.tryParse(expression);
    if (number != null) return number;
    
    // Si ce n\'est pas un nombre, retourner 0
    return 0.0;
  }

  List<String> _tokenize(String expression, List<String> operators) {
    List<String> tokens = [];
    String current = '';
    int parentheses = 0;
    
    for (int i = 0; i < expression.length; i++) {
      String char = expression[i];
      
      if (char == '(') {
        parentheses++;
        current += char;
      } else if (char == ')') {
        parentheses--;
        current += char;
      } else if (parentheses == 0 && operators.contains(char)) {
        if (current.isNotEmpty) {
          tokens.add(current.trim());
          current = '';
        }
        tokens.add(char);
      } else {
        current += char;
      }
    }
    
    if (current.isNotEmpty) {
      tokens.add(current.trim());
    }
    
    return tokens;
  }

  /// Évalue une expression logique
  bool _evaluateLogicalExpression(String expression) {
    expression = expression.replaceAll(' ', '');
    
    // Gestion des opérateurs logiques
    if (expression.contains('ET') || expression.contains('&&')) {
      return _evaluateAndExpression(expression);
    } else if (expression.contains('OU') || expression.contains('||')) {
      return _evaluateOrExpression(expression);
    } else {
      return _evaluateComparison(expression);
    }
  }

  bool _evaluateAndExpression(String expression) {
    List<String> parts = expression.contains('ET') 
        ? expression.split('ET') 
        : expression.split('&&');
    
    for (String part in parts) {
      if (!_evaluateLogicalExpression(part.trim())) {
        return false;
      }
    }
    return true;
  }

  bool _evaluateOrExpression(String expression) {
    List<String> parts = expression.contains('OU') 
        ? expression.split('OU') 
        : expression.split('||');
    
    for (String part in parts) {
      if (_evaluateLogicalExpression(part.trim())) {
        return true;
      }
    }
    return false;
  }

  bool _evaluateComparison(String expression) {
    // Opérateurs de comparaison dans l\'ordre de priorité
    List<String> operators = ['>=', '<=', '!=', '==', '>', '<', '='];
    
    for (String op in operators) {
      if (expression.contains(op)) {
        List<String> parts = expression.split(op);
        if (parts.length == 2) {
          String left = parts[0].trim();
          String right = parts[1].trim();
          
          // Essayer de parser comme nombres
          double? leftNum = double.tryParse(left);
          double? rightNum = double.tryParse(right);
          
          if (leftNum != null && rightNum != null) {
            return _compareNumbers(leftNum, rightNum, op);
          } else {
            // Comparaison de chaînes
            return _compareStrings(left, right, op);
          }
        }
      }
    }
    
    // Si pas de comparaison, évaluer comme booléen
    if (expression.toLowerCase() == 'true' || expression == '1') return true;
    if (expression.toLowerCase() == 'false' || expression == '0') return false;
    
    return false;
  }

  bool _compareNumbers(double left, double right, String operator) {
    switch (operator) {
      case '>': return left > right;
      case '<': return left < right;
      case '>=': return left >= right;
      case '<=': return left <= right;
      case '=':
      case '==': return left == right;
      case '!=': return left != right;
      default: return false;
    }
  }

  bool _compareStrings(String left, String right, String operator) {
    // Nettoyer les guillemets
    left = left.replaceAll('"', '');
    right = right.replaceAll('"', '');
    
    switch (operator) {
      case '=':
      case '==': return left == right;
      case '!=': return left != right;
      default: return false;
    }
  }

  /// Valide qu\'une expression est correctement formée
  bool validateExpression(String expression, List<Variable> availableVariables) {
    try {
      // Vérifier que toutes les variables utilisées existent
      final RegExp variablePattern = RegExp(r'\{(\w+)\}');
      final matches = variablePattern.allMatches(expression);
      
      for (final match in matches) {
        final variableName = match.group(1)!;
        final variableExists = availableVariables.any((v) => v.name == variableName);
        if (!variableExists) {
          return false;
        }
      }
      
      // Créer des valeurs de test pour toutes les variables
      Map<String, dynamic> testValues = {};
      for (final variable in availableVariables) {
        switch (variable.type) {
          case VariableType.number:
            testValues[variable.name] = 1.0;
            break;
          case VariableType.boolean:
            testValues[variable.name] = true;
            break;
          case VariableType.string:
            testValues[variable.name] = 'test';
            break;
          case VariableType.choice:
            testValues[variable.name] = variable.choices.isNotEmpty ? variable.choices.first : 'test';
            break;
        }
      }
      
      // Essayer d\'évaluer l\'expression avec les valeurs de test
      evaluateExpression(expression, testValues);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Calcule tous les résultats pour un ensemble de valeurs
  Map<String, dynamic> calculateAllResults(
    List<Formula> formulas,
    Map<String, dynamic> inputValues,
  ) {
    Map<String, dynamic> results = {};
    
    // Copier les valeurs d\'entrée
    Map<String, dynamic> allValues = Map.from(inputValues);
    
    // Calculer les formules dans l\'ordre (les résultats peuvent être utilisés dans d\'autres formules)
    for (final formula in formulas) {
      try {
        final result = evaluateFormula(formula, allValues);
        results[formula.name] = result;
        allValues[formula.name] = result; // Ajouter le résultat aux valeurs disponibles
      } catch (e) {
        print('Erreur lors du calcul de la formule ${formula.name}: $e');
        results[formula.name] = 0.0;
      }
    }
    
    return results;
  }
}