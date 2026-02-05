import 'package:flutter/material.dart';
import 'package:garden/util/format_util.dart';

class NetworkItem extends StatelessWidget {
  final Map<String, dynamic> network;
  final int index;

  const NetworkItem({
    super.key,
    required this.network,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text("局域网${index + 1}：")),
          const Icon(
            Icons.upload_sharp,
            color: Colors.blue,
          ),
          Text(
            "${FormatUtil.formatSize(network['tx'])}/S",
            style: const TextStyle(color: Colors.blue),
          ),
          const Spacer(),
          const Icon(
            Icons.download_sharp,
            color: Colors.green,
          ),
          Text(
            "${FormatUtil.formatSize(network['rx'])}/S",
            style: const TextStyle(color: Colors.green),
          ),
        ],
      ),
    );
  }
}