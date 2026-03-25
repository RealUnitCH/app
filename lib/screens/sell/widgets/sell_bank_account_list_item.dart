import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/bank_account/bank_account.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/iban_text_formatter.dart';

class SellBankAccountListItem extends StatelessWidget {
  const SellBankAccountListItem({
    required this.account,
    this.onTap,
    this.onDelete,
    super.key,
  });

  final BankAccount account;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = account.isActive;
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          border: .all(color: RealUnitColors.neutral300),
          color: isActive ? RealUnitColors.brand200 : RealUnitColors.neutral200,
          borderRadius: .circular(12.0),
        ),
        padding: const .symmetric(
          horizontal: 12.0,
          vertical: 8.0,
        ),
        child: Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Expanded(
              child: Column(
                spacing: 4.0,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    isActive
                        ? account.name ?? '${S.of(context).without} ${S.of(context).label}'
                        : S.of(context).deactivated,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isActive ? RealUnitColors.neutral600 : RealUnitColors.neutral500,
                    ),
                  ),
                  Text(
                    IbanTextFormatter.formatIban(account.iban),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: .w600,
                      color: isActive ? null : RealUnitColors.realUnitBlack.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: isActive && onDelete != null,
              maintainSize: true,
              maintainState: true,
              maintainAnimation: true,
              child: IconButton(
                onPressed: onDelete,
                style: IconButton.styleFrom(
                  backgroundColor: RealUnitColors.neutral50,
                  side: const BorderSide(
                    color: RealUnitColors.neutral400,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: .circular(8.0),
                  ),
                ),
                icon: const Icon(
                  Icons.delete_outline_outlined,
                  color: RealUnitColors.realUnitBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
