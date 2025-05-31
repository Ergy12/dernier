import 'dart:convert';

enum VariableType { number, string, boolean, choice }

class Variable {
  final String id;
  final String name;
  final String? description;
  final VariableType type;
  final dynamic defaultValue;
  final List<String> choices;
  final bool isDisplayed;
  final String displayName;

  Variable({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.defaultValue,
    this.choices = const [],
    this.isDisplayed = true,
    String? displayName,
  }) : displayName = displayName ?? name;

  Variable copyWith({
    String? id,
    String? name,
    String? description,
    VariableType? type,
    dynamic defaultValue,
    List<String>? choices,
    bool? isDisplayed,
    String? displayName,
  }) {
    return Variable(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      defaultValue: defaultValue ?? this.defaultValue,
      choices: choices ?? this.choices,
      isDisplayed: isDisplayed ?? this.isDisplayed,
      displayName: displayName ?? this.displayName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'defaultValue': defaultValue,
      'choices': choices,
      'isDisplayed': isDisplayed,
      'displayName': displayName,
    };
  }

  factory Variable.fromJson(Map<String, dynamic> json) {
    return Variable(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: VariableType.values.firstWhere((e) => e.name == json['type']),
      defaultValue: json['defaultValue'],
      choices: List<String>.from(json['choices'] ?? []),
      isDisplayed: json['isDisplayed'] ?? true,
      displayName: json['displayName'],
    );
  }

  String getDisplayValue(dynamic value) {
    switch (type) {
      case VariableType.boolean:
        return value == true ? 'Oui' : 'Non';
      case VariableType.choice:
        return value?.toString() ?? '';
      case VariableType.number:
        return value?.toString() ?? '0';
      case VariableType.string:
        return value?.toString() ?? '';
    }
  }

  dynamic parseValue(String input) {
    switch (type) {
      case VariableType.number:
        return double.tryParse(input) ?? 0.0;
      case VariableType.boolean:
        return input.toLowerCase() == 'true' || input == '1' || input.toLowerCase() == 'oui';
      case VariableType.choice:
        return choices.contains(input) ? input : (choices.isNotEmpty ? choices.first : '');
      case VariableType.string:
        return input;
    }
  }

  bool isValidValue(dynamic value) {
    switch (type) {
      case VariableType.number:
        return value is num;
      case VariableType.boolean:
        return value is bool;
      case VariableType.choice:
        return choices.contains(value.toString());
      case VariableType.string:
        return value is String;
    }
  }
}