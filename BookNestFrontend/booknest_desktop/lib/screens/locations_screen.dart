import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/city.dart';
import '../models/country.dart';
import '../screens/dashboard_screen.dart';
import '../services/city_service.dart';
import '../services/country_service.dart';
import '../widgets/book_form_widgets.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final _countryService = CountryService();
  final _cityService = CityService();

  List<Country> _countries = [];
  List<Country> _filteredCountries = [];
  List<City> _cities = [];
  List<City> _filteredCities = [];

  Country? _cityFilterCountry;
  bool _isLoading = true;

  final _countrySearchController = TextEditingController();
  final _citySearchController = TextEditingController();

  final LayerLink _filterCountryLink = LayerLink();
  OverlayEntry? _filterCountryOverlay;
  bool _filterCountryOpen = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _filterCountryOverlay?.remove();
    _countrySearchController.dispose();
    _citySearchController.dispose();
    super.dispose();
  }

  void _closeFilterCountryDropdown() {
    _filterCountryOverlay?.remove();
    _filterCountryOverlay = null;
    if (mounted) setState(() => _filterCountryOpen = false);
  }

  void _toggleFilterCountryDropdown() {
    if (_filterCountryOpen) { _closeFilterCountryDropdown(); return; }
    final entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(child: GestureDetector(onTap: _closeFilterCountryDropdown, behavior: HitTestBehavior.translucent, child: const SizedBox())),
          CompositedTransformFollower(
            link: _filterCountryLink,
            showWhenUnlinked: false,
            offset: const Offset(-20, 44),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 180,
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(color: AppColors.lightBrown, borderRadius: BorderRadius.circular(6)),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  children: [
                    InkWell(
                      onTap: () { _closeFilterCountryDropdown(); setState(() => _cityFilterCountry = null); _applyCityFilter(); },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Text('All countries',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.darkBrown, fontSize: 11.5, letterSpacing: 0.6,
                              fontWeight: _cityFilterCountry == null ? FontWeight.w900 : FontWeight.w500,
                            )),
                      ),
                    ),
                    ...List.generate(_countries.length, (i) {
                      final c = _countries[i];
                      return Column(
                        children: [
                          Divider(color: AppColors.darkBrown.withValues(alpha: 0.2), height: 1, thickness: 1, indent: 14, endIndent: 14),
                          InkWell(
                            onTap: () { _closeFilterCountryDropdown(); setState(() => _cityFilterCountry = c); _applyCityFilter(); },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Text(c.name.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.darkBrown, fontSize: 11.5, letterSpacing: 0.6,
                                    fontWeight: c.id == _cityFilterCountry?.id ? FontWeight.w900 : FontWeight.w500,
                                  )),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(entry);
    _filterCountryOverlay = entry;
    setState(() => _filterCountryOpen = true);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _countryService.getCountries(),
        _cityService.getCities(),
      ]);
      if (!mounted) return;
      final countries = results[0] as List<Country>;
      final cities = results[1] as List<City>;
      setState(() {
        _countries = countries;
        _cities = cities;
        _isLoading = false;
        _applyCountryFilter();
        _applyCityFilter();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.show(context, 'Failed to load data', isError: true);
      }
    }
  }

  void _applyCountryFilter() {
    final q = _countrySearchController.text.trim().toLowerCase();
    setState(() {
      _filteredCountries = q.isEmpty
          ? List.of(_countries)
          : _countries.where((c) => c.name.toLowerCase().contains(q)).toList();
    });
  }

  void _applyCityFilter() {
    final q = _citySearchController.text.trim().toLowerCase();
    setState(() {
      _filteredCities = _cities.where((c) {
        final matchesSearch = q.isEmpty || c.name.toLowerCase().contains(q);
        final matchesCountry = _cityFilterCountry == null || c.countryId == _cityFilterCountry!.id;
        return matchesSearch && matchesCountry;
      }).toList();
    });
  }

  void _openCountryDialog({Country? country}) {
    showDialog(
      context: context,
      builder: (_) => _CountryDialog(
        country: country,
        countryService: _countryService,
        onSaved: _loadData,
      ),
    );
  }

  Future<void> _deleteCountry(Country country) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Delete Country', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${country.name}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Color(0xFFE57373)))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _countryService.deleteCountry(country.id);
      if (mounted) {
        AppSnackBar.show(context, 'Country deleted');
        _loadData();
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to delete country', isError: true);
    }
  }

  void _openCityDialog({City? city}) {
    showDialog(
      context: context,
      builder: (_) => _CityDialog(
        city: city,
        countries: _countries,
        cityService: _cityService,
        onSaved: _loadData,
      ),
    );
  }

  Future<void> _deleteCity(City city) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Delete City', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${city.name}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Color(0xFFE57373)))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _cityService.deleteCity(city.id);
      if (mounted) {
        AppSnackBar.show(context, 'City deleted');
        _loadData();
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to delete city', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'LOCATIONS',
      onBack: () => Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DashboardScreen())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.darkBrown))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: _buildCountriesPanel(),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(0, 14, 18, 14),
                    child: _buildCitiesPanel(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCountriesPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Countries',
                style: TextStyle(color: AppColors.darkBrown, fontSize: 20, fontWeight: FontWeight.w800)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _openCountryDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Country', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkBrown,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SearchBar(controller: _countrySearchController, hint: 'Search countries...', onChanged: (_) => _applyCountryFilter()),
        const SizedBox(height: 12),
        _buildCountryList(),
      ],
    );
  }

  Widget _buildCountryList() {
    if (_filteredCountries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No countries found.', style: TextStyle(color: AppColors.mediumBrown, fontSize: 14)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredCountries.length,
      itemBuilder: (_, i) => _LocationRow(
        name: _filteredCountries[i].name,
        subtitle: null,
        onEdit: () => _openCountryDialog(country: _filteredCountries[i]),
        onDelete: () => _deleteCountry(_filteredCountries[i]),
      ),
    );
  }

  Widget _buildCitiesPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Cities',
                style: TextStyle(color: AppColors.darkBrown, fontSize: 20, fontWeight: FontWeight.w800)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _openCityDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add City', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkBrown,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SearchBar(controller: _citySearchController, hint: 'Search cities...', onChanged: (_) => _applyCityFilter()),
            ),
            const SizedBox(width: 10),
            CompositedTransformTarget(
              link: _filterCountryLink,
              child: GestureDetector(
                onTap: _toggleFilterCountryDropdown,
                child: Container(
                  height: 42,
                  width: 160,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.lightBrown.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.lightBrown.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _cityFilterCountry?.name ?? 'All countries',
                          style: TextStyle(
                            color: _cityFilterCountry != null ? AppColors.darkBrown : AppColors.mediumBrown,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        _filterCountryOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.darkBrown,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCityList(),
      ],
    );
  }

  Widget _buildCityList() {
    if (_filteredCities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No cities found.', style: TextStyle(color: AppColors.mediumBrown, fontSize: 14)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredCities.length,
      itemBuilder: (_, i) => _LocationRow(
        name: _filteredCities[i].name,
        subtitle: _filteredCities[i].countryName,
        onEdit: () => _openCityDialog(city: _filteredCities[i]),
        onDelete: () => _deleteCity(_filteredCities[i]),
      ),
    );
  }
}

// ─── Reusable Widgets ────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.lightBrown.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightBrown.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.mediumBrown, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: AppColors.darkBrown, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: AppColors.mediumBrown, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final String name;
  final String? subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LocationRow({required this.name, this.subtitle, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: AppColors.darkBrown, fontSize: 14, fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Text(subtitle!, style: TextStyle(color: AppColors.mediumBrown, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.darkBrown),
                tooltip: 'Edit',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE57373)),
                tooltip: 'Delete',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
              ),
            ],
          ),
        ),
        Divider(color: AppColors.darkBrown.withValues(alpha: 0.1), height: 1, thickness: 1),
      ],
    );
  }
}

// ─── Country Dialog ──────────────────────────────────────────────────────────

class _CountryDialog extends StatefulWidget {
  final Country? country;
  final CountryService countryService;
  final VoidCallback onSaved;

  const _CountryDialog({this.country, required this.countryService, required this.onSaved});

  @override
  State<_CountryDialog> createState() => _CountryDialogState();
}

class _CountryDialogState extends State<_CountryDialog> {
  late final TextEditingController _nameController;
  String? _nameError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.country?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) { setState(() => _nameError = 'Required'); return; }
    setState(() { _nameError = null; _isLoading = true; });
    try {
      if (widget.country == null) {
        await widget.countryService.createCountry(name);
      } else {
        await widget.countryService.updateCountry(widget.country!.id, name);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        AppSnackBar.show(context, widget.country == null ? 'Country added' : 'Country updated');
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to save country', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.country != null;
    return Dialog(
      backgroundColor: AppColors.darkBrown,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEdit ? 'EDIT COUNTRY' : 'ADD COUNTRY',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              const SizedBox(height: 24),
              BookFormField(
                controller: _nameController,
                hint: 'Country name',
                error: _nameError,
                onChanged: (_) => setState(() => _nameError = null),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.lightBrown),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightBrown,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.darkBrown, strokeWidth: 2))
                        : Text(isEdit ? 'Save' : 'Add', style: const TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── City Dialog ─────────────────────────────────────────────────────────────

class _CityDialog extends StatefulWidget {
  final City? city;
  final List<Country> countries;
  final CityService cityService;
  final VoidCallback onSaved;

  const _CityDialog({this.city, required this.countries, required this.cityService, required this.onSaved});

  @override
  State<_CityDialog> createState() => _CityDialogState();
}

class _CityDialogState extends State<_CityDialog> {
  late final TextEditingController _nameController;
  Country? _selectedCountry;
  String? _nameError;
  String? _countryError;
  bool _isLoading = false;

  final LayerLink _countryLink = LayerLink();
  OverlayEntry? _countryOverlay;
  bool _countryOpen = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.city?.name ?? '');
    if (widget.city != null) {
      try {
        _selectedCountry = widget.countries.firstWhere((c) => c.id == widget.city!.countryId);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _countryOverlay?.remove();
    _nameController.dispose();
    super.dispose();
  }

  void _closeCountryDropdown() {
    _countryOverlay?.remove(); _countryOverlay = null;
    if (mounted) setState(() => _countryOpen = false);
  }

  void _toggleCountryDropdown() {
    if (_countryOpen) { _closeCountryDropdown(); return; }
    final entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(child: GestureDetector(onTap: _closeCountryDropdown, behavior: HitTestBehavior.translucent, child: const SizedBox())),
          CompositedTransformFollower(
            link: _countryLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 44),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 320,
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(color: AppColors.lightBrown, borderRadius: BorderRadius.circular(6)),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  itemCount: widget.countries.length,
                  separatorBuilder: (_, __) => Divider(color: AppColors.darkBrown.withValues(alpha: 0.2), height: 1, thickness: 1, indent: 14, endIndent: 14),
                  itemBuilder: (ctx, i) {
                    final c = widget.countries[i];
                    return InkWell(
                      onTap: () { _closeCountryDropdown(); setState(() { _selectedCountry = c; _countryError = null; }); },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Text(c.name.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.darkBrown, fontSize: 11.5, letterSpacing: 0.6,
                              fontWeight: c.id == _selectedCountry?.id ? FontWeight.w900 : FontWeight.w500,
                            )),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(entry);
    _countryOverlay = entry;
    setState(() => _countryOpen = true);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? 'Required' : null;
      _countryError = _selectedCountry == null ? 'Required' : null;
    });
    if (_nameError != null || _countryError != null) return;
    setState(() => _isLoading = true);
    try {
      if (widget.city == null) {
        await widget.cityService.createCity(name, _selectedCountry!.id);
      } else {
        await widget.cityService.updateCity(widget.city!.id, name, _selectedCountry!.id);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        AppSnackBar.show(context, widget.city == null ? 'City added' : 'City updated');
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to save city', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.city != null;
    return Dialog(
      backgroundColor: AppColors.darkBrown,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEdit ? 'EDIT CITY' : 'ADD CITY',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              const SizedBox(height: 24),
              BookFormField(
                controller: _nameController,
                hint: 'City name',
                error: _nameError,
                onChanged: (_) => setState(() => _nameError = null),
              ),
              const SizedBox(height: 14),
              BookFormDropdownTrigger(
                link: _countryLink,
                hint: 'Country',
                selectedLabel: _selectedCountry?.name,
                isOpen: _countryOpen,
                error: _countryError,
                onTap: _toggleCountryDropdown,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.lightBrown),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightBrown,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.darkBrown, strokeWidth: 2))
                        : Text(isEdit ? 'Save' : 'Add', style: const TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
