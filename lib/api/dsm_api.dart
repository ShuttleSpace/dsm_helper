import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:garden/extensions/datetime.dart';
import 'package:garden/models/api_model.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/log.dart';
import 'package:http_parser/http_parser.dart';

part 'dsm_api.base.dart';
part 'dsm_api.util.dart';

part 'dsm_api.core.dart';
part 'dsm_api.core.auth.dart';
part 'dsm_api.core.groups.dart';
part 'dsm_api.core.packages.dart';
part 'dsm_api.core.users.dart';
part 'dsm_api.core.shares.dart';
part 'dsm_api.core.certificates.dart';
part 'dsm_api.core.storage.dart';
part 'dsm_api.core.security.dart';
part 'dsm_api.core.terminal.dart';
part 'dsm_api.core.power.dart';
part 'dsm_api.core.network.dart';
part 'dsm_api.core.ddns.dart';
part 'dsm_api.core.otp.dart';
part 'dsm_api.core.trustdevice.dart';
part 'dsm_api.core.firmware.dart';
part 'dsm_api.core.normaluser.dart';

part 'dsm_api.filestation.dart';
part 'dsm_api.filestation.search.dart';
part 'dsm_api.filestation.favorites.dart';
part 'dsm_api.filestation.fileoperations.dart';
part 'dsm_api.filestation.backgroundtasks.dart';
part 'dsm_api.filestation.compression.dart';
part 'dsm_api.filestation.sharing.dart';
part 'dsm_api.filestation.uploaddownload.dart';
part 'dsm_api.filestation.mount.dart';
part 'dsm_api.filestation.pages.dart';

part 'dsm_api.fototeam.dart';

part 'dsm_api.downloadstation.dart';
part 'dsm_api.downloadstation.tasks.dart';
part 'dsm_api.downloadstation.btsearch.dart';
part 'dsm_api.downloadstation.rss.dart';
part 'dsm_api.downloadstation.statistics.dart';

part 'dsm_api.docker.dart';
part 'dsm_api.docker.images.dart';
part 'dsm_api.docker.networks.dart';
part 'dsm_api.docker.volumes.dart';

part 'dsm_api.photos.dart';
part 'dsm_api.photos.folders.dart';
part 'dsm_api.photos.items.dart';
part 'dsm_api.photos.sharing.dart';

part 'dsm_api.systemservices.logcenter.dart';
part 'dsm_api.systemservices.universalsearch.dart';
part 'dsm_api.systemservices.dhcpserver.dart';
part 'dsm_api.systemservices.notestation.dart';
part 'dsm_api.systemservices.securityadvisor.dart';
part 'dsm_api.systemservices.usbcopy.dart';

part 'dsm_api.gaps.dart';

part 'dsm_api.taskscheduler.dart';

part 'dsm_api.snapshot.volumesnapshots.dart';
part 'dsm_api.snapshot.dart';

part 'dsm_api.vpn.dart';

part 'dsm_api.drive.dart';

part 'dsm_api.audiostation.dart';

part 'dsm_api.cloudsync.dart';

part 'dsm_api.hyperbackup.dart';

part 'dsm_api.surveillancestation.dart';

part 'dsm_api.virtualization.dart';
part 'dsm_api.virtualization.pages.dart';

part 'dsm_api.control_panel.pages.dart';

part 'dsm_api.directoryserver.dart';

part 'dsm_api.activebackup.core.dart';
part 'dsm_api.activebackup.agent.dart';
part 'dsm_api.activebackup.vm.dart';
part 'dsm_api.activebackup.aem.dart';
part 'dsm_api.activebackup.system.dart';
part 'dsm_api.activebackup.other.dart';

part 'dsm_api.moments.dart';

part 'dsm_api.storage.dart';

// 由 tool/gen_api.py 从抓包生成（不要手改）
part 'dsm_api.captured.g.dart';
