import 'package:flutter/material.dart';

class ContainerLinks extends StatelessWidget {
  final List links;

  const ContainerLinks({
    super.key,
    required this.links,
  });

  Widget _buildLinkItem(link) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${link['link_container']}",
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              "${link['alias']}",
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
              "链接",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            const Row(
              children: [
                Expanded(
                  child: Text(
                    "容器名称",
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    "别名",
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            ...links.map(_buildLinkItem),
          ],
        ),
      ),
    );
  }
}
