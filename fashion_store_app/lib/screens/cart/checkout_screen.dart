import 'package:flutter/material.dart';
import '../../core/app_routes.dart';
import '../../core/mvvm/view_model_builder.dart';
import '../../view_models/checkout_view_model.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  static const Color _accent = Color(0xFFF26B3A);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF7A7A7A);
  static const Color _cardBorder = Color(0xFFE8E8E8);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<CheckoutViewModel>(
      create: (_) => CheckoutViewModel(),
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: _textPrimary),
            ),
            title: const Text(
              'Checkout',
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const Text(
                'Shipping Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _InfoCard(
                leading: const Icon(Icons.location_on_outlined, color: _accent),
                title: viewModel.shippingTitle,
                subtitle: viewModel.shippingSubtitle,
                onEdit: () =>
                    Navigator.pushNamed(context, AppRoutes.shippingAddress),
              ),
              const SizedBox(height: 18),
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _InfoCard(
                leading: Image.asset(
                  'assets/images/Mastercard/visa logo.jpg',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.credit_card,
                      color: _accent,
                      size: 18,
                    );
                  },
                ),
                title: viewModel.paymentTitle,
                subtitle: viewModel.paymentSubtitle,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentMethodsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cardBorder),
                ),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Subtotal', value: viewModel.subtotal),
                    const SizedBox(height: 10),
                    _SummaryRow(label: 'Shipping', value: viewModel.shipping),
                    const SizedBox(height: 10),
                    _SummaryRow(label: 'Tax', value: viewModel.tax),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: CheckoutScreen._cardBorder),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      label: 'Total',
                      value: viewModel.total,
                      highlight: true,
                    ),
                  ],
                ),
              ),
              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                width: double.infinity,
                  child: ElevatedButton(
                  onPressed: viewModel.isBusy
                      ? null
                      : () async {
                          final orderId = await viewModel.placeOrder();
                          if (!context.mounted) {
                            return;
                          }
                          if (orderId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  viewModel.errorMessage ??
                                      'Unable to place order. Please try again.',
                                ),
                              ),
                            );
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order placed successfully'),
                            ),
                          );
                          Navigator.pushNamed(context, AppRoutes.orderConfirmation);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: viewModel.isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Place Order (${viewModel.total})'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onEdit,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CheckoutScreen._cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CheckoutScreen._accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: leading),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: CheckoutScreen._textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: CheckoutScreen._textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: CheckoutScreen._accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: CheckoutScreen._accent,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlight
                ? CheckoutScreen._accent
                : CheckoutScreen._textMuted,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight
                ? CheckoutScreen._accent
                : CheckoutScreen._textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: highlight ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
        ),
        title: const Text(
          'Payment Methods',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: const [
          ListTile(
            leading: Icon(Icons.credit_card, color: Color(0xFFF26B3A)),
            title: Text('Visa ending in 4242'),
            subtitle: Text('Expires 12/24'),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.credit_card, color: Color(0xFFF26B3A)),
            title: Text('Mastercard ending in 1122'),
            subtitle: Text('Expires 08/25'),
          ),
        ],
      ),
    );
  }
}
