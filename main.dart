import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xff202020),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff76b9ed),
          brightness: Brightness.dark,
        ),
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  late final FocusNode _keyboardFocusNode;
  String _display = '0';
  String _expression = '';
  double? _storedValue;
  String? _pendingOperator;
  bool _resetDisplay = false;

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _press(String value) {
    setState(() {
      if (value == 'C') {
        _clear();
      } else if (value == 'CE') {
        _display = '0';
      } else if (value == '⌫') {
        _display = _display.length > 1
            ? _display.substring(0, _display.length - 1)
            : '0';
      } else if (value == '±') {
        if (_display != '0') {
          _display = _display.startsWith('-')
              ? _display.substring(1)
              : '-$_display';
        }
      } else if (value == '%') {
        _display = _format(double.parse(_display) / 100);
      } else if (value == '1/x') {
        final number = double.parse(_display);
        _display = number == 0 ? '오류' : _format(1 / number);
        _resetDisplay = true;
      } else if (value == 'x²') {
        final number = double.parse(_display);
        _display = _format(number * number);
        _resetDisplay = true;
      } else if (value == '√x') {
        final number = double.parse(_display);
        _display = number < 0 ? '오류' : _format(math.sqrt(number));
        _resetDisplay = true;
      } else if ('÷×−+'.contains(value)) {
        _chooseOperator(value);
      } else if (value == '=') {
        _calculate();
      } else {
        _enterDigit(value);
      }
    });
    _keyboardFocusNode.requestFocus();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final key = event.logicalKey;
    final physicalKey = event.physicalKey;
    final label = key.keyLabel;
    if (RegExp(r'^(Numpad )?[0-9]$').hasMatch(label)) {
      _press(label.substring(label.length - 1));
    } else if (physicalKey == PhysicalKeyboardKey.numpadAdd) {
      _press('+');
    } else if (physicalKey == PhysicalKeyboardKey.numpadSubtract) {
      _press('−');
    } else if (physicalKey == PhysicalKeyboardKey.numpadMultiply) {
      _press('×');
    } else if (physicalKey == PhysicalKeyboardKey.numpadDivide) {
      _press('÷');
    } else if (physicalKey == PhysicalKeyboardKey.numpadDecimal) {
      _press('.');
    } else if (physicalKey == PhysicalKeyboardKey.numpadEnter) {
      _press('=');
    } else if (['.', 'Decimal', 'Numpad .'].contains(label)) {
      _press('.');
    } else if (['+', 'Add', 'Numpad +'].contains(label)) {
      _press('+');
    } else if (['-', 'Subtract', 'Numpad -', '−'].contains(label)) {
      _press('−');
    } else if (['*', 'Multiply', 'Numpad *', '×', 'x', 'X'].contains(label)) {
      _press('×');
    } else if (['/', 'Divide', 'Numpad /', '÷'].contains(label)) {
      _press('÷');
    } else if (label == '%') {
      _press('%');
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.equal) {
      _press('=');
    } else if (key == LogicalKeyboardKey.backspace) {
      _press('⌫');
    } else if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.delete) {
      _press('C');
    }
  }

  void _clear() {
    _display = '0';
    _expression = '';
    _storedValue = null;
    _pendingOperator = null;
    _resetDisplay = false;
  }

  void _enterDigit(String value) {
    if (_resetDisplay || _display == '0') {
      _display = value == '.' ? '0.' : value;
      _resetDisplay = false;
    } else if (value != '.' || !_display.contains('.')) {
      _display += value;
    }
  }

  void _chooseOperator(String operator) {
    final current = double.parse(_display);
    if (_storedValue != null && _pendingOperator != null && !_resetDisplay) {
      _display = _format(_apply(_storedValue!, current, _pendingOperator!));
    }
    _storedValue = double.parse(_display);
    _pendingOperator = operator;
    _expression = '${_format(_storedValue!)} $operator';
    _resetDisplay = true;
  }

  void _calculate() {
    if (_storedValue == null || _pendingOperator == null) return;
    final right = double.parse(_display);
    final result = _apply(_storedValue!, right, _pendingOperator!);
    _expression =
        '${_format(_storedValue!)} $_pendingOperator ${_format(right)} =';
    _display = _format(result);
    _storedValue = null;
    _pendingOperator = null;
    _resetDisplay = true;
  }

  double _apply(double left, double right, String operator) {
    switch (operator) {
      case '+':
        return left + right;
      case '−':
        return left - right;
      case '×':
        return left * right;
      case '÷':
        return right == 0 ? 0 : left / right;
      default:
        return right;
    }
  }

  String _format(double value) {
    if (value.isNaN || value.isInfinite) return '오류';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value
              .toStringAsFixed(8)
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ['%', 'CE', 'C', '⌫'],
      ['1/x', 'x²', '√x', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['±', '0', '.', '='],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('계산기', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xff202020),
        elevation: 0,
      ),
      body: KeyboardListener(
        autofocus: true,
        focusNode: _keyboardFocusNode,
        onKeyEvent: _handleKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _expression,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            child: Text(
                              _display,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: GridView.count(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.45,
                      physics: const NeverScrollableScrollPhysics(),
                      children: buttons
                          .expand((row) => row.map(_button))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _button(String label) {
    final isOperator = '÷×−+'.contains(label) || label == '=';
    final isUtility = ['%', 'CE', 'C', '⌫', '1/x', 'x²', '√x'].contains(label);
    return FilledButton(
      onPressed: () => _press(label),
      style: FilledButton.styleFrom(
        backgroundColor: isOperator
            ? (label == '=' ? const Color(0xff76b9ed) : const Color(0xff3a3a3a))
            : (isUtility ? const Color(0xff323232) : const Color(0xff292929)),
        foregroundColor: label == '=' ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        textStyle: TextStyle(
          fontSize: label.length > 2 ? 14 : 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Text(label),
    );
  }
}
