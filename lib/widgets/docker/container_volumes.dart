import 'package:flutter/material.dart';

class ContainerVolumes extends StatelessWidget {
  final List volumes;

  const ContainerVolumes({
    super.key,
    required this.volumes,
  });

  Widget _buildVolumeItem(volume) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "${volume['host_volume_file']}",
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "${volume['mount_point']}",
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              "${volume['type']}",
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
              "卷",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    "文件/文件夹",
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "装载路径",
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
            ...volumes.map(_buildVolumeItem),
          ],
        ),
      ),
    );
  }
}
