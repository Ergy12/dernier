import 'dart:convert';

enum FormulaType { normal, conditional }

class FormulaCondition {
  final String expression;
  final String resultExpression;
  final List<FormulaCondition> nestedConditions;

  FormulaCondition({
    required this.expression,
    required this.resultExpression,
    this.nestedConditions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'expression': expression,
      'resultExpression': resultExpression,
      'nestedConditions': nestedConditions.map((c) => c.toJson()).toList(),
    };
  }

  factory FormulaCondition.fromJson(Map<String, dynamic> json) {
    return FormulaCondition(
      expression: json['expression'],
      resultExpression: json['resultExpression'],
      nestedConditions: (json['nestedConditions'] as List<dynamic>?)
          ?.map((c) => FormulaCondition.fromJson(c))
          .toList() ?? [],
    );
  }

  FormulaCondition copyWith({
    String? expression,
    String? resultExpression,
    List<FormulaCondition>? nestedConditions,
  }) {
    return FormulaCondition(
      expression: expression ?? this.expression,
      resultExpression: resultExpression ?? this.resultExpression,
      nestedConditions: nestedConditions ?? this.nestedConditions,
    );
  }
}

class Formula {
  final String id;
  final String name;
  final FormulaType type;
  final String? expression; // Pour les formules normales
  final List<FormulaCondition> conditions; // Pour les formules conditionnelles
  final String? defaultExpression; // Expression par défaut si aucune condition n'est satisfaite
  final String? description;

  Formula({
    required this.id,
    required this.name,
    required this.type,
    this.expression,
    this.conditions = const [],
    this.defaultExpression,
    this.description,
  });

  Formula copyWith({
    String? id,
    String? name,
    FormulaType? type,
    String? expression,
    List<FormulaCondition>? conditions,
    String? defaultExpression,
    String? description,
  }) {
    return Formula(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      expression: expression ?? this.expression,
      conditions: conditions ?? this.conditions,
      defaultExpression: defaultExpression ?? this.defaultExpression,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'expression': expression,
      'conditions': conditions.map((c) => c.toJson()).toList(),
      'defaultExpression': defaultExpression,
      'description': description,
    };
  }

  factory Formula.fromJson(Map<String, dynamic> json) {
    return Formula(
      id: json['id'],
      name: json['name'],
      type: FormulaType.values.firstWhere((e) => e.name == json['type']),
      expression: json['expression'],
      conditions: (json['conditions'] as List<dynamic>?)
          ?.map((c) => FormulaCondition.fromJson(c))
          .toList() ?? [],
      defaultExpression: json['defaultExpression'],
      description: json['description'],
    );
  }

  bool get isValid {
    switch (type) {
      case FormulaType.normal:
        return expression != null && expression!.isNotEmpty;
      case FormulaType.conditional:
        return conditions.isNotEmpty;
    }
  }

  String getDisplayExpression() {
    switch (type) {
      case FormulaType.normal:
        return expression ?? '';
      case FormulaType.conditional:
        if (conditions.isEmpty) return '';
        final firstCondition = conditions.first;
        return 'SI ${firstCondition.expression} ALORS ${firstCondition.resultExpression}';
    }
  }

  List<String> getUsedVariables() {
    final Set<String> variables = {};
    
    switch (type) {
      case FormulaType.normal:
        if (expression != null) {
          variables.addAll(_extractVariables(expression!));
        }
        break;
      case FormulaType.conditional:
        for (final condition in conditions) {
          variables.addAll(_extractVariables(condition.expression));
          variables.addAll(_extractVariables(condition.resultExpression));
          for (final nested in condition.nestedConditions) {
            variables.addAll(_extractVariables(nested.expression));
            variables.addAll(_extractVariables(nested.resultExpression));
          }
        }
        if (defaultExpression != null) {
          variables.addAll(_extractVariables(defaultExpression!));
        }
        break;
    }
    
    return variables.toList();
  }

  List<String> _extractVariables(String expression) {
    final RegExp variablePattern = RegExp(r'\{(\w+)\}');
    final matches = variablePattern.allMatches(expression);
    return matches.map((match) => match.group(1)!).toList();
  }
}