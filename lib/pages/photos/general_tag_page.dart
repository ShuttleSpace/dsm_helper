import 'package:garden/models/photos/general_tag_model.dart';
import 'package:garden/pages/photos/timeline_page.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class GeneralTagPage extends HookWidget {
  const GeneralTagPage(this.isTeam, {super.key});
  final bool isTeam;

  @override
  Widget build(BuildContext context) {
    final loading = useSignal(true);
    final photoWidth = useSignal(0.0);
    final tags = useSignal<List<GeneralTagModel>>([]);

    Future getData() async {
      tags.value = await GeneralTagModel.fetch(
          additional: ['thumbnail'], isTeam: isTeam);
      loading.value = false;
    }

    useEffect(() {
      getData();
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("标签"),
      ),
      body: loading.value
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                runSpacing: 20,
                spacing: 20,
                children: tags.value.map((tag) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context)
                          .push(CupertinoPageRoute(builder: (context) {
                        return TimelinePage(
                          title: tag.name ?? '',
                          isTeam: isTeam,
                          generalTagId: tag.id ?? 0,
                        );
                      }));
                    },
                    child: SizedBox(
                      width: photoWidth.value,
                      child: Column(
                        children: [
                          ExtendedImage.network(
                            tag.additional!.thumbnail?.thumbUrl(
                                    size: 'sm', isTeam: isTeam) ??
                                '',
                            width: photoWidth.value,
                            height: photoWidth.value,
                            shape: BoxShape.rectangle,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          Text(
                            tag.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${tag.itemCount}个项目",
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}
