import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/family_group_model.dart';
import '../../services/family_group_service.dart';
import 'family_map_screen.dart';

class FamilyGroupScreen extends StatefulWidget {
  const FamilyGroupScreen({super.key});

  @override
  State<FamilyGroupScreen> createState() => _FamilyGroupScreenState();
}

class _FamilyGroupScreenState extends State<FamilyGroupScreen> {
  final FamilyGroupService _groupService = FamilyGroupService();
  bool _isLoading = true;
  FamilyGroup? _familyGroup;
  List<Map<String, dynamic>> _members = [];
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFamilyGroup();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyGroup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final group = await _groupService.getCurrentFamilyGroup();
      setState(() {
        _familyGroup = group;
      });

      if (group != null) {
        final members = await _groupService.getFamilyGroupMembers(group.id);
        setState(() {
          _members = members;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading family group: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreateGroupDialog() {
    _groupNameController.text = 'My Family Group';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Family Group'),
        content: TextField(
          controller: _groupNameController,
          decoration: const InputDecoration(
            labelText: 'Group Name',
            hintText: 'Enter a name for your family group',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _createFamilyGroup();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createFamilyGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final group = await _groupService.createFamilyGroup(
        _groupNameController.text.trim(),
      );

      if (group != null) {
        setState(() {
          _familyGroup = group;
        });
        await _loadFamilyGroup();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Family group created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create family group'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating family group: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showJoinGroupDialog() {
    _inviteCodeController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Family Group'),
        content: TextField(
          controller: _inviteCodeController,
          decoration: const InputDecoration(
            labelText: 'Invite Code',
            hintText: 'Enter the 6-character invite code',
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            LengthLimitingTextInputFormatter(6),
          ],
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _joinFamilyGroup();
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinFamilyGroup() async {
    if (_inviteCodeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-character code')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _groupService.joinFamilyGroup(
        _inviteCodeController.text.toUpperCase(),
      );

      if (success) {
        await _loadFamilyGroup();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined family group!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to join family group. The code may be invalid or the group may be full.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining family group: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _leaveFamilyGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Family Group'),
        content: const Text(
          'Are you sure you want to leave this family group? '
          'If you are the host, another member will become the host.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _groupService.leaveFamilyGroup();

      if (success) {
        setState(() {
          _familyGroup = null;
          _members = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have left the family group'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to leave family group'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving family group: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyInviteCode() {
    if (_familyGroup == null) return;
    
    Clipboard.setData(ClipboardData(text: _familyGroup!.inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied to clipboard')),
    );
  }

  void _navigateToFamilyMap() {
    if (_familyGroup == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FamilyMapScreen(groupId: _familyGroup!.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Group'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_familyGroup == null) {
      return _buildNoGroupContent();
    } else {
      return _buildGroupContent();
    }
  }

  Widget _buildNoGroupContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.group_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'You are not in a family group',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new group or join an existing one',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create Family Group'),
            onPressed: _showCreateGroupDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.group_add),
            label: const Text('Join Family Group'),
            onPressed: _showJoinGroupDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amber,
              side: const BorderSide(color: Colors.amber),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupContent() {
    final isHost = _familyGroup!.hostId == _members.firstWhere(
      (m) => m['isHost'],
      orElse: () => {'userId': ''},
    )['userId'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group info card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _familyGroup!.groupName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map),
                        onPressed: _navigateToFamilyMap,
                        tooltip: 'View on Map',
                        color: Colors.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created on ${_familyGroup!.createdAt.toLocal().toString().split(' ')[0]}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Invite Code: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _familyGroup!.inviteCode,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: _copyInviteCode,
                        tooltip: 'Copy Code',
                        color: Colors.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Members: ${_members.length}/${_familyGroup!.memberLimit}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Members',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // Members list
          Card(
            elevation: 2,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _members.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = _members[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: member['isHost'] ? Colors.amber : Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      color: member['isHost'] ? Colors.black : Colors.grey[700],
                    ),
                  ),
                  title: Text(
                    member['displayName'] ?? 'Unknown User',
                    style: TextStyle(
                      fontWeight: member['isHost'] ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    member['isHost'] ? 'Host' : 'Member',
                    style: TextStyle(
                      color: member['isHost'] ? Colors.amber : Colors.grey,
                    ),
                  ),
                  trailing: member['userId'] == _members.firstWhere(
                    (m) => m['isHost'],
                    orElse: () => {'userId': ''},
                  )['userId']
                      ? const Icon(Icons.star, color: Colors.amber)
                      : null,
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Leave Family Group'),
              onPressed: _leaveFamilyGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
