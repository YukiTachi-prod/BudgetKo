import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/group_wallet_models.dart';
import '../providers/group_wallet_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/math_util.dart';

class GroupWalletScreen extends StatelessWidget {
  const GroupWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Wallet'), centerTitle: true),
      body: const GroupWalletTab(),
    );
  }
}

class GroupWalletTab extends StatefulWidget {
  const GroupWalletTab({super.key});

  @override
  State<GroupWalletTab> createState() => _GroupWalletTabState();
}

class _GroupWalletTabState extends State<GroupWalletTab> {
  String _txFilter = 'All'; // 'All', 'Expenses', 'Contributions'

  // ── Dialog: Profile Setup & Edit ──────────────────────────────────────
  void _showProfileDialog(BuildContext context, [GroupProfile? current]) {
    final nameCtrl = TextEditingController(text: current?.name ?? '');
    int selectedColor = current?.colorHex ?? 0xFF7C3AED;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                current == null ? 'Create Local Profile' : 'Edit Profile',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your profile is held locally on this device to identify your contributions and expenses in group wallets.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Your Name / Nickname',
                        hintText: 'e.g. Alex, Sam, Yuki',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Avatar Color:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (colorCtx) {
                                Color tempColor = Color(selectedColor);
                                return AlertDialog(
                                  title: const Text('Pick Profile Color'),
                                  content: SingleChildScrollView(
                                    child: ColorPicker(
                                      pickerColor: tempColor,
                                      onColorChanged: (c) => tempColor = c,
                                      pickerAreaHeightPercent: 0.8,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(colorCtx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(
                                          () => selectedColor = tempColor
                                              .toARGB32(),
                                        );
                                        Navigator.pop(colorCtx);
                                      },
                                      child: const Text('Select'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(selectedColor),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isNotEmpty) {
                      context.read<GroupWalletProvider>().saveProfile(
                        name,
                        selectedColor,
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Save Profile'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Dialog: Supabase Configuration ────────────────────────────────────
  void _showSupabaseConfigDialog(BuildContext context) {
    final provider = context.read<GroupWalletProvider>();
    final urlCtrl = TextEditingController(text: provider.supabaseUrl ?? '');
    final keyCtrl = TextEditingController(text: provider.supabaseKey ?? '');
    bool isObscured = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Supabase Connection'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your Supabase project credentials to synchronize the collective budget with other group members.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: urlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Supabase Project URL',
                        hintText: 'https://xyzcompany.supabase.co',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: keyCtrl,
                      obscureText: isObscured,
                      decoration: InputDecoration(
                        labelText: 'Supabase API Key (Anon / Service)',
                        suffixIcon: IconButton(
                          icon: Icon(
                            isObscured
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                          ),
                          onPressed: () =>
                              setState(() => isObscured = !isObscured),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (provider.isConfigured)
                  TextButton(
                    onPressed: () async {
                      await provider.disconnectSupabase();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Disconnect',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final url = urlCtrl.text.trim();
                    final key = keyCtrl.text.trim();
                    if (url.isNotEmpty && key.isNotEmpty) {
                      final ok = await provider.connectSupabase(url, key);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        if (!ok && provider.connectionError != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.connectionError!)),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Connect & Verify'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Dialog: Database SQL Setup Script ─────────────────────────────────
  void _showSqlScriptDialog(BuildContext context) {
    const sqlScript = '''
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Group Wallets Table
CREATE TABLE IF NOT EXISTS group_wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    currency TEXT DEFAULT '₱',
    created_by_name TEXT NOT NULL,
    created_by_id TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Group Members Table
CREATE TABLE IF NOT EXISTS group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES group_wallets(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    color_hex BIGINT DEFAULT 4280391411,
    joined_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(wallet_id, user_id)
);

-- Group Transactions Table
CREATE TABLE IF NOT EXISTS group_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES group_wallets(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL,
    transaction_type TEXT NOT NULL,
    category TEXT DEFAULT 'General',
    notes TEXT,
    paid_by_name TEXT NOT NULL,
    paid_by_id TEXT NOT NULL,
    paid_by_color_hex BIGINT DEFAULT 4280391411,
    date TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Helper RPC for automated migrations
CREATE OR REPLACE FUNCTION exec_sql(query text) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER AS \$\$ BEGIN EXECUTE query; END; \$\$;

-- Enable Row Level Security (RLS)
ALTER TABLE group_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_transactions ENABLE ROW LEVEL SECURITY;

-- Public Access Policies
CREATE POLICY "Public access on group_wallets" ON group_wallets FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Public access on group_members" ON group_members FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Public access on group_transactions" ON group_transactions FOR ALL USING (true) WITH CHECK (true);
''';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Supabase Database Setup Script'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Run this query in your Supabase project\'s SQL Editor to create the required tables and security policies:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: const SelectableText(
                      sqlScript,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: sqlScript));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('SQL setup script copied to clipboard!'),
                  ),
                );
              },
              child: const Text('Copy to Clipboard'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ── Dialog: Create New Group Wallet ───────────────────────────────────
  void _showCreateWalletDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final settings = context.read<SettingsProvider>();
    String selectedCurrency = settings.currency;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Group Wallet'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Group Wallet Name',
                        hintText:
                            'e.g. Trip to Tokyo, Flatmates, Family Budget',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'e.g. Shared expenses for household',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCurrency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: ['₱', '\$', '€', '£', '¥', '₹', '₩']
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedCurrency = val);
                      },
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
                    final name = nameCtrl.text.trim();
                    if (name.isNotEmpty) {
                      await context.read<GroupWalletProvider>().createWallet(
                        name,
                        description: descCtrl.text.trim().isNotEmpty
                            ? descCtrl.text.trim()
                            : null,
                        currency: selectedCurrency,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Dialog: Join Wallet by ID ─────────────────────────────────────────
  void _showJoinWalletDialog(BuildContext context) {
    final idCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Join Group Wallet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the Wallet ID shared by another group member to join their collective budget.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: idCtrl,
                decoration: const InputDecoration(
                  labelText: 'Group Wallet ID (UUID)',
                  hintText: 'e.g. 550e8400-e29b-41d4-a716-446655440000',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final id = idCtrl.text.trim();
                if (id.isNotEmpty) {
                  final ok = await context
                      .read<GroupWalletProvider>()
                      .joinWalletById(id);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    if (!ok) {
                      final err = context
                          .read<GroupWalletProvider>()
                          .connectionError;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(err ?? 'Could not join wallet')),
                      );
                    }
                  }
                }
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
  }

  // ── Dialog: Remove Group Wallet ─────────────────────────────────────────
  void _showRemoveWalletDialog(
    BuildContext context,
    GroupWalletProvider provider,
    GroupWallet wallet,
  ) {
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isConfirmed =
                confirmCtrl.text.trim() == 'Remove group wallet';

            return AlertDialog(
              title: const Text('Remove Group Wallet'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to permanently delete "${wallet.name}"? All associated collective transactions and member entries will be removed.',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'To confirm, type "Remove group wallet" below:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Type "Remove group wallet"',
                        hintText: 'Remove group wallet',
                      ),
                      onChanged: (_) => setDialogState(() {}),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isConfirmed
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(ctx);
                          final ok = await provider.deleteWallet(wallet.id);
                          if (ok) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Group wallet "${wallet.name}" removed.',
                                ),
                              ),
                            );
                          } else if (provider.connectionError != null) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(provider.connectionError!),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      : null,
                  child: const Text('Remove'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Dialog: Add Group Transaction ─────────────────────────────────────
  void _showAddTransactionDialog(BuildContext context) {
    final provider = context.read<GroupWalletProvider>();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String transactionType = 'expense'; // 'expense' or 'contribution'
    String selectedCategory = 'Food';
    DateTime selectedDate = DateTime.now();
    String paidByName = provider.profile?.name ?? 'Me';
    String paidById = provider.profile?.id ?? '';
    int paidByColorHex = provider.profile?.colorHex ?? 0xFF7C3AED;
    bool isSubmitting = false;

    final categories = [
      'Food',
      'Groceries',
      'Housing / Rent',
      'Utilities',
      'Transport',
      'Activities',
      'Entertainment',
      'Health',
      'General',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Group Transaction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Type selector
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Expense (Spent)'),
                          selected: transactionType == 'expense',
                          selectedColor: Colors.red.withValues(alpha: 0.2),
                          onSelected: (v) =>
                              setState(() => transactionType = 'expense'),
                        ),
                        ChoiceChip(
                          label: const Text('Contribution (Added)'),
                          selected: transactionType == 'contribution',
                          selectedColor: Colors.green.withValues(alpha: 0.2),
                          onSelected: (v) =>
                              setState(() => transactionType = 'contribution'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      decoration: InputDecoration(
                        labelText:
                            'Amount (${provider.currentWallet?.currency ?? '₱'})',
                        hintText: 'e.g. 250 or 150 + 50',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    // Paid By Selector
                    if (provider.members.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue:
                            paidById.isNotEmpty &&
                                provider.members.any(
                                  (m) => m.userId == paidById,
                                )
                            ? paidById
                            : provider.members.first.userId,
                        decoration: const InputDecoration(labelText: 'Paid By'),
                        items: provider.members.map((m) {
                          return DropdownMenuItem(
                            value: m.userId,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 6,
                                  backgroundColor: Color(m.colorHex),
                                ),
                                const SizedBox(width: 8),
                                Text(m.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final m = provider.members.firstWhere(
                              (e) => e.userId == val,
                            );
                            setState(() {
                              paidById = m.userId;
                              paidByName = m.name;
                              paidByColorHex = m.colorHex;
                            });
                          }
                        },
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Description',
                        hintText: 'e.g. Dinner with team',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          child: const Text('Change Date'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final amount = parseAmount(amountCtrl.text);
                          if (amount > 0) {
                            setState(() => isSubmitting = true);
                            try {
                              final saved = await provider.addTransaction(
                                amount: amount,
                                transactionType: transactionType,
                                category: selectedCategory,
                                notes: notesCtrl.text.trim().isNotEmpty
                                    ? notesCtrl.text.trim()
                                    : null,
                                date: selectedDate,
                                paidByName: paidByName,
                                paidById: paidById,
                                paidByColorHex: paidByColorHex,
                              );
                              if (ctx.mounted) {
                                if (saved) {
                                  Navigator.pop(ctx);
                                } else {
                                  setState(() => isSubmitting = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        provider.connectionError ??
                                            'Could not save the transaction.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            } catch (_) {
                              if (ctx.mounted) {
                                setState(() => isSubmitting = false);
                              }
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Add to Group'),
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
    final provider = context.watch<GroupWalletProvider>();
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        if (provider.isConnected && provider.isTablesReady) {
          await provider.fetchWallets();
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Top Status & Profile Bar ──────────────────────────────
            _buildTopStatusRow(context, provider, theme),
            const SizedBox(height: 14),

            // ── 2. Configuration & Setup Warnings (if not ready) ─────────
            if (!provider.hasProfile)
              _buildSetupProfileCard(context, theme)
            else if (!provider.isConfigured || !provider.isConnected)
              _buildSetupSupabaseCard(context, provider, theme)
            else if (!provider.isTablesReady)
              _buildSetupTablesCard(context, provider, theme)
            else if (provider.currentWallet == null)
              _buildNoWalletsCard(context, provider, theme)
            else ...[
              // ── 3. Active Group Wallet Header & Switcher ───────────────
              _buildWalletHeaderCard(context, provider, theme),
              const SizedBox(height: 14),

              // ── 4. Collective Budget Overview Card ────────────────────
              _buildCollectiveBudgetCard(context, provider, theme),
              const SizedBox(height: 14),

              // ── 5. Member Shares & Contributions Breakdown ────────────
              _buildMemberBreakdownCard(context, provider, theme),
              const SizedBox(height: 20),

              // ── 6. Group Transactions Section ─────────────────────────
              _buildTransactionsSection(context, provider, theme),
            ],

            const SizedBox(height: 80), // Padding to avoid FAB overlap
          ],
        ),
      ),
    );
  }

  // ── Widgets: Top Status Bar ───────────────────────────────────────────
  Widget _buildTopStatusRow(
    BuildContext context,
    GroupWalletProvider provider,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Profile Chip / Button
        InkWell(
          onTap: () => _showProfileDialog(context, provider.profile),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: provider.hasProfile
                      ? Color(provider.profile!.colorHex)
                      : Colors.grey,
                  child: Text(
                    provider.hasProfile && provider.profile!.name.isNotEmpty
                        ? provider.profile!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  provider.hasProfile ? provider.profile!.name : 'Set Profile',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit, size: 12, color: theme.colorScheme.secondary),
              ],
            ),
          ),
        ),

        // Supabase Status Badge
        InkWell(
          onTap: () => _showSupabaseConfigDialog(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud,
                  size: 14,
                  color: provider.isConnected && provider.isTablesReady
                      ? Colors.green
                      : (provider.isConnected ? Colors.orange : Colors.grey),
                ),
                const SizedBox(width: 6),
                Text(
                  provider.isConnected && provider.isTablesReady
                      ? 'Supabase Connected'
                      : (provider.isConnected
                            ? 'Tables Missing'
                            : 'Setup Supabase'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: provider.isConnected && provider.isTablesReady
                        ? Colors.green
                        : (provider.isConnected ? Colors.orange : null),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Widgets: Setup Cards ──────────────────────────────────────────────
  Widget _buildSetupProfileCard(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_pin_rounded, size: 48, color: Colors.purple),
          const SizedBox(height: 12),
          Text(
            'Create Your Local Profile',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Before accessing group wallets, set up your display name and avatar color. Your profile stays safely stored on this device.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showProfileDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupSupabaseCard(
    BuildContext context,
    GroupWalletProvider provider,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_sync_rounded, size: 48, color: Colors.blue),
          const SizedBox(height: 12),
          Text(
            'Connect Supabase API',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Group wallets use Supabase to sync collective budgets and transactions across members in real time. Add your project URL and API key to connect.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          if (provider.connectionError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                provider.connectionError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showSupabaseConfigDialog(context),
            icon: const Icon(Icons.key),
            label: const Text('Add Supabase API Key'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupTablesCard(
    BuildContext context,
    GroupWalletProvider provider,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        children: [
          const Icon(Icons.table_chart_rounded, size: 48, color: Colors.orange),
          const SizedBox(height: 12),
          Text(
            'Database Tables Setup Required',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connected to Supabase, but the group wallet tables (`group_wallets`, `group_members`, `group_transactions`) were not found in your database.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: () async {
                  final ok = await provider.attemptAutoInitTables();
                  if (context.mounted) {
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tables initialized successfully!'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Auto-init requires SQL execution permissions. Please copy and run the SQL script.',
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: const Text('Auto-Init'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => _showSqlScriptDialog(context),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy SQL Script'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => provider.checkDatabaseTables(),
            child: const Text('Re-check Tables'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWalletsCard(
    BuildContext context,
    GroupWalletProvider provider,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'No Group Wallets Found',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a group wallet for your family, flatmates, or travel group, or join an existing one with its Wallet ID.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => _showCreateWalletDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Wallet'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _showJoinWalletDialog(context),
                icon: const Icon(Icons.login, size: 16),
                label: const Text('Join with ID'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Widgets: Active Wallet Header & Collective Budget ─────────────────
  Widget _buildWalletHeaderCard(
    BuildContext context,
    GroupWalletProvider provider,
    ThemeData theme,
  ) {
    final wallet = provider.currentWallet!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        wallet.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${provider.members.length} members',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (wallet.description != null &&
                    wallet.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    wallet.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'switch') {
                _showWalletPicker(context, provider);
              } else if (val == 'copy_id') {
                Clipboard.setData(ClipboardData(text: wallet.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Wallet ID copied! Share with group members.',
                    ),
                  ),
                );
              } else if (val == 'new') {
                _showCreateWalletDialog(context);
              } else if (val == 'join') {
                _showJoinWalletDialog(context);
              } else if (val == 'remove') {
                _showRemoveWalletDialog(context, provider, wallet);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'switch',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 18),
                    SizedBox(width: 8),
                    Text('Switch Wallet'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy_id',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 18),
                    SizedBox(width: 8),
                    Text('Copy Wallet ID'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'new',
                child: Row(
                  children: [
                    Icon(Icons.add, size: 18),
                    SizedBox(width: 8),
                    Text('New Wallet'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'join',
                child: Row(
                  children: [
                    Icon(Icons.login, size: 18),
                    SizedBox(width: 8),
                    Text('Join Wallet'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Remove Wallet', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showWalletPicker(BuildContext context, GroupWalletProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Group Wallet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(height: 1),
              ...provider.wallets.map((w) {
                final isSelected = provider.currentWallet?.id == w.id;
                return ListTile(
                  title: Text(w.name),
                  subtitle: Text('Currency: ${w.currency}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(right: 4.0),
                          child: Icon(Icons.check, color: Colors.green),
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Remove Group Wallet',
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showRemoveWalletDialog(context, provider, w);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    provider.selectWallet(w);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create New Wallet'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateWalletDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollectiveBudgetCard(
    BuildContext context,
    GroupWalletProvider provider,
    ThemeData theme,
  ) {
    final wallet = provider.currentWallet!;
    final currency = wallet.currency;
    final pool = provider.collectivePoolBalance;
    final totalIncome = provider.collectiveTotalIncome;
    final totalExpenses = provider.collectiveTotalExpenses;

    final poolStr = NumberFormat('#,##0.00').format(pool.abs());
    final displayPool = pool < 0 ? '-$currency$poolStr' : '$currency$poolStr';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
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
                    Icons.account_balance_outlined,
                    size: 18,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Collective Pool Balance',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (pool >= 0 ? Colors.green : Colors.red).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  pool >= 0 ? 'Funds Available' : 'Deficit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: pool >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayPool,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: pool < 0 ? Colors.red : null,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Contributions
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Contributions',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+$currency${NumberFormat('#,##0.00').format(totalIncome)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Expenses
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 14,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Group Expenses',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '-$currency${NumberFormat('#,##0.00').format(totalExpenses)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberBreakdownCard(
    BuildContext context,
    GroupWalletProvider provider,
    ThemeData theme,
  ) {
    final currency = provider.currentWallet?.currency ?? '₱';
    final contributions = provider.memberContributionMap;
    final expenses = provider.memberExpenseMap;
    final members = provider.members;

    if (members.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Member Breakdown',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...members.map((m) {
            final contributed = contributions[m.userId] ?? 0.0;
            final spent = expenses[m.userId] ?? 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(m.colorHex),
                    child: Text(
                      m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Contributed: +$currency${NumberFormat('#,##0.00').format(contributed)}  •  Spent: -$currency${NumberFormat('#,##0.00').format(spent)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Widgets: Transactions List ────────────────────────────────────────
  Widget _buildTransactionsSection(
    BuildContext context,
    GroupWalletProvider provider,
    ThemeData theme,
  ) {
    final currency = provider.currentWallet?.currency ?? '₱';

    final filtered = provider.transactions.where((tx) {
      if (_txFilter == 'Expenses') return tx.isExpense;
      if (_txFilter == 'Contributions') return tx.isContribution;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Group Transactions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            FilledButton.icon(
              onPressed: () => _showAddTransactionDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Transaction'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Filter chips
        Row(
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _txFilter == 'All',
              onSelected: (v) => setState(() => _txFilter = 'All'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Expenses'),
              selected: _txFilter == 'Expenses',
              onSelected: (v) => setState(() => _txFilter = 'Expenses'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Contributions'),
              selected: _txFilter == 'Contributions',
              onSelected: (v) => setState(() => _txFilter = 'Contributions'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 36,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No group transactions found',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "Add Transaction" above to record a collective expense or contribution.',
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
            children: filtered.map((tx) {
              final isContribution = tx.isContribution;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(
                        tx.paidByColorHex,
                      ).withValues(alpha: 0.18),
                      child: Text(
                        tx.paidByName.isNotEmpty
                            ? tx.paidByName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Color(tx.paidByColorHex),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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
                                      : tx.category,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: Text(
                                  tx.category,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Paid by ${tx.paidByName} • ${DateFormat('MMM d, yyyy • hh:mm a').format(tx.date)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isContribution ? '+' : '-'}$currency${NumberFormat('#,##0.00').format(tx.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isContribution
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                title: const Text('Delete Transaction'),
                                content: const Text(
                                  'Are you sure you want to remove this group transaction?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      provider.deleteTransaction(tx.id);
                                      Navigator.pop(dCtx);
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.delete_outline,
                              size: 14,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
