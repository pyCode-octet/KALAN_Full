import 'package:equatable/equatable.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class CheckConnectivity extends SyncEvent {}
class ProcessSyncQueue extends SyncEvent {}
