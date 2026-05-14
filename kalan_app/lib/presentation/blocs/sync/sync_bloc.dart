import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kalan_app/services/sync_service.dart';
import 'package:kalan_app/services/connectivity_service.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final ConnectivityService _connectivity = ConnectivityService();

  SyncBloc() : super(SyncInitial()) {
    on<CheckConnectivity>((event, emit) async {
      if (await _connectivity.isOnline()) {
        emit(SyncSuccess());
      } else {
        emit(SyncOffline());
      }
    });

    on<ProcessSyncQueue>((event, emit) async {
      if (!(await _connectivity.isOnline())) {
        emit(SyncOffline());
        return;
      }
      
      emit(SyncInProgress());
      try {
        await SyncService.instance.processQueue();
        emit(SyncSuccess());
      } catch (e) {
        emit(SyncFailure(e.toString()));
      }
    });
  }
}
