import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';


import '../../../../core/di/ServiceLocator.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/storage/hive_storage.dart';

import '../../data/mock_upload_api.dart';
import '../../data/sync_repository_impl.dart';

import '../../domain/auto_sync_service.dart';
import '../../domain/sync_engine.dart';
import '../../domain/upload_item.dart';

class PendingUploadsScreen extends StatefulWidget {
  const PendingUploadsScreen({
    super.key,
  });

  @override
  State<PendingUploadsScreen> createState() =>
      _PendingUploadsScreenState();
}

class _PendingUploadsScreenState
    extends State<PendingUploadsScreen> {

  // =========================================================
  // DEPENDENCIES
  // =========================================================

  late final SyncRepositoryImpl _repository;

  late final SyncEngine _syncEngine;

  late final ConnectivityService
  _connectivityService;

  // =========================================================
  // STATE
  // =========================================================

  List<UploadItem> _items = [];

  bool _isLoading = true;

  bool _isSyncing = false;

  // =========================================================
  // SYNC EVENT SUBSCRIPTION
  // =========================================================

  StreamSubscription<SyncEvent>?
  _syncSubscription;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    // ---------------------------------------------------------
    // STORAGE
    // ---------------------------------------------------------

    final storage = HiveStorage();

    _repository = SyncRepositoryImpl(
      storage,
    );

    // ---------------------------------------------------------
    // CONNECTIVITY
    // ---------------------------------------------------------

    _connectivityService =
        ConnectivityService();

    // ---------------------------------------------------------
    // MOCK API
    // ---------------------------------------------------------

    final mockApi = MockUploadApi(
      connectivityService:
      _connectivityService,
      shouldFail: false,
    );

    // ---------------------------------------------------------
    // SYNC ENGINE
    // ---------------------------------------------------------

    _syncEngine = SyncEngine(
      repository: _repository,
      api: mockApi,
    );

    // ---------------------------------------------------------
    // LISTEN TO AUTO SYNC EVENTS
    // ---------------------------------------------------------

    _syncSubscription =
        ServiceLocator
            .autoSyncService
            .syncEvents
            .listen(
          _handleSyncEvent,
        );

    // ---------------------------------------------------------
    // LOAD EXISTING UPLOADS
    // ---------------------------------------------------------

    _loadUploads();
  }

  // =========================================================
  // HANDLE AUTO SYNC EVENTS
  // =========================================================

  Future<void> _handleSyncEvent(
      SyncEvent event,
      ) async {
    if (!mounted) {
      return;
    }

    print(
      'PendingUploadsScreen: '
          'Received event = $event',
    );

    switch (event) {

    // -------------------------------------------------------
    // OFFLINE
    // -------------------------------------------------------

      case SyncEvent.offline:

        print(
          'PendingUploadsScreen: Device offline',
        );

        // We don't show a message here because
        // this event can happen frequently.
        //
        // The message is already shown when the
        // user tries to manually upload while offline.

        break;

    // -------------------------------------------------------
    // SYNC STARTED
    // -------------------------------------------------------

      case SyncEvent.syncStarted:

        print(
          'PendingUploadsScreen: '
              'Automatic sync started',
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _isSyncing = true;
        });

        break;

    // -------------------------------------------------------
    // SYNC COMPLETED
    // -------------------------------------------------------

      case SyncEvent.syncCompleted:

        print(
          'PendingUploadsScreen: '
              'Automatic sync completed',
        );

        // -----------------------------------------------------
        // IMPORTANT
        // Reload Hive.
        //
        // Uploaded items are no longer returned by
        // getPendingUploads().
        //
        // Therefore they will disappear from the
        // Pending Uploads list.
        // -----------------------------------------------------

        await _loadUploads();

        if (!mounted) {
          return;
        }

        setState(() {
          _isSyncing = false;
        });

        // -----------------------------------------------------
        // SHOW SUCCESS MESSAGE
        // -----------------------------------------------------

        ScaffoldMessenger.of(context)
            .hideCurrentSnackBar();

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Pending images uploaded successfully.',
            ),
            duration:
            Duration(seconds: 4),
          ),
        );

        break;

    // -------------------------------------------------------
    // SYNC FAILED
    // -------------------------------------------------------

      case SyncEvent.syncFailed:

        print(
          'PendingUploadsScreen: '
              'Automatic sync failed',
        );

        await _loadUploads();

        if (!mounted) {
          return;
        }

        setState(() {
          _isSyncing = false;
        });

        ScaffoldMessenger.of(context)
            .hideCurrentSnackBar();

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Upload failed. '
                  'Images remain in the pending queue.',
            ),
            duration:
            Duration(seconds: 4),
          ),
        );

        break;
    }
  }

  // =========================================================
  // MANUAL SYNC
  // =========================================================

  Future<void> _syncNow() async {

    if (_isSyncing) {
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    // ---------------------------------------------------------
    // CHECK INTERNET
    // ---------------------------------------------------------

    final hasInternet =
    await _connectivityService
        .hasInternetConnection();

    if (!hasInternet) {

      if (!mounted) {
        return;
      }

      setState(() {
        _isSyncing = false;
      });

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'No internet connection. '
                'Upload is not possible right now. '
                'The image will be uploaded automatically '
                'when internet is available.',
          ),
          duration:
          Duration(seconds: 5),
        ),
      );

      return;
    }

    // ---------------------------------------------------------
    // START MANUAL SYNC
    // ---------------------------------------------------------

    try {

      final success =
      await _syncEngine
          .syncPendingUploads();

      if (!mounted) {
        return;
      }

      if (success) {

        ScaffoldMessenger.of(context)
            .hideCurrentSnackBar();

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Images uploaded successfully.',
            ),
          ),
        );

      } else {

        ScaffoldMessenger.of(context)
            .hideCurrentSnackBar();

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Some images could not be uploaded. '
                  'They remain in the pending queue.',
            ),
          ),
        );
      }

    } catch (e) {

      debugPrint(
        'Manual sync failed: $e',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Upload failed. '
                'The image remains in the pending queue.',
          ),
        ),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSyncing = false;
    });

    // ---------------------------------------------------------
    // REFRESH UI
    // ---------------------------------------------------------

    await _loadUploads();
  }

  // =========================================================
  // LOAD PENDING UPLOADS
  // =========================================================

  Future<void> _loadUploads() async {

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {

      final items =
      await _repository
          .getPendingUploads();

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _isLoading = false;
      });

    } catch (e) {

      debugPrint(
        'Failed to load uploads: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items = [];
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {

    _syncSubscription?.cancel();

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pending Uploads',
        ),
        actions: [

          IconButton(
            onPressed:
            _isSyncing
                ? null
                : _syncNow,
            icon:
            _isSyncing
                ? const SizedBox(
              width: 20,
              height: 20,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.sync,
            ),
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  // =========================================================
  // BODY
  // =========================================================

  Widget _buildBody() {

    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_items.isEmpty) {

      return RefreshIndicator(
        onRefresh: _loadUploads,

        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),

          children: const [

            SizedBox(
              height: 300,

              child: Center(
                child: Text(
                  'No pending uploads',

                  style: TextStyle(
                    fontSize: 18,
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

      child: ListView.builder(
        padding:
        const EdgeInsets.all(16),

        itemCount:
        _items.length,

        itemBuilder: (
            context,
            index,
            ) {

          final item =
          _items[index];

          return _UploadItemCard(
            item: item,
          );
        },
      ),
    );
  }
}

// =========================================================
// UPLOAD ITEM CARD
// =========================================================

class _UploadItemCard
    extends StatelessWidget {

  final UploadItem item;

  const _UploadItemCard({
    required this.item,
  });

  @override
  Widget build(
      BuildContext context,
      ) {

    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),

      child: Padding(
        padding:
        const EdgeInsets.all(12),

        child: Row(
          children: [

            _buildImage(),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child:
              _buildDetails(),
            ),

            const SizedBox(
              width: 8,
            ),

            _buildStatus(),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // IMAGE
  // =========================================================

  Widget _buildImage() {

    return ClipRRect(
      borderRadius:
      BorderRadius.circular(8),

      child: Image.file(
        File(item.localPath),

        width: 70,
        height: 70,

        fit: BoxFit.cover,

        errorBuilder: (
            context,
            error,
            stackTrace,
            ) {

          return Container(
            width: 70,
            height: 70,

            color:
            Colors.grey.shade300,

            child: const Icon(
              Icons.image_not_supported,
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // DETAILS
  // =========================================================

  Widget _buildDetails() {

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        const Text(
          'Batch',

          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          item.batchId,

          maxLines: 1,

          overflow:
          TextOverflow.ellipsis,
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          item.localPath
              .split('/')
              .last,

          maxLines: 1,

          overflow:
          TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // =========================================================
  // STATUS
  // =========================================================

  Widget _buildStatus() {

    return _StatusBadge(
      status: item.status,
    );
  }
}

// =========================================================
// STATUS BADGE
// =========================================================

class _StatusBadge
    extends StatelessWidget {

  final UploadStatus status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(
      BuildContext context,
      ) {

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration:
      BoxDecoration(
        color:
        _backgroundColor(),

        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),

      child: Text(
        _text(),

        style: TextStyle(
          color:
          _textColor(),

          fontWeight:
          FontWeight.bold,
        ),
      ),
    );
  }

  String _text() {

    switch (status) {

      case UploadStatus.pending:
        return 'Pending';

      case UploadStatus.uploading:
        return 'Uploading';

      case UploadStatus.uploaded:
        return 'Uploaded';

      case UploadStatus.failed:
        return 'Failed';
    }
  }

  Color _backgroundColor() {

    switch (status) {

      case UploadStatus.pending:
        return Colors
            .orange.shade100;

      case UploadStatus.uploading:
        return Colors
            .blue.shade100;

      case UploadStatus.uploaded:
        return Colors
            .green.shade100;

      case UploadStatus.failed:
        return Colors
            .red.shade100;
    }
  }

  Color _textColor() {

    switch (status) {

      case UploadStatus.pending:
        return Colors
            .orange.shade900;

      case UploadStatus.uploading:
        return Colors
            .blue.shade900;

      case UploadStatus.uploaded:
        return Colors
            .green.shade900;

      case UploadStatus.failed:
        return Colors
            .red.shade900;
    }
  }
}