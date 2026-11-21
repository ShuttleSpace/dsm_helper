import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:xterm/xterm.dart';
import 'package:signals_hooks/signals_hooks.dart';

import 'terminal_button.dart';

class VirtualKeyboardView extends HookWidget {
  const VirtualKeyboardView(this.keyboard, this.terminal, {super.key});

  final VirtualKeyboard keyboard;
  final Terminal terminal;

  @override
  Widget build(BuildContext context) {
    final rebuild = useSignal(0);
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SafeArea(
        child: DefaultTextStyle(
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  TerminalButton(
                    width: 36,
                    onPressed: () {
                      terminal.keyInput(TerminalKey.escape);
                    },
                    child: const Text("ESC"),
                  ),
                  TerminalButton(
                    width: 36,
                    onPressed: () {
                      terminal.onOutput?.call('/');
                    },
                    child: const Text("/"),
                  ),
                  TerminalButton(
                    width: 36,
                    onPressed: () {
                      terminal.keyInput(TerminalKey.arrowUp);
                    },
                    child: Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(
                    width: 40,
                  ),
                  const Spacer(),
                  TerminalButton(
                    width: 36,
                    onPressed: () {
                      terminal.keyInput(TerminalKey.home);
                    },
                    child: const Text(
                      "INS",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TerminalButton(
                    width: 36,
                    onPressed: () {
                      terminal.keyInput(TerminalKey.insert);
                    },
                    child: const Text(
                      "HOME",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TerminalButton(
                    width: 36,
                    onPressed: () {
                      terminal.keyInput(TerminalKey.pageUp);
                    },
                    child: const Text(
                      "PGUP",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TerminalButton(
                    width: 36,
                    onPressed: () {
                      terminal.keyInput(TerminalKey.tab);
                    },
                    child: const Text("TAB"),
                  ),
                  // 左
                  TerminalButton(
                    width: 36,
                    onPressed: () {
                      terminal.keyInput(TerminalKey.arrowLeft);
                    },
                    child: Icon(
                      Icons.keyboard_arrow_left,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  // //下
                  TerminalButton(
                    width: 36,
                    onPressed: () {
                      terminal.keyInput(TerminalKey.arrowDown);
                    },
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  // // 右
                  TerminalButton(
                    width: 36,
                    onPressed: () {
                      terminal.keyInput(TerminalKey.arrowRight);
                    },
                    child: Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  TerminalButton(
                    width: 36,
                    onPressed: () {
                      keyboard.ctrl = !keyboard.ctrl;
                      rebuild.value++;
                    },
                    active: keyboard.ctrl,
                    child: const Text("Ctrl"),
                  ),
                  TerminalButton(
                    width: 36,
                    onPressed: () {
                      keyboard.alt = !keyboard.alt;
                      rebuild.value++;
                    },
                    active: keyboard.alt,
                    child: const Text("Alt"),
                  ),
                  TerminalButton(
                    width: 36,
                    onPressed: () {
                      keyboard.shift = !keyboard.shift;
                      rebuild.value++;
                    },
                    active: keyboard.shift,
                    child: const Text("Shift"),
                  ),
                  TerminalButton(
                    width: 36,
                    onPressed: () {
                      terminal.keyInput(TerminalKey.delete);
                    },
                    child: const Text("DEL"),
                  ),
                  TerminalButton(
                    width: 36,
                    onPressed: () {
                      terminal.keyInput(TerminalKey.end);
                    },
                    child: const Text("END"),
                  ),
                  TerminalButton(
                    width: 36,
                    onPressed: () {
                      terminal.keyInput(TerminalKey.pageDown);
                    },
                    child: const Text(
                      "PGDN",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class VirtualKeyboard extends TerminalInputHandler {
  final TerminalInputHandler _inputHandler;

  VirtualKeyboard(this._inputHandler);

  final _ctrl = signal<bool>(false);
  bool get ctrl => _ctrl.value;

  set ctrl(bool value) {
    _ctrl.value = value;
  }

  final _shift = signal<bool>(false);
  bool get shift => _shift.value;

  set shift(bool value) {
    _shift.value = value;
  }

  final _alt = signal<bool>(false);
  bool get alt => _alt.value;

  set alt(bool value) {
    _alt.value = value;
  }

  @override
  String call(TerminalKeyboardEvent event) {
    return _inputHandler.call(event.copyWith(
          ctrl: event.ctrl || ctrl,
          shift: event.shift || shift,
          alt: event.alt || alt,
        )) ??
        '';
  }
}
