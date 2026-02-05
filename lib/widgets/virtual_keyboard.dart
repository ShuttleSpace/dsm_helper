import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'terminal_button.dart';

class VirtualKeyboardView extends StatefulWidget {
  const VirtualKeyboardView(this.keyboard, this.terminal, {super.key});

  final VirtualKeyboard keyboard;
  final Terminal terminal;

  @override
  State<VirtualKeyboardView> createState() => _VirtualKeyboardViewState();
}

class _VirtualKeyboardViewState extends State<VirtualKeyboardView> {
  @override
  Widget build(BuildContext context) {
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
                    onPressed: () {
                      widget.terminal.keyInput(TerminalKey.escape);
                    },
                    child: const Text("ESC"),
                  ),
                  TerminalButton(
                    onPressed: () {
                      widget.terminal.onOutput?.call('/');
                    },
                    child: const Text("/"),
                  ),
                  TerminalButton(
                    onPressed: () {
                      widget.terminal.keyInput(TerminalKey.arrowUp);
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
                    onPressed: () {
                      widget.terminal.keyInput(TerminalKey.home);
                    },
                    child: const Text(
                      "INS",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TerminalButton(
                    onPressed: () {
                      widget.terminal.keyInput(TerminalKey.insert);
                    },
                    child: const Text(
                      "HOME",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TerminalButton(
                    onPressed: () {
                      widget.terminal.keyInput(TerminalKey.pageUp);
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
                    onPressed: () {
                      widget.terminal.keyInput(TerminalKey.tab);
                    },
                    child: const Text("TAB"),
                  ),
                  // 左
                  TerminalButton(
                    onPressed: () {
                      widget.terminal.keyInput(TerminalKey.arrowLeft);
                    },
                    child: Icon(
                      Icons.keyboard_arrow_left,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  // //下
                  TerminalButton(
                    onPressed: () {
                      widget.terminal.keyInput(TerminalKey.arrowDown);
                    },
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  // // 右
                  TerminalButton(
                    onPressed: () {
                      widget.terminal.keyInput(TerminalKey.arrowRight);
                    },
                    child: Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  TerminalButton(
                    onPressed: () {
                      setState(() {
                        widget.keyboard.ctrl = !widget.keyboard.ctrl;
                      });
                    },
                    active: widget.keyboard.ctrl,
                    child: const Text("Ctrl"),
                  ),
                  TerminalButton(
                    onPressed: () {
                      setState(() {
                        widget.keyboard.alt = !widget.keyboard.alt;
                      });
                    },
                    active: widget.keyboard.alt,
                    child: const Text("Alt"),
                  ),
                  TerminalButton(
                    onPressed: () {
                      setState(() {
                        widget.keyboard.shift = !widget.keyboard.shift;
                      });
                    },
                    active: widget.keyboard.shift,
                    child: const Text("Shift"),
                  ),
                  TerminalButton(
                    onPressed: () {
                      widget.terminal.keyInput(TerminalKey.delete);
                    },
                    child: const Text("DEL"),
                  ),
                  TerminalButton(
                    onPressed: () {
                      widget.terminal.keyInput(TerminalKey.end);
                    },
                    child: const Text("END"),
                  ),
                  TerminalButton(
                    onPressed: () {
                      widget.terminal.keyInput(TerminalKey.pageDown);
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
