import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'device_location_service.dart';
import 'location_service.dart';

part 'location_providers.g.dart';

@Riverpod(keepAlive: true)
LocationService locationService(LocationServiceRef ref) => const DeviceLocationService();
