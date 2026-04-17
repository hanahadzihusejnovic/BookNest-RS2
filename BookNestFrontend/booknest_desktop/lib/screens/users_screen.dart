import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/pagination_bar.dart';

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
            // Search bar
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

            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: const [
                  SizedBox(width: 56),
                  _ColHeader('First Name', flex: 2),
                  _ColHeader('Last Name', flex: 2),
                  _ColHeader('Username', flex: 2),
                  _ColHeader('Registration Date', flex: 2),
                  SizedBox(width: 120),
                ],
              ),
            ),
            Divider(color: AppColors.darkBrown.withValues(alpha: 0.25), thickness: 1, height: 12),

            // Users list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.darkBrown))
                  : _filteredUsers.isEmpty
                      ? const Center(
                          child: Text(
                            'No users found.',
                            style: TextStyle(color: AppColors.mediumBrown, fontSize: 14),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                itemCount: _currentPageItems.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: AppColors.darkBrown.withValues(alpha: 0.15),
                                  thickness: 1,
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final user = _currentPageItems[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Row(
                                      children: [
                                        // Avatar
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.mediumBrown,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: user.imageUrl != null
                                                ? Image.network(
                                                    user.imageUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Icon(
                                                      Icons.person_outline,
                                                      color: AppColors.mediumBrown,
                                                      size: 22,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.person_outline,
                                                    color: AppColors.mediumBrown,
                                                    size: 22,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        Expanded(flex: 2, child: Text(user.firstName, style: _rowStyle)),
                                        Expanded(flex: 2, child: Text(user.lastName, style: _rowStyle)),
                                        Expanded(flex: 2, child: Text(user.username, style: _rowStyle)),
                                        Expanded(flex: 2, child: Text(_formatDate(user.createdAt), style: _rowStyle)),

                                        SizedBox(
                                          width: 120,
                                          height: 34,
                                          child: ElevatedButton(
                                            onPressed: () {},
                                            style: ElevatedButton.styleFrom(
                                              elevation: 0,
                                              backgroundColor: AppColors.darkBrown,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                            child: const Text(
                                              'Click for more\ndetails',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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

  static const _rowStyle = TextStyle(
    color: AppColors.darkBrown,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

/* ----------------------- COLUMN HEADER ----------------------- */

class _ColHeader extends StatelessWidget {
  final String text;
  final int flex;

  const _ColHeader(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.darkBrown,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
