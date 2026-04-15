import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cartService = CartService();
  CartModel? _cart;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final cart = await _cartService.getMyCart();
      setState(() {
        _cart = cart;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(CartItemModel item, int newQty) async {
    if (newQty < 1) return;
    try {
      final cart = await _cartService.updateItem(item.id, newQty);
      setState(() => _cart = cart);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e);
      }
    }
  }

  Future<void> _removeItem(CartItemModel item) async {
    try {
      final cart = await _cartService.removeItem(item.id);
      setState(() => _cart = cart);
      if (mounted) {
        AppSnackBar.show(context, 'Removed from cart!');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'SHOPPING CART',
      showBackButton: true,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.darkBrown,
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.darkBrown,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              : _cart == null || _cart!.cartItems.isEmpty
                  ? Center(
                      child: Text(
                        'Your cart is empty.',
                        style: TextStyle(
                          color: AppColors.darkBrown,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.mediumBrown,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _cart!.cartItems.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 14,
                                      crossAxisSpacing: 14,
                                      childAspectRatio: 0.40,
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = _cart!.cartItems[index];
                                      return _CartItemCard(
                                        item: item,
                                        onIncrease: () => _updateQuantity(
                                          item,
                                          item.quantity + 1,
                                        ),
                                        onDecrease: () => _updateQuantity(
                                          item,
                                          item.quantity - 1,
                                        ),
                                        onRemove: () => _removeItem(item),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    width: 210,
                                    padding: const EdgeInsets.fromLTRB(
                                        14, 14, 14, 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.mediumBrown,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TOTAL: ${_cart!.totalPrice.toStringAsFixed(2)} BAM',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => CheckoutScreen(cart: _cart!),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  elevation: 0,
                                                  backgroundColor:
                                                      AppColors.darkBrown,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                  ),
                                                ),
                                                child: const Text(
                                                  'CHECKOUT',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                style: ElevatedButton.styleFrom(
                                                  elevation: 0,
                                                  backgroundColor:
                                                      AppColors.darkBrown,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    vertical: 10,
                                                  ),
                                                ),
                                                child: const Text(
                                                  'CANCEL',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

/* ----------------------- CART ITEM CARD ----------------------- */

class _CartItemCard extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.pageBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: double.infinity,
                child: item.bookImageUrl != null &&
                        item.bookImageUrl!.isNotEmpty
                    ? Image.network(
                        item.bookImageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _fallback(),
                      )
                    : _fallback(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Text(
                  item.bookTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.darkBrown,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.bookAuthor ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.darkBrown.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.mediumBrown.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onIncrease,
                        child: Icon(
                          Icons.add,
                          color: AppColors.darkBrown,
                          size: 12,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '${item.quantity}',
                          style: TextStyle(
                            color: AppColors.darkBrown,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onDecrease,
                        child: Icon(
                          Icons.remove,
                          color: AppColors.darkBrown,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 22,
                  child: ElevatedButton(
                    onPressed: onRemove,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.darkBrown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'REMOVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: Colors.white.withValues(alpha: 0.45),
      child: Icon(
        Icons.menu_book_rounded,
        color: AppColors.darkBrown.withValues(alpha: 0.5),
        size: 28,
      ),
    );
  }
}