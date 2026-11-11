import 'package:garden/util/moments_api.dart';
import 'package:garden/widgets/moments/photo_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:signals_hooks/signals_hooks.dart';

class TimelineItemWidget extends HookWidget {
  final Map line;
  final double photoWidth;

  const TimelineItemWidget({
    super.key,
    required this.line,
    required this.photoWidth,
  });

  @override
  Widget build(BuildContext context) {
    final rebuild = useSignal(0);

    getLineInfo() {
      if (line['items'] == null) {
        line['items'] = [];
        MomentsApi.photos(
                year: line['year'], month: line['month'], day: line['day'])
            .then((res) {
          if (res['success'] && context.mounted) {
            line['items'] = res['data']['list'];
            rebuild.value++;
          }
        });
      }
      if (line['location'] == null) {
        line['location'] = {};
        MomentsApi.location(line['year'], line['month'], line['day'])
            .then((res) {
          if (res['success'] && context.mounted) {
            line['location'] = res['data'];
            rebuild.value++;
          }
        });
      }
    }

    useEffect(() {
      getLineInfo();
      return null;
    }, const []);

    List items = line['items'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          height: 40,
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLarge),
          child: Row(
            children: [
              Text(
                "${line['year']}-${line['month'].toString().padLeft(2, "0")}-${line['day'].toString().padLeft(2, "0")}",
              ),
              if (line['location'] != null &&
                  ((line['location']['first_level'] != null &&
                      line['location']['first_level'] != "")))
                Text("   ${line['location']['first_level']}"),
              if (line['location'] != null &&
                  ((line['location']['second_level'] != null &&
                      line['location']['second_level'].length > 0)))
                Text("${line['location']['second_level'].join(",")}"),
            ],
          ),
        ),
        Wrap(
          spacing: 2,
          runSpacing: 2,
          children: items.isEmpty
              ? List.generate(line['item_count'], (index) {
                  return Container(
                    color: Colors.grey,
                    width: photoWidth,
                    height: photoWidth,
                  );
                })
              : items.map((item) {
                  return PhotoItemWidget(
                    photo: item,
                    photos: items,
                    photoWidth: photoWidth,
                  );
                }).toList(),
        ),
      ],
    );
  }
}
