import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing a family/group subscription
class FamilyGroup {
  /// Unique identifier for the group
  final String id;
  
  /// User ID of the host/creator
  final String hostId;
  
  /// Name of the family/group
  final String groupName;
  
  /// Unique code for others to join
  final String inviteCode;
  
  /// When the group was created
  final DateTime createdAt;
  
  /// Maximum number of members allowed (5 as per requirement)
  final int memberLimit;
  
  /// List of user IDs who are members of this group
  final List<String> members;
  
  /// Whether the group is active
  final bool isActive;

  /// Constructor
  FamilyGroup({
    required this.id,
    required this.hostId,
    required this.groupName,
    required this.inviteCode,
    required this.createdAt,
    this.memberLimit = 5,
    required this.members,
    this.isActive = true,
  });

  /// Create a copy of this group with some fields replaced
  FamilyGroup copyWith({
    String? id,
    String? hostId,
    String? groupName,
    String? inviteCode,
    DateTime? createdAt,
    int? memberLimit,
    List<String>? members,
    bool? isActive,
  }) {
    return FamilyGroup(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      groupName: groupName ?? this.groupName,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      memberLimit: memberLimit ?? this.memberLimit,
      members: members ?? this.members,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Create a group from a Firebase document
  factory FamilyGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FamilyGroup(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      groupName: data['groupName'] ?? 'My Family Group',
      inviteCode: data['inviteCode'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      memberLimit: data['memberLimit'] ?? 5,
      members: List<String>.from(data['members'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Convert this group to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'hostId': hostId,
      'groupName': groupName,
      'inviteCode': inviteCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'memberLimit': memberLimit,
      'members': members,
      'isActive': isActive,
    };
  }
}
