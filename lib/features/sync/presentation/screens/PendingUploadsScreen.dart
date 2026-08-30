import 'dart:async';
import 'package:capture_sync/features/sync/presentation/screens/widget/sync_action_button.dart';
import 'package:capture_sync/features/sync/presentation/screens/widget/upload_header_bar.dart';
import 'package:capture_sync/features/sync/presentation/screens/widget/upload_item_card.dart';
import 'package:capture_sync/features/sync/presentation/screens/upload_palette.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/ServiceLocator.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/storage/hive_storage.dart';

import '../../data/mock_upload_api.dart';
import '../../data/sync_repository_impl.dart';

import '../../domain/auto_sync_service.dart';
import '../../domain/sync_engine.dart';
import '../../domain/upload_item.dart';
import 'widget/batch_progress_section.dart';



class PendingUploadsScreen extends StatefulWidget {
  const PendingUploadsScreen({super.key});

  @override
  State<PendingUploadsScreen> createState() => _PendingUploadsScreenState();
}

class _PendingUploadsScreenState extends State<PendingUploadsScreen> {
  // ---------------------------------------------------------
  // DEPENDENCIES
  // ---------------------------------------------------------
  late final SyncRepositoryImpl _repository;
  late final SyncEngine _syncEngine;
  late final ConnectivityService _connectivityService;

  // ---------------------------------------------------------
  // STATE
  // ---------------------------------------------------------
  List<UploadItem> _items = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _hasInternet = true;

  StreamSubscription<SyncEvent>? _syncSubscription;

  // ---------------------------------------------------------
  // INIT
  // ---------------------------------------------------------
  @override
  void initState() {
    super.initState();

    final storage = HiveStorage();
    _repository = SyncRepositoryImpl(storage);

    _connectivityService = ConnectivityService();

    final mockApi = MockUploadApi(
      connectivityService: _connectivityService,
      shouldFail: false,
    );

    _syncEngine = SyncEngine(
      repository: _repository,
      api: mockApi,
    );

    _syncSubscription =
        ServiceLocator.autoSyncService.syncEvents.listen(_handleSyncEvent);

    _loadUploads();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final hasInternet = await _connectivityService.hasInternetConnection();
    if (mounted) setState(() => _hasInternet = hasInternet);
  }

  // ---------------------------------------------------------
  // AUTO SYNC EVENTS
  // ---------------------------------------------------------
  Future<void> _handleSyncEvent(SyncEvent event) async {
    if (!mounted) return;

    switch (event) {
      case SyncEvent.offline:
        setState(() => _hasInternet = false);
        break;

      case SyncEvent.syncStarted:
        setState(() {
          _isSyncing = true;
          _hasInternet = true;
        });
        break;

      case SyncEvent.syncCompleted:
        await _loadUploads();
        if (!mounted) return;
        setState(() => _isSyncing = false);
        _showSnack('Pending images uploaded successfully.');
        break;

      case SyncEvent.syncFailed:
        await _loadUploads();
        if (!mounted) return;
        setState(() => _isSyncing = false);
        _showSnack('Upload failed. Images remain in the pending queue.');
        break;
    }
  }

  // ---------------------------------------------------------
  // MANUAL SYNC
  // ---------------------------------------------------------
  Future<void> _syncNow() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    final hasInternet = await _connectivityService.hasInternetConnection();

    if (!hasInternet) {
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _hasInternet = false;
      });
      _showSnack(
        'No internet connection. Upload is not possible right now. '
            'The image will be uploaded automatically when internet is available.',
        duration: const Duration(seconds: 5),
      );
      return;
    }

    setState(() => _hasInternet = true);

    try {
      final success = await _syncEngine.syncPendingUploads();
      if (!mounted) return;

      _showSnack(
        success
            ? 'Images uploaded successfully.'
            : 'Some images could not be uploaded. They remain in the pending queue.',
      );
    } catch (e) {
      debugPrint('Manual sync failed: $e');
      if (!mounted) return;
      _showSnack('Upload failed. The image remains in the pending queue.');
    }

    if (!mounted) return;
    setState(() => _isSyncing = false);
    await _loadUploads();
  }

  // ---------------------------------------------------------
  // LOAD PENDING UPLOADS
  // ---------------------------------------------------------
  Future<void> _loadUploads() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final items = await _repository.getPendingUploads();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load uploads: $e');
      if (!mounted) return;
      setState(() {
        _items = [];
        _isLoading = false;
      });
    }
  }

  void _showSnack(String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }

  // ---------------------------------------------------------
  // DERIVED VALUES
  //
  // NOTE: UploadItem has no file-size / byte-progress field, and
  // getPendingUploads() drops items once uploaded — so this is an
  // item-count based approximation, not true byte-level progress.
  // ---------------------------------------------------------
  int get _uploadedCount =>
      _items.where((i) => i.status == UploadStatus.uploaded).length;

  double get _batchProgress =>
      _items.isEmpty ? 0 : _uploadedCount / _items.length;

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UploadPalette.bg,
      body: SafeArea(
        child: Column(
          children: [
            UploadHeaderBar(
              hasInternet: _hasInternet,
              isSyncing: _isSyncing,
              onTapSync: _syncNow,
            ),
            BatchProgressSection(
              progress: _batchProgress,
              uploadedCount: _uploadedCount,
              totalCount: _items.length,
            ),
            SectionLabel(text: 'PENDING UPLOADS (${_items.length})'),
            Expanded(child: _buildBody()),
            SyncActionButton(
              isSyncing: _isSyncing,
              onPressed: _syncNow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: UploadPalette.blue),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadUploads,
        color: UploadPalette.blue,
        backgroundColor: UploadPalette.card,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 300,
              child: Center(
                child: Text(
                  'No pending uploads',
                  style: TextStyle(
                    fontSize: 16,
                    color: UploadPalette.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUploads,
      color: UploadPalette.blue,
      backgroundColor: UploadPalette.card,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        itemCount: _items.length,
        itemBuilder: (context, index) =>
            UploadItemCard(item: _items[index]),
      ),
    );
  }
}