import 'package:garden/stores/connection_store.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals_hooks/signals_hooks.dart';

class About extends HookWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    final packageInfo = useSignal<PackageInfo?>(null);

    getInfo() async {
      packageInfo.value = await PackageInfo.fromPlatform();
    }

    useEffect(() {
      getInfo();
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(
          "关于${connectionStore.appName}",
        ),
      ),
      body: const Placeholder(),
    );
  }
}
