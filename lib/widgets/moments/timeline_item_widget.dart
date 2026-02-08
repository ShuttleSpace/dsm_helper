import 'package:garden/api/dsm_api.dart';
import 'package:garden/widgets/moments/photo_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class TimelineItemWidget extends StatefulWidget {
  final Map line;
  final double photoWidth;

  const TimelineItemWidget({
    super.key,
    required this.line,
    required this.photoWidth,
  });

  @override
  TimelineItemWidgetState createState() => TimelineItemWidgetState();
}

class TimelineItemWidgetState extends State<TimelineItemWidget> {
  @override
  void initState() {
    super.initState();
    _getLineInfo();
  }

  void _getLineInfo() {
    if (widget.line['items'] == null) {
      widget.line['items'] = [];
      dsmFotoBrowsePhotoList(
              year: widget.line['year'],
              month: widget.line['month'],
              day: widget.line['day'])
          .then((res) {
        if (mounted) {
          setState(() {
            widget.line['items'] = res['list'];
          });
        }
      });
    }
    if (widget.line['location'] == null) {
      widget.line['location'] = {};
      dsmFotoBrowseTimelineLocation(
              widget.line['year'], widget.line['month'], widget.line['day'])
          .then((res) {
        if (mounted) {
          setState(() {
            widget.line['location'] = res;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List items = widget.line['items'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          height: 40,
          padding:
              const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
          child: Row(
            children: [
              Text(
                "${widget.line['year']}-${widget.line['month'].toString().padLeft(2, "0")}-${widget.line['day'].toString().padLeft(2, "0")}",
              ),
              if (widget.line['location'] != null &&
                  ((widget.line['location']['first_level'] != null &&
                      widget.line['location']['first_level'] != "")))
                Text("   ${widget.line['location']['first_level']}"),
              if (widget.line['location'] != null &&
                  ((widget.line['location']['second_level'] != null &&
                      widget.line['location']['second_level'].length > 0)))
                Text("${widget.line['location']['second_level'].join(",")}"),
            ],
          ),
        ),
        Wrap(
          spacing: 2,
          runSpacing: 2,
          children: items.isEmpty
              ? List.generate(widget.line['item_count'], (index) {
                  return Container(
                    color: Colors.grey,
                    width: widget.photoWidth,
                    height: widget.photoWidth,
                  );
                })
              : items.map((item) {
                  return PhotoItemWidget(
                    photo: item,
                    photos: items,
                    photoWidth: widget.photoWidth,
                  );
                }).toList(),
        ),
      ],
    );
  }
}
