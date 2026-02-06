import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_card.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';

class ImageItem extends StatelessWidget {
  final Map<String, dynamic> image;

  const ImageItem({
    super.key,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: ExtendedText(
                    "${image['repository']}:${image['tags'].join(",")}",
                    maxLines: 1,
                    overflowWidget: const TextOverflowWidget(
                      position: TextOverflowPosition.middle,
                      align: TextOverflowAlign.right,
                      child: Text(
                        "…",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Label(
                    (int.parse(image['size']))
                        .formatSize(fixed: 0, format: 1000),
                    Theme.of(context).primaryColor),
              ],
            ),
            if (image['description'] != null && image['description'] != '') ...[
              const SizedBox(
                height: 10,
              ),
              Text(
                "${image['description']}",
                style: const TextStyle(
                  color: Colors.grey,
                ),
              )
            ],
          ],
        ),
      ),
    );
  }
}
