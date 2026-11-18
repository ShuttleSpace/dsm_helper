import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/widgets/system_info/dev_item.dart';
import 'package:garden/widgets/system_info/disk_item.dart';
import 'package:garden/widgets/system_info/nif_item.dart';

void main() {
  testWidgets('system info item cards render their data', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ListView(
        children: [
          NetworkInterfaceItem({
            'mac': '00:11:22:33:44:55',
            'addr': '192.168.1.2',
            'mask': '255.255.255.0',
          }, 0),
          UsbDeviceItem({'cls': 'hub', 'product': 'Hub', 'producer': 'X'}),
          SystemDiskItem({
            'isSsd': true,
            'longName': 'Disk 1',
            'overview_status': 'normal',
            'vendor': 'A',
            'model': 'B',
            'size_total': 1024,
            'temp': 30,
          }),
        ],
      ),
    ));

    expect(find.text('局域网 1'), findsOneWidget);
    expect(find.text('00:11:22:33:44:55'), findsOneWidget);
    expect(find.text('USB集线器'), findsOneWidget);
    expect(find.text('Disk 1'), findsOneWidget);
  });
}
