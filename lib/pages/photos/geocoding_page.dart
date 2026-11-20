import 'package:garden/models/photos/geocoding_model.dart';
import 'package:garden/pages/photos/timeline_page.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:signals_hooks/signals_hooks.dart';

class GeocodingPage extends HookWidget {
  const GeocodingPage(this.isTeam, {super.key});
  final bool isTeam;

  @override
  Widget build(BuildContext context) {
    final loading = useSignal(true);
    final geocodingGroups = useSignal<Map<String, List<GeocodingModel>>>({});
    final double photoWidth = (MediaQuery.sizeOf(context).width - 6) / 4;

    Future getData() async {
      final geocodings = await GeocodingModel.fetch(
          additional: ['thumbnail'], isTeam: isTeam);
      final groups = <String, List<GeocodingModel>>{};
      for (var element in geocodings) {
        if (groups[element.country] == null) {
          groups[element.country ?? ''] = [];
        }
        groups[element.country]?.add(element);
      }
      geocodingGroups.value = groups;
      loading.value = false;
    }

    useEffect(() {
      getData();
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("位置"),
      ),
      body: loading.value
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
                    geocodingGroups.value.entries.toList()[i];
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
                                  isTeam: isTeam,
                                  geocodingId: geocoding.id?.toInt() ?? 0);
                            }));
                          },
                          child: SizedBox(
                            width: photoWidth,
                            child: Column(
                              children: [
                                ExtendedImage.network(
                                  geocoding.additional?.thumbnail?.thumbUrl(
                                          size: 'sm', isTeam: isTeam) ??
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
              itemCount: geocodingGroups.value.length,
            ),
    );
  }
}
