import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';

class LookupItem {
  final int id;
  final String name;
  const LookupItem({required this.id, required this.name});
}

class ManageDataOption {
  final String label;
  final VoidCallback onTap;
  const ManageDataOption({required this.label, required this.onTap});
}

class ManageDataModal extends StatelessWidget {
  final List<ManageDataOption> options;
  const ManageDataModal({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkBrown,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const SizedBox(width: 28),
                  const Expanded(
                    child: Text(
                      'MANAGE DATA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...options.map((opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: opt.onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightBrown,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          opt.label,
                          style: const TextStyle(
                              color: AppColors.darkBrown,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class LookupManageScreen extends StatefulWidget {
  final String title;
  final Future<List<LookupItem>> Function() getAll;
  final Future<void> Function(String name) create;
  final Future<void> Function(int id, String name) update;
  final Future<void> Function(int id) delete;
  final Widget Function() backScreen;

  const LookupManageScreen({
    super.key,
    required this.title,
    required this.getAll,
    required this.create,
    required this.update,
    required this.delete,
    required this.backScreen,
  });

  @override
  State<LookupManageScreen> createState() => _LookupManageScreenState();
}

class _LookupManageScreenState extends State<LookupManageScreen> {
  List<LookupItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final items = await widget.getAll();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.show(context, 'Failed to load data', isError: true);
    }
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (_) => _LookupItemDialog(
        title: 'Add ${widget.title}',
        onSave: (name) async {
          await widget.create(name);
          await _load();
        },
      ),
    );
  }

  void _openEditDialog(LookupItem item) {
    showDialog(
      context: context,
      builder: (_) => _LookupItemDialog(
        title: 'Edit ${widget.title}',
        initialName: item.name,
        onSave: (name) async {
          await widget.update(item.id, name);
          await _load();
        },
      ),
    );
  }

  Future<void> _delete(LookupItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Confirm Delete',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Text('Delete "${item.name}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.lightBrown)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.delete(item.id);
      await _load();
      if (mounted) AppSnackBar.show(context, 'Deleted successfully');
    } catch (_) {
      if (mounted) AppSnackBar.show(context, 'Failed to delete', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: widget.title.toUpperCase(),
      onBack: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => widget.backScreen()),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _openAddDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  child: Text(
                    'Add New',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.darkBrown))
                  : _items.isEmpty
                      ? Center(
                          child: Text(
                              'No ${widget.title.toLowerCase()} found.',
                              style: const TextStyle(
                                  color: AppColors.mediumBrown, fontSize: 14)))
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => Divider(
                            color:
                                AppColors.darkBrown.withValues(alpha: 0.15),
                            thickness: 1,
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: AppColors.darkBrown,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _openEditDialog(item),
                                    child: const Text('Edit',
                                        style: TextStyle(
                                            color: AppColors.darkBrown,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 4),
                                  TextButton(
                                    onPressed: () => _delete(item),
                                    child: const Text('Delete',
                                        style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LookupItemDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final Future<void> Function(String name) onSave;

  const _LookupItemDialog({
    required this.title,
    this.initialName,
    required this.onSave,
  });

  @override
  State<_LookupItemDialog> createState() => _LookupItemDialogState();
}

class _LookupItemDialogState extends State<_LookupItemDialog> {
  late final TextEditingController _controller;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onSave(name);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = 'Failed to save.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkBrown,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const SizedBox(width: 28),
                  Expanded(
                    child: Text(
                      widget.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Name',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _error,
                  errorStyle: const TextStyle(color: Colors.redAccent),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightBrown,
                    disabledBackgroundColor:
                        AppColors.lightBrown.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: AppColors.darkBrown, strokeWidth: 2))
                      : const Text('Save',
                          style: TextStyle(
                              color: AppColors.darkBrown,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
