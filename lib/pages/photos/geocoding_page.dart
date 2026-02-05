import 'package:garden/models/photos/geocoding_model.dart';
import 'package:garden/pages/photos/timeline_page.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class GeocodingPage extends StatefulWidget {
  const GeocodingPage(this.isTeam, {super.key});
  final bool isTeam;
  @override
  State<GeocodingPage> createState() => _GeocodingPageState();
}

class _GeocodingPageState extends State<GeocodingPage> {
  bool loading = true;
  double photoWidth = 0;
  List<GeocodingModel> geocodings = [];
  Map<String, List<GeocodingModel>> geocodingGroups = {};
  @override
  void initState() {
    getData();
    super.initState();
  }

  Future getData() async {
    geocodings = await GeocodingModel.fetch(
        additional: ['thumbnail'], isTeam: widget.isTeam);
    for (var element in geocodings) {
      if (geocodingGroups[element.country] == null) {
        geocodingGroups[element.country ?? ''] = [];
      }
      geocodingGroups[element.country]?.add(element);
    }
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("位置"),
      ),
      body: loading
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge),
              itemBuilder: (context, i) {
                MapEntry<String, List<GeocodingModel>> entry =
                    geocodingGroups.entries.toList()[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingSmall + 2),
                      child: Text(entry.key),
                    ),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: entry.value.map((geocoding) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context)
                                .push(CupertinoPageRoute(builder: (context) {
                              return TimelinePage(
                                  title: geocoding.name ?? '',
                                  isTeam: widget.isTeam,
                                  geocodingId: geocoding.id?.toInt() ?? 0);
                            }));
                          },
                          child: SizedBox(
                            width: photoWidth,
                            child: Column(
                              children: [
                                ExtendedImage.network(
                                  geocoding.additional?.thumbnail?.thumbUrl(
                                          size: 'sm', isTeam: widget.isTeam) ??
                                      '',
                                  width: photoWidth,
                                  height: photoWidth,
                                  shape: BoxShape.rectangle,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                Text(
                                  geocoding.name ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${geocoding.itemCount}个项目",
                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  ],
                );
              },
              itemCount: geocodingGroups.length,
            ),
    );
  }
}
