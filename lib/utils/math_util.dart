import 'package:math_expressions/math_expressions.dart';

double parseAmount(String input) {
  if (input.isEmpty) return 0.0;
  try {
    GrammarParser p = GrammarParser();
    Expression exp = p.parse(input);
    return RealEvaluator().evaluate(exp) as double;
  } catch (e) {
    return double.tryParse(input) ?? 0.0;
  }
}
