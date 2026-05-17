import 'dart:io';
import 'package:flutter/material.dart';
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
import '../widgets/book_card.dart';
import '../widgets/pagination_bar.dart';
import '../services/book_service.dart';
import 'book_details_screen.dart';

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
      final countries = await _countryService.getCountries();
      final cities = await _cityService.getCities();
      if (mounted) {
        setState(() {
          _countries = countries;
          _cities = cities;
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
      showBackButton: true,
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
                    // Profile header card
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
                            // Info
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
                            // Avatar
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

                    // Tab bar
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
                            Tab(text: 'MY BOOKS'),
                            Tab(text: 'RESERVATIONS'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _MyBooksTab(),
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

    // Pre-select country/city by ID
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

            Widget dropdownField<T>({
              required String hint,
              required T? value,
              required List<T> items,
              required String Function(T) labelFn,
              required ValueChanged<T?>? onChanged,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<T>(
                        value: value,
                        isExpanded: true,
                        hint: Text(hint,
                            style: TextStyle(
                                color: AppColors.darkBrown.withValues(alpha: 0.5),
                                fontSize: 15)),
                        icon: Icon(Icons.arrow_drop_down, color: AppColors.darkBrown),
                        style: TextStyle(color: AppColors.darkBrown, fontSize: 15),
                        dropdownColor: AppColors.lightBrown,
                        onChanged: onChanged,
                        items: items
                            .map((item) => DropdownMenuItem<T>(
                                  value: item,
                                  child: Text(labelFn(item)),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(width: double.infinity, height: 1, color: AppColors.darkBrown),
                ],
              );
            }

            return AlertDialog(
              backgroundColor: AppColors.pageBg,
              title: Text('Edit profile',
                  style: TextStyle(
                      color: AppColors.darkBrown,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar picker
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
                      errorText: firstNameError,
                      onChanged: () => setDialogState(() => firstNameError = null),
                    ),
                    const SizedBox(height: 20),
                    _EditField(
                      controller: lastNameController,
                      hint: 'Last name',
                      errorText: lastNameError,
                      onChanged: () => setDialogState(() => lastNameError = null),
                    ),
                    const SizedBox(height: 20),
                    _EditField(
                      controller: usernameController,
                      hint: 'Username',
                      errorText: usernameError,
                      onChanged: () => setDialogState(() => usernameError = null),
                    ),
                    const SizedBox(height: 20),
                    _EditField(
                      controller: emailController,
                      hint: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      errorText: emailError,
                      onChanged: () => setDialogState(() => emailError = null),
                    ),
                    const SizedBox(height: 20),
                    _EditField(
                      controller: phoneController,
                      hint: 'Phone (optional)',
                      keyboardType: TextInputType.phone,
                      errorText: phoneError,
                      onChanged: () => setDialogState(() => phoneError = null),
                    ),
                    const SizedBox(height: 20),
                    _EditField(
                      controller: addressController,
                      hint: 'Address (optional)',
                    ),
                    const SizedBox(height: 20),
                    dropdownField<Country>(
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
                    dropdownField<City>(
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: AppColors.darkBrown)),
                ),
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
                              if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(ph)) {
                                phoneError = 'Invalid phone format';
                              } else if (ph.replaceAll(RegExp(r'[^0-9]'), '').length < 9) {
                                phoneError = 'Min 9 digits';
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

/* ----------------------- MY BOOKS TAB ----------------------- */

  class _MyBooksTab extends StatefulWidget {
    const _MyBooksTab();

    @override
    State<_MyBooksTab> createState() => _MyBooksTabState();
  }

  class _MyBooksTabState extends State<_MyBooksTab>
      with AutomaticKeepAliveClientMixin {
    final _orderService = OrderService();
    final _bookService = BookService();
    List<OrderItemModel> _books = [];
    Map<int, int> _bookQuantities = {}; // bookId → total quantity bought (best-effort)
    bool _isLoading = true;
    String? _error;

    static const int _pageSize = 12;
    int _currentPage = 0;

    List<OrderItemModel> get _currentPageItems {
      final start = _currentPage * _pageSize;
      final end = (start + _pageSize).clamp(0, _books.length);
      return _books.sublist(start, end);
    }

    int get _totalPages => (_books.length / _pageSize).ceil();

    @override
    bool get wantKeepAlive => true;

    @override
    void initState() {
      super.initState();
      _loadBooks();
    }

    Future<void> _loadBooks() async {
      try {
        final orders = await _orderService.getMyOrders();
        final allItems = orders.expand((order) => order.orderItems).toList();

        // Deduplicate by bookId, summing quantities
        // Deduplicate by bookId; fall back to title+author if bookId repeats as 0
        final Map<String, OrderItemModel> uniqueBooks = {};
        final Map<String, int> quantities = {};
        for (final item in allItems) {
          final key = item.bookId > 0
              ? 'id:${item.bookId}'
              : 'title:${item.bookTitle.toLowerCase().trim()}';
          quantities[key] = (quantities[key] ?? 0) + item.quantity;
          uniqueBooks.putIfAbsent(key, () => item);
        }

        setState(() {
          _books = uniqueBooks.values.toList();
          _bookQuantities = {
            for (final entry in quantities.entries)
              uniqueBooks[entry.key]!.bookId: entry.value,
          };
          _isLoading = false;
        });
      } catch (e) {
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
              child: CircularProgressIndicator(color: AppColors.darkBrown),
            )
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppColors.darkBrown),
                  ),
                )
              : _books.isEmpty
                  ? Center(
                      child: Text(
                        'No purchased books yet.',
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
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.mediumBrown,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bought books!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: GridView.builder(
                                      itemCount: _currentPageItems.length,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisSpacing: 14,
                                        crossAxisSpacing: 14,
                                        childAspectRatio: 0.50,
                                      ),
                                      itemBuilder: (context, index) {
                                        final item = _currentPageItems[index];
                                        final qty = _bookQuantities[item.bookId] ?? 1;
                                        return BookCard(
                                          title: item.bookTitle,
                                          author: item.bookAuthorName,
                                          imageUrl: item.bookImageUrl,
                                          style: BookCardStyle.details,
                                          statusLabel: qty > 1 ? 'Bought: $qty books' : null,
                                          onTap: () async {
                                            try {
                                              final book = await _bookService.getBookById(item.bookId);
                                              if (!context.mounted) return;
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => BookDetailsScreen(book: book),
                                                ),
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              AppSnackBar.showError(context, e);
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

/* ----------------------- RESERVATIONS TAB ----------------------- */

class _ReservationsTab extends StatefulWidget {
  const _ReservationsTab();

  @override
  State<_ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<_ReservationsTab>
    with AutomaticKeepAliveClientMixin {
  final _reservationService = ReservationService();
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
  }

  Future<void> _loadReservations() async {
    try {
      final reservations = await _reservationService.getMyReservations();
      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
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
                                reservation: _currentPageItems[index]);
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

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;

  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
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
          SizedBox(
            width: 92,
            child: ElevatedButton(
              onPressed: () {
                // navigacija na event details ako imas event model
                // za sada samo QR u dialogu
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

  const _EditField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.errorText,
    this.onChanged,
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