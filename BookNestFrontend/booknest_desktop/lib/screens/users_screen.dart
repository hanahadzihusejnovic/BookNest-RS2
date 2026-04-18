import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/admin_table.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _userService = UserService();
  final _searchController = TextEditingController();

  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;

  static const int _pageSize = 10;
  int _currentPage = 0;

  List<User> get _currentPageItems {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredUsers.length);
    return _filteredUsers.sublist(start, end);
  }

  int get _totalPages => (_filteredUsers.length / _pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getUsers(pageSize: 200);
      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.show(context, 'Failed to load users', isError: true);
    }
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _currentPage = 0;
      _filteredUsers = q.isEmpty
          ? _allUsers
          : _allUsers.where((u) {
              return u.firstName.toLowerCase().contains(q) ||
                  u.lastName.toLowerCase().contains(q) ||
                  u.username.toLowerCase().contains(q);
            }).toList();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'USERS',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lightBrown.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: AppColors.darkBrown, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search by first name, last name and username',
                  hintStyle: TextStyle(color: AppColors.mediumBrown, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: const [
                  SizedBox(width: 56),
                  AdminColHeader('First Name', flex: 2),
                  AdminColHeader('Last Name', flex: 2),
                  AdminColHeader('Username', flex: 2),
                  AdminColHeader('Registration Date', flex: 2),
                  SizedBox(width: 120),
                ],
              ),
            ),
            Divider(color: AppColors.darkBrown.withValues(alpha: 0.25), thickness: 1, height: 12),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.darkBrown))
                  : _filteredUsers.isEmpty
                      ? const Center(
                          child: Text('No users found.',
                              style: TextStyle(color: AppColors.mediumBrown, fontSize: 14)))
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                itemCount: _currentPageItems.length,
                                separatorBuilder: (_, __) => Divider(
                                    color: AppColors.darkBrown.withValues(alpha: 0.15),
                                    thickness: 1,
                                    height: 1),
                                itemBuilder: (context, index) {
                                  final user = _currentPageItems[index];
                                  return AdminListRow(
                                    leading: AdminAvatar(imageUrl: user.imageUrl),
                                    columns: [
                                      AdminColumn(flex: 2, text: user.firstName),
                                      AdminColumn(flex: 2, text: user.lastName),
                                      AdminColumn(flex: 2, text: user.username),
                                      AdminColumn(flex: 2, text: _formatDate(user.createdAt)),
                                    ],
                                    actions: const [
                                      AdminActionButton(label: 'Click for more\ndetails'),
                                    ],
                                  );
                                },
                              ),
                            ),
                            PaginationBar(
                              currentPage: _currentPage,
                              totalPages: _totalPages,
                              onPrevious: () => setState(() => _currentPage--),
                              onNext: () => setState(() => _currentPage++),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
