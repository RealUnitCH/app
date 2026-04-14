import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/screens/debug_auth/cubit/debug_auth_cubit.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';

class DebugAuthView extends StatefulWidget {
  const DebugAuthView({super.key});

  @override
  State<DebugAuthView> createState() => _DebugAuthViewState();
}

class _DebugAuthViewState extends State<DebugAuthView> {
  late final TextEditingController _addressController;
  late final TextEditingController _signatureController;

  @override
  void initState() {
    super.initState();
    final state = context.read<DebugAuthCubit>().state;
    _addressController = TextEditingController(text: state.address);
    _signatureController = TextEditingController(text: state.savedSignature ?? '');
  }

  @override
  void dispose() {
    _addressController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Debug Auth')),
    body: BlocListener<DebugAuthCubit, DebugAuthState>(
      listenWhen: (prev, curr) =>
          !prev.isAuthenticated && curr.isAuthenticated,
      listener: (context, state) {
        context.read<HomeBloc>().add(const DebugAuthCompleteEvent());
      },
      child: BlocBuilder<DebugAuthCubit, DebugAuthState>(
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Wallet Address',
                  hintText: '0x...',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () => context
                        .read<DebugAuthCubit>()
                        .fetchSignMessage(
                          _addressController.text.trim(),
                        ),
                child: const Text('Fetch Sign Message'),
              ),
              if (state.signMessage != null) ...[
                const Divider(color: RealUnitColors.neutral200),
                Text(
                  'Sign Message:',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: state.signMessage!),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: RealUnitColors.neutral100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      state.signMessage!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                TextField(
                  controller: _signatureController,
                  decoration: const InputDecoration(
                    labelText: 'Signature',
                    hintText: '0x...',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                ),
                ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () => context
                          .read<DebugAuthCubit>()
                          .authenticate(
                            _signatureController.text.trim(),
                          ),
                  child: const Text('Authenticate'),
                ),
              ],
              if (state.isAuthenticated)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: RealUnitColors.green
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Authenticated! Token set in AppStore.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: RealUnitColors.green,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              if (state.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: RealUnitColors.status.red600
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: RealUnitColors.status.red600,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
