import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/blast_provider.dart';

class EditTripDialog extends ConsumerWidget {
  final dynamic trip;
  final int? firstTripId;
  final int entriesCount;
  final int blastId;

  const EditTripDialog({
    super.key,
    required this.trip,
    required this.firstTripId,
    required this.entriesCount,
    required this.blastId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (firstTripId == null) return const SizedBox.shrink();

    final controller = TextEditingController(text: trip['trips_count'].toString());

    return AlertDialog(
      title: Text('Edit Trip - ${trip['vehicle_number']}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entriesCount > 1)
            Text(
              'Note: This will update 1 of $entriesCount entries for this vehicle',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Number of Trips',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final newCount = int.tryParse(controller.text);
            if (newCount == null || newCount < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid number')),
              );
              return;
            }
            Navigator.pop(context);
            await ref.read(blastProvider.notifier).updateTrip(firstTripId!, {
              'trips_count': newCount,
              'blast_id': blastId,
            });
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class EditExpenseDialog extends ConsumerWidget {
  final dynamic expense;
  final int blastId;

  const EditExpenseDialog({
    super.key,
    required this.expense,
    required this.blastId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseId = int.tryParse(expense['id'].toString());
    if (expenseId == null) return const SizedBox.shrink();

    final amountController = TextEditingController(text: expense['amount']?.toString() ?? '');
    final descriptionController = TextEditingController(text: expense['description']?.toString() ?? '');
    String selectedType = expense['expense_type']?.toString() ?? 'other';

    return AlertDialog(
      title: const Text('Edit Expense'),
      content: StatefulBuilder(
        builder: (context, setDialogState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Expense Type', border: OutlineInputBorder()),
                items: ['labour', 'material', 'machinery', 'transport', 'loading', 'drilling', 'other']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type[0].toUpperCase() + type.substring(1))))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => selectedType = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final amount = double.tryParse(amountController.text);
            if (amount == null || amount < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid amount')),
              );
              return;
            }
            Navigator.pop(context);
            await ref.read(blastProvider.notifier).updateExpense(expenseId, {
              'expense_type': selectedType,
              'description': descriptionController.text,
              'amount': amount,
              'blast_id': blastId,
            });
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final Color? confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: confirmColor != null
              ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
              : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class DeleteTripDialog extends StatelessWidget {
  final List<int> tripIds;
  final WidgetRef ref;
  final int blastId;

  const DeleteTripDialog({
    super.key,
    required this.tripIds,
    required this.ref,
    required this.blastId,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Trips'),
      content: Text('Delete ${tripIds.length} trip record(s)?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            for (final id in tripIds) {
              await ref.read(blastProvider.notifier).deleteTrip(id);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

class DeleteExpenseDialog extends StatelessWidget {
  final int expenseId;
  final WidgetRef ref;

  const DeleteExpenseDialog({
    super.key,
    required this.expenseId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Expense'),
      content: const Text('Are you sure?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ref.read(blastProvider.notifier).deleteExpense(expenseId);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}