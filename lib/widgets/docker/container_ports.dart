import 'package:flutter/material.dart';

class ContainerPorts extends StatelessWidget {
  final List ports;

  const ContainerPorts({
    super.key,
    required this.ports,
  });

  Widget _buildPortItem(port) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${port['host_port']}",
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              "${port['container_port']}",
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              "${port['type']}",
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "端口设置",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            const Row(
              children: [
                Expanded(
                  child: Text(
                    "本地端口",
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    "容器端口",
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    "类型",
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            ...ports.map(_buildPortItem),
          ],
        ),
      ),
    );
  }
}
