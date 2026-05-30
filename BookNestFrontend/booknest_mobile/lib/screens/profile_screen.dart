import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user.dart';
import '../models/city.dart';
import '../models/country.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/city_service.dart';
import '../services/country_service.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import '../screens/login_screen.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/reservation_service.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/pagination_bar.dart';

class ProfileScreen extends StatefulWidget {
  final int initialTab;

  const ProfileScreen({super.key, this.initialTab = 0});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _userService = UserService();
  final _cityService = CityService();
  final _countryService = CountryService();
  User? _user;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  List<Country> _countries = [];
  List<City> _cities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _loadUser();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    try {
      final results = await Future.wait([
        _countryService.getCountries(),
        _cityService.getCities(),
      ]);
      if (mounted) {
        setState(() {
          _countries = results[0] as List<Country>;
          _cities = results[1] as List<City>;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _userService.getCurrentUser();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();
    await NotificationService().disconnect();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'MY PROFILE',
      onBack: () => Navigator.pop(context),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.darkBrown),
            )
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppColors.darkBrown),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.mediumBrown,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _user!.fullName.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _InfoRow(
                                      label: 'Username',
                                      value: _user!.username),
                                  _InfoRow(
                                      label: 'Email',
                                      value: _user!.emailAddress),
                                  if (_user!.phoneNumber != null)
                                    _InfoRow(
                                        label: 'Phone',
                                        value: _user!.phoneNumber!),
                                  if (_user!.address != null)
                                    _InfoRow(
                                        label: 'Address',
                                        value: [
                                          _user!.address
                                        ]
                                            .where((e) => e != null)
                                            .join(', ')),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _ProfileButton(
                                          text: 'Edit profile',
                                          onTap: _showEditProfileDialog,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _ProfileButton(
                                          text: 'Logout',
                                          onTap: _logout,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.pageBg.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: _user!.imageUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        _user!.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _avatarFallback(),
                                      ),
                                    )
                                  : _avatarFallback(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.mediumBrown,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: AppColors.darkBrown,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white,
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                          tabs: const [
                            Tab(text: 'ORDERS'),
                            Tab(text: 'RESERVATIONS'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _MyOrdersTab(),
                          _ReservationsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _avatarFallback() {
    return Icon(
      Icons.person_outline,
      color: Colors.white.withValues(alpha: 0.8),
      size: 40,
    );
  }

  void _showEditProfileDialog() {
    final firstNameController = TextEditingController(text: _user!.firstName);
    final lastNameController = TextEditingController(text: _user!.lastName);
    final usernameController = TextEditingController(text: _user!.username);
    final emailController = TextEditingController(text: _user!.emailAddress);
    final phoneController = TextEditingController(text: _user!.phoneNumber ?? '');
    final addressController = TextEditingController(text: _user!.address ?? '');

    final matchingCountries = _countries.where((c) => c.id == _user!.countryId);
    Country? selectedCountry = matchingCountries.isNotEmpty ? matchingCountries.first : null;
    List<City> filteredCities = selectedCountry != null
        ? _cities.where((c) => c.countryId == selectedCountry!.id).toList()
        : [];
    final matchingCities = filteredCities.where((c) => c.id == _user!.cityId);
    City? selectedCity = matchingCities.isNotEmpty ? matchingCities.first : null;

    File? selectedImage;
    bool imageDeleted = false;

    String? firstNameError;
    String? lastNameError;
    String? usernameError;
    String? emailError;
    String? phoneError;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            ImageProvider? currentImageProvider;
            if (selectedImage != null) {
              currentImageProvider = FileImage(selectedImage!);
            } else if (!imageDeleted && _user!.imageUrl != null) {
              currentImageProvider = NetworkImage(_user!.imageUrl!);
            }
            final hasImage = currentImageProvider != null;

            return AlertDialog(
              backgroundColor: AppColors.pageBg,
              title: Row(
                children: [
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'Edit profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: AppColors.darkBrown, size: 20),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final result = await FilePicker.platform.pickFiles(
                                  type: FileType.image, allowMultiple: false);
                              if (result != null && result.files.single.path != null) {
                                setDialogState(() {
                                  selectedImage = File(result.files.single.path!);
                                  imageDeleted = false;
                                });
                              }
                            },
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor:
                                  AppColors.mediumBrown.withValues(alpha: 0.3),
                              backgroundImage: currentImageProvider,
                              child: !hasImage
                                  ? const Icon(Icons.person,
                                      size: 40, color: AppColors.darkBrown)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  final result = await FilePicker.platform.pickFiles(
                                      type: FileType.image, allowMultiple: false);
                                  if (result != null &&
                                      result.files.single.path != null) {
                                    setDialogState(() {
                                      selectedImage =
                                          File(result.files.single.path!);
                                      imageDeleted = false;
                                    });
                                  }
                                },
                                child: Text('Change photo',
                                    style: TextStyle(
                                        color: AppColors.darkBrown,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ),
                              if (hasImage) ...[
                                Text('  |  ',
                                    style: TextStyle(
                                        color: AppColors.darkBrown
                                            .withValues(alpha: 0.4))),
                                GestureDetector(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: AppColors.pageBg,
                                        title: Text(
                                          'Remove photo',
                                          style: TextStyle(
                                            color: AppColors.darkBrown,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        content: Text(
                                          'Are you sure you want to remove your profile photo?',
                                          style: TextStyle(
                                            color: AppColors.darkBrown.withValues(alpha: 0.8),
                                            fontSize: 14,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: Text('No',
                                                style: TextStyle(color: AppColors.darkBrown)),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red),
                                            child: const Text('Yes',
                                                style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      setDialogState(() {
                                        selectedImage = null;
                                        imageDeleted = true;
                                      });
                                    }
                                  },
                                  child: Text('Remove',
                                      style: TextStyle(
                                          color: Colors.red.withValues(alpha: 0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _EditField(
                      controller: firstNameController,
                      hint: 'First name',
                      maxLength: 50,
                      errorText: firstNameError,
                      onChanged: () => setDialogState(() => firstNameError = null),
                    ),
                    const SizedBox(height: 20),
                    _EditField(
                      controller: lastNameController,
                      hint: 'Last name',
                      maxLength: 50,
                      errorText: lastNameError,
                      onChanged: () => setDialogState(() => lastNameError = null),
                    ),
                    const SizedBox(height: 20),
                    _EditField(
                      controller: usernameController,
                      hint: 'Username',
                      maxLength: 100,
                      errorText: usernameError,
                      onChanged: () => setDialogState(() => usernameError = null),
                    ),
                    const SizedBox(height: 20),
                    _EditField(
                      controller: emailController,
                      hint: 'Email',
                      maxLength: 50,
                      keyboardType: TextInputType.emailAddress,
                      errorText: emailError,
                      onChanged: () => setDialogState(() => emailError = null),
                    ),
                    const SizedBox(height: 20),
                    _EditField(
                      controller: phoneController,
                      hint: 'Phone (optional)',
                      maxLength: 20,
                      keyboardType: TextInputType.phone,
                      errorText: phoneError,
                      onChanged: () => setDialogState(() => phoneError = null),
                    ),
                    const SizedBox(height: 20),
                    _EditField(
                      controller: addressController,
                      hint: 'Address (optional)',
                      maxLength: 255,
                    ),
                    const SizedBox(height: 20),
                    AppDropdown<Country>(
                      hint: 'Country (optional)',
                      value: selectedCountry,
                      items: _countries,
                      labelFn: (c) => c.name,
                      onChanged: (country) {
                        setDialogState(() {
                          selectedCountry = country;
                          selectedCity = null;
                          filteredCities = country == null
                              ? []
                              : _cities
                                  .where((c) => c.countryId == country.id)
                                  .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    AppDropdown<City>(
                      hint: selectedCountry == null
                          ? 'Select country first'
                          : 'City (optional)',
                      value: selectedCity,
                      items: filteredCities,
                      labelFn: (c) => c.name,
                      onChanged: selectedCountry == null
                          ? null
                          : (city) => setDialogState(() => selectedCity = city),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() {
                            final fn = firstNameController.text.trim();
                            if (fn.isEmpty) {
                              firstNameError = 'First name is required';
                            } else if (fn.length < 2) {
                              firstNameError = 'Min 2 characters';
                            } else {
                              firstNameError = null;
                            }

                            final ln = lastNameController.text.trim();
                            if (ln.isEmpty) {
                              lastNameError = 'Last name is required';
                            } else if (ln.length < 2) {
                              lastNameError = 'Min 2 characters';
                            } else {
                              lastNameError = null;
                            }

                            final un = usernameController.text.trim();
                            if (un.isEmpty) {
                              usernameError = 'Username is required';
                            } else if (un.length < 4) {
                              usernameError = 'Min 4 characters';
                            } else if (un.length > 20) {
                              usernameError = 'Max 20 characters';
                            } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(un)) {
                              usernameError = 'Only letters, numbers and _';
                            } else {
                              usernameError = null;
                            }

                            final em = emailController.text.trim();
                            final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                            if (em.isEmpty) {
                              emailError = 'Email is required';
                            } else if (!emailRegex.hasMatch(em)) {
                              emailError = 'Invalid email format';
                            } else {
                              emailError = null;
                            }

                            final ph = phoneController.text;
                            if (ph.isNotEmpty) {
                              if (!RegExp(r'^\+?[0-9\s\-\(\)]{7,20}$').hasMatch(ph)) {
                                phoneError = 'Enter a valid phone number (e.g. +387 61 234 567)';
                              } else {
                                phoneError = null;
                              }
                            } else {
                              phoneError = null;
                            }

                          });
                          if (firstNameError != null ||
                              lastNameError != null ||
                              usernameError != null ||
                              emailError != null ||
                              phoneError != null) {
                            return;
                          }

                          final nav = Navigator.of(context);
                          final overlay = Overlay.of(context);
                          setDialogState(() => isSubmitting = true);
                          try {
                            String? newImageUrl;
                            if (selectedImage != null) {
                              newImageUrl =
                                  await _userService.uploadImage(selectedImage!);
                            } else if (imageDeleted) {
                              newImageUrl = null;
                            } else {
                              newImageUrl = _user!.imageUrl;
                            }

                            final updated = await _userService.updateSelf(
                              firstName: firstNameController.text.trim(),
                              lastName: lastNameController.text.trim(),
                              username: usernameController.text.trim(),
                              emailAddress: emailController.text.trim(),
                              phoneNumber: phoneController.text.isEmpty
                                  ? null
                                  : phoneController.text,
                              address: addressController.text.isEmpty
                                  ? null
                                  : addressController.text,
                              cityId: selectedCity?.id,
                              countryId: selectedCountry?.id,
                              imageUrl: newImageUrl,
                            );
                            if (mounted) {
                              setState(() => _user = updated);
                              nav.pop();
                              AppSnackBar.show(overlay, 'Profile updated!');
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) AppSnackBar.showError(overlay, e);
                          }
                        },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppColors.darkBrown),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/* ----------------------- INFO ROW ----------------------- */

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, height: 1.3),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------------- PROFILE BUTTON ----------------------- */

class _ProfileButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _ProfileButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.darkBrown,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/* ----------------------- MY ORDERS TAB ----------------------- */

class _MyOrdersTab extends StatefulWidget {
  const _MyOrdersTab();

  @override
  State<_MyOrdersTab> createState() => _MyOrdersTabState();
}

class _MyOrdersTabState extends State<_MyOrdersTab>
    with AutomaticKeepAliveClientMixin {
  final _orderService = OrderService();
  final _notificationService = NotificationService();
  Timer? _refreshTimer;
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _error;

  static const int _pageSize = 10;
  int _currentPage = 0;

  List<OrderModel> get _currentPageItems {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _orders.length);
    return _orders.sublist(start, end);
  }

  int get _totalPages => (_orders.length / _pageSize).ceil();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _notificationService.addListener(_onNotification);
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) { if (mounted) _loadOrders(); },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationService.removeListener(_onNotification);
    super.dispose();
  }

  void _onNotification(Map<String, dynamic> _) {
    if (mounted) _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _orderService.getMyOrders();
      orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _isLoading
        ? Center(child: CircularProgressIndicator(color: AppColors.darkBrown))
        : _error != null
            ? Center(child: Text(_error!, style: TextStyle(color: AppColors.darkBrown)))
            : _orders.isEmpty
                ? Center(
                    child: Text(
                      'No orders yet.',
                      style: TextStyle(
                        color: AppColors.darkBrown,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                          itemCount: _currentPageItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = _currentPageItems[index];
                            return _OrderCard(
                              order: order,
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => _OrderDetailsDialog(order: order),
                              ),
                              onCancelled: _loadOrders,
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
                  );
  }
}

/* ----------------------- ORDER CARD ----------------------- */

class _OrderCard extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback onCancelled;

  const _OrderCard({required this.order, required this.onTap, required this.onCancelled});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  final _orderService = OrderService();
  bool _isCancelling = false;

  bool get _canCancel => widget.order.status == 'Pending';

  Color _statusColor() {
    switch (widget.order.status.toLowerCase()) {
      case 'delivered': return const Color(0xFF4CAF50);
      case 'cancelled': return const Color(0xFFE53935);
      case 'shipped':   return const Color(0xFF2196F3);
      default: return AppColors.darkBrown;
    }
  }

  Future<void> _showCancelDialog() async {
    final reasonController = TextEditingController();
    final overlay = Overlay.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pageBg,
        title: Text('Cancel order',
            style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel order #${widget.order.id}?',
                style: TextStyle(color: AppColors.darkBrown.withValues(alpha: 0.8), fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              style: TextStyle(color: AppColors.darkBrown, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Reason for cancellation...',
                hintStyle: TextStyle(color: AppColors.darkBrown.withValues(alpha: 0.4), fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No', style: TextStyle(color: AppColors.darkBrown)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      AppSnackBar.show(overlay, 'Cancellation reason is required', isError: true);
      return;
    }
    setState(() => _isCancelling = true);
    try {
      await _orderService.cancelOrder(widget.order.id, reason);
      if (mounted) {
        widget.onCancelled();
        AppSnackBar.show(overlay, 'Order cancelled');
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(overlay, e);
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final d = order.orderDate;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final itemCount = order.orderItems.fold(0, (s, i) => s + i.quantity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mediumBrown,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                _OrderInfoRow('Date', dateStr),
                _OrderInfoRow(
                  'Items',
                  '$itemCount ${itemCount == 1 ? 'book' : 'books'}',
                ),
                _OrderInfoRow(
                  'Total',
                  '${order.totalPrice.toStringAsFixed(2)} BAM',
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 11, height: 1.3),
                    children: [
                      const TextSpan(
                        text: 'Status: ',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: order.status,
                        style: TextStyle(
                          color: _statusColor(),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 92,
                child: ElevatedButton(
                  onPressed: widget.onTap,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.darkBrown,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  ),
                  child: const Text(
                    'View\ndetails',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              if (_canCancel) ...[
                const SizedBox(height: 6),
                SizedBox(
                  width: 92,
                  child: ElevatedButton(
                    onPressed: _isCancelling ? null : _showCancelDialog,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFFB71C1C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    ),
                    child: _isCancelling
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Cancel order',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _OrderInfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, height: 1.3),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------- ORDER DETAILS DIALOG ----------------------- */

class _OrderDetailsDialog extends StatelessWidget {
  final OrderModel order;

  const _OrderDetailsDialog({required this.order});

  Color _statusColor() {
    switch (order.status.toLowerCase()) {
      case 'delivered': return const Color(0xFF4CAF50);
      case 'cancelled': return const Color(0xFFE53935);
      case 'shipped':   return const Color(0xFF2196F3);
      default: return AppColors.darkBrown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = order.orderDate;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

    return AlertDialog(
      backgroundColor: AppColors.pageBg,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'Order #${order.id}',
              style: TextStyle(
                color: AppColors.darkBrown,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            order.status,
            style: TextStyle(
              color: _statusColor(),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: $dateStr',
              style: TextStyle(
                color: AppColors.darkBrown.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Items',
              style: TextStyle(
                color: AppColors.darkBrown,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            Divider(color: AppColors.darkBrown.withValues(alpha: 0.3)),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  children: order.orderItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              width: 46,
                              height: 62,
                              child: item.bookImageUrl != null &&
                                      item.bookImageUrl!.isNotEmpty
                                  ? Image.network(
                                      item.bookImageUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          _bookFallback(),
                                    )
                                  : _bookFallback(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.bookTitle,
                                  style: TextStyle(
                                    color: AppColors.darkBrown,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (item.bookAuthorName != null)
                                  Text(
                                    item.bookAuthorName!,
                                    style: TextStyle(
                                      color: AppColors.darkBrown
                                          .withValues(alpha: 0.65),
                                      fontSize: 11,
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  'Quantity: ${item.quantity}',
                                  style: TextStyle(
                                    color: AppColors.darkBrown.withValues(alpha: 0.75),
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  'Price per book: ${item.price.toStringAsFixed(2)} BAM',
                                  style: TextStyle(
                                    color: AppColors.darkBrown.withValues(alpha: 0.75),
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  'Total: ${item.subtotal.toStringAsFixed(2)} BAM',
                                  style: TextStyle(
                                    color: AppColors.darkBrown,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Divider(color: AppColors.darkBrown.withValues(alpha: 0.3)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL',
                  style: TextStyle(
                    color: AppColors.darkBrown,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${order.totalPrice.toStringAsFixed(2)} BAM',
                  style: TextStyle(
                    color: AppColors.darkBrown,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: TextStyle(color: AppColors.darkBrown)),
        ),
      ],
    );
  }

  Widget _bookFallback() {
    return Container(
      color: AppColors.mediumBrown.withValues(alpha: 0.3),
      child: Icon(
        Icons.menu_book_rounded,
        color: AppColors.darkBrown.withValues(alpha: 0.5),
        size: 20,
      ),
    );
  }
}

/* ----------------------- RESERVATIONS TAB ----------------------- */

class _ReservationsTab extends StatefulWidget {
  const _ReservationsTab();

  @override
  State<_ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<_ReservationsTab>
    with AutomaticKeepAliveClientMixin {
  final _reservationService = ReservationService();
  final _notificationService = NotificationService();
  Timer? _refreshTimer;
  List<ReservationModel> _reservations = [];
  bool _isLoading = true;
  String? _error;

  static const int _pageSize = 12;
  int _currentPage = 0;

  List<ReservationModel> get _currentPageItems {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _reservations.length);
    return _reservations.sublist(start, end);
  }

  int get _totalPages => (_reservations.length / _pageSize).ceil();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
    _notificationService.addListener(_onNotification);
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) { if (mounted) _loadReservations(); },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationService.removeListener(_onNotification);
    super.dispose();
  }

  void _onNotification(Map<String, dynamic> _) {
    if (mounted) _loadReservations();
  }

  Future<void> _loadReservations() async {
    try {
      final reservations = await _reservationService.getMyReservations();
      if (!mounted) return;
      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _isLoading
        ? Center(
            child: CircularProgressIndicator(color: AppColors.darkBrown))
        : _error != null
            ? Center(
                child: Text(_error!,
                    style: TextStyle(color: AppColors.darkBrown)))
            : _reservations.isEmpty
                ? Center(
                    child: Text(
                      'No reservations yet.',
                      style: TextStyle(
                        color: AppColors.darkBrown,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                          itemCount: _currentPageItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _ReservationCard(
                              reservation: _currentPageItems[index],
                              onCancelled: _loadReservations,
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
                  );
  }
}

class _ReservationCard extends StatefulWidget {
  final ReservationModel reservation;
  final VoidCallback onCancelled;

  const _ReservationCard({required this.reservation, required this.onCancelled});

  @override
  State<_ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends State<_ReservationCard> {
  final _reservationService = ReservationService();
  bool _isCancelling = false;

  bool get _canCancel =>
      widget.reservation.reservationStatus == 'Pending' ||
      widget.reservation.reservationStatus == 'Confirmed';

  Future<void> _showCancelDialog() async {
    final reasonController = TextEditingController();
    final overlay = Overlay.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pageBg,
        title: Text('Cancel reservation',
            style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel your reservation for "${widget.reservation.eventName}"?',
                style: TextStyle(color: AppColors.darkBrown.withValues(alpha: 0.8), fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              style: TextStyle(color: AppColors.darkBrown, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Reason for cancellation...',
                hintStyle: TextStyle(color: AppColors.darkBrown.withValues(alpha: 0.4), fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No', style: TextStyle(color: AppColors.darkBrown)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      AppSnackBar.show(overlay, 'Cancellation reason is required', isError: true);
      return;
    }

    setState(() => _isCancelling = true);
    try {
      await _reservationService.cancelReservation(widget.reservation.id, reason);
      if (mounted) {
        widget.onCancelled();
        AppSnackBar.show(overlay, 'Reservation cancelled');
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(overlay, e);
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservation = widget.reservation;
    final date = reservation.eventDateTime;
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final formattedDate =
        '${days[date.weekday - 1]} ${date.day}.${date.month}.${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mediumBrown,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.eventName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                _ReservationInfoRow('Date & Time', formattedDate),
                const SizedBox(height: 2),
                _ReservationInfoRow('Location', reservation.eventLocation),
                const SizedBox(height: 2),
                _ReservationInfoRow('Tickets', '${reservation.quantity}'),
                const SizedBox(height: 2),
                _ReservationInfoRow(
                  'Total',
                  reservation.totalPrice == 0
                      ? 'Free'
                      : '${reservation.totalPrice.toStringAsFixed(2)} BAM',
                ),
                const SizedBox(height: 2),
                _ReservationInfoRow('Status', reservation.reservationStatus),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 92,
                child: ElevatedButton(
                  onPressed: () {
                    if (reservation.ticketQRCodeLink != null) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.pageBg,
                          title: Text(
                            reservation.eventName,
                            style: TextStyle(
                              color: AppColors.darkBrown,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 160,
                                  height: 160,
                                  child: QrImageView(
                                    data: reservation.ticketQRCodeLink!,
                                    version: QrVersions.auto,
                                    size: 160,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Scan for access!',
                                  style: TextStyle(
                                    color: AppColors.darkBrown,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Close',
                                style: TextStyle(color: AppColors.darkBrown),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.darkBrown,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  ),
                  child: const Text(
                    'View\nticket',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              if (_canCancel) ...[
                const SizedBox(height: 6),
                SizedBox(
                  width: 92,
                  child: ElevatedButton(
                    onPressed: _isCancelling ? null : _showCancelDialog,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.red.shade700,
                      disabledBackgroundColor: Colors.red.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    ),
                    child: _isCancelling
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Cancel\nreservation',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ReservationInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReservationInfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, height: 1.3),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? errorText;
  final VoidCallback? onChanged;
  final int? maxLength;

  const _EditField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.errorText,
    this.onChanged,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            onChanged: onChanged != null ? (_) => onChanged!() : null,
            style: const TextStyle(color: AppColors.darkBrown, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: errorText != null
                    ? Colors.red
                    : AppColors.darkBrown.withValues(alpha: 0.5),
                fontSize: 15,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 1,
          color: errorText != null ? Colors.red : AppColors.darkBrown,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 2),
          Text(errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 11)),
        ],
      ],
    );
  }
}