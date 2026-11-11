import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:garden/widgets/virtual_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:xterm/xterm.dart';

class Ssh extends HookWidget {
  final String host;
  final String port;
  final String username;
  final String password;
  const Ssh(this.host, this.port, this.username, this.password, {super.key});

  @override
  Widget build(BuildContext context) {
    final keyboard = useMemoized(() => VirtualKeyboard(defaultInputHandler), const []);
    final terminal = useSignal<Terminal>(Terminal());
    final terminalTitle = useSignal("终端");

    Future<void> initTerminal() async {
      terminal.value = Terminal(inputHandler: keyboard);
      terminalTitle.value = "$username@$host:$port";
      terminal.value
          .write('Connecting to $username@$host:$port\r\n');

      final client = SSHClient(
        await SSHSocket.connect(host, int.parse(port)),
        username: username,
        onPasswordRequest: () => password,
      );

      terminal.value.write('Connected\r\n');

      final session = await client.shell(
        pty: SSHPtyConfig(
          width: terminal.value.viewWidth,
          height: terminal.value.viewHeight,
        ),
      );

      terminal.value.buffer.clear();
      terminal.value.buffer.setCursor(0, 0);

      terminal.value.onTitleChange = (title) {
        Log.info("terminal title changed: : $title");
        terminalTitle.value = title;
      };

      terminal.value.onResize = (width, height, pixelWidth, pixelHeight) {
        session.resizeTerminal(width, height, pixelWidth, pixelHeight);
      };

      terminal.value.onOutput = (data) {
        session.write(utf8.encode(data));
      };

      session.stdout
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .listen(terminal.value.write);

      session.stderr
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .listen(terminal.value.write);
    }

    useEffect(() {
      initTerminal();
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          context,
          color: Colors.black,
          iconColor: Colors.white.withValues(alpha: .5),
        ),
        title: Text(
          terminalTitle.value,
          style: TextStyle(color: Colors.white.withValues(alpha: .5)),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: TerminalView(terminal.value),
          ),
          VirtualKeyboardView(keyboard, terminal.value),
        ],
      ),
    );
  }
}
