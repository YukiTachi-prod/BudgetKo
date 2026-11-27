import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/date_util.dart';
import 'package:provider/provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import '../database/budget_database.dart';
import '../utils/math_util.dart';

class LoansAndSubscriptionsTab extends StatelessWidget {
  const LoansAndSubscriptionsTab({super.key});

  void _showLoanDialog(
    BuildContext context, {
    Loan? loanToEdit,
    bool isOutgoing = false,
  }) {
    final provider = context.read<LedgerProvider>();
    final isEditOutgoing = loanToEdit?.isOutgoing ?? isOutgoing;
    final creditorCtrl = TextEditingController(
      text: loanToEdit?.creditorName ?? '',
    );
    final amountCtrl = TextEditingController(
      text: loanToEdit?.amount.toString() ?? '',
    );
    final remainingCtrl = TextEditingController(
      text: loanToEdit?.remainingAmount.toString() ?? '',
    );
    final notesCtrl = TextEditingController(text: loanToEdit?.notes ?? '');
    DateTime selectedDate =
        loanToEdit?.dueDate ?? DateTime.now().add(const Duration(days: 30));
    int? selectedAccountId =
        loanToEdit?.accountId ??
        (provider.accounts.isNotEmpty ? provider.accounts.first.id : null);
    bool isPaid = loanToEdit?.isPaid ?? false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(loanToEdit == null ? 'Add Loan' : 'Edit Loan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: creditorCtrl,
                      decoration: InputDecoration(
                        labelText: isEditOutgoing
                            ? 'Debtor Name (owes you)'
                            : 'Creditor Name (you owe)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Total Loan Amount',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remainingCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Remaining Amount',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Pay from Account',
                      ),
                      items: provider.accounts.map((a) {
                        return DropdownMenuItem(
                          value: a.id,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Color(a.colorHex),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(a.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => selectedAccountId = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Due Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                        ),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 10),
                              ),
                            );
                            if (date != null) {
                              setState(() => selectedDate = date);
                            }
                          },
                          child: const Text('Pick Date'),
                        ),
                      ],
                    ),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                      ),
                    ),
                    if (loanToEdit != null) ...[
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Mark as Fully Paid'),
                        value: isPaid,
                        onChanged: (val) => setState(() => isPaid = val),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (loanToEdit != null)
                  TextButton(
                    onPressed: () {
                      provider.deleteLoan(loanToEdit.id);
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final creditor = creditorCtrl.text.trim();
                    final amount = parseAmount(amountCtrl.text);
                    final remaining = remainingCtrl.text.isNotEmpty
                        ? parseAmount(remainingCtrl.text)
                        : amount;
                    if (creditor.isNotEmpty && selectedAccountId != null) {
                      if (loanToEdit == null) {
                        provider.addLoan(
                          creditorName: creditor,
                          amount: amount,
                          remainingAmount: remaining,
                          dueDate: selectedDate,
                          accountId: selectedAccountId!,
                          isOutgoing: isEditOutgoing,
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                        );
                      } else {
                        provider.updateLoan(
                          loanId: loanToEdit.id,
                          creditorName: creditor,
                          amount: amount,
                          remainingAmount: remaining,
                          dueDate: selectedDate,
                          isPaid: isPaid,
                          accountId: selectedAccountId!,
                          isOutgoing: isEditOutgoing,
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                        );
                      }
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(loanToEdit == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _checkNotificationsSafely(
    BuildContext context,
    LedgerProvider provider,
  ) {
    try {
      context.read<NotificationProvider>().checkLedgerWarnings(provider);
    } catch (_) {}
  }

  void _showMarkSubscriptionPaidDialog(
    BuildContext context,
    Subscription sub,
    String currency,
  ) {
    final provider = context.read<LedgerProvider>();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Mark Subscription as Paid?'),
          content: Text(
            'Have you already paid "${sub.name}" ($currency${sub.cost.toStringAsFixed(2)})?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showSubscriptionDialog(context, sub);
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () async {
                await provider.updateSubscription(
                  subscriptionId: sub.id,
                  name: sub.name,
                  cost: sub.cost,
                  billingCycle: sub.billingCycle,
                  nextBillingDate: sub.nextBillingDate,
                  isActive: false,
                  accountId: sub.accountId,
                  notes: sub.notes,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Yes, Paid'),
            ),
          ],
        );
      },
    );
  }

  void _showSubscriptionDialog(
    BuildContext context, [
    Subscription? subToEdit,
  ]) {
    final provider = context.read<LedgerProvider>();
    final nameCtrl = TextEditingController(text: subToEdit?.name ?? '');
    final costCtrl = TextEditingController(
      text: subToEdit?.cost.toString() ?? '',
    );
    final notesCtrl = TextEditingController(text: subToEdit?.notes ?? '');
    final parsedCycle = parseBillingCycle(
      subToEdit?.billingCycle ?? 'Every 1 Month',
    );
    final intervalCtrl = TextEditingController(
      text: parsedCycle.interval.toString(),
    );
    String selectedUnit = parsedCycle.unit;
    DateTime selectedDate =
        subToEdit?.nextBillingDate ??
        DateTime.now().add(const Duration(days: 30));
    int? selectedAccountId =
        subToEdit?.accountId ??
        (provider.accounts.isNotEmpty ? provider.accounts.first.id : null);
    bool isActive = subToEdit?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                subToEdit == null ? 'Add Subscription' : 'Edit Subscription',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subscription Name (e.g. Netflix)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: costCtrl,
                      decoration: const InputDecoration(labelText: 'Cost'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Every',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 68,
                          child: TextField(
                            controller: intervalCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(hintText: '1'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedUnit,
                            decoration: const InputDecoration(
                              labelText: 'Period',
                            ),
                            items: billingCycleUnits
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => selectedUnit = v ?? 'Months'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Pay from Account',
                      ),
                      items: provider.accounts.map((a) {
                        return DropdownMenuItem(
                          value: a.id,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Color(a.colorHex),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(a.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => selectedAccountId = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Renewal Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                        ),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 30),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 5),
                              ),
                            );
                            if (date != null) {
                              setState(() => selectedDate = date);
                            }
                          },
                          child: const Text('Pick Date'),
                        ),
                      ],
                    ),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                      ),
                    ),
                    if (subToEdit != null) ...[
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Paid'),
                        value: !isActive,
                        onChanged: (val) => setState(() => isActive = !val),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (subToEdit != null)
                  TextButton(
                    onPressed: () {
                      provider.deleteSubscription(subToEdit.id);
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final cost = parseAmount(costCtrl.text);
                    final interval =
                        int.tryParse(intervalCtrl.text.trim()) ?? 1;
                    final billingCycle = formatBillingCycle(
                      interval,
                      selectedUnit,
                    );
                    if (name.isNotEmpty && selectedAccountId != null) {
                      if (subToEdit == null) {
                        await provider.addSubscription(
                          name: name,
                          cost: cost,
                          billingCycle: billingCycle,
                          nextBillingDate: selectedDate,
                          accountId: selectedAccountId!,
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                        );
                      } else {
                        await provider.updateSubscription(
                          subscriptionId: subToEdit.id,
                          name: name,
                          cost: cost,
                          billingCycle: billingCycle,
                          nextBillingDate: selectedDate,
                          isActive: isActive,
                          accountId: selectedAccountId!,
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                        );
                      }
                      if (context.mounted) {
                        _checkNotificationsSafely(context, provider);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: Text(subToEdit == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLoansList(
    BuildContext context,
    List<Loan> loansList,
    LedgerProvider provider,
    String currency,
    bool isOutgoing,
  ) {
    if (loansList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('No active loans here. Add one above!'),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: loansList.length,
      itemBuilder: (context, index) {
        final theme = Theme.of(context);
        final loan = loansList[index];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            onTap: () => _showLoanDialog(context, loanToEdit: loan),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: theme.dividerColor, width: 1.0),
            ),
            tileColor: theme.cardColor,
            leading: CircleAvatar(
              backgroundColor: loan.isPaid
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              child: Icon(
                loan.isPaid
                    ? Icons.check
                    : (isOutgoing
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded),
                color: loan.isPaid ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              loan.creditorName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: loan.isPaid ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Due Date: ${DateFormat('yyyy-MM-dd').format(loan.dueDate)}',
                ),
                if (loan.notes != null && loan.notes!.isNotEmpty)
                  Text(
                    'Notes: ${loan.notes}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!loan.isPaid) ...[
                  SizedBox(
                    height: 32,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () {
                        provider.updateLoan(
                          loanId: loan.id,
                          creditorName: loan.creditorName,
                          amount: loan.amount,
                          remainingAmount: loan.remainingAmount,
                          dueDate: loan.dueDate,
                          isPaid: true,
                          accountId: loan.accountId,
                          isOutgoing: loan.isOutgoing,
                          notes: loan.notes,
                        );
                      },
                      child: const Text('Paid', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currency${loan.remainingAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: loan.isPaid
                            ? Colors.grey
                            : (isOutgoing
                                  ? Colors.green.shade700
                                  : Colors.red.shade700),
                        fontSize: 24,
                      ),
                    ),
                    if (loan.isPaid)
                      Text(
                        'of $currency${loan.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final currency = context.watch<SettingsProvider>().currency;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Incoming Loans Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Incoming Loans', style: theme.textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                onPressed: () => _showLoanDialog(context, isOutgoing: false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildLoansList(
            context,
            provider.loans.where((l) => !l.isOutgoing).toList(),
            provider,
            currency,
            false,
          ),
          const SizedBox(height: 32),

          // Outgoing Loans Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Outgoing Loans', style: theme.textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                onPressed: () => _showLoanDialog(context, isOutgoing: true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildLoansList(
            context,
            provider.loans.where((l) => l.isOutgoing).toList(),
            provider,
            currency,
            true,
          ),

          const SizedBox(height: 32),

          // Subscriptions Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subscriptions & Bills', style: theme.textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                onPressed: () => _showSubscriptionDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (provider.subscriptions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('No active subscriptions. Add one above!'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.subscriptions.length,
              itemBuilder: (context, index) {
                final sub = provider.subscriptions[index];
                final acc = provider.accounts.firstWhere(
                  (a) => a.id == sub.accountId,
                  orElse: () => provider.accounts.first, // fallback
                );
                final accColor = Color(acc.colorHex);

                final isPaid = !sub.isActive;
                final isDueNow =
                    sub.isActive && calendarDaysUntil(sub.nextBillingDate) <= 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    onTap: () {
                      if (isDueNow) {
                        _showMarkSubscriptionPaidDialog(context, sub, currency);
                      } else {
                        _showSubscriptionDialog(context, sub);
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: theme.dividerColor, width: 1.0),
                    ),
                    tileColor: theme.cardColor,
                    leading: CircleAvatar(
                      backgroundColor: isPaid
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.blue.withValues(alpha: 0.2),
                      child: Icon(
                        isPaid ? Icons.check : Icons.autorenew,
                        color: isPaid ? Colors.green : Colors.blue,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            sub.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPaid ? Colors.grey : null,
                              decoration: isPaid
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (isPaid) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Paid',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            acc.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: accColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Next Bill: ${DateFormat('yyyy-MM-dd').format(sub.nextBillingDate)}',
                        ),
                        Text(
                          isPaid
                              ? 'Paid'
                              : subscriptionDueStatus(sub.nextBillingDate),
                          style: TextStyle(
                            color: isPaid
                                ? Colors.green.shade700
                                : (isDueNow ? theme.colorScheme.error : null),
                            fontWeight: isPaid || isDueNow
                                ? FontWeight.w600
                                : null,
                          ),
                        ),
                        if (sub.notes != null && sub.notes!.isNotEmpty)
                          Text(
                            'Notes: ${sub.notes}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$currency${sub.cost.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPaid ? Colors.grey : Colors.blue.shade700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          shortBillingCycleLabel(sub.billingCycle),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
