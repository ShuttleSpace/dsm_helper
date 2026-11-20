import 'package:flutter/material.dart';

class ContainerNetworks extends StatelessWidget {
  final List networks;

  const ContainerNetworks({
    super.key,
    required this.networks,
  });

  Widget _buildNetworkItem(network) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${network['name']}",
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              "${network['driver']}",
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
              "网络",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            const Row(
              children: [
                Expanded(
                  child: Text(
                    "网络名称",
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    "驱动程序",
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            ...networks.map(_buildNetworkItem),
          ],
        ),
      ),
    );
  }
}
