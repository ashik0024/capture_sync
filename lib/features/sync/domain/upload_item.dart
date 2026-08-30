enum UploadStatus {
  pending,
  uploading,
  uploaded,
  failed,
}

class UploadItem {
  final String id;
  final String batchId;
  final String localPath;
  final UploadStatus status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? uploadedAt;

  UploadItem({
    required this.id,
    required this.batchId,
    required this.localPath,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'localPath': localPath,
      'status': status.name,
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
      'uploadedAt': uploadedAt?.toIso8601String(),
    };
  }

  factory UploadItem.fromMap(
      Map<dynamic, dynamic> map,
      ) {
    return UploadItem(
      id: map['id'] as String,
      batchId: map['batchId'] as String,
      localPath: map['localPath'] as String,
      status: UploadStatus.values.firstWhere(
            (status) => status.name == map['status'],
      ),
      retryCount: map['retryCount'] as int,
      createdAt: DateTime.parse(
        map['createdAt'] as String,
      ),
      uploadedAt: map['uploadedAt'] != null
          ? DateTime.parse(
        map['uploadedAt'] as String,
      )
          : null,
    );
  }
}