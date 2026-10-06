import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/settings_provider.dart';
import '../database/budget_database.dart';
import '../theme/app_theme.dart';

class MainTab extends StatelessWidget {
  final VoidCallback? onAddAccount;
  final ValueChanged<int>? onNavigateToTab;

  const MainTab({
    super.key,
    this.onAddAccount,
    this.onNavigateToTab,
  });

  String _formatAmount(double amount, String currency, bool isHidden) {
    if (isHidden) {
      return '$currency ••••••';
    }
    final formatted = NumberFormat('#,##0.00').format(amount.abs());
    return amount < 0 ? '-$currency$formatted' : '$currency$formatted';
  }

  String _formatMetric(double amount, String currency, bool isHidden, {required String prefix}) {
    if (isHidden) {
      return '••••••';
    }
    final formatted = NumberFormat('#,##0.00').format(amount.abs());
    return '$prefix$currency$formatted';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currency;
    final isHidden = settings.hideTotalAmount;
    final theme = Theme.of(context);

    // Calculate total balance across all accounts
    final totalMoney = provider.accounts.fold<double>(
      0.0,
      (sum, acc) => sum + acc.currentBalance,
    );

    // Calculate income and expense totals
    final totalIncome = provider.allTransactions
        .where((tx) => tx.transactionType == TransactionType.income.index)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);

    final totalExpenses = provider.allTransactions
        .where((tx) => tx.transactionType == TransactionType.expense.index)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);

    final recentTransactions = provider.recentTransactions.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Main Hero Card: Total Amount ────────────────────────────
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: theme.dividerColor, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 18,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total Balance',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        isHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: theme.colorScheme.secondary,
                      ),
                      tooltip: isHidden ? 'Show total amount' : 'Hide total amount',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => settings.toggleHideTotalAmount(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => settings.toggleHideTotalAmount(),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            _formatAmount(totalMoney, currency, isHidden),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: isHidden ? 2.0 : -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${provider.accounts.length} ${provider.accounts.length == 1 ? 'account' : 'accounts'} active',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (totalMoney >= 0 ? Colors.green : Colors.red)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        totalMoney >= 0 ? 'Net Positive' : 'Net Negative',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: totalMoney >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Cash Flow Summary (Income / Expenses) ───────────────────
          Row(
            children: [
              // Income
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: theme.dividerColor, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 15,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Total Income',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatMetric(totalIncome, currency, isHidden, prefix: '+'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isHidden ? null : Colors.green.shade600,
                          letterSpacing: isHidden ? 1.5 : 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Expenses
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: theme.dividerColor, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 15,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Total Expenses',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatMetric(totalExpenses, currency, isHidden, prefix: '-'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isHidden ? null : Colors.red.shade600,
                          letterSpacing: isHidden ? 1.5 : 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Accounts Overview ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Accounts Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onAddAccount != null)
                TextButton.icon(
                  onPressed: onAddAccount,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Account'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (provider.accounts.isEmpty)
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(color: theme.dividerColor, width: 1.0),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 32,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No accounts yet',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add your bank, e-wallet, or cash account to begin.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: provider.accounts.map((acc) {
                final accColor = Color(acc.colorHex);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: theme.dividerColor, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              acc.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (acc.minBalance > 0)
                              Text(
                                'Min: $currency${acc.minBalance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        isHidden
                            ? '$currency ••••••'
                            : '$currency${NumberFormat('#,##0.00').format(acc.currentBalance)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: isHidden ? 1.5 : 0,
                          color: acc.currentBalance < acc.minBalance
                              ? Colors.red
                              : null,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 20),

          // ── Recent Activity ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onNavigateToTab != null)
                TextButton(
                  onPressed: () => onNavigateToTab!(1), // Go to Wallet tab
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (recentTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(color: theme.dividerColor, width: 1.0),
              ),
              child: Center(
                child: Text(
                  'No transactions recorded yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            )
          else
            Column(
              children: recentTransactions.map((tx) {
                final isInc = tx.transactionType == TransactionType.income.index;
                final isTransfer = tx.transactionType == TransactionType.transfer.index;
                final cat = provider.categories
                    .where((c) => c.id == tx.categoryId)
                    .firstOrNull;
                final catColor = cat?.colorHex != null ? Color(cat!.colorHex) : null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: theme.dividerColor, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isInc
                            ? Colors.green.withValues(alpha: 0.15)
                            : (isTransfer
                                ? Colors.blue.withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15)),
                        child: Icon(
                          isTransfer
                              ? Icons.swap_horiz
                              : (isInc ? Icons.arrow_downward : Icons.arrow_upward),
                          size: 18,
                          color: isInc
                              ? Colors.green
                              : (isTransfer ? Colors.blue : Colors.red),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    tx.notes?.isNotEmpty == true
                                        ? tx.notes!
                                        : (isTransfer
                                            ? 'Transfer'
                                            : (isInc ? 'Income' : 'Expense')),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (cat != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (catColor ?? theme.colorScheme.primary)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      cat.name,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: catColor ?? theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMM d, yyyy • hh:mm a').format(tx.date),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isHidden
                            ? '••••••'
                            : '${isInc ? '+' : (isTransfer ? '' : '-')}$currency${NumberFormat('#,##0.00').format(tx.amount)}',
                        style: TextStyle(
                          color: isInc
                              ? Colors.green
                              : (isTransfer ? Colors.blueGrey : Colors.red),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: isHidden ? 1.5 : 0,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 80), // Padding to avoid FAB overlap
        ],
      ),
    );
  }
}
