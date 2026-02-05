import 'package:flutter/material.dart';

class ContainerEnvs extends StatelessWidget {
  final List envs;

  const ContainerEnvs({
    super.key,
    required this.envs,
  });

  Widget _buildEnvItem(env) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Text(
            "${env['key']}：",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              "${env['value']}",
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
              "环境变量",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            ...envs.map(_buildEnvItem),
          ],
        ),
      ),
    );
  }
}
