import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/user.dart';
import '../models/review.dart';
import '../models/reservation.dart';
import '../models/order.dart';
import '../services/user_service.dart';
import '../services/reservation_service.dart';
import '../services/order_service.dart';
import '../widgets/admin_table.dart';
import '../widgets/book_form_widgets.dart';
import 'users_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _userService = UserService();
  final _reservationService = ReservationService();
  final _orderService = OrderService();
  User? _user;
  List<Review> _reviews = [];
  List<Reservation> _reservations = [];
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _userService.getUser(widget.userId),
        _userService.getUserReviews(widget.userId),
        _userService.getUserReservations(widget.userId),
        _userService.getUserOrders(widget.userId),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as User;
        _reviews = results[1] as List<Review>;
        _reservations = results[2] as List<Reservation>;
        _orders = results[3] as List<Order>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.show(context, 'Failed to load user', isError: true);
      }
    }
  }

  String _fmt(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}.${date.month}.${date.year}';
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Delete User',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${_user!.fullName}"?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFE57373))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _userService.deleteUser(widget.userId);
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const UsersScreen()));
        AppSnackBar.show(context, 'User deleted successfully');
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to delete user', isError: true);
    }
  }

  void _openEditDialog() {
    if (_user == null) return;
    showDialog(
      context: context,
      builder: (_) => _EditUserDialog(user: _user!, onUpdated: _loadData),
    );
  }

  Future<void> _deleteReview(int reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Delete Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete this review?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Color(0xFFE57373)))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _userService.deleteReview(reviewId);
      if (mounted) {
        AppSnackBar.show(context, 'Review deleted');
        _loadData();
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to delete review', isError: true);
    }
  }

  // Reservation: Pending(0)→Confirmed(1)/Cancelled(2), Confirmed(1)→Attended(3)/Cancelled(2)
  static const _reservationTransitions = {
    'Pending':   [('Confirmed', 1), ('Cancelled', 2)],
    'Confirmed': [('Attended', 3), ('Cancelled', 2)],
  };

  Future<void> _changeReservationStatus(Reservation r) async {
    final options = _reservationTransitions[r.reservationStatus];
    if (options == null || options.isEmpty) return;
    final chosen = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Change Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((o) => ListTile(
            title: Text(o.$1, style: const TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(ctx, o.$2),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown))),
        ],
      ),
    );
    if (chosen == null || !mounted) return;
    try {
      await _reservationService.updateStatus(r.id, chosen);
      if (mounted) {
        AppSnackBar.show(context, 'Status updated');
        _loadData();
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to update status', isError: true);
    }
  }

  // Order: Pending(0)→Processing(1), Processing(1)→Shipped(2), Shipped(2)→Delivered(3), any→Cancelled(4)
  static const _orderTransitions = {
    'Pending':    [('Processing', 1), ('Cancelled', 4)],
    'Processing': [('Shipped', 2),    ('Cancelled', 4)],
    'Shipped':    [('Delivered', 3),  ('Cancelled', 4)],
  };

  Future<void> _changeOrderStatus(Order o) async {
    final options = _orderTransitions[o.status];
    if (options == null || options.isEmpty) return;
    final chosen = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Change Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => ListTile(
            title: Text(opt.$1, style: const TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(ctx, opt.$2),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown))),
        ],
      ),
    );
    if (chosen == null || !mounted) return;
    try {
      await _orderService.updateStatus(o.id, chosen);
      if (mounted) {
        AppSnackBar.show(context, 'Status updated');
        _loadData();
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to update status', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'USERS',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.darkBrown))
          : _user == null
              ? const Center(
                  child: Text('User not found.',
                      style: TextStyle(color: AppColors.mediumBrown)))
              : _buildContent(_user!),
    );
  }

  Widget _buildContent(User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const UsersScreen())),
            icon: const Icon(Icons.arrow_back, color: AppColors.darkBrown, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(user),
              const SizedBox(width: 32),
              Expanded(child: _buildDetails(user)),
              const SizedBox(width: 28),
              _buildActionButtons(),
            ],
          ),
          const SizedBox(height: 32),
          _buildReviews(),
          const SizedBox(height: 32),
          _buildReservations(),
          const SizedBox(height: 32),
          _buildOrders(),
        ],
      ),
    );
  }

  Widget _buildAvatar(User user) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.lightBrown.withValues(alpha: 0.3),
      ),
      child: ClipOval(
        child: user.imageUrl != null && user.imageUrl!.isNotEmpty
            ? Image.network(user.imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.person_outline, color: AppColors.mediumBrown, size: 72))
            : const Icon(Icons.person_outline, color: AppColors.mediumBrown, size: 72),
      ),
    );
  }

  Widget _buildDetails(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow('First Name:', user.firstName),
        const SizedBox(height: 10),
        _DetailRow('Last Name:', user.lastName),
        const SizedBox(height: 10),
        _DetailRow('Username:', user.username),
        const SizedBox(height: 10),
        _DetailRow('Email:', user.emailAddress),
        const SizedBox(height: 10),
        _DetailRow('Date of Birth:', _fmt(user.dateOfBirth)),
        const SizedBox(height: 10),
        _DetailRow('Phone:', user.phoneNumber ?? '-'),
        const SizedBox(height: 10),
        _DetailRow('Address:', user.address ?? '-'),
        const SizedBox(height: 10),
        _DetailRow('City:', user.city ?? '-'),
        const SizedBox(height: 10),
        _DetailRow('Country:', user.country ?? '-'),
        const SizedBox(height: 10),
        _DetailRow('Member Since:', _fmt(user.createdAt)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _UserActionButton(
          icon: Icons.edit_outlined,
          label: 'EDIT USER',
          onTap: _openEditDialog,
        ),
        const SizedBox(height: 12),
        _UserActionButton(
          icon: Icons.delete_outline,
          label: 'DELETE USER',
          onTap: _deleteUser,
        ),
      ],
    );
  }

  Widget _buildReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reviews',
            style: TextStyle(
                color: AppColors.darkBrown, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: const [
              Expanded(flex: 3, child: Text('Book', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Rating', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 4, child: Text('Review', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Date', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              SizedBox(width: 140),
            ],
          ),
        ),
        Divider(color: AppColors.darkBrown.withValues(alpha: 0.25), thickness: 1, height: 12),
        if (_reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No reviews yet.',
                style: TextStyle(color: AppColors.mediumBrown, fontSize: 14)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (_, __) =>
                Divider(color: AppColors.darkBrown.withValues(alpha: 0.15), thickness: 1, height: 1),
            itemBuilder: (ctx, i) {
              final r = _reviews[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(r.bookTitle ?? '-', style: adminRowStyle, overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 2, child: _StarRow(r.rating)),
                    Expanded(flex: 4, child: Text(r.comment ?? '-', style: adminRowStyle, overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 2, child: Text(_fmt(r.createdAt), style: adminRowStyle)),
                    SizedBox(
                      width: 140,
                      height: 34,
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteReview(r.id),
                        icon: const Icon(Icons.delete_outline, size: 15),
                        label: const Text('DELETE REVIEW',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.darkBrown,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildReservations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reservations',
            style: TextStyle(
                color: AppColors.darkBrown, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: const [
              Expanded(flex: 3, child: Text('Event', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Location', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Event Date', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 1, child: Text('Qty', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Total', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Status', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              SizedBox(width: 140),
            ],
          ),
        ),
        Divider(color: AppColors.darkBrown.withValues(alpha: 0.25), thickness: 1, height: 12),
        if (_reservations.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No reservations yet.',
                style: TextStyle(color: AppColors.mediumBrown, fontSize: 14)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reservations.length,
            separatorBuilder: (_, __) =>
                Divider(color: AppColors.darkBrown.withValues(alpha: 0.15), thickness: 1, height: 1),
            itemBuilder: (ctx, i) {
              final r = _reservations[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(r.eventName, style: adminRowStyle, overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 2, child: Text(r.eventLocation, style: adminRowStyle, overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 2, child: Text(_fmt(r.eventDateTime), style: adminRowStyle)),
                    Expanded(flex: 1, child: Text('${r.quantity}', style: adminRowStyle)),
                    Expanded(flex: 2, child: Text('${r.totalPrice.toStringAsFixed(2)} BAM', style: adminRowStyle)),
                    Expanded(flex: 2, child: Text(r.reservationStatus, style: adminRowStyle)),
                    if (_reservationTransitions.containsKey(r.reservationStatus))
                      SizedBox(
                        width: 140,
                        height: 34,
                        child: ElevatedButton.icon(
                          onPressed: () => _changeReservationStatus(r),
                          icon: const Icon(Icons.swap_horiz, size: 15),
                          label: const Text('CHANGE STATUS',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.darkBrown,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 140),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Orders',
            style: TextStyle(
                color: AppColors.darkBrown, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: const [
              Expanded(flex: 1, child: Text('Order ID', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Order Date', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 1, child: Text('Items', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Total', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Status', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              SizedBox(width: 140),
            ],
          ),
        ),
        Divider(color: AppColors.darkBrown.withValues(alpha: 0.25), thickness: 1, height: 12),
        if (_orders.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No orders yet.',
                style: TextStyle(color: AppColors.mediumBrown, fontSize: 14)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _orders.length,
            separatorBuilder: (_, __) =>
                Divider(color: AppColors.darkBrown.withValues(alpha: 0.15), thickness: 1, height: 1),
            itemBuilder: (ctx, i) {
              final o = _orders[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    Expanded(flex: 1, child: Text('#${o.id}', style: adminRowStyle)),
                    Expanded(flex: 2, child: Text(_fmt(o.orderDate), style: adminRowStyle)),
                    Expanded(flex: 1, child: Text('${o.itemCount}', style: adminRowStyle)),
                    Expanded(flex: 2, child: Text('${o.totalPrice.toStringAsFixed(2)} BAM', style: adminRowStyle)),
                    Expanded(flex: 2, child: Text(o.status, style: adminRowStyle)),
                    if (_orderTransitions.containsKey(o.status))
                      SizedBox(
                        width: 140,
                        height: 34,
                        child: ElevatedButton.icon(
                          onPressed: () => _changeOrderStatus(o),
                          icon: const Icon(Icons.swap_horiz, size: 15),
                          label: const Text('CHANGE STATUS',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.darkBrown,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 140),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.darkBrown,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
        ),
        Expanded(
          child: Text(value ?? '-',
              style: const TextStyle(color: AppColors.darkBrown, fontSize: 15)),
        ),
      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;
  const _StarRow(this.rating);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 14,
          color: const Color(0xFFE8A838),
        ),
      ),
    );
  }
}

class _UserActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UserActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.darkBrown,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// ─── Edit Dialog ─────────────────────────────────────────────────────────────

class _EditUserDialog extends StatefulWidget {
  final User user;
  final VoidCallback onUpdated;

  const _EditUserDialog({required this.user, required this.onUpdated});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _userService = UserService();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;

  String? _firstNameError;
  String? _lastNameError;
  String? _usernameError;
  String? _emailError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.emailAddress);
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _cityController = TextEditingController(text: widget.user.city ?? '');
    _countryController = TextEditingController(text: widget.user.country ?? '');
  }

  bool _validate() {
    setState(() {
      _firstNameError = _firstNameController.text.trim().isEmpty ? 'Required' : null;
      _lastNameError = _lastNameController.text.trim().isEmpty ? 'Required' : null;
      _usernameError = _usernameController.text.trim().isEmpty ? 'Required' : null;
      _emailError = _emailController.text.trim().isEmpty ? 'Required' : null;
    });
    return _firstNameError == null && _lastNameError == null &&
        _usernameError == null && _emailError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    try {
      await _userService.updateUser(widget.user.id, {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'emailAddress': _emailController.text.trim(),
        if (_phoneController.text.trim().isNotEmpty) 'phoneNumber': _phoneController.text.trim(),
        if (_addressController.text.trim().isNotEmpty) 'address': _addressController.text.trim(),
        if (_cityController.text.trim().isNotEmpty) 'city': _cityController.text.trim(),
        if (_countryController.text.trim().isNotEmpty) 'country': _countryController.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
        AppSnackBar.show(context, 'User updated successfully');
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to update user', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkBrown,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 600,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'EDIT USER',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        BookFormField(controller: _firstNameController, hint: 'First Name', error: _firstNameError, onChanged: (_) => setState(() => _firstNameError = null)),
                        const SizedBox(height: 16),
                        BookFormField(controller: _lastNameController, hint: 'Last Name', error: _lastNameError, onChanged: (_) => setState(() => _lastNameError = null)),
                        const SizedBox(height: 16),
                        BookFormField(controller: _usernameController, hint: 'Username', error: _usernameError, onChanged: (_) => setState(() => _usernameError = null)),
                        const SizedBox(height: 16),
                        BookFormField(controller: _emailController, hint: 'Email', error: _emailError, keyboardType: TextInputType.emailAddress, onChanged: (_) => setState(() => _emailError = null)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        BookFormField(controller: _phoneController, hint: 'Phone (optional)', keyboardType: TextInputType.phone, onChanged: (_) {}),
                        const SizedBox(height: 16),
                        BookFormField(controller: _addressController, hint: 'Address (optional)', onChanged: (_) {}),
                        const SizedBox(height: 16),
                        BookFormField(controller: _cityController, hint: 'City (optional)', onChanged: (_) {}),
                        const SizedBox(height: 16),
                        BookFormField(controller: _countryController, hint: 'Country (optional)', onChanged: (_) {}),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.lightBrown),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightBrown,
                        disabledBackgroundColor: AppColors.lightBrown.withValues(alpha: 0.7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(color: AppColors.darkBrown, strokeWidth: 2))
                          : const Text('Save',
                              style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }
}
