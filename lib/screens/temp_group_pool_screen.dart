import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/temp_group_pool_models.dart';
import '../providers/settings_provider.dart';
import '../providers/temp_group_pool_provider.dart';
import '../theme/app_theme.dart';
import '../utils/math_util.dart';

class TempGroupPoolScreen extends StatefulWidget {
  const TempGroupPoolScreen({super.key});

  @override
  State<TempGroupPoolScreen> createState() => _TempGroupPoolScreenState();
}

class _TempGroupPoolScreenState extends State<TempGroupPoolScreen> {
  final NumberFormat _amountFormat = NumberFormat('#,##0.00');

  String _fmt(double value, String currency) {
    return '$currency${_amountFormat.format(value.abs())}';
  }

  // ── Dialog: Create Temporary Pool ─────────────────────────────────────
  void _showCreatePoolDialog(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final nameCtrl = TextEditingController();
    final equalAmountCtrl = TextEditingController();
    bool isEqualShare = false;
    String selectedCurrency = settings.currency;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Temporary Group Pool'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This temporary wallet is completely isolated and never affects your personal accounts.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Pool Name',
                        hintText: 'e.g. Friday Ramen Dinner, Coffee Run',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCurrency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: ['₱', '\$', '€', '£', '¥', '₹', '₽']
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCurrency = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Amount to Pay Mode',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Unique per person'),
                          selected: !isEqualShare,
                          onSelected: (_) =>
                              setDialogState(() => isEqualShare = false),
                        ),
                        ChoiceChip(
                          label: const Text('Same for everyone'),
                          selected: isEqualShare,
                          onSelected: (_) =>
                              setDialogState(() => isEqualShare = true),
                        ),
                      ],
                    ),
                    if (isEqualShare) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: equalAmountCtrl,
                        decoration: InputDecoration(
                          labelText: 'Amount per person ($selectedCurrency)',
                          hintText: 'e.g. 250 or 1200 / 4',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final equalAmt = isEqualShare
                        ? parseAmount(equalAmountCtrl.text.trim())
                        : 0.0;
                    await context.read<TempGroupPoolProvider>().createPool(
                      name: name.isNotEmpty ? name : 'Temporary Pool',
                      currency: selectedCurrency,
                      isEqualShare: isEqualShare,
                      equalShareAmount: equalAmt,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Create Pool'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Dialog: Delete Pool (Delete + Confirm) ────────────────────────────
  void _showDeletePoolConfirmDialog(BuildContext context, TempGroupPool pool) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Temporary Pool'),
          content: Text(
            'Are you sure you want to permanently delete "${pool.name}" and all ${pool.participants.length} ${pool.participants.length == 1 ? 'person' : 'people'} in it? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await context.read<TempGroupPoolProvider>().deletePool(pool.id);
                if (ctx.mounted) Navigator.pop(ctx);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Temporary pool "${pool.name}" deleted.'),
                  ),
                );
              },
              child: const Text('Confirm Delete'),
            ),
          ],
        );
      },
    );
  }

  // ── Dialog: Set Equal Share or Split Total Bill ───────────────────────
  void _showEqualShareDialog(BuildContext context, TempGroupPool pool) {
    final perPersonCtrl = TextEditingController(
      text: pool.equalShareAmount > 0
          ? pool.equalShareAmount.toStringAsFixed(2)
          : '',
    );
    final totalBillCtrl = TextEditingController();
    bool splitByTotal = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final count = pool.participants.length;
            return AlertDialog(
              title: const Text('Same Amount for Everyone'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (count > 0) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Per Person'),
                            selected: !splitByTotal,
                            onSelected: (_) =>
                                setDialogState(() => splitByTotal = false),
                          ),
                          ChoiceChip(
                            label: Text('Split Total ÷ $count'),
                            selected: splitByTotal,
                            onSelected: (_) =>
                                setDialogState(() => splitByTotal = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (!splitByTotal)
                      TextField(
                        controller: perPersonCtrl,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Amount to Pay Each (${pool.currency})',
                          hintText: 'e.g. 250',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      )
                    else
                      TextField(
                        controller: totalBillCtrl,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Total Group Bill (${pool.currency})',
                          hintText: 'e.g. 1500',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final provider = context.read<TempGroupPoolProvider>();
                    if (splitByTotal && count > 0) {
                      final total = parseAmount(totalBillCtrl.text.trim());
                      await provider.splitTotalBillEqually(total);
                    } else {
                      final perPerson = parseAmount(perPersonCtrl.text.trim());
                      await provider.updateActivePool(
                        isEqualShare: true,
                        equalShareAmount: perPerson,
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Dialog: Manage Categories (Cash, E-Cash + Custom) ─────────────────
  void _showCategoriesDialog(BuildContext context, TempGroupPool pool) {
    final catCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer<TempGroupPoolProvider>(
          builder: (context, provider, _) {
            final current = provider.activePool;
            if (current == null) return const SizedBox.shrink();

            return AlertDialog(
              title: const Text('Pool Categories'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default categories are Cash and E-Cash. Add custom categories if needed (e.g. Bank Transfer, Card).',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: catCtrl,
                            decoration: const InputDecoration(
                              labelText: 'New Category',
                              hintText: 'e.g. GCash, Card',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            final name = catCtrl.text.trim();
                            if (name.isNotEmpty) {
                              await provider.addCategory(name);
                              catCtrl.clear();
                            }
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: current.categories.map((cat) {
                        final isDefault = TempGroupPool.defaultCategories
                            .contains(cat);
                        return InputChip(
                          label: Text(cat),
                          deleteIcon: isDefault
                              ? null
                              : const Icon(Icons.close, size: 16),
                          onDeleted: isDefault
                              ? null
                              : () => provider.removeCategory(cat),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Dialog: Add / Edit Participant ────────────────────────────────────
  void _showParticipantDialog(
    BuildContext context,
    TempGroupPool pool, [
    TempPoolParticipant? existing,
  ]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final paidCtrl = TextEditingController(
      text: existing != null ? existing.amountPaid.toStringAsFixed(2) : '',
    );
    final toPayCtrl = TextEditingController(
      text: existing != null
          ? existing.amountToPay.toStringAsFixed(2)
          : (pool.isEqualShare && pool.equalShareAmount > 0
                ? pool.equalShareAmount.toStringAsFixed(2)
                : ''),
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    String selectedCategory =
        existing != null && pool.categories.contains(existing.category)
        ? existing.category
        : pool.categories.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final previewPaid = parseAmount(paidCtrl.text.trim());
            final previewToPay = pool.isEqualShare
                ? pool.equalShareAmount
                : parseAmount(toPayCtrl.text.trim());
            final previewChange = previewPaid - previewToPay;

            return AlertDialog(
              title: Text(existing == null ? 'Add Person' : 'Edit Person'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      autofocus: existing == null,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g. Alex, Sam, Jamie',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: paidCtrl,
                      decoration: InputDecoration(
                        labelText: 'Amount Given / Paid (${pool.currency})',
                        hintText: 'e.g. 500 or 200 + 100',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    if (pool.isEqualShare)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(
                            AppTheme.buttonRadius,
                          ),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Text(
                          'Amount to Pay (Same for everyone): ${_fmt(pool.equalShareAmount, pool.currency)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                    else
                      TextField(
                        controller: toPayCtrl,
                        decoration: InputDecoration(
                          labelText: 'Amount to Pay (${pool.currency})',
                          hintText: 'e.g. 320',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: pool.categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText:
                            'e.g. Ordered ramen + iced tea, sent via GCash',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ChangePreviewBanner(
                      change: previewChange,
                      currency: pool.currency,
                      formatAmount: _fmt,
                    ),
                  ],
                ),
              ),
              actions: [
                if (existing != null)
                  TextButton(
                    onPressed: () async {
                      await context
                          .read<TempGroupPoolProvider>()
                          .removeParticipant(existing.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(
                      'Remove',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final paid = parseAmount(paidCtrl.text.trim());
                    final toPay = pool.isEqualShare
                        ? (existing?.amountToPay ?? pool.equalShareAmount)
                        : parseAmount(toPayCtrl.text.trim());
                    final notes = notesCtrl.text.trim();

                    final provider = context.read<TempGroupPoolProvider>();
                    if (existing == null) {
                      await provider.addParticipant(
                        name: name,
                        amountPaid: paid,
                        amountToPay: toPay,
                        category: selectedCategory,
                        notes: notes.isNotEmpty ? notes : null,
                      );
                    } else {
                      await provider.updateParticipant(
                        existing.copyWith(
                          name: name,
                          amountPaid: paid,
                          amountToPay: toPay,
                          category: selectedCategory,
                          notes: notes.isNotEmpty ? notes : null,
                          clearNotes: notes.isEmpty,
                        ),
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(existing == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TempGroupPoolProvider>();
    final pool = provider.activePool;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Temporary Group Pool'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'New Temporary Pool',
            onPressed: () => _showCreatePoolDialog(context),
          ),
          if (pool != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              tooltip: 'Delete Temporary Pool',
              onPressed: () => _showDeletePoolConfirmDialog(context, pool),
            ),
        ],
      ),
      floatingActionButton: pool == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showParticipantDialog(context, pool),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Person'),
            ),
      body: pool == null
          ? _buildEmptyState(context, theme)
          : _buildActivePoolBody(context, provider, pool, theme),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: theme.dividerColor, width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.donut_large_rounded,
                  size: 38,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Temporary Group Pool',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Eating out with friends where one person pays? Track who gave what, each person\'s share, payment method (Cash / E-Cash), notes, and exact change owed back — completely separate from your personal wallets.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _showCreatePoolDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Create Temporary Pool'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePoolBody(
    BuildContext context,
    TempGroupPoolProvider provider,
    TempGroupPool pool,
    ThemeData theme,
  ) {
    final categoryTotals = pool.categoryTotals;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Pool Switcher (when multiple temporary pools exist) ──────
          if (provider.pools.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: provider.pools.map((p) {
                  final selected = p.id == pool.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p.name),
                      selected: selected,
                      onSelected: (_) => provider.selectPool(p.id),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Pool Header Card ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pool.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Temporary wallet • Isolated from your personal accounts',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.category_outlined, size: 20),
                      tooltip: 'Manage Categories',
                      onPressed: () => _showCategoriesDialog(context, pool),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Split Mode Toggle (Unique vs Same for everyone)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Unique per person'),
                      selected: !pool.isEqualShare,
                      onSelected: (_) =>
                          provider.updateActivePool(isEqualShare: false),
                    ),
                    ChoiceChip(
                      label: const Text('Same for everyone'),
                      selected: pool.isEqualShare,
                      onSelected: (_) {
                        provider.updateActivePool(isEqualShare: true);
                        if (pool.equalShareAmount <= 0) {
                          _showEqualShareDialog(context, pool);
                        }
                      },
                    ),
                    if (pool.isEqualShare)
                      OutlinedButton.icon(
                        onPressed: () => _showEqualShareDialog(context, pool),
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: Text(
                          '${_fmt(pool.equalShareAmount, pool.currency)} / person',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 32),
                          shape: AppTheme.squircleShape(
                            radius: AppTheme.chipRadius,
                          ),
                        ),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 15),
                      label: const Text('Categories'),
                      onPressed: () => _showCategoriesDialog(context, pool),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Centerpiece: Large Circular Money Pool ───────────────────
          Center(
            child: _MoneyPoolCircle(pool: pool, formatAmount: _fmt),
          ),

          const SizedBox(height: 18),

          // ── Category Breakdown Strip (Cash, E-Cash, Custom) ──────────
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              ...categoryTotals.entries.map((entry) {
                final color = AppTheme.categoryColor(entry.key);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: AppTheme.squircleDecoration(
                    color: theme.cardColor,
                    radius: AppTheme.chipRadius,
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${entry.key}: ${_fmt(entry.value, pool.currency)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 18),

          // ── Summary Metrics (Bill / Change Back / Still Owed) ────────
          Row(
            children: [
              Expanded(
                child: _SummaryMetricCard(
                  label: 'Total Bill',
                  value: _fmt(pool.totalExpected, pool.currency),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetricCard(
                  label: 'Change Back',
                  value: _fmt(pool.totalChangeBack, pool.currency),
                  valueColor: pool.totalChangeBack > 0
                      ? Colors.green.shade700
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetricCard(
                  label: 'Still Owed',
                  value: _fmt(pool.totalStillOwed, pool.currency),
                  valueColor: pool.totalStillOwed > 0
                      ? theme.colorScheme.error
                      : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ── Participants Header ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'People (${pool.participants.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showParticipantDialog(context, pool),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Person'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (pool.participants.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Center(
                child: Text(
                  'No people added yet. Tap "Add Person" to record who paid what.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Column(
              children: pool.participants.map((person) {
                final toPay = pool.effectiveAmountToPay(person);
                final change = pool.changeFor(person);
                final catColor = AppTheme.categoryColor(person.category);

                final String statusLabel;
                final Color statusColor;
                if (change > 0.005) {
                  statusLabel = 'Change: ${_fmt(change, pool.currency)}';
                  statusColor = Colors.green.shade700;
                } else if (change < -0.005) {
                  statusLabel = 'Owes: ${_fmt(change.abs(), pool.currency)}';
                  statusColor = theme.colorScheme.error;
                } else {
                  statusLabel = 'Exact';
                  statusColor = Colors.teal.shade600;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _showParticipantDialog(context, pool, person),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      person.name,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: AppTheme.squircleDecoration(
                                        color: catColor.withValues(alpha: 0.15),
                                      ),
                                      child: Text(
                                        person.category,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: catColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: AppTheme.squircleDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Paid: ${_fmt(person.amountPaid, pool.currency)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'To Pay: ${_fmt(toPay, pool.currency)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          if (person.notes != null &&
                              person.notes!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.notes_rounded,
                                  size: 14,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    person.notes!,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),

          // ── Explicit Delete Temporary Pool Button ────────────────────
          OutlinedButton.icon(
            onPressed: () => _showDeletePoolConfirmDialog(context, pool),
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: theme.colorScheme.error,
            ),
            label: Text(
              'Delete Temporary Pool',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyPoolCircle extends StatelessWidget {
  final TempGroupPool pool;
  final String Function(double, String) formatAmount;

  const _MoneyPoolCircle({required this.pool, required this.formatAmount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalPooled = pool.totalPooled;
    final totalExpected = pool.totalExpected;
    final net = pool.netBalance;

    final double progress;
    if (totalExpected <= 0) {
      progress = totalPooled > 0 ? 1.0 : 0.0;
    } else {
      progress = (totalPooled / totalExpected).clamp(0.0, 1.0);
    }

    final Color ringColor;
    final String statusText;
    if (totalExpected <= 0 && totalPooled <= 0) {
      ringColor = theme.colorScheme.primary;
      statusText = 'Empty Pool';
    } else if (net > 0.005) {
      ringColor = Colors.green.shade600;
      statusText = '+${formatAmount(net, pool.currency)} excess';
    } else if (net < -0.005) {
      ringColor = theme.colorScheme.error;
      statusText = '-${formatAmount(net.abs(), pool.currency)} short';
    } else {
      ringColor = Colors.teal.shade600;
      statusText = 'Balanced';
    }

    return SizedBox(
      width: 224,
      height: 224,
      child: CustomPaint(
        painter: _PoolRingPainter(
          progress: progress,
          trackColor: theme.dividerColor,
          progressColor: ringColor,
        ),
        child: Container(
          margin: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.cardColor,
            border: Border.all(color: theme.dividerColor, width: 1.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'MONEY POOL',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatAmount(totalPooled, pool.currency),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                totalExpected > 0
                    ? 'of ${formatAmount(totalExpected, pool.currency)} bill'
                    : '${pool.participants.length} ${pool.participants.length == 1 ? 'person' : 'people'}',
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: AppTheme.squircleDecoration(
                  color: ringColor.withValues(alpha: 0.14),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ringColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PoolRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _PoolRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 5;
    const strokeWidth = 6.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweep = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PoolRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}

class _SummaryMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryMetricCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePreviewBanner extends StatelessWidget {
  final double change;
  final String currency;
  final String Function(double, String) formatAmount;

  const _ChangePreviewBanner({
    required this.change,
    required this.currency,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String text;
    final Color color;

    if (change > 0.005) {
      text = 'Change to give back: ${formatAmount(change, currency)}';
      color = Colors.green.shade700;
    } else if (change < -0.005) {
      text = 'Still owes: ${formatAmount(change.abs(), currency)}';
      color = theme.colorScheme.error;
    } else {
      text = 'Exact amount — no change needed';
      color = Colors.teal.shade600;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
