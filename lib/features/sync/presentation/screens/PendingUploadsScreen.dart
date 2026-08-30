import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/storage/hive_storage.dart';
import '../../data/mock_upload_api.dart';
import '../../data/sync_repository_impl.dart';
import '../../domain/sync_engine.dart';
import '../../domain/upload_item.dart';



import '../../../../core/network/connectivity_service.dart';


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
  late final SyncRepositoryImpl _repository;

  late final SyncEngine _syncEngine;

  List<UploadItem> _items = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final storage = HiveStorage();

    _repository = SyncRepositoryImpl(
      storage,
    );

    // Connectivity service
    final connectivityService =
    ConnectivityService();

    // Connectivity-aware Mock API
    final mockApi = MockUploadApi(
      connectivityService: connectivityService,
      shouldFail: false,
    );

    // Sync Engine
    _syncEngine = SyncEngine(
      repository: _repository,
      api: mockApi,
    );

    _loadUploads();
  }

  Future<void> _syncNow() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _syncEngine.syncPendingUploads();
    } catch (e) {
      debugPrint(
        'Manual sync failed: $e',
      );
    }

    await _loadUploads();
  }

  Future<void> _loadUploads() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final items =
      await _repository.getPendingUploads();

      if (!mounted) return;

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Failed to load uploads: $e',
      );

      if (!mounted) return;

      setState(() {
        _items = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pending Uploads',
        ),
        actions: [
          IconButton(
            onPressed:
            _isLoading ? null : _syncNow,
            icon: const Icon(
              Icons.sync,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'No pending uploads',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUploads,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];

          return _UploadItemCard(
            item: item,
          );
        },
      ),
    );
  }
}

class _UploadItemCard extends StatelessWidget {
  final UploadItem item;

  const _UploadItemCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildImage(),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetails(),
            ),
            const SizedBox(width: 8),
            _buildStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
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
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.image_not_supported,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Batch',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          item.batchId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        Text(
          item.localPath.split('/').last,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatus() {
    return _StatusBadge(
      status: item.status,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final UploadStatus status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _text(),
        style: TextStyle(
          color: _textColor(),
          fontWeight: FontWeight.bold,
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
        return Colors.orange.shade100;

      case UploadStatus.uploading:
        return Colors.blue.shade100;

      case UploadStatus.uploaded:
        return Colors.green.shade100;

      case UploadStatus.failed:
        return Colors.red.shade100;
    }
  }

  Color _textColor() {
    switch (status) {
      case UploadStatus.pending:
        return Colors.orange.shade900;

      case UploadStatus.uploading:
        return Colors.blue.shade900;

      case UploadStatus.uploaded:
        return Colors.green.shade900;

      case UploadStatus.failed:
        return Colors.red.shade900;
    }
  }
}

